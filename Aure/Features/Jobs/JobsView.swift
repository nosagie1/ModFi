//
//  JobsView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI
import SwiftData

struct JobsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query private var localJobs: [Job]
    @State private var showingAddJob = false
    @State private var selectedJob: Job?
    @State private var searchText = ""
    @State private var selectedStatus: JobStatus?
    
    // Supabase data
    @StateObject private var jobService = JobService()
    @State private var supabaseJobs: [SupabaseJob] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var jobToDelete: Job?
    
    // Use Supabase jobs converted to local Job objects for display
    var jobs: [Job] {
        return supabaseJobs.map { $0.toLocalJob() }
    }
    
    var filteredJobs: [Job] {
        let statusFiltered = selectedStatus == nil ? jobs : jobs.filter { $0.status == selectedStatus }
        
        if searchText.isEmpty {
            return statusFiltered
        } else {
            return statusFiltered.filter { job in
                job.title.localizedCaseInsensitiveContains(searchText) ||
                job.jobDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterSection
                
                if isLoading {
                    loadingView
                } else if filteredJobs.isEmpty {
                    emptyStateView
                } else {
                    jobsList
                }
            }
            .navigationTitle("Jobs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddJob = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddJob) {
                SimpleJobCreationView()
            }
            .sheet(item: $selectedJob) { job in
                JobDetailView(job: job)
            }
            .alert("Delete Job", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let job = jobToDelete {
                        deleteJobFromSupabase(job)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this job? This action cannot be undone.")
            }
            .onAppear {
                loadJobs()
            }
            .refreshable {
                loadJobs()
            }
            .overlay(
                // Add Lottie receipt pull animation for refresh
                ReceiptPullAnimation(isRefreshing: isLoading)
                    .opacity(isLoading ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isLoading),
                alignment: .top
            )
            .onChange(of: appState.dataRefreshTrigger) { _, _ in
                loadJobs()
            }
        }
        .requiresAuthentication()
        .darkTranslucentNavigationBar()
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search jobs...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedStatus == nil,
                        action: { selectedStatus = nil }
                    )
                    
                    ForEach(JobStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName,
                            isSelected: selectedStatus == status,
                            action: { selectedStatus = status }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color.appCardBackground)
    }
    
    private var jobsList: some View {
        List(Array(filteredJobs.enumerated()), id: \.element.id) { index, job in
            JobRow(job: job)
                .staggeredAnimation(index: index, itemDelay: 0.05, baseDuration: 0.3, baseDelay: 0.1)
                .onTapGesture {
                    selectedJob = job
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        jobToDelete = job
                        showingDeleteConfirmation = true
                    }
                    
                    Button("Edit") {
                        selectedJob = job
                    }
                    .tint(.blue)
                }
        }
        .listStyle(PlainListStyle())
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80) // Space for tab bar
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Jobs Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
            
            Text("Add your first job to start tracking your freelance work")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                showingAddJob = true
            }) {
                Text("Add Job")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
            .buttonStyle(.springyRipple)
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading jobs...")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadJobs() {
        guard appState.authenticationState == .authenticated else { return }
        
        isLoading = true
        Task {
            do {
                let jobs = try await jobService.getAllJobs()
                await MainActor.run {
                    self.supabaseJobs = jobs
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("🔴 Error loading jobs: \(error)")
                }
            }
        }
    }
    
    private func deleteJobFromSupabase(_ job: Job) {
        // Find the corresponding Supabase job
        guard let supabaseJob = supabaseJobs.first(where: { $0.title == job.title && $0.jobDescription == job.jobDescription }) else {
            print("🔴 Could not find Supabase job to delete")
            return
        }
        
        Task {
            do {
                try await jobService.deleteJob(id: supabaseJob.id)
                await MainActor.run {
                    // Remove from local array and trigger refresh
                    self.supabaseJobs.removeAll { $0.id == supabaseJob.id }
                    self.appState.triggerDataRefresh() // Refresh dashboard and other views
                    print("✅ Job deleted successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete job: \(error.localizedDescription)"
                    print("🔴 Error deleting job: \(error)")
                }
            }
        }
    }
}

struct JobRow: View {
    let job: Job
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    if let agency = job.agency {
                        Text(agency.name)
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: job.status)
                    
                    if let rate = job.hourlyRate {
                        Text("$\(String(format: "%.0f", rate))/hr")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    } else if let price = job.fixedPrice {
                        Text("$\(String(format: "%.0f", price))")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
            }
            
            HStack {
                Text(job.type.displayName)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                if let location = job.location {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Spacer()
                
                if let startDate = job.startDate {
                    Text(startDate, style: .date)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

struct StatusBadge: View {
    let status: JobStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(4)
            .pulseAnimation(intensity: 0.2, duration: 0.8, repeatCount: 1)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .gray
        case .active:
            return .green
        case .completed:
            return .blue
        case .cancelled:
            return .red
        case .onHold:
            return .orange
        }
    }
}