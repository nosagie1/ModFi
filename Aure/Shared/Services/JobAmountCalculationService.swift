//
//  JobAmountCalculationService.swift
//  Aure
//
//  Service for calculating job amounts and distributing to charts/visuals
//

import Foundation

@MainActor
class JobAmountCalculationService: ObservableObject {
    
    // MARK: - Published Properties for UI Updates
    @Published var totalJobIncome: Double = 0.0 // Only RECEIVED payments
    @Published var monthlyBreakdown: [MonthlyJobData] = []
    @Published var currentMonthTotal: Double = 0.0
    @Published var previousMonthTotal: Double = 0.0
    @Published var thirtyDayPercentageChange: Double = 0.0
    
    // Payment status categorized amounts
    @Published var pendingAmount: Double = 0.0      // Shows in Upcoming
    @Published var invoicedAmount: Double = 0.0     // Shows in Upcoming  
    @Published var partiallyPaidAmount: Double = 0.0 // Shows in Upcoming
    @Published var receivedAmount: Double = 0.0     // Shows in Total Income
    @Published var overdueAmount: Double = 0.0      // Shows in Overdue
    @Published var cancelledAmount: Double = 0.0    // Not shown in financial calculations
    
    // Stored job data for chart calculations
    private var receivedJobAmountData: [JobAmountData] = []
    
    // MARK: - Data Models
    struct MonthlyJobData: Identifiable {
        let id = UUID()
        let month: String
        let monthDate: Date
        let totalAmount: Double
        let jobCount: Int
        let jobs: [JobAmountData]
    }
    
    struct JobAmountData: Identifiable {
        let id: UUID
        let title: String
        let amount: Double
        let clientName: String
        let date: Date
        let paymentStatus: String
    }
    
    // MARK: - Calculation Methods
    
    /// Calculate all job amounts and distribute based on payment status
    func calculateJobAmounts(from supabaseJobs: [SupabaseJob], payments: [SupabasePayment]) {
        // Reset all amounts
        resetAmounts()
        
        // Calculate amounts by payment status
        calculateAmountsByPaymentStatus(payments: payments)
        
        // Generate job amount data only for RECEIVED payments (for charts)
        receivedJobAmountData = supabaseJobs.compactMap { job -> JobAmountData? in
            let jobPayments = payments.filter { $0.jobId == job.id && $0.paymentStatus == .received }
            guard !jobPayments.isEmpty else { return nil }
            
            let totalPaidAmount = jobPayments.reduce(0.0) { $0 + $1.amount }
            
            return JobAmountData(
                id: job.id,
                title: job.title,
                amount: totalPaidAmount,
                clientName: extractClientName(from: job),
                date: mostRecentPaymentDate(from: jobPayments) ?? job.startDate ?? job.createdAt,
                paymentStatus: "received"
            )
        }
        
        // Generate monthly breakdown for charts (only received payments)
        generateMonthlyBreakdown(from: receivedJobAmountData)
        
        // Calculate 30-day comparison (only received payments)
        calculate30DayComparison(from: receivedJobAmountData)
        
        print("📊 Payment amounts by status:")
        print("   💰 Received: \(formatCurrency(receivedAmount))")
        print("   ⏳ Pending: \(formatCurrency(pendingAmount))")
        print("   📄 Invoiced: \(formatCurrency(invoicedAmount))")
        print("   🔶 Partially Paid: \(formatCurrency(partiallyPaidAmount))")
        print("   🔴 Overdue: \(formatCurrency(overdueAmount))")
        print("   30-day change: \(String(format: "%.1f", thirtyDayPercentageChange))%")
    }
    
    /// Reset all calculated amounts
    private func resetAmounts() {
        pendingAmount = 0.0
        invoicedAmount = 0.0
        partiallyPaidAmount = 0.0
        receivedAmount = 0.0
        overdueAmount = 0.0
        cancelledAmount = 0.0
        totalJobIncome = 0.0
    }
    
    /// Calculate amounts categorized by payment status
    func calculateAmountsByPaymentStatus(payments: [SupabasePayment]) {
        for payment in payments {
            switch payment.paymentStatus {
            case .pending:
                pendingAmount += payment.amount
            case .invoiced:
                invoicedAmount += payment.amount
            case .partiallyPaid:
                partiallyPaidAmount += payment.amount
            case .received:
                receivedAmount += payment.amount
                totalJobIncome += payment.amount // Only received payments count as income
            case .overdue:
                overdueAmount += payment.amount
            case .cancelled:
                cancelledAmount += payment.amount
            }
        }
    }
    
    /// Get upcoming payments total (pending + invoiced + partially paid)
    var upcomingPaymentsTotal: Double {
        return pendingAmount + invoicedAmount + partiallyPaidAmount
    }
    
    /// Get most recent payment date from a list of payments
    private func mostRecentPaymentDate(from payments: [SupabasePayment]) -> Date? {
        return payments.compactMap { $0.paidDate }.max()
    }
    
    
    /// Generate 6-month breakdown for dashboard chart
    private func generateMonthlyBreakdown(from jobs: [JobAmountData]) {
        let calendar = Calendar.current
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        var monthlyData: [String: (date: Date, jobs: [JobAmountData], total: Double)] = [:]
        
        // Initialize 6-month window (3 before, current, 2 after)
        for i in -3...2 {
            guard let monthDate = calendar.date(byAdding: .month, value: i, to: currentDate) else { continue }
            let monthKey = dateFormatter.string(from: monthDate)
            monthlyData[monthKey] = (date: monthDate, jobs: [], total: 0.0)
        }
        
        // Group jobs by month
        for job in jobs {
            let monthKey = dateFormatter.string(from: job.date)
            
            if var monthData = monthlyData[monthKey] {
                monthData.jobs.append(job)
                monthData.total += job.amount
                monthlyData[monthKey] = monthData
            }
        }
        
        // Convert to sorted array
        monthlyBreakdown = monthlyData.compactMap { (key, value) in
            MonthlyJobData(
                month: key,
                monthDate: value.date,
                totalAmount: value.total,
                jobCount: value.jobs.count,
                jobs: value.jobs
            )
        }.sorted { $0.monthDate < $1.monthDate }
    }
    
    /// Calculate 30-day income comparison for percentage indicator
    private func calculate30DayComparison(from jobs: [JobAmountData]) {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: currentDate) ?? currentDate
        currentMonthTotal = jobs.filter { job in
            job.date >= thirtyDaysAgo && job.date <= currentDate
        }.reduce(0.0) { $0 + $1.amount }
        
        // Previous 30 days (31-60 days ago)
        let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: currentDate) ?? currentDate
        let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -31, to: currentDate) ?? currentDate
        previousMonthTotal = jobs.filter { job in
            job.date >= sixtyDaysAgo && job.date <= thirtyOneDaysAgo
        }.reduce(0.0) { $0 + $1.amount }
        
        // Calculate percentage change
        if previousMonthTotal > 0 {
            thirtyDayPercentageChange = ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100
        } else {
            thirtyDayPercentageChange = currentMonthTotal > 0 ? 100 : 0
        }
    }
    
    /// Get chart data for dashboard visualization
    func getChartData(for timePeriod: String = "Last 6 months") -> [(period: String, earnings: Double)] {
        switch timePeriod {
        case "Day":
            return getDayChartData()
        case "Week":
            return getWeekChartData()
        case "Month":
            return getMonthChartData()
        case "Year":
            return getYearChartData()
        default: // "Last 6 months"
            return monthlyBreakdown.map { month in
                (period: month.month, earnings: month.totalAmount)
            }
        }
    }
    
    /// Calculate dynamic Y-axis maximum for charts
    func calculateChartYAxisMax(for timePeriod: String = "Last 6 months") -> Double {
        let chartData = getChartData(for: timePeriod)
        let maxValue = chartData.map { $0.earnings }.max() ?? 0
        let paddedMax = maxValue * 1.2
        return max(ceil(paddedMax / 1000) * 1000, 1000)
    }
    
    /// Calculate percentage change based on timeline
    func getPercentageChange(for timePeriod: String) -> Double {
        switch timePeriod {
        case "Day":
            return getDailyPercentageChange()
        case "Week":
            return getWeeklyPercentageChange()
        case "Month":
            return getMonthlyPercentageChange()
        case "Year":
            return getYearlyPercentageChange()
        default: // "Last 6 months"
            return thirtyDayPercentageChange // Use existing 30-day calculation
        }
    }
    
    // MARK: - Time Period Specific Chart Data
    
    private func getDayChartData() -> [(period: String, earnings: Double)] {
        let calendar = Calendar.current
        let currentDate = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E" // Mon, Tue, Wed, etc.
        
        var dailyData: [(period: String, earnings: Double)] = []
        
        // Get last 7 days
        for i in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: i, to: currentDate) else { continue }
            let dayKey = dayFormatter.string(from: date)
            
            let dayTotal = receivedJobAmountData.filter { job in
                calendar.isDate(job.date, inSameDayAs: date)
            }.reduce(0.0) { $0 + $1.amount }
            
            dailyData.append((period: dayKey, earnings: dayTotal))
        }
        
        return dailyData
    }
    
    private func getWeekChartData() -> [(period: String, earnings: Double)] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        var weeklyData: [(period: String, earnings: Double)] = []
        
        // Get last 4 weeks
        for i in -3...0 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: i, to: currentDate) else { continue }
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }
            
            let weekFormatter = DateFormatter()
            weekFormatter.dateFormat = "MMM d"
            let weekKey = weekFormatter.string(from: weekStart)
            
            let weekTotal = receivedJobAmountData.filter { job in
                job.date >= weekStart && job.date <= weekEnd
            }.reduce(0.0) { $0 + $1.amount }
            
            weeklyData.append((period: weekKey, earnings: weekTotal))
        }
        
        return weeklyData
    }
    
    private func getMonthChartData() -> [(period: String, earnings: Double)] {
        let calendar = Calendar.current
        let currentDate = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        var monthlyData: [(period: String, earnings: Double)] = []
        
        // Get last 6 months
        for i in -5...0 {
            guard let monthDate = calendar.date(byAdding: .month, value: i, to: currentDate) else { continue }
            let monthKey = monthFormatter.string(from: monthDate)
            
            let monthTotal = receivedJobAmountData.filter { job in
                calendar.isDate(job.date, equalTo: monthDate, toGranularity: .month)
            }.reduce(0.0) { $0 + $1.amount }
            
            monthlyData.append((period: monthKey, earnings: monthTotal))
        }
        
        return monthlyData
    }
    
    private func getYearChartData() -> [(period: String, earnings: Double)] {
        let calendar = Calendar.current
        let currentDate = Date()
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        
        var yearlyData: [(period: String, earnings: Double)] = []
        
        // Get last 3 years
        for i in -2...0 {
            guard let yearDate = calendar.date(byAdding: .year, value: i, to: currentDate) else { continue }
            let yearKey = yearFormatter.string(from: yearDate)
            
            let yearTotal = receivedJobAmountData.filter { job in
                calendar.isDate(job.date, equalTo: yearDate, toGranularity: .year)
            }.reduce(0.0) { $0 + $1.amount }
            
            yearlyData.append((period: yearKey, earnings: yearTotal))
        }
        
        return yearlyData
    }
    
    // MARK: - Percentage Change Calculations
    
    private func getDailyPercentageChange() -> Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Today's earnings
        let todayTotal = receivedJobAmountData.filter { job in
            calendar.isDate(job.date, inSameDayAs: currentDate)
        }.reduce(0.0) { $0 + $1.amount }
        
        // Look back through previous days to find the last increase
        for i in 1...7 { // Check last 7 days
            guard let previousDay = calendar.date(byAdding: .day, value: -i, to: currentDate) else { continue }
            let previousDayTotal = receivedJobAmountData.filter { job in
                calendar.isDate(job.date, inSameDayAs: previousDay)
            }.reduce(0.0) { $0 + $1.amount }
            
            if previousDayTotal > 0 && todayTotal > previousDayTotal {
                return ((todayTotal - previousDayTotal) / previousDayTotal) * 100
            }
        }
        
        return todayTotal > 0 ? 100 : 0 // If no previous positive period found, show 100% for any current earnings
    }
    
    private func getWeeklyPercentageChange() -> Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Current week earnings
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return 0 }
        let currentWeekTotal = receivedJobAmountData.filter { job in
            currentWeekInterval.contains(job.date)
        }.reduce(0.0) { $0 + $1.amount }
        
        // Look back through previous weeks to find the last increase
        for i in 1...4 { // Check last 4 weeks
            guard let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: currentWeekInterval.start),
                  let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeekStart) else { continue }
            
            let previousWeekTotal = receivedJobAmountData.filter { job in
                previousWeekInterval.contains(job.date)
            }.reduce(0.0) { $0 + $1.amount }
            
            if previousWeekTotal > 0 && currentWeekTotal > previousWeekTotal {
                return ((currentWeekTotal - previousWeekTotal) / previousWeekTotal) * 100
            }
        }
        
        return currentWeekTotal > 0 ? 100 : 0
    }
    
    private func getMonthlyPercentageChange() -> Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Current month earnings
        let currentMonthTotal = receivedJobAmountData.filter { job in
            calendar.isDate(job.date, equalTo: currentDate, toGranularity: .month)
        }.reduce(0.0) { $0 + $1.amount }
        
        // Look back through previous months to find the last increase
        for i in 1...6 { // Check last 6 months
            guard let previousMonth = calendar.date(byAdding: .month, value: -i, to: currentDate) else { continue }
            let previousMonthTotal = receivedJobAmountData.filter { job in
                calendar.isDate(job.date, equalTo: previousMonth, toGranularity: .month)
            }.reduce(0.0) { $0 + $1.amount }
            
            if previousMonthTotal > 0 && currentMonthTotal > previousMonthTotal {
                return ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100
            }
        }
        
        return currentMonthTotal > 0 ? 100 : 0
    }
    
    private func getYearlyPercentageChange() -> Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Current year earnings
        let currentYearTotal = receivedJobAmountData.filter { job in
            calendar.isDate(job.date, equalTo: currentDate, toGranularity: .year)
        }.reduce(0.0) { $0 + $1.amount }
        
        // Look back through previous years to find the last increase
        for i in 1...3 { // Check last 3 years
            guard let previousYear = calendar.date(byAdding: .year, value: -i, to: currentDate) else { continue }
            let previousYearTotal = receivedJobAmountData.filter { job in
                calendar.isDate(job.date, equalTo: previousYear, toGranularity: .year)
            }.reduce(0.0) { $0 + $1.amount }
            
            if previousYearTotal > 0 && currentYearTotal > previousYearTotal {
                return ((currentYearTotal - previousYearTotal) / previousYearTotal) * 100
            }
        }
        
        return currentYearTotal > 0 ? 100 : 0
    }
    
    private func calculatePercentageChange(current: Double, previous: Double) -> Double {
        if previous > 0 {
            let change = ((current - previous) / previous) * 100
            // Only return positive changes (increases)
            return max(change, 0)
        } else {
            return current > 0 ? 100 : 0
        }
    }
    
    /// Get job details for specific month (for drill-down views)
    func getJobsForMonth(_ monthAbbreviation: String) -> [JobAmountData] {
        return monthlyBreakdown.first { $0.month == monthAbbreviation }?.jobs ?? []
    }
    
    // MARK: - Helper Methods
    
    private func extractClientName(from job: SupabaseJob) -> String {
        // Try to extract client name from job title or description
        if job.title.contains("for ") {
            let components = job.title.components(separatedBy: "for ")
            if components.count > 1 {
                return components[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Try to extract from notes
        if let notes = job.notes, notes.contains("Client: ") {
            let components = notes.components(separatedBy: "Client: ")
            if components.count > 1 {
                return components[1].components(separatedBy: "\n")[0].trimmingCharacters(in: .whitespaces)
            }
        }
        
        return "Unknown Client"
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}