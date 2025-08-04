//
//  JobService.swift
//  Aure
//
//  Service for managing jobs with Supabase
//

import Foundation
import Supabase

@MainActor
class JobService: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    // MARK: - Job CRUD Operations
    
    /// Create a new job
    func createJob(_ request: CreateJobRequest) async throws -> SupabaseJob {
        do {
            let response: SupabaseJob = try await supabase.database
                .from("jobs")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Job created: \(response.title) (\(response.id))")
            return response
        } catch {
            print("🔴 Error creating job: \(error)")
            throw JobServiceError.createFailed(error)
        }
    }
    
    /// Get all jobs for current user
    func getAllJobs() async throws -> [SupabaseJob] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) jobs")
            return response
        } catch {
            print("🔴 Error fetching jobs: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Get jobs by agency
    func getJobsByAgency(agencyId: UUID) async throws -> [SupabaseJob] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select()
                .eq("user_id", value: userId)
                .eq("agency_id", value: agencyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) jobs for agency \(agencyId)")
            return response
        } catch {
            print("🔴 Error fetching jobs by agency: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Get job by ID
    func getJob(id: UUID) async throws -> SupabaseJob? {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select()
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let job = response.first {
                print("✅ Job retrieved: \(job.title)")
                return job
            } else {
                print("⚠️ Job not found: \(id)")
                return nil
            }
        } catch {
            print("🔴 Error fetching job: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Update job
    func updateJob(id: UUID, _ request: UpdateJobRequest) async throws -> SupabaseJob {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: SupabaseJob = try await supabase.database
                .from("jobs")
                .update(request)
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Job updated: \(response.title)")
            return response
        } catch {
            print("🔴 Error updating job: \(error)")
            throw JobServiceError.updateFailed(error)
        }
    }
    
    /// Delete job
    func deleteJob(id: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            try await supabase.database
                .from("jobs")
                .delete()
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Job deleted: \(id)")
        } catch {
            print("🔴 Error deleting job: \(error)")
            throw JobServiceError.deleteFailed(error)
        }
    }
    
    /// Search jobs
    func searchJobs(query: String) async throws -> [SupabaseJob] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select()
                .eq("user_id", value: userId)
                .or("title.ilike.%\(query)%,job_description.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(response.count) jobs matching '\(query)'")
            return response
        } catch {
            print("🔴 Error searching jobs: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Get jobs by status
    func getJobsByStatus(_ status: JobStatus) async throws -> [SupabaseJob] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: status.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) jobs with status \(status.displayName)")
            return response
        } catch {
            print("🔴 Error fetching jobs by status: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Get monthly earnings data
    func getMonthlyEarnings(monthsBack: Int = 6) async throws -> [(month: String, earnings: Double)] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            // Calculate the date range
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .month, value: -monthsBack, to: endDate) ?? endDate
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: formatter.string(from: startDate))
                .lte("created_at", value: formatter.string(from: endDate))
                .execute()
                .value
            
            // Group by month and calculate earnings
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            
            var monthlyData: [String: Double] = [:]
            
            for job in response {
                let month = monthFormatter.string(from: job.createdAt)
                let earnings = job.fixedPrice ?? 0.0
                monthlyData[month, default: 0.0] += earnings
            }
            
            // Convert to array and sort by date
            let sortedData = monthlyData.map { (month: $0.key, earnings: $0.value) }
                .sorted { first, second in
                    // This is a simplified sort - you might want to sort by actual date
                    first.month < second.month
                }
            
            print("✅ Retrieved monthly earnings for \(sortedData.count) months")
            return sortedData
        } catch {
            print("🔴 Error fetching monthly earnings: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Get total earnings
    func getTotalEarnings() async throws -> Double {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseJob] = try await supabase.database
                .from("jobs")
                .select("fixed_price")
                .eq("user_id", value: userId)
                .not("fixed_price", operator: .is, value: "null")
                .execute()
                .value
            
            let total = response.reduce(0.0) { $0 + ($1.fixedPrice ?? 0.0) }
            print("✅ Total earnings calculated: $\(total)")
            return total
        } catch {
            print("🔴 Error calculating total earnings: \(error)")
            throw JobServiceError.fetchFailed(error)
        }
    }
    
    /// Create job from job setup flow
    func createJobFromSetup(
        title: String,
        clientName: String,
        amount: Double,
        commissionPercentage: Double,
        bookedBy: String,
        jobTitle: String?,
        jobDate: Date,
        paymentDueDate: Date,
        agencyId: UUID?
    ) async throws -> SupabaseJob {
        guard let userId = supabase.auth.currentUser?.id else {
            print("🔴 JobService: User not authenticated")
            throw JobServiceError.notAuthenticated
        }
        
        print("🔵 JobService: Creating job for user \(userId)")
        print("🔵 Job details: \(title), amount: \(amount), client: \(clientName)")
        
        let request = CreateJobRequest(
            userId: userId,
            agencyId: agencyId,
            title: title,
            jobDescription: jobTitle ?? "Job for \(clientName)",
            location: nil,
            hourlyRate: nil,
            fixedPrice: amount,
            estimatedHours: nil,
            startDate: jobDate,
            endDate: paymentDueDate,
            status: JobStatus.active.rawValue,
            type: JobType.freelance.rawValue,
            skillsString: nil,
            notes: "Booked by: \(bookedBy)\nCommission: \(commissionPercentage)%"
        )
        
        let result = try await createJob(request)
        print("🔵 JobService: Job created successfully with ID: \(result.id)")
        return result
    }
    
    /// Delete all jobs for current user (useful for clearing test data)
    func deleteAllJobs() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw JobServiceError.notAuthenticated
        }
        
        do {
            try await supabase.database
                .from("jobs")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ All jobs deleted for user \(userId)")
        } catch {
            print("🔴 Error deleting all jobs: \(error)")
            throw JobServiceError.deleteFailed(error)
        }
    }
}

// MARK: - Error Handling
enum JobServiceError: LocalizedError {
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
            return "Failed to create job: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch jobs: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update job: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete job: \(error.localizedDescription)"
        }
    }
}