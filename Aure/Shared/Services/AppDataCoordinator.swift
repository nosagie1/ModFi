//
//  AppDataCoordinator.swift
//  Aure
//
//  Coordinates data flow between local SwiftData and remote Supabase
//

import Foundation
import SwiftUI

@MainActor
class AppDataCoordinator: ObservableObject {
    // Services
    private let userService = UserService()
    private let jobService = JobService()
    private let agencyService = AgencyService()
    private let paymentService = PaymentService()
    
    // Published data
    @Published var currentUser: SupabaseUser?
    @Published var jobs: [SupabaseJob] = []
    @Published var agencies: [SupabaseAgency] = []
    @Published var payments: [SupabasePayment] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    
    // MARK: - Data Loading
    
    func loadAllData() async {
        isLoading = true
        
        do {
            async let userTask = userService.getCurrentProfile()
            async let jobsTask = jobService.getAllJobs()
            async let agenciesTask = agencyService.getAllAgencies()
            async let paymentsTask = paymentService.getAllPayments()
            
            // Wait for all data to load
            currentUser = try await userTask
            jobs = try await jobsTask
            agencies = try await agenciesTask
            payments = try await paymentsTask
            
            lastSyncDate = Date()
            print("✅ All app data loaded successfully")
            
        } catch {
            print("🔴 Error loading app data: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadAllData()
    }
    
    // MARK: - Quick Access Methods
    
    func getJobsForAgency(_ agencyId: UUID) -> [SupabaseJob] {
        return jobs.filter { $0.agencyId == agencyId }
    }
    
    func getPaymentsForJob(_ jobId: UUID) -> [SupabasePayment] {
        return payments.filter { $0.jobId == jobId }
    }
    
    func getTotalEarnings() -> Double {
        return jobs.reduce(0.0) { $0 + ($1.fixedPrice ?? 0.0) }
    }
    
    func getPendingPayments() -> [SupabasePayment] {
        return payments.filter { $0.paymentStatus == .pending || $0.paymentStatus == .invoiced }
    }
    
    func getOverduePayments() -> [SupabasePayment] {
        return payments.filter { $0.isOverdue }
    }
    
    // MARK: - Data Creation Helpers
    
    func createJobWithPayment(
        title: String,
        clientName: String, 
        amount: Double,
        agencyId: UUID?,
        paymentStatus: PaymentStatus
    ) async throws -> (job: SupabaseJob, payment: SupabasePayment) {
        
        // Create job
        let job = try await jobService.createJobFromSetup(
            title: title,
            clientName: clientName,
            amount: amount,
            commissionPercentage: 20.0,
            bookedBy: currentUser?.name ?? "Unknown",
            jobTitle: title,
            jobDate: Date(),
            paymentDueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            agencyId: agencyId
        )
        
        // Create payment
        let payment = try await paymentService.createPaymentFromJobSetup(
            jobId: job.id,
            amount: amount,
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            status: paymentStatus
        )
        
        // Update local data
        jobs.append(job)
        payments.append(payment)
        
        return (job, payment)
    }
    
    // MARK: - Sync Status
    
    var syncStatusText: String {
        if isLoading {
            return "Syncing..."
        } else if let lastSync = lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Last synced: \(formatter.string(from: lastSync))"
        } else {
            return "Not synced"
        }
    }
}