//
//  TaxDocsView.swift
//  Aure
//
//  Tax documents listing view with QuickLook preview
//

import SwiftUI
import QuickLook
import UniformTypeIdentifiers

enum DocumentUploadError: Error, LocalizedError {
    case accessDenied
    case invalidFile
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to the file was denied"
        case .invalidFile:
            return "The selected file is invalid"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}

struct TaxDocsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TaxDocsViewModel()
    @State private var showingPreview = false
    @State private var selectedDocument: TaxDocument?
    @State private var showingFilePicker = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    documentsSection
                    otherSection
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 20)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(Color.appBackground)
        .task {
            await viewModel.loadDocuments()
        }
        .sheet(isPresented: $showingPreview) {
            if let document = selectedDocument {
                QuickLookPreview(url: document.url)
                    .ignoresSafeArea()
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .image, UTType(filenameExtension: "docx") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    // MARK: - File Upload Handling
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            uploadDocument(from: url)
        case .failure(let error):
            print("🔴 File selection failed: \(error.localizedDescription)")
            viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func uploadDocument(from url: URL) {
        Task {
            isUploading = true
            uploadProgress = 0.0
            
            do {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw DocumentUploadError.accessDenied
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Read file data
                let fileData = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                
                print("📤 Uploading document: \(fileName) (\(fileData.count) bytes)")
                
                // Simulate upload progress (replace with actual upload progress when available)
                await updateUploadProgress()
                
                // Upload to Supabase
                try await viewModel.uploadDocument(fileName: fileName, data: fileData)
                
                // Reload documents to show the new upload
                await viewModel.loadDocuments()
                
                await MainActor.run {
                    uploadProgress = 1.0
                    isUploading = false
                    print("✅ Document uploaded successfully")
                }
                
            } catch {
                await MainActor.run {
                    isUploading = false
                    uploadProgress = 0.0
                    viewModel.errorMessage = "Upload failed: \(error.localizedDescription)"
                    print("🔴 Upload failed: \(error)")
                }
            }
        }
    }
    
    private func updateUploadProgress() async {
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                uploadProgress = Double(i) / 10.0
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.appPrimaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.appCardBackground.opacity(0.6))
                    )
            }
            
            Spacer()
            
            Text("Tax Documents")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.appPrimaryText)
            
            Spacer()
            
            // Upload button
            Button(action: {
                showingFilePicker = true
            }) {
                Image(systemName: isUploading ? "arrow.up.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isUploading ? Color.appSecondaryText : Color.appAccentBlue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.appCardBackground.opacity(0.6))
                    )
                    .overlay(
                        // Upload progress ring
                        isUploading ? Circle()
                            .trim(from: 0, to: uploadProgress)
                            .stroke(Color.appAccentBlue, lineWidth: 2)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 40, height: 40) : nil
                    )
            }
            .disabled(isUploading)
        }
    }
    
    // MARK: - Documents Section
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documents")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.appPrimaryText.opacity(0.9))
                .padding(.horizontal, 4)
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.documents.isEmpty {
                emptyStateView
            } else {
                documentsListView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appCardBackground.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appCardBackground.opacity(0.3))
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appCardBackground.opacity(0.2))
                            .frame(width: 80, height: 12)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appSecondaryText.opacity(0.3))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground)
                )
            }
        }
        .redacted(reason: .placeholder)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color.appSecondaryText.opacity(0.6))
            
            Text("No Documents")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.appPrimaryText.opacity(0.8))
            
            Text("Your tax documents will appear here once uploaded")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                showingFilePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Upload Document")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appAccentBlue)
                )
            }
            .padding(.top, 20)
            .disabled(isUploading)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
        )
    }
    
    private var documentsListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.documents.enumerated()), id: \.element.id) { index, document in
                TaxDocRow(
                    document: document,
                    showDivider: index < viewModel.documents.count - 1
                ) {
                    selectedDocument = document
                    showingPreview = true
                }
                .contextMenu {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteDocument(document)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        shareDocument(document)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
        )
    }
    
    // MARK: - Other Section
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.appPrimaryText.opacity(0.9))
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                Button(action: {
                    openHelpFAQ()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.appAccentBlue)
                            .frame(width: 24, height: 24)
                        
                        Text("Help / FAQ")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.appPrimaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("How to file taxes as a model")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.appSecondaryText)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, 16)
                
                Button(action: {
                    contactSupport()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.appAccentBlue)
                            .frame(width: 24, height: 24)
                        
                        Text("Contact Support")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.appPrimaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
            )
        }
    }
    
    // MARK: - Helper Functions
    private func shareDocument(_ document: TaxDocument) {
        let activityVC = UIActivityViewController(activityItems: [document.url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func openHelpFAQ() {
        // Open help/FAQ URL or navigate to help view
        if let url = URL(string: "https://aure.com/help/tax-guide") {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        // Open mailto link for support
        if let url = URL(string: "mailto:support@aure.com?subject=Tax%20Document%20Support") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - QuickLook Preview
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview
        
        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}

#Preview {
    TaxDocsView()
}