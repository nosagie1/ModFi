//
//  JobSummaryView.swift
//  Aure
//
//  Second screen of simplified job creation - summary and payment status
//

import SwiftUI
import Foundation

struct JobSummaryView: View {
    @Binding var jobData: SimpleJobData
    let isEditMode: Bool
    let onCreateJob: () -> Void
    @State private var isCreatingJob = false
    @State private var errorMessage: String?
    
    init(jobData: Binding<SimpleJobData>, isEditMode: Bool = false, onCreateJob: @escaping () -> Void) {
        self._jobData = jobData
        self.isEditMode = isEditMode
        self.onCreateJob = onCreateJob
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Job Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text("Review the details and set the payment status")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Job Details Summary
                VStack(spacing: 16) {
                    Text("Job Details")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        SummaryRowView(title: "Client", value: jobData.clientName)
                        SummaryRowView(title: "Job Title", value: jobData.jobTitle)
                        SummaryRowView(title: "Booked By", value: jobData.bookedBy)
                        SummaryRowView(title: "Job Date", value: jobData.jobDate.formatted(date: .abbreviated, time: .omitted))
                        
                        Divider()
                        
                        SummaryRowView(title: "Gross Amount", value: jobData.formattedAmount, valueColor: .primary)
                        SummaryRowView(title: "Commission (\(jobData.commissionPercentage)%)", value: "-\(formatCurrency(jobData.amount * Double(jobData.commissionPercentage) / 100))", valueColor: .red)
                        SummaryRowView(title: "Net Amount", value: formatCurrency(jobData.netAmount), valueColor: .green, isHighlighted: true)
                        
                        Divider()
                        
                        SummaryRowView(title: "Payment Terms", value: jobData.paymentTerms.rawValue)
                        SummaryRowView(title: "Due Date", value: jobData.paymentDueDate.formatted(date: .abbreviated, time: .omitted))
                        
                        if !jobData.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.appSecondaryText)
                                
                                Text(jobData.notes)
                                    .font(.subheadline)
                                    .foregroundColor(Color.appPrimaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                
                // Payment Status Selection
                VStack(spacing: 16) {
                    Text("Payment Status")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("What's the current status of payment for this job?")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Menu {
                        ForEach([PaymentStatus.pending, .invoiced, .partiallyPaid, .received, .overdue], id: \.self) { status in
                            Button(action: {
                                jobData.paymentStatus = status
                            }) {
                                HStack {
                                    Circle()
                                        .fill(status.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(status.displayName)
                                    
                                    Spacer()
                                    
                                    if status == jobData.paymentStatus {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(jobData.paymentStatus.color)
                                .frame(width: 12, height: 12)
                            
                            Text(jobData.paymentStatus.displayName)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
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
                    
                    // Status Description
                    Text(getStatusDescription(for: jobData.paymentStatus))
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                
                // Create Job Button
                Button(action: {
                    createJob()
                }) {
                    HStack {
                        if isCreatingJob {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text(isEditMode ? "Update Job" : "Create Job")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isCreatingJob)
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for tab bar
        }
        .background(Color.appBackground)
    }
    
    private func createJob() {
        isCreatingJob = true
        errorMessage = nil
        
        // Add delay to show loading state, then call onCreateJob
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCreatingJob = false
            onCreateJob()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func getStatusDescription(for status: PaymentStatus) -> String {
        switch status {
        case .pending:
            return "Payment has not been processed yet"
        case .invoiced:
            return "Invoice has been sent to client"
        case .partiallyPaid:
            return "Partial payment has been received"
        case .received:
            return "Full payment has been received"
        case .overdue:
            return "Payment is past the due date"
        case .cancelled:
            return "Payment has been cancelled"
        }
    }
}

// MARK: - Summary Row Component
struct SummaryRowView: View {
    let title: String
    let value: String
    var valueColor: Color = Color.appPrimaryText
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .headline : .subheadline)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, isHighlighted ? 4 : 0)
        .background(isHighlighted ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

#Preview {
    @State var previewData: SimpleJobData = {
        let data = SimpleJobData()
        data.clientName = "Calvin Klein"
        data.jobTitle = "Runway Show"
        data.amount = 5000
        data.bookedBy = "Agent Name"
        return data
    }()
    
    return JobSummaryView(jobData: $previewData) {
        // Preview action
    }
}
