import SwiftUI
import Charts
import SwiftData

struct AgencyDetailView: View {
    let agency: Agency
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Query private var allJobs: [Job]
    @State private var selectedTimeframe = "Last 6 months"
    @State private var earningsData: [EarningsData] = []
    
    // Supabase data services  
    @StateObject private var jobService = JobService()
    @StateObject private var paymentService = PaymentService()
    
    // Real data from Supabase
    @State private var supabaseJobs: [SupabaseJob] = []
    @State private var supabasePayments: [SupabasePayment] = []
    @State private var isLoading = false
    
    private var agencyJobs: [Job] {
        allJobs.filter { $0.agency?.id == agency.id }
    }
    
    private var supabaseAgencyJobs: [SupabaseJob] {
        supabaseJobs.filter { $0.agencyId == agency.id }
    }
    
    private var totalEarnings: Double {
        supabaseAgencyJobs.reduce(0.0) { total, job in
            return total + (job.fixedPrice ?? 0.0)
        }
    }
    
    private var availableBalance: Double {
        return totalEarnings * 0.8
    }
    
    private var commissionPaid: Double {
        return totalEarnings * 0.2
    }
    
    private var bookingCount: Int {
        return supabaseAgencyJobs.count
    }
    
    private var avgRate: Double {
        return totalEarnings > 0 ? totalEarnings / Double(max(supabaseAgencyJobs.count, 1)) : 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                accountHeaderSection
                
                balanceSection
                
                bookingStatsSection
                
                earningsOverviewSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100) // Space for tab bar and navigation
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
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
    }
    
    private var accountHeaderSection: some View {
        HStack {
            Rectangle()
                .fill(.purple)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .overlay(
                    Text(String(agency.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agency.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Current Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("$\(String(format: "%.2f", availableBalance))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Available Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Commission Paid: $\(String(format: "%.2f", commissionPaid))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("20% rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                }
                
                Text("\(bookingCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Total bookings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Avg Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("$\(Int(avgRate))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Per booking")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button("Last 6 months") { selectedTimeframe = "Last 6 months" }
                    Button("Last 12 months") { selectedTimeframe = "Last 12 months" }
                    Button("This year") { selectedTimeframe = "This year" }
                } label: {
                    HStack {
                        Text(selectedTimeframe)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Chart Section
            Chart(earningsData) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Earnings", data.earnings)
                )
                .foregroundStyle(.purple)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Earnings", data.earnings)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .purple.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                PointMark(
                    x: .value("Month", data.month),
                    y: .value("Earnings", data.earnings)
                )
                .foregroundStyle(.purple)
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
                                .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }
    
@MainActor
    private func loadSupabaseData() async {
        guard appState.authenticationState == .authenticated else {
            print("⚠️ User not authenticated, skipping data load")
            return
        }
        
        isLoading = true
        
        do {
            // Load jobs and payments
            async let jobsTask = jobService.getAllJobs()
            async let paymentsTask = paymentService.getAllPayments()
            
            supabaseJobs = try await jobsTask
            supabasePayments = try await paymentsTask
            
            // Generate earnings data based on real job data
            loadEarningsData()
            
            print("✅ Agency detail data loaded successfully")
            print("📊 Jobs for agency \(agency.name): \(supabaseAgencyJobs.count)")
            
        } catch {
            print("🔴 Error loading agency detail data: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadEarningsData() {
        // Generate earnings data based on real Supabase job data
        let calendar = Calendar.current
        let now = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        var data: [EarningsData] = []
        
        for i in (0..<6).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                let monthName = monthFormatter.string(from: monthDate)
                
                // Calculate earnings for this month from Supabase jobs
                let monthEarnings = supabaseAgencyJobs.filter { job in
                    guard let startDate = job.startDate else { return false }
                    return calendar.isDate(startDate, equalTo: monthDate, toGranularity: .month)
                }.reduce(0.0) { total, job in
                    return total + (job.fixedPrice ?? 0.0)
                }
                
                data.append(EarningsData(month: monthName, earnings: monthEarnings))
            }
        }
        
        earningsData = data
    }
}


#Preview {
    AgencyDetailView(agency: Agency(name: "Soul Artist Management", contactPerson: "John Doe", email: "john@soul.com"))
        .modelContainer(for: [Job.self, Agency.self, Payment.self])
        .environmentObject(AppState())
}