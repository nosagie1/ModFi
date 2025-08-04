//
//  PaymentStatusView.swift
//  Aure
//
//  Payment status selection step after job creation
//

import SwiftUI

struct PaymentStatusView: View {
    @ObservedObject var jobData: JobSetupData
    let onComplete: () -> Void
    let onCreateJob: (PaymentStatus) async throws -> Void
    @State private var selectedStatus: PaymentStatus = .pending
    @State private var isCreatingJob = false
    @State private var expectedPaymentDate = Date()
    @State private var errorMessage: String?
    
    init(jobData: JobSetupData, onComplete: @escaping () -> Void, onCreateJob: @escaping (PaymentStatus) async throws -> Void) {
        self.jobData = jobData
        self.onComplete = onComplete
        self.onCreateJob = onCreateJob
        // Initialize expected payment date to the payment due date
        self._expectedPaymentDate = State(initialValue: jobData.paymentDueDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.appAccentBlue)
                    
                    Text("Payment Status")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("What's the current payment status?")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Job Summary Card
                VStack(spacing: 16) {
                    Text("Job Summary")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Client:")
                            Spacer()
                            Text(jobData.clientName)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Amount:")
                            Spacer()
                            Text(formatCurrency(jobData.amount))
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Commission (\(jobData.commissionPercentage)%):")
                            Spacer()
                            Text("-\(formatCurrency(jobData.commissionAmount))")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Net Amount:")
                            Spacer()
                            Text(formatCurrency(jobData.netAmount))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.appPrimaryText)
                        }
                        
                        HStack {
                            Text("Due Date:")
                            Spacer()
                            Text(jobData.paymentDueDate, style: .date)
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .padding(.horizontal, 32)
                
                // Payment Status Options
                VStack(spacing: 12) {
                    Text("Select Payment Status")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                        .padding(.horizontal, 32)
                    
                    VStack(spacing: 12) {
                        // First row: Pending, Invoiced, Partially Paid
                        HStack(spacing: 12) {
                            ForEach([PaymentStatus.pending, .invoiced, .partiallyPaid], id: \.self) { status in
                                PaymentStatusOptionView(
                                    status: status,
                                    isSelected: selectedStatus == status
                                ) {
                                    selectedStatus = status
                                }
                            }
                        }
                        
                        // Second row: Received, Overdue
                        HStack(spacing: 12) {
                            ForEach([PaymentStatus.received, .overdue], id: \.self) { status in
                                PaymentStatusOptionView(
                                    status: status,
                                    isSelected: selectedStatus == status
                                ) {
                                    selectedStatus = status
                                }
                            }
                            
                            // Add a spacer to balance the layout
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Show date picker when overdue is selected
                    if selectedStatus == .overdue {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("When was payment expected?")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                                .padding(.horizontal, 32)
                            
                            VStack(spacing: 12) {
                                DatePicker(
                                    "Expected Payment Date",
                                    selection: $expectedPaymentDate,
                                    in: ...Date(),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appCardBackground)
                                .cornerRadius(8)
                                
                                HStack {
                                    Text("Expected:")
                                    Spacer()
                                    Text(expectedPaymentDate, style: .date)
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.appCardBackground.opacity(0.5))
                                .cornerRadius(6)
                            }
                            .padding(.horizontal, 32)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.3), value: selectedStatus)
                    }
                }
                
                Spacer()
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
                
                // Create Job Button
                Button(action: createJob) {
                    HStack {
                        if isCreatingJob {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Color.appButtonText)
                        } else {
                            Text("Create Job")
                                .font(.headline)
                                .foregroundColor(Color.appButtonText)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
                }
                .disabled(isCreatingJob)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onComplete()
                    }
                    .foregroundColor(Color.appAccentBlue)
                }
            }
        }
    }
    
    private func createJob() {
        isCreatingJob = true
        
        // Update job data with expected payment date if overdue
        if selectedStatus == .overdue {
            jobData.expectedPaymentDate = expectedPaymentDate
        }
        
        errorMessage = nil
        Task {
            do {
                try await onCreateJob(selectedStatus)
                await MainActor.run {
                    isCreatingJob = false
                }
            } catch {
                await MainActor.run {
                    isCreatingJob = false
                    errorMessage = "Failed to create job: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct PaymentStatusOptionView: View {
    let status: PaymentStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.white : status.color)
                
                Text(status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color.white : Color.appPrimaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 16)
            .background(isSelected ? status.color : Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? status.color : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    PaymentStatusView(jobData: {
        let data = JobSetupData()
        data.clientName = "Calvin Klein"
        data.amount = 5000
        data.commissionPercentage = 20
        data.bookedBy = "Dupont"
        data.jobTitle = "Runway"
        return data
    }(), onComplete: {
        // completion
    }, onCreateJob: { _ in
        // create job
    })
}