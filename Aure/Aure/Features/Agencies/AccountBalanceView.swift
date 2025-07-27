import SwiftUI
import Charts
import SwiftData

struct AccountBalanceView: View {
    let agency: Agency
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Query private var allJobs: [Job]
    @State private var selectedTimeframe = "Last 6 months"
    @State private var earningsData: [EarningsData] = []
    @State private var showingAddJob = false
    
    // Supabase data services
    @StateObject private var jobService = JobService()
    @StateObject private var paymentService = PaymentService()
    
    // Real data from Supabase
    @State private var supabaseJobs: [SupabaseJob] = []
    @State private var supabasePayments: [SupabasePayment] = []
    @State private var supabaseAgencies: [SupabaseAgency] = []
    @State private var isLoading = false
    
    private var agencyJobs: [Job] {
        allJobs.filter { $0.agency?.id == agency.id }
    }
    
    private var supabaseAgencyJobs: [SupabaseJob] {
        // First try to match by ID, then fall back to matching by name
        let jobsByID = supabaseJobs.filter { $0.agencyId == agency.id }
        if !jobsByID.isEmpty {
            return jobsByID
        }
        
        // If no jobs found by ID, try matching by agency name
        // This handles cases where local SwiftData agency ID doesn't match Supabase agency ID
        return supabaseJobs.filter { job in
            // Get the agency for this job and compare names
            return supabaseAgencies.first { $0.id == job.agencyId }?.name == agency.name
        }
    }
    
    private var totalEarnings: Double {
        // Calculate based on actual received payments for this agency's jobs
        let agencyJobIds = Set(supabaseAgencyJobs.map { $0.id })
        let receivedPayments = supabasePayments.filter { payment in
            agencyJobIds.contains(payment.jobId) && payment.paymentStatus == .received
        }
        return receivedPayments.reduce(0.0) { total, payment in
            return total + payment.amount
        }
    }
    
    private var availableBalance: Double {
        return totalEarnings * 0.8
    }
    
    private var commissionPaid: Double {
        return totalEarnings * 0.2
    }
    
    private var bookingCount: Int {
        // Count all jobs for this agency, regardless of payment status
        return supabaseAgencyJobs.count
    }
    
    private var avgRate: Double {
        // Calculate average rate based on total job amounts (not just received payments)
        let totalJobAmounts = supabaseAgencyJobs.reduce(0.0) { total, job in
            return total + (job.fixedPrice ?? 0.0)
        }
        return supabaseAgencyJobs.count > 0 ? totalJobAmounts / Double(supabaseAgencyJobs.count) : 0
    }
    
    private var currentMonthEarnings: Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Get all job IDs for this agency
        let agencyJobIds = Set(supabaseAgencyJobs.map { $0.id })
        
        // Calculate current month earnings from received payments
        return supabasePayments.filter { payment in
            guard agencyJobIds.contains(payment.jobId),
                  payment.paymentStatus == .received,
                  let paidDate = payment.paidDate else { return false }
            return calendar.isDate(paidDate, equalTo: currentDate, toGranularity: .month)
        }.reduce(0.0) { total, payment in
            return total + payment.amount
        }
    }
    
    private var agencyColor: Color {
        if agency.name.contains("Soul") {
            return .purple
        } else if agency.name.contains("IMG") {
            return .pink
        } else {
            return .blue
        }
    }
    
    private var peakMonth: String {
        if agency.name.contains("Soul") {
            return "Mar"
        } else if agency.name.contains("IMG") {
            return "Mar"
        } else {
            return earningsData.max(by: { $0.earnings < $1.earnings })?.month ?? "N/A"
        }
    }
    
    private var growthPercentage: Double {
        if agency.name.contains("Soul") {
            return 0.0
        } else if agency.name.contains("IMG") {
            return 0.0
        } else {
            return 0.0
        }
    }
    
    private var avgMonthlyEarnings: Double {
        if agency.name.contains("Soul") {
            return 0
        } else if agency.name.contains("IMG") {
            return 0
        } else {
            let total = earningsData.reduce(0) { $0 + $1.earnings }
            return earningsData.count > 0 ? total / Double(earningsData.count) : 0
        }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                accountHeaderSection
                
                balanceSection
                
                bookingStatsSection
                
                earningsOverviewSection
                
                performanceOverviewSection
                
                recentJobsSection
                
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 120) // Increased padding for tab bar and safe area
        }
        .navigationBarHidden(true)
        .background(Color.appBackground)
        .onAppear {
            Task {
                await loadSupabaseData()
            }
        }
        .onChange(of: appState.dataRefreshTrigger) { _, _ in
            Task {
                await loadSupabaseData()
            }
        }
        .sheet(isPresented: $showingAddJob) {
            SimpleJobCreationView(preSelectedAgency: agency)
                .onAppear {
                    print("🔵 Sheet is presenting SimpleJobCreationView")
                }
        }
        .onChange(of: showingAddJob) { _, newValue in
            print("🔵 showingAddJob changed to: \(newValue)")
            // Refresh data when sheet is dismissed
            if !newValue {
                Task {
                    await loadSupabaseData()
                }
            }
        }
    }
    
    private var accountHeaderSection: some View {
        VStack(spacing: 16) {
            // Back button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                Spacer()
            }
            
            // Agency info
            HStack {
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
                        Text(String(agency.name.prefix(1)))
                            .font(.newYorkTitle2Bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(agency.name)
                        .font(.newYorkTitle2Bold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text("Current Balance")
                        .font(.newYorkSubheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Spacer()
            }
        }
        .padding(.bottom, 8)
    }
    
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(availableBalance.formatAsCurrency)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Available Balance")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                HStack {
                    Text("Commission Paid: \(commissionPaid.formatAsCurrency)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text("20% rate")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var bookingStatsSection: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("Bookings")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Text(bookingCount.formatWithCommas)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Total bookings")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Avg Rate")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Text(avgRate.formatAsCurrency)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Per booking")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
    }
    
    private var earningsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Earnings Overview")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
                
                Menu {
                    Button("Last 6 months") { selectedTimeframe = "Last 6 months" }
                    Button("Last 12 months") { selectedTimeframe = "Last 12 months" }
                    Button("This year") { selectedTimeframe = "This year" }
                } label: {
                    HStack {
                        Text(selectedTimeframe)
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
            }
            
            // Chart Section
            Chart(earningsData) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Earnings", data.earnings)
                )
                .foregroundStyle(agencyColor)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Earnings", data.earnings)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [agencyColor.opacity(0.3), agencyColor.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                PointMark(
                    x: .value("Month", data.month),
                    y: .value("Earnings", data.earnings)
                )
                .foregroundStyle(agencyColor)
                .symbolSize(40)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...17000)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 7000, 10000, 14000, 17000]) { value in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let earnings = value.as(Double.self) {
                            Text("$\(Int(earnings/1000))k")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                }
            }
            
            // Peak Month, Growth, Avg Monthly Stats
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peak Month")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Text(peakMonth)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Text("+\(String(format: "%.1f", growthPercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Monthly")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Text("$\(Int(avgMonthlyEarnings))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 16)
        }
    }
    
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Top Client")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text("No clients yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                HStack {
                    Text("This Month")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text(currentMonthEarnings.formatAsCurrency)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                HStack {
                    Text("Total Earnings")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text(totalEarnings.formatAsCurrency)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                }
            }
        }
    }
    
    private var recentJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Jobs")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
                
                Button("View All") {
                    // Handle view all jobs
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                if supabaseAgencyJobs.isEmpty {
                    Text("No jobs found for this agency")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(Array(supabaseAgencyJobs.prefix(5)), id: \.id) { job in
                        JobRowView(job: job)
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                print("🔵 Add Job button tapped")
                showingAddJob = true
                print("🔵 showingAddJob set to: \(showingAddJob)")
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.title3)
                    
                    Text("Add Job")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue)
                )
            }
        }
    }
    
@MainActor
    private func loadSupabaseData() async {
        guard appState.authenticationState == .authenticated else {
            print("⚠️ User not authenticated, skipping data load")
            return
        }
        
        print("🔵 Loading data for agency: \(agency.name) (ID: \(agency.id))")
        isLoading = true
        
        do {
            // Load jobs, payments, and agencies
            let agencyService = AgencyService()
            async let jobsTask = jobService.getAllJobs()
            async let paymentsTask = paymentService.getAllPayments()
            async let agenciesTask = agencyService.getAllAgencies()
            
            supabaseJobs = try await jobsTask
            supabasePayments = try await paymentsTask
            supabaseAgencies = try await agenciesTask
            
            print("🔵 Total Supabase jobs loaded: \(supabaseJobs.count)")
            print("🔵 Jobs for this agency: \(supabaseAgencyJobs.count)")
            print("🔵 Agency jobs details:")
            for job in supabaseAgencyJobs {
                print("  - \(job.title): $\(job.fixedPrice ?? 0) (Agency ID: \(job.agencyId?.uuidString ?? "none"))")
            }
            
            // Generate earnings data based on real job data
            loadEarningsData()
            
            print("✅ Agency data loaded successfully")
            print("📊 Total earnings: $\(totalEarnings)")
            print("📊 Available balance: $\(availableBalance)")
            print("📊 Commission paid: $\(commissionPaid)")
            
        } catch {
            print("🔴 Error loading agency data: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadEarningsData() {
        // Generate earnings data based on actual received payments for this agency
        let calendar = Calendar.current
        let now = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        // Get all job IDs for this agency
        let agencyJobIds = Set(supabaseAgencyJobs.map { $0.id })
        
        // Filter payments for this agency's jobs that are received
        let agencyPayments = supabasePayments.filter { payment in
            agencyJobIds.contains(payment.jobId) && payment.paymentStatus == .received
        }
        
        var data: [EarningsData] = []
        
        for i in (0..<6).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                let monthName = monthFormatter.string(from: monthDate)
                
                // Calculate actual earnings for this month from received payments
                let monthEarnings = agencyPayments.filter { payment in
                    guard let paidDate = payment.paidDate else { return false }
                    return calendar.isDate(paidDate, equalTo: monthDate, toGranularity: .month)
                }.reduce(0.0) { total, payment in
                    return total + payment.amount
                }
                
                data.append(EarningsData(month: monthName, earnings: monthEarnings))
            }
        }
        
        earningsData = data
        print("🔵 Chart data loaded: \(data.map { "\($0.month): $\($0.earnings)" }.joined(separator: ", "))")
    }
}

#Preview {
    AccountBalanceView(agency: Agency(name: "Soul Artist Management", contactPerson: "John Doe", email: "john@soul.com"))
        .modelContainer(for: [Job.self, Agency.self, Payment.self])
        .environmentObject(AppState())
}

// MARK: - Job Row Component
struct JobRowView: View {
    let job: SupabaseJob
    
    var body: some View {
        HStack(spacing: 12) {
            // Job icon/initial
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(job.title.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            // Job details
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appPrimaryText)
                
                if let startDate = job.startDate {
                    Text(startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
            
            Spacer()
            
            // Job amount
            VStack(alignment: .trailing, spacing: 4) {
                if let amount = job.fixedPrice {
                    Text(amount.formatAsCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                Text(jobStatusDisplayName(for: job.status))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColorFromString(job.status).opacity(0.1))
                    .foregroundColor(statusColorFromString(job.status))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func statusColorFromString(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "active":
            return .blue
        case "completed":
            return .green
        case "cancelled":
            return .red
        case "on_hold":
            return .gray
        default:
            return .gray
        }
    }
    
    private func jobStatusDisplayName(for status: String) -> String {
        switch status.lowercased() {
        case "pending":
            return "Pending"
        case "active":
            return "Active"
        case "completed":
            return "Completed"
        case "cancelled":
            return "Cancelled"
        case "on_hold":
            return "On Hold"
        default:
            return status.capitalized
        }
    }
}