import SwiftUI
import Charts
import SwiftData

enum ChartTimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query private var jobs: [Job]
    @Query private var payments: [Payment]
    @Query private var agencies: [Agency]
    
    // Supabase data services
    @StateObject private var jobService = JobService()
    @StateObject private var paymentService = PaymentService()
    @StateObject private var agencyService = AgencyService()
    @StateObject private var jobAmountService = JobAmountCalculationService()
    
    // Real data from Supabase
    @State private var supabaseJobs: [SupabaseJob] = []
    @State private var supabasePayments: [SupabasePayment] = []
    @State private var supabaseAgencies: [SupabaseAgency] = []
    @State private var monthlyEarnings: [(month: String, earnings: Double)] = []
    @State private var paidPaymentData: [(period: String, earnings: Double)] = []
    @State private var paymentStats: PaymentStatistics?
    
    // Calculated properties from real data
    @State private var totalIncome: Double = 0.0
    @State private var netValue: Double = 0.0
    @State private var monthlyGoal: Double = 0.0
    @State private var currentMonthEarnings: Double = 0.0
    @State private var currentMonthNetEarnings: Double = 0.0
    @State private var upcomingPayments: Double = 0.0
    @State private var overduePayments: Double = 0.0
    @State private var grossEarnings: Double = 0.0
    @State private var totalDeductions: Double = 0.0
    @State private var netEarnings: Double = 0.0
    
    // Previous values for percentage calculation
    @State private var previousNetValue: Double = 0.0
    @State private var previousTotalIncome: Double = 0.0
    
    // 30-day income calculation for percentage change
    @State private var currentMonthIncome: Double = 0.0
    @State private var previousMonthIncome: Double = 0.0
    
    
    // UI state
    @State private var showingAddAgency = false
    @State private var showingDeductionsBreakdown = false
    @State private var selectedTimePeriod = "Week"
    @State private var chartTimePeriod: ChartTimePeriod = .month
    @State private var showingTimePeriodPicker = false
    @State private var isHovered = false
    @State private var bellHovered = false
    @State private var editHovered = false
    @State private var timePeriodHovered = false
    @State private var isPressed = false
    @State private var addAccountHovered = false
    @State private var isLoading = false
    
    // Monthly goal editing
    @State private var isEditingGoal = false
    @State private var goalText = ""
    @State private var goalEditHovered = false
    @State private var showingAllPaymentsModal = false
    
    // Animation states
    @State private var animatedProgress: CGFloat = 0
    @State private var targetProgress: CGFloat = 0
    @State private var progressPercentage: Double = 0
    @State private var showChart = false
    @State private var chartAnimationComplete = false
    @State private var isChangingTimeline = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    chartSection
                    
                    metricsOverviewSection
                    
                    accountsSection
                    
                    deductionsOverviewSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100) // Increased padding to ensure no content hidden behind tab bar
            }
            .scrollIndicators(.hidden)
            .navigationBarHidden(true)
            .background(Color.appBackground)
        }
        .requiresAuthentication()
        .onAppear {
            loadMonthlyGoal()
            loadDashboardData()
        }
        .refreshable {
            await loadSupabaseData()
        }
        .onChange(of: appState.authenticationState) { _, newState in
            if newState == .authenticated {
                loadMonthlyGoal()
                loadDashboardData()
            }
        }
        .onChange(of: appState.dataRefreshTrigger) { _, _ in
            loadDashboardData()
        }
        .onChange(of: monthlyGoal) { _, _ in
            // Recalculate progress when monthly goal changes
            calculateProgressPercentage()
        }
        .sheet(isPresented: $showingAddAgency) {
            AgencyOnboardingView()
        }
        .sheet(isPresented: $showingDeductionsBreakdown) {
            DeductionsBreakdownView()
        }
        .sheet(isPresented: $showingAllPaymentsModal) {
            AllPaymentsModalView(payments: allPayments, jobs: supabaseJobs)
        }
        .actionSheet(isPresented: $showingTimePeriodPicker) {
            ActionSheet(
                title: Text("Select Time Period"),
                buttons: [
                    .default(Text("Day")) { 
                        animateTimelineChange(to: "Day")
                    },
                    .default(Text("Week")) { 
                        animateTimelineChange(to: "Week")
                    },
                    .default(Text("Month")) { 
                        animateTimelineChange(to: "Month")
                    },
                    .default(Text("Last 6 months")) { 
                        animateTimelineChange(to: "Last 6 months")
                    },
                    .default(Text("Year")) { 
                        animateTimelineChange(to: "Year")
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 12) {
                NavigationLink(destination: ProfileView()) {
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
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(appState.dataCoordinator.currentUser?.name?.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
                
                if case .authenticated = appState.authenticationState,
                   let user = appState.dataCoordinator.currentUser {
                    let userName = user.name ?? ""
                    Text("Hello \(userName.components(separatedBy: " ").first ?? userName)")
                        .font(.newYorkTitle)
                        .foregroundColor(Color.appPrimaryText)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Handle notifications
            }) {
                Image(systemName: "bell")
                    .font(.newYorkTitle2)
                    .foregroundColor(Color.appPrimaryText)
                    .scaleEffect(bellHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: bellHovered)
            }
            .onHover { hovering in
                bellHovered = hovering
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Total Income")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
                
                Button(action: {
                    showingTimePeriodPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(selectedTimePeriod)
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .scaleEffect(timePeriodHovered ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: timePeriodHovered)
                }
                .onHover { hovering in
                    timePeriodHovered = hovering
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    CountUpCurrency(value: .constant(netValue), duration: 0.8, useDigitalFont: true)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                }
                
                Group {
                    if generatePaidIncomeData().isEmpty {
                        // Empty state for chart
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.newYork(size: 40))
                                .foregroundColor(Color.appSecondaryText)
                            
                            Text("No Income Yet")
                                .font(.newYorkHeadline)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text("Income will appear here when payments are marked as received")
                                .font(.newYorkCaption)
                                .foregroundColor(Color.appSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                    } else {
                        incomeChart
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showChart = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    chartAnimationComplete = true
                                }
                            }
                        }
                        .frame(height: 150)
                        .chartXAxis {
                            AxisMarks { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, lineCap: .round))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel()
                                    .font(.caption2)
                                    .foregroundStyle(Color.appSecondaryText)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, lineCap: .round))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel { 
                                    if let doubleValue = value.as(Double.self) {
                                        Text(formatAxisValueWithCommas(doubleValue))
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundStyle(Color.appSecondaryText)
                                    }
                                }
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...calculateDynamicYAxisMax())
            }
            .padding()
        }
    }
    
    private var incomeChart: some View {
        Chart {
            ForEach(Array(generatePaidIncomeData().enumerated()), id: \.element.period) { index, data in
                BarMark(
                    x: .value("Period", data.period),
                    y: .value("Amount", showChart ? data.earnings : 0),
                    width: .ratio(0.7)
                )
                .foregroundStyle(chartBarGradient)
                .cornerRadius(6)
            }
        }
        .animation(.easeOut(duration: 0.8), value: showChart)
    }
    
    private var chartBarGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .blue.opacity(0.6),
                .blue.opacity(0.8), 
                .blue,
                .cyan.opacity(0.8)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Accounts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
                
                Button(action: {
                    // Handle edit accounts
                }) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .scaleEffect(editHovered ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: editHovered)
                }
                .onHover { hovering in
                    editHovered = hovering
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Real Agency Cards from Supabase
                    ForEach(supabaseAgencies.isEmpty ? agencies : supabaseAgencies.map { $0.toLocalAgency() }) { agency in
                        NavigationLink(destination: AccountBalanceView(agency: agency)) {
                            SupabaseAgencyAccountCardView(
                                agency: agency, 
                                supabaseJobs: supabaseJobs,
                                supabasePayments: supabasePayments,
                                supabaseAgencies: supabaseAgencies,
                                showChart: showChart
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Add Account Card
                    Button(action: {
                        showingAddAgency = true
                    }) {
                        VStack(spacing: 12) {
                            Spacer()
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(Color.appSecondaryText)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                            
                            VStack(spacing: 4) {
                                Text("Add Account")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.appPrimaryText)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Text("Connect new agency")
                                    .font(.caption)
                                    .foregroundColor(Color.appSecondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .frame(width: 160, height: 140)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                                .overlay(
                                    DashedBorderAnimation(
                                        cornerRadius: 12,
                                        dashLength: 8,
                                        dashGap: 4,
                                        lineWidth: 2,
                                        color: Color(.systemGray4),
                                        animationSpeed: 3.0
                                    )
                                )
                        )
                        .scaleEffect(addAccountHovered ? 1.05 : 1.0)
                        .breatheAnimation(minScale: 0.99, maxScale: 1.01, duration: 3.0)
                        .animation(.easeInOut(duration: 0.2), value: addAccountHovered)
                    }
                    .onHover { hovering in
                        addAccountHovered = hovering
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var metricsOverviewSection: some View {
        VStack(spacing: 16) {
            // Monthly Goal Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Monthly Goal")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        isEditingGoal = true
                        goalText = String(format: "%.0f", monthlyGoal)
                    }) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .scaleEffect(goalEditHovered ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: goalEditHovered)
                    }
                    .onHover { hovering in
                        goalEditHovered = hovering
                    }
                    
                    CountUpPercentage(value: $progressPercentage, duration: 1.0, animationDelay: 0.3)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.1))
                        )
                }
                
                if isEditingGoal {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Set Monthly Goal (Net Income)")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            Spacer()
                        }
                        
                        HStack {
                            Text("$")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                            
                            TextField("0", text: $goalText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                                .keyboardType(.numberPad)
                            
                            Spacer()
                            
                            Button("Save") {
                                if let newGoal = Double(goalText), newGoal > 0 {
                                    monthlyGoal = newGoal
                                    saveMonthlyGoal(newGoal)
                                } else {
                                    print("⚠️ Invalid goal amount: \(goalText)")
                                }
                                isEditingGoal = false
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            
                            Button("Cancel") {
                                isEditingGoal = false
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appCardBackground)
                        .cornerRadius(8)
                    }
                } else {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Net")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                            
                            Text(currentMonthNetEarnings.formatAsCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.appPrimaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                            
                            if monthlyGoal > 0 {
                                Text(monthlyGoal.formatAsCurrency)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.appPrimaryText)
                            } else {
                                Text("Tap to set")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.appSecondaryText)
                            }
                        }
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.8), .blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * animatedProgress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            // Upcoming Payments Section
            upcomingPaymentsSection
        }
    }
    
    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Payments")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
            }
            
            if filteredUpcomingPayments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No upcoming payments")
                            .font(.headline)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text("Payments will appear here when jobs are created")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appCardBackground)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            } else {
                VStack(spacing: 16) {
                    // Horizontal scrolling payment cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredUpcomingPayments.sorted { $0.dueDate < $1.dueDate }) { payment in
                                DashboardPaymentCardView(payment: payment, jobTitle: getJobTitle(for: payment))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // View All Payments text link
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingAllPaymentsModal = true
                        }) {
                            Text("View All Payments")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // Filter upcoming payments (excluding overdue and paid)
    private var filteredUpcomingPayments: [SupabasePayment] {
        supabasePayments.filter { payment in
            // Only show unpaid payments (pending, invoiced, partiallyPaid)
            // Exclude paid/received payments from horizontal scroll
            (payment.paymentStatus == .pending || 
             payment.paymentStatus == .invoiced || 
             payment.paymentStatus == .partiallyPaid)
        }
    }
    
    // All payments for the modal (paid and unpaid)
    private var allPayments: [SupabasePayment] {
        return supabasePayments.sorted { $0.dueDate < $1.dueDate }
    }
    
    // Helper function to get job title from payment
    private func getJobTitle(for payment: SupabasePayment) -> String {
        if let job = supabaseJobs.first(where: { $0.id == payment.jobId }) {
            return job.title
        }
        return payment.paymentDescription ?? "Payment"
    }
    
    private var deductionsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Deductions Overview")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
                
                Button("See breakdown") {
                    showingDeductionsBreakdown = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                // Summary Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Gross Earnings")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", grossEarnings))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appPrimaryText)
                    }
                    
                    HStack {
                        Text("Total Deductions")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        Text("-$\(String(format: "%.2f", totalDeductions))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    HStack {
                        Text("Net Earnings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", netEarnings))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                // Detailed Deductions
                VStack(spacing: 12) {
                    // Agency Commission
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Agency Commission")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text("20% standard commission")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-$\(String(format: "%.2f", grossEarnings * 0.2))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text("20%")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                    
                    // Tax Withholding
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tax Withholding")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text("Estimated federal & state")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-$\(String(format: "%.2f", grossEarnings * 0.15))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appPrimaryText)
                            
                            Text("15%")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private func loadDashboardData() {
        Task {
            await loadSupabaseData()
        }
    }
    
    @MainActor
    private func loadSupabaseData() async {
        guard appState.authenticationState == .authenticated else {
            print("⚠️ User not authenticated, skipping data load")
            return
        }
        
        isLoading = true
        
        do {
            // Load all data concurrently
            async let jobsTask = jobService.getAllJobs()
            async let paymentsTask = paymentService.getAllPayments()
            async let agenciesTask = agencyService.getAllAgencies()
            async let monthlyEarningsTask = jobService.getMonthlyEarnings(monthsBack: 6)
            async let paymentStatsTask = paymentService.getPaymentStatistics()
            
            // Wait for all tasks to complete
            supabaseJobs = try await jobsTask
            supabasePayments = try await paymentsTask
            supabaseAgencies = try await agenciesTask
            monthlyEarnings = try await monthlyEarningsTask
            paymentStats = try await paymentStatsTask
            
            // Calculate dashboard metrics from real data
            calculateDashboardMetrics()
            
            print("✅ Dashboard data loaded successfully")
            print("📊 Jobs: \(supabaseJobs.count), Payments: \(supabasePayments.count), Agencies: \(supabaseAgencies.count)")
            print("📊 Monthly goal progress: \(String(format: "%.1f", progressPercentage))% (\(currentMonthNetEarnings.formatAsCurrency) / \(monthlyGoal.formatAsCurrency))")
            
        } catch {
            print("🔴 Error loading dashboard data: \(error)")
            // SECURITY: No fallback to mock data - show empty state instead
            // All data must be user-specific and authenticated
        }
        
        isLoading = false
    }
    
    private func loadMonthlyGoal() {
        let goalKey = "monthlyGoal"
        let savedGoal = UserDefaults.standard.double(forKey: goalKey)
        if savedGoal > 0 {
            monthlyGoal = savedGoal
            print("📊 Loaded saved monthly goal: $\(savedGoal)")
            
            // Recalculate progress if we already have earnings data
            if currentMonthNetEarnings > 0 {
                calculateProgressPercentage()
            }
        } else {
            monthlyGoal = 0.0 // No default goal - user must set it
            print("📊 No monthly goal set - user needs to set one")
        }
    }
    
    private func calculateProgressPercentage() {
        // Calculate progress percentage and target progress for monthly goal
        if monthlyGoal > 0 {
            let newProgressPercentage = (currentMonthNetEarnings / monthlyGoal) * 100
            let newTargetProgress = min(currentMonthNetEarnings / monthlyGoal, 1.0)
            
            print("📊 Calculating progress: \(currentMonthNetEarnings.formatAsCurrency) / \(monthlyGoal.formatAsCurrency) = \(String(format: "%.1f", newProgressPercentage))%")
            
            progressPercentage = newProgressPercentage
            targetProgress = newTargetProgress
            
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = targetProgress
            }
        } else {
            progressPercentage = 0
            targetProgress = 0
            animatedProgress = 0
        }
    }
    
    private func saveMonthlyGoal(_ goal: Double) {
        let goalKey = "monthlyGoal"
        UserDefaults.standard.set(goal, forKey: goalKey)
        print("📊 Monthly goal saved: $\(goal)")
        
        // Recalculate progress with new goal
        calculateProgressPercentage()
    }
    
    private func calculateDashboardMetrics() {
        // Use the job amount calculation service for comprehensive calculations
        jobAmountService.calculateJobAmounts(from: supabaseJobs, payments: supabasePayments)
        
        // Update ALL amounts from service based on payment status
        totalIncome = jobAmountService.receivedAmount        // Only received payments
        upcomingPayments = jobAmountService.upcomingPaymentsTotal  // pending + invoiced + partiallyPaid
        overduePayments = jobAmountService.overdueAmount     // overdue payments
        grossEarnings = jobAmountService.receivedAmount      // Only received payments for gross
        
        // Calculate current month earnings for goal tracking (received payments only)
        let calendar = Calendar.current
        let currentDate = Date()
        let receivedPayments = supabasePayments.filter { payment in
            payment.paymentStatus == .received && payment.paidDate != nil
        }
        
        print("📊 Total payments: \(supabasePayments.count)")
        print("📊 Received payments: \(receivedPayments.count)")
        print("📊 Payment statuses: \(supabasePayments.map { $0.paymentStatus.rawValue })")
        
        currentMonthEarnings = receivedPayments.filter { payment in
            guard let paidDate = payment.paidDate else { return false }
            return calendar.isDate(paidDate, equalTo: currentDate, toGranularity: .month)
        }.reduce(0.0) { total, payment in
            return total + payment.amount
        }
        
        print("📊 Current month earnings (received only): \(currentMonthEarnings.formatAsCurrency)")
        
        // Calculate current month net earnings (after 35% deductions: 20% commission + 15% tax)
        currentMonthNetEarnings = currentMonthEarnings * 0.65
        
        // Calculate progress using the dedicated helper function
        calculateProgressPercentage()
        
        // Calculate deductions (20% commission + 15% tax = 35%)
        totalDeductions = grossEarnings * 0.35
        netEarnings = grossEarnings - totalDeductions
        netValue = netEarnings
        
        // SECURITY: No hardcoded financial goals - must be user-set
        // monthlyGoal remains 0 until user explicitly sets it
    }
    
    // REMOVED: loadMockData() function
    // SECURITY: No mock data allowed - all data must be user-authenticated
    
    struct MonthlyData {
        let month: String
        let amount: Double
    }
    
    private func generatePaidIncomeData() -> [(period: String, earnings: Double)] {
        return jobAmountService.getChartData(for: selectedTimePeriod)
    }
    
    private func generatePaidPaymentChartData() {
        let paidPayments = supabasePayments.filter { payment in
            payment.paymentStatus == .received && payment.paidDate != nil
        }
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Generate 6-month window (3 months before current, current month, 2 months after)
        var monthlyData: [String: Double] = [:]
        var monthlyDates: [String: Date] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM" // Only month abbreviation
        
        // Create all 6 months in the window, starting 3 months ago
        for i in -3...2 {
            guard let monthDate = calendar.date(byAdding: .month, value: i, to: currentDate) else { continue }
            let monthKey = dateFormatter.string(from: monthDate)
            monthlyData[monthKey] = 0.0 // Initialize with 0
            monthlyDates[monthKey] = monthDate // Store actual date for sorting
        }
        
        // Add actual payment data to the corresponding months
        for payment in paidPayments {
            guard let paidDate = payment.paidDate else { continue }
            let monthKey = dateFormatter.string(from: paidDate)
            
            // Only include if it's within our 6-month window
            if monthlyData.keys.contains(monthKey) {
                monthlyData[monthKey, default: 0] += payment.amount
            }
        }
        
        // Convert to array and sort by actual date order using stored dates
        let sortedKeys = monthlyData.keys.sorted { first, second in
            guard let firstDate = monthlyDates[first],
                  let secondDate = monthlyDates[second] else {
                return first < second
            }
            return firstDate < secondDate
        }
        
        paidPaymentData = sortedKeys.map { key in
            (period: key, earnings: monthlyData[key] ?? 0.0)
        }
    }
    
    private func calculateDynamicYAxisMax() -> Double {
        return jobAmountService.calculateChartYAxisMax(for: selectedTimePeriod)
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0fK", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    private func formatAxisValueWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        let number = NSNumber(value: value)
        let formattedValue = formatter.string(from: number) ?? "0"
        
        // For Y-axis, add $ prefix and use abbreviated format for large numbers
        if value >= 1000000 {
            return String(format: "$%.1fM", value / 1000000)
        } else if value >= 1000 {
            return String(format: "$%@K", String(Int(value / 1000)))
        } else if value > 0 {
            return "$\(formattedValue)"
        } else {
            return "$0"
        }
    }
    
    private func animateTimelineChange(to newTimePeriod: String) {
        guard !isChangingTimeline else { return } // Prevent multiple rapid changes
        
        isChangingTimeline = true
        
        // First, animate the chart bars going down with a smooth ease-in
        withAnimation(.easeInOut(duration: 0.5)) {
            showChart = false
        }
        
        // Change the time period after the bars are hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedTimePeriod = newTimePeriod
            
            // Add a small delay then animate the new bars growing up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.1)) {
                    showChart = true
                }
                
                // Reset the changing state after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isChangingTimeline = false
                }
            }
        }
    }
    
    private func createMockAgencies() -> [Agency] {
        return [
            Agency(name: "IMG", contactPerson: "Manager", email: "contact@img.com"),
            Agency(name: "Soul Artist Management", contactPerson: "Manager", email: "contact@soul.com")
        ]
    }
}

struct AgencyAccountCardView: View {
    let agency: Agency
    let jobs: [Job]
    @State private var isHovered = false
    
    private var agencyJobs: [Job] {
        jobs.filter { $0.agency?.id == agency.id }
    }
    
    private var totalEarnings: Double {
        agencyJobs.reduce(0.0) { total, job in
            return total + (job.fixedPrice ?? 0.0)
        }
    }
    
    private var jobCount: Int {
        agencyJobs.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(agency.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
            }
            
            // Mini trend chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.appSecondaryText)
                        .frame(width: 3, height: CGFloat.random(in: 8...20))
                }
            }
            .frame(height: 24)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(String(format: "%.0f", totalEarnings > 0 ? totalEarnings : 32000))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("\(jobCount > 0 ? jobCount : 1) jobs")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
        }
        .padding()
        .frame(width: 160, height: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
        )
        .interactiveCardDepth(
            normalDepth: 4,
            pressedDepth: 2,
            hoverDepth: 8,
            animationDuration: 0.2
        )
    }
}

// MARK: - Dashboard Payment Card View
struct DashboardPaymentCardView: View {
    let payment: SupabasePayment
    let jobTitle: String
    
    private var isOverdue: Bool {
        payment.dueDate < Date()
    }
    
    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: payment.dueDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with profile image and job info
            HStack(spacing: 12) {
                // Circular profile image with gradient
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
                        Text(String(jobTitle.prefix(1).uppercased()))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(jobTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Elite Models") // Placeholder for agency/client name
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Overdue indicator dot
                if isOverdue {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Bottom section with due date and amount
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(formattedDueDate)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Amount")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(payment.amount.formatAsCurrency)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280, height: 140)
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

// MARK: - Supabase Agency Account Card View
struct SupabaseAgencyAccountCardView: View {
    let agency: Agency
    let supabaseJobs: [SupabaseJob]
    let supabasePayments: [SupabasePayment]
    let supabaseAgencies: [SupabaseAgency]
    let showChart: Bool
    @State private var isHovered = false
    
    private var agencyJobs: [SupabaseJob] {
        // First try to match by ID, then fall back to matching by name
        let jobsByID = supabaseJobs.filter { $0.agencyId == agency.id }
        if !jobsByID.isEmpty {
            print("🔵 Dashboard card: Found \(jobsByID.count) jobs for agency \(agency.name) by ID")
            return jobsByID
        }
        
        // If no jobs found by ID, try matching by agency name
        // This handles cases where local SwiftData agency ID doesn't match Supabase agency ID
        let jobsByName = supabaseJobs.filter { job in
            // Get the agency for this job and compare names
            return supabaseAgencies.first { $0.id == job.agencyId }?.name == agency.name
        }
        
        print("🔵 Dashboard card: Found \(jobsByName.count) jobs for agency \(agency.name) by name")
        return jobsByName
    }
    
    private var totalEarnings: Double {
        // Calculate based on actual received payments for this agency's jobs
        let agencyJobIds = Set(agencyJobs.map { $0.id })
        let receivedPayments = supabasePayments.filter { payment in
            agencyJobIds.contains(payment.jobId) && payment.paymentStatus == .received
        }
        return receivedPayments.reduce(0.0) { total, payment in
            return total + payment.amount
        }
    }
    
    private var jobCount: Int {
        agencyJobs.count
    }
    
    // Generate mini chart data from real payment data
    private var chartData: [Double] {
        let agencyJobIds = Set(agencyJobs.map { $0.id })
        let receivedPayments = supabasePayments.filter { payment in
            agencyJobIds.contains(payment.jobId) && payment.paymentStatus == .received
        }
        
        if receivedPayments.isEmpty {
            return Array(repeating: 2, count: 8)
        }
        
        // Create chart data based on payment amounts over time
        let maxPayment = receivedPayments.max(by: { $0.amount < $1.amount })?.amount ?? 1000
        let chartPayments = receivedPayments.prefix(8)
        
        // Generate heights based on payment amounts
        var data = chartPayments.map { payment in
            (payment.amount / maxPayment) * 20 + 8
        }
        
        // Fill remaining slots if we have fewer than 8 payments
        while data.count < 8 {
            data.append(2)
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(agency.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
            }
            
            // Mini animated sparkline with real data
            AnimatedSparkline(
                data: chartData,
                lineColor: totalEarnings > 0 ? Color.green : Color.appSecondaryText,
                strokeWidth: 2,
                animationDuration: 1.0,
                animationDelay: showChart ? 1.5 : 0.0
            )
            .frame(height: 24)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCurrency(totalEarnings))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("\(jobCount) job\(jobCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
        }
        .padding()
        .frame(width: 160, height: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
        )
        .interactiveCardDepth(
            normalDepth: 4,
            pressedDepth: 2,
            hoverDepth: 8,
            animationDuration: 0.2
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - All Payments Modal View
struct AllPaymentsModalView: View {
    let payments: [SupabasePayment]
    let jobs: [SupabaseJob]
    @Environment(\.dismiss) private var dismiss
    
    private var paidPayments: [SupabasePayment] {
        payments.filter { $0.paymentStatus == .received }
    }
    
    private var upcomingPayments: [SupabasePayment] {
        payments.filter { 
            $0.paymentStatus == .pending || 
            $0.paymentStatus == .invoiced || 
            $0.paymentStatus == .partiallyPaid 
        }
    }
    
    // Helper function to get job title from payment
    private func getJobTitle(for payment: SupabasePayment) -> String {
        if let job = jobs.first(where: { $0.id == payment.jobId }) {
            return job.title
        }
        return payment.paymentDescription ?? "Payment"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Upcoming Payments Section
                    if !upcomingPayments.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Upcoming Payments")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .foregroundColor(Color.appPrimaryText)
                                
                                Spacer()
                                
                                Text("\(upcomingPayments.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.blue.opacity(0.1))
                                    )
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(upcomingPayments.sorted { $0.dueDate < $1.dueDate }) { payment in
                                    ModalPaymentRowView(payment: payment, isPaid: false, jobTitle: getJobTitle(for: payment))
                                }
                            }
                        }
                    }
                    
                    // Paid Payments Section
                    if !paidPayments.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Paid Payments")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.appPrimaryText)
                                
                                Spacer()
                                
                                Text("\(paidPayments.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.green.opacity(0.1))
                                    )
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(paidPayments.sorted { $0.dueDate > $1.dueDate }) { payment in
                                    ModalPaymentRowView(payment: payment, isPaid: true, jobTitle: getJobTitle(for: payment))
                                }
                            }
                        }
                    }
                    
                    // Empty State
                    if payments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                Text("No payments yet")
                                    .font(.headline)
                                    .foregroundColor(Color.appPrimaryText)
                                
                                Text("Payments will appear here when jobs are created")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("All Payments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Payment Row View for Modal
struct ModalPaymentRowView: View {
    let payment: SupabasePayment
    let isPaid: Bool
    let jobTitle: String
    
    private var isOverdue: Bool {
        !isPaid && payment.dueDate < Date()
    }
    
    private var statusColor: Color {
        if isPaid {
            return .green
        } else if isOverdue {
            return .red
        } else {
            switch payment.paymentStatus {
            case .pending: return .orange
            case .invoiced: return .blue
            case .partiallyPaid: return .yellow
            default: return .gray
            }
        }
    }
    
    private var statusText: String {
        if isPaid {
            return "Paid"
        } else if isOverdue {
            return "Overdue"
        } else {
            switch payment.paymentStatus {
            case .pending: return "Pending"
            case .invoiced: return "Invoiced"
            case .partiallyPaid: return "Partial"
            default: return "Unknown"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(jobTitle)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Text(payment.amount.formatAsCurrency)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                HStack {
                    Text(isPaid ? "Paid: \(payment.paidDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")" : "Due: \(payment.dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(statusColor)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .modelContainer(for: [Job.self, Agency.self, Payment.self])
}