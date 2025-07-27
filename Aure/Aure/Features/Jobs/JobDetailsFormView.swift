//
//  JobDetailsFormView.swift
//  Aure
//
//  First screen of simplified job creation - job details form
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct JobDetailsFormView: View {
    @Binding var jobData: SimpleJobData
    let onNext: () -> Void
    @State private var amountText = ""
    @State private var showingFilePicker = false
    @State private var commissionText = ""
    @State private var amountFieldFocused = false
    @State private var commissionFieldFocused = false
    @State private var paymentTermsRefreshTrigger = UUID()
    
    private var canContinue: Bool {
        !jobData.clientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jobData.jobTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jobData.bookedBy.trimmingCharacters(in: .whitespaces).isEmpty &&
        jobData.amount > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Job Details")
                        .font(.newYorkTitle2Bold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text("Enter the basic information about this job")
                        .font(.newYorkSubheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // File Upload Section - Moved to top
                FileUploadSectionView(jobData: $jobData)
                
                VStack(spacing: 20) {
                    // Client Name
                    FormFieldView(
                        title: "Client/Brand Name",
                        placeholder: "e.g., Calvin Klein",
                        text: $jobData.clientName
                    )
                    
                    // Job Title
                    FormFieldView(
                        title: "Job Title",
                        placeholder: "e.g., Runway Show, Editorial Shoot",
                        text: $jobData.jobTitle
                    )
                    
                    // Booked By
                    FormFieldView(
                        title: "Booked By",
                        placeholder: "e.g., Agent Name",
                        text: $jobData.bookedBy
                    )
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Job Amount (USD)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                        
                        HStack {
                            Text("$")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                                .padding(.leading, 16)
                            
                            TextField("0", text: $amountText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                                .keyboardType(.numberPad)
                                .onTapGesture {
                                    amountFieldFocused = true
                                }
                                .onChange(of: amountText) { _, newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        amountText = filtered
                                    }
                                    jobData.amount = Double(filtered) ?? 0
                                }
                                .padding(.trailing, 16)
                        }
                        .frame(height: 50)
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(getBorderColor(amount: jobData.amount, focused: amountFieldFocused), lineWidth: 1)
                        )
                    }
                    
                    // Commission Percentage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Agency Commission (%)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                        
                        HStack {
                            TextField("20", text: $commissionText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                                .keyboardType(.numberPad)
                                .onTapGesture {
                                    commissionFieldFocused = true
                                }
                                .onChange(of: commissionText) { _, newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        commissionText = filtered
                                    }
                                    if let percentage = Int(filtered), percentage <= 100 {
                                        jobData.commissionPercentage = percentage
                                    } else {
                                        // If empty or invalid, keep current value but clear text
                                        if filtered.isEmpty {
                                            jobData.commissionPercentage = 0
                                        }
                                    }
                                }
                                .padding(.leading, 16)
                            
                            Text("%")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                                .padding(.trailing, 16)
                        }
                        .frame(height: 50)
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(getBorderColor(amount: Double(jobData.commissionPercentage), focused: commissionFieldFocused), lineWidth: 1)
                        )
                        
                        if jobData.amount > 0 && jobData.commissionPercentage > 0 {
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Gross Amount:")
                                    Spacer()
                                    Text(jobData.formattedAmount)
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                                
                                HStack {
                                    Text("Commission (\(jobData.commissionPercentage)%):")
                                    Spacer()
                                    Text("-\(formatCurrency(jobData.amount * Double(jobData.commissionPercentage) / 100.0))")
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                }
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                                
                                HStack {
                                    Text("Net Amount:")
                                    Spacer()
                                    Text(formatCurrency(jobData.netAmount))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    // Job Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Job Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                        
                        DatePicker(
                            "Job Date",
                            selection: $jobData.jobDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .onChange(of: jobData.jobDate) { _, _ in
                            jobData.updateDueDate()
                        }
                    }
                    
                    // Payment Terms
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Terms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Menu {
                            ForEach(PaymentTerms.allCases, id: \.self) { term in
                                Button(term.rawValue) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        jobData.paymentTerms = term
                                        print("🔵 Payment terms changed to: \(term.rawValue)")
                                        jobData.updateDueDate()
                                        paymentTermsRefreshTrigger = UUID()
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(jobData.paymentTerms.rawValue)
                                    .foregroundColor(Color.appPrimaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.appSecondaryText)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                        
                        Text(jobData.paymentTerms.description)
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                            .padding(.top, 4)
                    }
                    
                    // Custom Due Date (if custom terms selected)
                    if jobData.paymentTerms == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom Due Date")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.appPrimaryText)
                            
                            DatePicker(
                                "Due Date",
                                selection: $jobData.paymentDueDate,
                                in: jobData.jobDate...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                    } else {
                        // Show calculated due date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Payment Due Date")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.appPrimaryText)
                            
                            HStack {
                                Text(jobData.paymentDueDate, style: .date)
                                    .foregroundColor(Color.appPrimaryText)
                                    .id(paymentTermsRefreshTrigger)
                                
                                Spacer()
                                
                                Button("Edit") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        jobData.paymentTerms = .custom
                                        paymentTermsRefreshTrigger = UUID()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.appCardBackground.opacity(0.5))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                    }
                    
                    // Notes (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                        
                        TextField("Additional details about the job...", text: $jobData.notes, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 80, alignment: .topLeading)
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                    }
                }
                
                // Continue Button
                Button(action: onNext) {
                    Text("Continue to Summary")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(canContinue ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canContinue)
                .buttonStyle(.springyRipple)
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for tab bar
        }
        .background(Color.appBackground)
        .onAppear {
            // Initialize text fields with current values
            if amountText.isEmpty {
                amountText = jobData.amount > 0 ? String(format: "%.0f", jobData.amount) : ""
            }
            if commissionText.isEmpty {
                commissionText = jobData.commissionPercentage > 0 ? String(jobData.commissionPercentage) : "20"
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func getBorderColor(amount: Double, focused: Bool) -> Color {
        if focused {
            return Color.blue
        } else {
            return Color.appBorder
        }
    }
}

// MARK: - Form Field Component
struct FormFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appPrimaryText)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .textInputAutocapitalization(.words)
        }
    }
}

// MARK: - File Upload Section Component
struct FileUploadSectionView: View {
    @Binding var jobData: SimpleJobData
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attachments (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 12) {
                // Upload button
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upload Files")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text("Contracts, briefs, reference materials")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
                
                // Uploaded files list
                if !jobData.uploadedFileNames.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(jobData.uploadedFileNames.enumerated()), id: \.offset) { index, fileName in
                            HStack {
                                Image(systemName: fileIcon(for: fileName))
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                Text(fileName)
                                    .font(.subheadline)
                                    .foregroundColor(Color.appPrimaryText)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .skeletonShimmer(when: false) // Shimmer while loading metadata
                                
                                Spacer()
                                
                                Button(action: {
                                    removeFile(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red.opacity(0.7))
                                        .font(.title3)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // File count indicator
                if !jobData.uploadedFileNames.isEmpty {
                    HStack {
                        Text("\\(jobData.uploadedFileNames.count) file(s) attached")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .jpeg, .png, .heic, .zip, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                handleSelectedFiles(urls)
            case .failure(let error):
                print("🔴 File picker error: \(error)")
            }
        }
    }
    
    private func fileIcon(for fileName: String) -> String {
        let lowercaseName = fileName.lowercased()
        if lowercaseName.hasSuffix(".pdf") {
            return "doc.fill"
        } else if lowercaseName.hasSuffix(".jpg") || lowercaseName.hasSuffix(".jpeg") || lowercaseName.hasSuffix(".png") || lowercaseName.hasSuffix(".heic") {
            return "photo.fill"
        } else if lowercaseName.hasSuffix(".zip") {
            return "archivebox.fill"
        } else {
            return "doc.text.fill"
        }
    }
    
    private func handleSelectedFiles(_ urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("🔴 Cannot access file: \\(url)")
                continue
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Copy file to app's documents directory
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileName = url.lastPathComponent
                let destinationURL = documentsURL.appendingPathComponent(fileName)
                
                do {
                    // Remove existing file if it exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    // Copy file
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    
                    // Add to job data
                    jobData.uploadedFiles.append(destinationURL)
                    jobData.uploadedFileNames.append(fileName)
                    
                    print("✅ File copied successfully: \\(fileName)")
                } catch {
                    print("🔴 Error copying file: \\(error)")
                }
            }
        }
    }
    
    private func removeFile(at index: Int) {
        guard index < jobData.uploadedFiles.count && index < jobData.uploadedFileNames.count else {
            return
        }
        
        let fileURL = jobData.uploadedFiles[index]
        
        // Remove from file system
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ File removed: \\(jobData.uploadedFileNames[index])")
        } catch {
            print("🔴 Error removing file: \\(error)")
        }
        
        // Remove from arrays
        jobData.uploadedFiles.remove(at: index)
        jobData.uploadedFileNames.remove(at: index)
    }
}

#Preview {
    @State var previewData = SimpleJobData()
    return JobDetailsFormView(jobData: $previewData) {
        // Preview action
    }
}