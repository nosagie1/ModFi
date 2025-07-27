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
        let receivedJobAmountData = supabaseJobs.compactMap { job -> JobAmountData? in
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
    func getChartData() -> [(period: String, earnings: Double)] {
        return monthlyBreakdown.map { month in
            (period: month.month, earnings: month.totalAmount)
        }
    }
    
    /// Calculate dynamic Y-axis maximum for charts
    func calculateChartYAxisMax() -> Double {
        let maxValue = monthlyBreakdown.map { $0.totalAmount }.max() ?? 0
        let paddedMax = maxValue * 1.2
        return max(ceil(paddedMax / 1000) * 1000, 1000)
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