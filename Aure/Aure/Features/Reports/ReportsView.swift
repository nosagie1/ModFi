import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedJob: Job?
    @State private var showingAddJob = false
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var showingFilters = false
    
    // Supabase data - ONLY real user data, no mock/arbitrary data
    @StateObject private var jobService = JobService()
    @State private var supabaseJobs: [SupabaseJob] = []
    @State private var isLoading = false
    
    // Use ONLY Supabase jobs converted to local Job objects for display
    // NO mock, sample, or arbitrary data - only real user-created jobs
    var jobs: [Job] {
        return supabaseJobs.map { $0.toLocalJob() }
    }
    
    private var filteredJobs: [Job] {
        jobs.filter { job in
            let matchesSearch = searchText.isEmpty || 
                job.title.localizedCaseInsensitiveContains(searchText) ||
                job.agency?.name.localizedCaseInsensitiveContains(searchText) == true
            
            let matchesStatus = selectedStatusFilter == .all || 
                statusMatchesFilter(job.status, filter: selectedStatusFilter)
            
            return matchesSearch && matchesStatus
        }.sorted { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) }
    }
    
    private func statusMatchesFilter(_ status: JobStatus, filter: StatusFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .draft:
            return status == .pending
        case .sent:
            return status == .active
        case .paid:
            return status == .completed
        case .late:
            guard let job = jobs.first(where: { $0.status == status }) else { return false }
            guard let endDate = job.endDate else { return false }
            return endDate < Date() && status != .completed
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Page title with add button
            HStack {
                Text("Jobs")
                    .font(.pageTitle)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Temporary clear data button
                Button(action: {
                    clearAllData()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.trailing, 12)
                
                Button(action: {
                    showingAddJob = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // Header with search and filters
            VStack(spacing: 16) {
                    // Search bar with filter button
                    HStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("Search jobs...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                        
                        // Filter button
                        Button(action: {
                            showingFilters.toggle()
                        }) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Status filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(StatusFilter.allCases, id: \.self) { filter in
                                StatusChip(
                                    title: filter.displayName,
                                    isSelected: selectedStatusFilter == filter
                                ) {
                                    selectedStatusFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(Color.appBackground)
                
                // Job list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredJobs.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "briefcase")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            Text("No jobs found")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text(jobs.isEmpty ? "Add your first job to get started" : "Try adjusting your search or filters")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
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
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredJobs) { job in
                                JobCardView(job: job)
                                    .onTapGesture {
                                        selectedJob = job
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .padding(.bottom, 100) // Space for tab bar
                    }
                    .background(Color.appBackground)
                }
        }
        .sheet(isPresented: $showingAddJob) {
            SimpleJobCreationView()
        }
        .sheet(item: $selectedJob) { job in
            JobDetailModalView(job: job)
        }
        .onAppear {
            loadJobs()
        }
        .refreshable {
            loadJobs()
        }
        .onChange(of: appState.dataRefreshTrigger) { _, _ in
            loadJobs()
        }
        .requiresAuthentication()
        .darkTranslucentNavigationBar()
    }
    
    private func loadJobs() {
        guard appState.authenticationState == .authenticated else { 
            print("🔴 Jobs load skipped - user not authenticated")
            return 
        }
        
        print("🔄 Loading jobs for Reports view...")
        isLoading = true
        Task {
            do {
                let jobs = try await jobService.getAllJobs()
                await MainActor.run {
                    print("✅ Loaded \(jobs.count) jobs for Reports view")
                    self.supabaseJobs = jobs
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.supabaseJobs = [] // Ensure no stale data on error
                    print("🔴 Error loading jobs: \(error)")
                }
            }
        }
    }
    
    private func clearAllData() {
        print("🗑️ Clearing all user data...")
        Task {
            do {
                // Delete all jobs and payments
                try await jobService.deleteAllJobs()
                
                let paymentService = PaymentService()
                try await paymentService.deleteAllPayments()
                
                await MainActor.run {
                    self.supabaseJobs = []
                    print("✅ All data cleared successfully")
                }
            } catch {
                print("🔴 Error clearing data: \(error)")
            }
        }
    }
}

// MARK: - Status Filter Enum
enum StatusFilter: String, CaseIterable {
    case all = "all"
    case draft = "draft"
    case sent = "sent"
    case paid = "paid"
    case late = "late"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .paid: return "Paid"
        case .late: return "Late"
        }
    }
}

// MARK: - Status Chip
struct StatusChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.appSecondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
    }
}

// MARK: - Job Card View
struct JobCardView: View {
    let job: Job
    
    private var statusColor: Color {
        switch job.status {
        case .completed:
            return .green
        case .active:
            return .blue
        case .pending:
            return .gray
        case .cancelled:
            return .red
        case .onHold:
            return .orange
        }
    }
    
    private var statusText: String {
        switch job.status {
        case .completed:
            return "Paid"
        case .active:
            return "Sent"
        case .pending:
            return "Draft"
        case .cancelled:
            return "Cancelled"
        case .onHold:
            return "Late"
        }
    }
    
    private var isOverdue: Bool {
        guard let endDate = job.endDate else { return false }
        return endDate < Date() && job.status != .completed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Profile image placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.8),
                                Color.pink.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(job.title.prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(job.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status badge
                        Text(isOverdue ? "Late" : statusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isOverdue ? Color.red : statusColor)
                            )
                    }
                    
                    Text(job.agency?.name ?? "Independent")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            // Bottom section with date and amount
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shoot Date")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if let startDate = job.startDate {
                        Text(startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Text("TBD")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Amount")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if let price = job.fixedPrice {
                        Text("$\(String(format: "%.0f", price))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else if let hourlyRate = job.hourlyRate {
                        Text("$\(String(format: "%.0f", hourlyRate))/hr")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("TBD")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ReportsView()
        .environmentObject(AppState())
        .modelContainer(for: [Job.self, Agency.self, Payment.self])
}