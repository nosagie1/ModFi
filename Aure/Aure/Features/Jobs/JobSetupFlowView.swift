//
//  JobSetupFlowView.swift
//  Aure
//
//  7-step job setup flow with proper validations
//

import SwiftUI

enum JobCreationError: LocalizedError {
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to create jobs"
        }
    }
}

// MARK: - Main Job Setup Flow
struct JobSetupFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var jobData = JobSetupData()
    @State private var showPaymentStatus = false
    @State private var isCreatingJob = false
    @State private var errorMessage: String?
    
    // Supabase services
    @StateObject private var jobService = JobService()
    @StateObject private var paymentService = PaymentService()
    @StateObject private var agencyService = AgencyService()
    
    // Data for agency selection
    @State private var agencies: [SupabaseAgency] = []
    @State private var selectedAgency: SupabaseAgency?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep + 1), total: 7)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.appAccentBlue))
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                
                Text("\(currentStep + 1) of 7")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.top, 8)
                
                // Current Step View
                Group {
                    switch currentStep {
                    case 0:
                        ClientNameStepView(jobData: $jobData, onNext: nextStep)
                    case 1:
                        AmountStepView(jobData: $jobData, onNext: nextStep)
                    case 2:
                        CommissionStepView(jobData: $jobData, onNext: nextStep)
                    case 3:
                        BookedByStepView(jobData: $jobData, onNext: nextStep)
                    case 4:
                        JobTitleStepView(jobData: $jobData, onNext: nextStep)
                    case 5:
                        JobDateStepView(jobData: $jobData, onNext: nextStep)
                    case 6:
                        PaymentDueDateStepView(jobData: $jobData, onNext: completeJobSetup)
                    default:
                        EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.appAccentBlue)
                }
                
                if currentStep > 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") {
                            previousStep()
                        }
                        .foregroundColor(Color.appAccentBlue)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaymentStatus) {
            PaymentStatusView(
                jobData: jobData,
                onComplete: { dismiss() },
                onCreateJob: { paymentStatus in
                    jobData.paymentStatus = paymentStatus
                    try await createJobInSupabase()
                }
            )
        }
        .onAppear {
            loadAgencies()
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
    
    private func completeJobSetup() {
        showPaymentStatus = true
    }
    
    private func createJobInSupabase() async throws {
        guard appState.authenticationState == .authenticated else {
            throw JobCreationError.notAuthenticated
        }
        
        isCreatingJob = true
        
        // Create the job in Supabase
        let createdJob = try await jobService.createJobFromSetup(
            title: jobData.jobTitle.isEmpty ? "Job for \(jobData.clientName)" : jobData.jobTitle,
            clientName: jobData.clientName,
            amount: jobData.amount,
            commissionPercentage: Double(jobData.commissionPercentage),
            bookedBy: jobData.bookedBy,
            jobTitle: jobData.jobTitle.isEmpty ? nil : jobData.jobTitle,
            jobDate: jobData.jobDate,
            paymentDueDate: jobData.paymentDueDate,
            agencyId: selectedAgency?.id
        )
        
        // Create associated payment
        try await paymentService.createPaymentFromJobSetup(
            jobId: createdJob.id,
            amount: jobData.amount,
            dueDate: jobData.paymentDueDate,
            status: jobData.paymentStatus,
            expectedPaymentDate: jobData.paymentStatus == .overdue ? jobData.expectedPaymentDate : nil
        )
        
        // Close the flow and trigger data refresh
        await MainActor.run {
            isCreatingJob = false
            appState.triggerDataRefresh() // Refresh all views with new data
            dismiss()
        }
    }
    
    private func loadAgencies() {
        Task {
            do {
                agencies = try await agencyService.getAllAgencies()
                if !agencies.isEmpty {
                    selectedAgency = agencies.first
                }
            } catch {
                print("🔴 Error loading agencies: \(error)")
            }
        }
    }
}

// MARK: - Job Setup Data Model
class JobSetupData: ObservableObject {
    @Published var clientName = ""
    @Published var amount: Double = 0
    @Published var commissionPercentage: Int = 20
    @Published var bookedBy = ""
    @Published var jobTitle = ""
    @Published var jobDate = Date()
    @Published var paymentDueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @Published var paymentStatus: PaymentStatus = .pending
    @Published var expectedPaymentDate = Date() // For overdue payments
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var commissionAmount: Double {
        return amount * (Double(commissionPercentage) / 100.0)
    }
    
    var netAmount: Double {
        return amount - commissionAmount
    }
}


// MARK: - Step 1: Client Name
struct ClientNameStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    
    private var canContinue: Bool {
        !jobData.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Client or Brand Name")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("Who are you working with?")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Client Name")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                TextField("e.g., Calvin Klein", text: $jobData.clientName)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(canContinue ? Color.green : Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        if canContinue {
                            onNext()
                        }
                    }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                print("🔘 ClientName continue button tapped - canContinue: \(canContinue)")
                if canContinue {
                    onNext()
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canContinue ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
            }
            .disabled(!canContinue)
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Step 2: Amount
struct AmountStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    @State private var amountText = ""
    
    private var canContinue: Bool {
        jobData.amount > 0
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Job Amount")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("How much will you earn?")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount (USD)")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
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
                        .onChange(of: amountText) { _, newValue in
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered != newValue {
                                amountText = filtered
                            }
                            
                            if let amount = Double(filtered) {
                                jobData.amount = amount
                            } else {
                                jobData.amount = 0
                            }
                            
                            // Format with commas
                            if let amount = Double(filtered), amount > 0 {
                                let formatter = NumberFormatter()
                                formatter.numberStyle = .decimal
                                formatter.maximumFractionDigits = 2
                                if let formattedNumber = formatter.string(from: NSNumber(value: amount)) {
                                    if formattedNumber != filtered {
                                        amountText = formattedNumber
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 16)
                }
                .padding(.vertical, 14)
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(canContinue ? Color.green : Color.appBorder, lineWidth: 1)
                )
                
                if jobData.amount > 0 {
                    Text("Amount: \(jobData.formattedAmount)")
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                print("🔘 Amount continue button tapped - canContinue: \(canContinue)")
                if canContinue {
                    onNext()
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canContinue ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
            }
            .disabled(!canContinue)
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Step 3: Commission
struct CommissionStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    @State private var commissionText = "20"
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "percent")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Commission Rate")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("What's the agency commission?")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Commission percentage text field
                VStack(spacing: 8) {
                    HStack {
                        TextField("20", text: $commissionText)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color.appPrimaryText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .onChange(of: commissionText) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    commissionText = filtered
                                }
                                if let percentage = Int(filtered), percentage <= 100 {
                                    jobData.commissionPercentage = percentage
                                } else if filtered.isEmpty {
                                    jobData.commissionPercentage = 0
                                }
                            }
                        
                        Text("%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color.appPrimaryText)
                    }
                    
                    Text("Commission")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                .padding(.horizontal, 40)
                
                if jobData.amount > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Gross Amount:")
                            Spacer()
                            Text(jobData.formattedAmount)
                        }
                        .foregroundColor(Color.appSecondaryText)
                        
                        HStack {
                            Text("Commission (\(jobData.commissionPercentage)%):")
                            Spacer()
                            Text("-\(formatCurrency(jobData.commissionAmount))")
                        }
                        .foregroundColor(Color.appSecondaryText)
                        
                        Divider()
                        
                        HStack {
                            Text("Net Amount:")
                            Spacer()
                            Text(formatCurrency(jobData.netAmount))
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Initialize commission text field with current value
            commissionText = String(jobData.commissionPercentage)
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

// MARK: - Step 4: Booked By
struct BookedByStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    
    private var canContinue: Bool {
        !jobData.bookedBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Booked By")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("Who arranged this job?")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Agent or Contact Name")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                TextField("e.g., Dupont", text: $jobData.bookedBy)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(canContinue ? Color.green : Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        if canContinue {
                            onNext()
                        }
                    }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                print("🔘 BookedBy continue button tapped - canContinue: \(canContinue)")
                if canContinue {
                    onNext()
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canContinue ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
            }
            .disabled(!canContinue)
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Step 5: Job Title
struct JobTitleStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Job Title")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("What type of work is this? (Optional)")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Job Type")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                TextField("e.g., Runway, Editorial, Commercial", text: $jobData.jobTitle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        onNext()
                    }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Step 6: Job Date
struct JobDateStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Job Date")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("When is this job scheduled?")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                DatePicker(
                    "Job Date",
                    selection: $jobData.jobDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .onChange(of: jobData.jobDate) { _, newDate in
                    // Auto-set payment due date to 30 days after job date
                    jobData.paymentDueDate = Calendar.current.date(byAdding: .day, value: 30, to: newDate) ?? newDate
                }
                
                HStack {
                    Text("Selected:")
                    Spacer()
                    Text(jobData.jobDate, style: .date)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .cornerRadius(8)
                .foregroundColor(Color.appPrimaryText)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Step 7: Payment Due Date
struct PaymentDueDateStepView: View {
    @Binding var jobData: JobSetupData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Payment Due Date")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("When should you get paid?")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                Text("Auto-set to 30 days after job date")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.horizontal, 32)
                
                DatePicker(
                    "Payment Due Date",
                    selection: $jobData.paymentDueDate,
                    in: jobData.jobDate...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                
                HStack {
                    Text("Due Date:")
                    Spacer()
                    Text(jobData.paymentDueDate, style: .date)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .cornerRadius(8)
                .foregroundColor(Color.appPrimaryText)
                
                let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: jobData.paymentDueDate).day ?? 0
                Text("\(daysUntilDue) days from today")
                    .font(.caption)
                    .foregroundColor(daysUntilDue < 0 ? .red : Color.appSecondaryText)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue to Payment Status")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    JobSetupFlowView()
}