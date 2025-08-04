//
//  TaxDocRow.swift
//  Aure
//
//  Reusable tax document row component
//

import SwiftUI

struct TaxDocRow: View {
    let document: TaxDocument
    let showDivider: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    // File type icon
                    Image(systemName: document.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(document.iconColor)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(document.displayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appPrimaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let year = document.year {
                            Text(year)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if let fileSize = document.formattedFileSize {
                        Text(fileSize)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.appSecondaryText)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appSecondaryText.opacity(0.6))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            
            if showDivider {
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Tax Document Model
struct TaxDocument: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let url: URL
    let fileSize: Int64?
    let uploadDate: Date?
    
    var displayName: String {
        // Remove file extension for display
        let nameWithoutExtension = fileName.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
        
        // Clean up common naming patterns
        return nameWithoutExtension
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
    
    var year: String? {
        // Extract year from filename
        let yearRegex = try? NSRegularExpression(pattern: "\\b(20\\d{2})\\b")
        let range = NSRange(location: 0, length: fileName.utf16.count)
        
        if let match = yearRegex?.firstMatch(in: fileName, options: [], range: range) {
            let yearRange = Range(match.range, in: fileName)
            return yearRange.map { String(fileName[$0]) }
        }
        
        return nil
    }
    
    var iconName: String {
        if fileName.lowercased().contains("1099") {
            return "doc.text.fill"
        } else if fileName.lowercased().contains("w-9") || fileName.lowercased().contains("w9") {
            return "doc.plaintext.fill"
        } else if fileName.lowercased().contains("receipt") {
            return "receipt.fill"
        } else {
            return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if fileName.lowercased().contains("1099") {
            return Color.blue
        } else if fileName.lowercased().contains("w-9") || fileName.lowercased().contains("w9") {
            return Color.green
        } else if fileName.lowercased().contains("receipt") {
            return Color.orange
        } else {
            return Color.appAccentBlue
        }
    }
    
    var formattedFileSize: String? {
        guard let fileSize = fileSize else { return nil }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Tax Documents ViewModel
@MainActor
class TaxDocsViewModel: ObservableObject {
    @Published var documents: [TaxDocument] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fileService = SupabaseFileService()
    
    func loadDocuments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let files = await fileService.listTaxDocuments()
            documents = files.map { fileInfo in
                TaxDocument(
                    fileName: fileInfo.name,
                    url: fileInfo.url,
                    fileSize: fileInfo.size,
                    uploadDate: fileInfo.uploadDate
                )
            }.sorted { doc1, doc2 in
                // Sort by year (newest first), then by type
                if let year1 = doc1.year, let year2 = doc2.year {
                    return year1 > year2
                }
                return doc1.displayName < doc2.displayName
            }
        } catch {
            errorMessage = "Failed to load documents: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func uploadDocument(fileName: String, data: Data) async throws {
        do {
            let uploadedURL = try await fileService.uploadTaxDocument(fileData: data, fileName: fileName)
            print("📤 Document uploaded to: \(uploadedURL)")
            
            // Add the new document to the list
            let newDocument = TaxDocument(
                fileName: fileName,
                url: uploadedURL,
                fileSize: Int64(data.count),
                uploadDate: Date()
            )
            
            await MainActor.run {
                documents.append(newDocument)
                documents.sort { doc1, doc2 in
                    // Sort by year (newest first), then by type
                    if let year1 = doc1.year, let year2 = doc2.year {
                        return year1 > year2
                    }
                    return doc1.displayName < doc2.displayName
                }
            }
        } catch {
            errorMessage = "Failed to upload document: \(error.localizedDescription)"
            throw error
        }
    }
    
    func deleteDocument(_ document: TaxDocument) async {
        do {
            await fileService.deleteFile(at: document.url)
            documents.removeAll { $0.id == document.id }
        } catch {
            errorMessage = "Failed to delete document: \(error.localizedDescription)"
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        TaxDocRow(
            document: TaxDocument(
                fileName: "1099-NEC-2023.pdf",
                url: URL(string: "https://example.com/doc.pdf")!,
                fileSize: 245760,
                uploadDate: Date()
            ),
            showDivider: true
        ) {
            print("Document tapped")
        }
        
        TaxDocRow(
            document: TaxDocument(
                fileName: "W-9-Form.pdf",
                url: URL(string: "https://example.com/doc2.pdf")!,
                fileSize: 180000,
                uploadDate: Date()
            ),
            showDivider: true
        ) {
            print("Document tapped")
        }
        
        TaxDocRow(
            document: TaxDocument(
                fileName: "1099-2022.pdf",
                url: URL(string: "https://example.com/doc3.pdf")!,
                fileSize: 320000,
                uploadDate: Date()
            ),
            showDivider: false
        ) {
            print("Document tapped")
        }
    }
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.appCardBackground)
    )
    .padding()
    .background(Color.appBackground)
}
