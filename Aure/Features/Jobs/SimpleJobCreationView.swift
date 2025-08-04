//
//  SimpleJobCreationView.swift
//  Aure
//
//  Simplified 2-screen job creation flow
//

import SwiftUI
import Supabase

struct SimpleJobCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var currentScreen = 1
    @State private var jobData = SimpleJobData()
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // Edit mode properties
    let editJob: Job?
    let isEditMode: Bool
    let preSelectedAgency: Agency?
    
    init(editJob: Job? = nil, preSelectedAgency: Agency? = nil) {
        self.editJob = editJob
        self.isEditMode = editJob != nil
        self.preSelectedAgency = preSelectedAgency
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator with animation
                AnimatedProgressDots(
                    totalSteps: 2,
                    currentStep: currentScreen - 1,
                    dotSize: 12,
                    spacing: 16,
                    activeColor: .blue,
                    inactiveColor: .gray.opacity(0.3)
                )
                .padding(.top, 16)
                
                Text("Step \(currentScreen) of 2")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.top, 8)
                
                // Screen content
                if currentScreen == 1 {
                    JobDetailsFormView(jobData: $jobData) {
                        withAnimation(.easeInOut) {
                            currentScreen = 2
                        }
                    }
                } else {
                    JobSummaryView(jobData: $jobData, isEditMode: isEditMode) {
                        print("🔵 JobSummaryView onCreateJob called")
                        if isEditMode {
                            updateJob()
                        } else {
                            createJob()
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle(isEditMode ? "Edit Job" : "Add Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                if currentScreen == 2 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") {
                            withAnimation(.easeInOut) {
                                currentScreen = 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .darkTranslucentNavigationBar()
        .onAppear {
            if isEditMode, let job = editJob {
                populateFormWithJobData(job)
            }
        }
    }
    
    private func createJob() {
        print("🔵 createJob() called")
        Task {
            print("🔵 Starting createJobInSupabase task")
            await createJobInSupabase()
        }
    }
    
    private func updateJob() {
        print("🔵 updateJob() called")
        Task {
            print("🔵 Starting updateJobInSupabase task")
            await updateJobInSupabase()
        }
    }
    
    private func populateFormWithJobData(_ job: Job) {
        print("🔵 Populating form with job data: \(job.title)")
        jobData.clientName = "Client" // Job model doesn't have client name, using placeholder
        jobData.jobTitle = job.title
        jobData.amount = job.fixedPrice ?? 0
        jobData.bookedBy = "Booked By" // Placeholder
        jobData.jobDate = job.startDate ?? Date()
        jobData.paymentDueDate = job.endDate ?? Date()
        // Note: We'll need to extract more data from job.notes if available
        if let notes = job.notes, notes.contains("Commission:") {
            // Try to extract commission percentage from notes
            let components = notes.components(separatedBy: "Commission: ")
            if components.count > 1 {
                let percentString = components[1].components(separatedBy: "%")[0]
                if let percent = Int(percentString) {
                    jobData.commissionPercentage = percent
                }
            }
        }
    }
    
    @MainActor
    private func createJobInSupabase() async {
        guard appState.authenticationState == .authenticated else {
            print("🔴 User not authenticated")
            return
        }
        
        do {
            let jobService = JobService()
            let paymentService = PaymentService()
            
            // Find or create matching Supabase agency if preSelectedAgency is provided
            var supabaseAgencyId: UUID? = nil
            if let preSelectedAgency = preSelectedAgency {
                print("🔵 Looking for agency: \(preSelectedAgency.name)")
                let agencyService = AgencyService()
                let supabaseAgencies = try await agencyService.getAllAgencies()
                print("🔵 Found \(supabaseAgencies.count) agencies in Supabase")
                
                // First try to find existing agency by name
                if let existingAgency = supabaseAgencies.first(where: { $0.name == preSelectedAgency.name }) {
                    supabaseAgencyId = existingAgency.id
                    print("🔵 Found existing Supabase agency: \(supabaseAgencyId?.uuidString ?? "none")")
                } else {
                    // If no matching agency found, create one
                    print("🔵 No matching agency found, creating new agency: \(preSelectedAgency.name)")
                    do {
                        // Get current user ID  
                        guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else {
                            throw JobCreationError.notAuthenticated
                        }
                        
                        let request = CreateAgencyRequest(
                            userId: userId,
                            name: preSelectedAgency.name,
                            contactPerson: preSelectedAgency.contactPerson,
                            email: preSelectedAgency.email,
                            phone: preSelectedAgency.phone,
                            address: preSelectedAgency.address,
                            website: preSelectedAgency.website,
                            industry: preSelectedAgency.industry,
                            notes: preSelectedAgency.notes,
                            isActive: true
                        )
                        let newAgency = try await agencyService.createAgency(request)
                        supabaseAgencyId = newAgency.id
                        print("✅ Created new Supabase agency: \(supabaseAgencyId?.uuidString ?? "none")")
                    } catch {
                        print("🔴 Failed to create agency: \(error)")
                        // Continue without agency association
                    }
                }
            } else {
                print("🔵 No preSelectedAgency provided")
            }
            
            // Create the job
            let createdJob = try await jobService.createJobFromSetup(
                title: jobData.jobTitle,
                clientName: jobData.clientName,
                amount: jobData.amount,
                commissionPercentage: Double(jobData.commissionPercentage),
                bookedBy: jobData.bookedBy,
                jobTitle: jobData.jobTitle,
                jobDate: jobData.jobDate,
                paymentDueDate: jobData.paymentDueDate,
                agencyId: supabaseAgencyId
            )
            
            // Create associated payment
            try await paymentService.createPaymentFromJobSetup(
                jobId: createdJob.id,
                amount: jobData.amount,
                dueDate: jobData.paymentDueDate,
                status: jobData.paymentStatus,
                expectedPaymentDate: nil
            )
            
            print("✅ Job created successfully: \(createdJob.title)")
            print("🔵 Job agency ID: \(createdJob.agencyId?.uuidString ?? "none")")
            
            // Trigger data refresh across the app immediately and with delay
            appState.triggerDataRefresh()
            print("🔄 Immediate data refresh triggered")
            
            // Additional refresh with delay for DB consistency
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                appState.triggerDataRefresh()
                print("🔄 Delayed data refresh triggered after job creation")
            }
            
            dismiss()
            
        } catch {
            print("🔴 Error creating job: \(error)")
            errorMessage = "Failed to create job: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    @MainActor
    private func updateJobInSupabase() async {
        guard appState.authenticationState == .authenticated else {
            print("🔴 User not authenticated")
            return
        }
        
        guard let job = editJob else {
            print("🔴 No job to update")
            return
        }
        
        do {
            let jobService = JobService()
            
            // First, find the Supabase job that matches this local job
            // since local Job.id != Supabase job UUID
            let allSupabaseJobs = try await jobService.getAllJobs()
            
            // Find matching job by title, description, and amount
            guard let matchingSupabaseJob = allSupabaseJobs.first(where: { supabaseJob in
                supabaseJob.title == job.title &&
                supabaseJob.jobDescription == job.jobDescription &&
                supabaseJob.fixedPrice == job.fixedPrice
            }) else {
                print("🔴 Could not find matching Supabase job for local job: \(job.title)")
                errorMessage = "Could not find job to update. Please try refreshing and trying again."
                showingErrorAlert = true
                return
            }
            
            print("🔵 Found matching Supabase job with ID: \(matchingSupabaseJob.id)")
            
            // Create update request
            let updateRequest = UpdateJobRequest(
                title: jobData.jobTitle,
                jobDescription: jobData.jobTitle,
                location: nil,
                hourlyRate: nil,
                fixedPrice: jobData.amount,
                estimatedHours: nil,
                startDate: jobData.jobDate,
                endDate: jobData.paymentDueDate,
                status: nil,
                type: nil,
                skillsString: nil,
                notes: "Booked by: \(jobData.bookedBy)\nCommission: \(jobData.commissionPercentage)%"
            )
            
            // Update the job using the correct Supabase UUID
            _ = try await jobService.updateJob(id: matchingSupabaseJob.id, updateRequest)
            
            print("✅ Job updated successfully: \(jobData.jobTitle)")
            
            // Trigger data refresh across the app with slight delay for DB consistency
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                appState.triggerDataRefresh()
                print("🔄 Data refresh triggered after job update")
            }
            
            dismiss()
            
        } catch {
            print("🔴 Error updating job: \(error)")
            errorMessage = "Failed to update job: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

#Preview {
    SimpleJobCreationView()
        .environmentObject(AppState())
}