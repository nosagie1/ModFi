//
//  PaymentService.swift
//  Aure
//
//  Service for managing payments with Supabase
//

import Foundation
import Supabase

@MainActor
class PaymentService: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    // MARK: - Payment CRUD Operations
    
    /// Create a new payment
    func createPayment(_ request: CreatePaymentRequest) async throws -> SupabasePayment {
        do {
            let response: SupabasePayment = try await supabase.database
                .from("payments")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Payment created: $\(response.amount) (\(response.id))")
            return response
        } catch {
            print("🔴 Error creating payment: \(error)")
            throw PaymentServiceError.createFailed(error)
        }
    }
    
    /// Get all payments for current user
    func getAllPayments() async throws -> [SupabasePayment] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabasePayment] = try await supabase.database
                .from("payments")
                .select()
                .eq("user_id", value: userId)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) payments")
            return response
        } catch {
            print("🔴 Error fetching payments: \(error)")
            throw PaymentServiceError.fetchFailed(error)
        }
    }
    
    /// Get payments by job
    func getPaymentsByJob(jobId: UUID) async throws -> [SupabasePayment] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabasePayment] = try await supabase.database
                .from("payments")
                .select()
                .eq("user_id", value: userId)
                .eq("job_id", value: jobId)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) payments for job \(jobId)")
            return response
        } catch {
            print("🔴 Error fetching payments by job: \(error)")
            throw PaymentServiceError.fetchFailed(error)
        }
    }
    
    /// Get payment by ID
    func getPayment(id: UUID) async throws -> SupabasePayment? {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabasePayment] = try await supabase.database
                .from("payments")
                .select()
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let payment = response.first {
                print("✅ Payment retrieved: $\(payment.amount)")
                return payment
            } else {
                print("⚠️ Payment not found: \(id)")
                return nil
            }
        } catch {
            print("🔴 Error fetching payment: \(error)")
            throw PaymentServiceError.fetchFailed(error)
        }
    }
    
    /// Update payment
    func updatePayment(id: UUID, _ request: UpdatePaymentRequest) async throws -> SupabasePayment {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            let response: SupabasePayment = try await supabase.database
                .from("payments")
                .update(request)
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Payment updated: $\(response.amount)")
            return response
        } catch {
            print("🔴 Error updating payment: \(error)")
            throw PaymentServiceError.updateFailed(error)
        }
    }
    
    /// Delete payment
    func deletePayment(id: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            try await supabase.database
                .from("payments")
                .delete()
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Payment deleted: \(id)")
        } catch {
            print("🔴 Error deleting payment: \(error)")
            throw PaymentServiceError.deleteFailed(error)
        }
    }
    
    /// Get payments by status
    func getPaymentsByStatus(_ status: PaymentStatus) async throws -> [SupabasePayment] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabasePayment] = try await supabase.database
                .from("payments")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: status.rawValue)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) payments with status \(status.displayName)")
            return response
        } catch {
            print("🔴 Error fetching payments by status: \(error)")
            throw PaymentServiceError.fetchFailed(error)
        }
    }
    
    /// Get overdue payments
    func getOverduePayments() async throws -> [SupabasePayment] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            let response: [SupabasePayment] = try await supabase.database
                .from("payments")
                .select()
                .eq("user_id", value: userId)
                .in("status", values: [PaymentStatus.pending.rawValue, PaymentStatus.invoiced.rawValue])
                .lt("due_date", value: formatter.string(from: today))
                .order("due_date", ascending: true)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) overdue payments")
            return response
        } catch {
            print("🔴 Error fetching overdue payments: \(error)")
            throw PaymentServiceError.fetchFailed(error)
        }
    }
    
    /// Get upcoming payments (due in next 30 days)
    func getUpcomingPayments(days: Int = 30) async throws -> [SupabasePayment] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            let response: [SupabasePayment] = try await supabase.database
                .from("payments")
                .select()
                .eq("user_id", value: userId)
                .in("status", values: [PaymentStatus.pending.rawValue, PaymentStatus.invoiced.rawValue])
                .gte("due_date", value: formatter.string(from: today))
                .lte("due_date", value: formatter.string(from: futureDate))
                .order("due_date", ascending: true)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) upcoming payments")
            return response
        } catch {
            print("🔴 Error fetching upcoming payments: \(error)")
            throw PaymentServiceError.fetchFailed(error)
        }
    }
    
    /// Mark payment as received
    func markPaymentAsReceived(id: UUID, paidDate: Date = Date()) async throws -> SupabasePayment {
        let request = UpdatePaymentRequest(
            amount: nil,
            currency: nil,
            paymentDescription: nil,
            dueDate: nil,
            paidDate: paidDate,
            status: PaymentStatus.received.rawValue,
            type: nil,
            invoiceNumber: nil,
            notes: nil
        )
        
        return try await updatePayment(id: id, request)
    }
    
    /// Create payment from job setup
    func createPaymentFromJobSetup(
        jobId: UUID,
        amount: Double,
        dueDate: Date,
        status: PaymentStatus,
        expectedPaymentDate: Date? = nil
    ) async throws -> SupabasePayment {
        guard let userId = supabase.auth.currentUser?.id else {
            print("🔴 PaymentService: User not authenticated")
            throw PaymentServiceError.notAuthenticated
        }
        
        print("🔵 PaymentService: Creating payment for job \(jobId), amount: \(amount), status: \(status)")
        
        // Use expectedPaymentDate for overdue payments, otherwise use provided dueDate
        let paymentDueDate = (status == .overdue && expectedPaymentDate != nil) ? expectedPaymentDate! : dueDate
        
        let request = CreatePaymentRequest(
            userId: userId,
            jobId: jobId,
            amount: amount,
            currency: "USD",
            paymentDescription: "Payment for job",
            dueDate: paymentDueDate,
            paidDate: status == .received ? Date() : nil,
            status: status.rawValue,
            type: PaymentType.fixed.rawValue,
            invoiceNumber: nil,
            notes: status == .overdue ? "Created from job setup - Expected payment on \(paymentDueDate.formatted(date: .abbreviated, time: .omitted))" : "Created from job setup"
        )
        
        let result = try await createPayment(request)
        print("🔵 PaymentService: Payment created successfully with ID: \(result.id)")
        return result
    }
    
    /// Get payment statistics
    func getPaymentStatistics() async throws -> PaymentStatistics {
        let allPayments = try await getAllPayments()
        
        let totalAmount = allPayments.reduce(0.0) { $0 + $1.amount }
        let receivedAmount = allPayments.filter { $0.paymentStatus == .received }.reduce(0.0) { $0 + $1.amount }
        let pendingAmount = allPayments.filter { $0.paymentStatus == .pending || $0.paymentStatus == .invoiced }.reduce(0.0) { $0 + $1.amount }
        let overdueAmount = allPayments.filter { $0.isOverdue }.reduce(0.0) { $0 + $1.amount }
        
        return PaymentStatistics(
            totalAmount: totalAmount,
            receivedAmount: receivedAmount,
            pendingAmount: pendingAmount,
            overdueAmount: overdueAmount,
            totalCount: allPayments.count,
            receivedCount: allPayments.filter { $0.paymentStatus == .received }.count,
            pendingCount: allPayments.filter { $0.paymentStatus == .pending || $0.paymentStatus == .invoiced }.count,
            overdueCount: allPayments.filter { $0.isOverdue }.count
        )
    }
    
    /// Delete all payments for current user (useful for clearing test data)
    func deleteAllPayments() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw PaymentServiceError.notAuthenticated
        }
        
        do {
            try await supabase.database
                .from("payments")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ All payments deleted for user \(userId)")
        } catch {
            print("🔴 Error deleting all payments: \(error)")
            throw PaymentServiceError.deleteFailed(error)
        }
    }
}

// MARK: - Payment Statistics Model
struct PaymentStatistics {
    let totalAmount: Double
    let receivedAmount: Double
    let pendingAmount: Double
    let overdueAmount: Double
    let totalCount: Int
    let receivedCount: Int
    let pendingCount: Int
    let overdueCount: Int
}

// MARK: - Error Handling
enum PaymentServiceError: LocalizedError {
    case notAuthenticated
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .createFailed(let error):
            return "Failed to create payment: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch payments: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update payment: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete payment: \(error.localizedDescription)"
        }
    }
}