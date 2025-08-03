//
//  AgencyService.swift
//  Aure
//
//  Service for managing agencies with Supabase
//

import Foundation
import Supabase

@MainActor
class AgencyService: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    // MARK: - Agency CRUD Operations
    
    /// Create a new agency
    func createAgency(_ request: CreateAgencyRequest) async throws -> SupabaseAgency {
        do {
            let response: SupabaseAgency = try await supabase.database
                .from("agencies")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Agency created: \(response.name) (\(response.id))")
            return response
        } catch {
            print("🔴 Error creating agency: \(error)")
            throw AgencyServiceError.createFailed(error)
        }
    }
    
    /// Get all agencies for current user
    func getAllAgencies() async throws -> [SupabaseAgency] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseAgency] = try await supabase.database
                .from("agencies")
                .select()
                .eq("user_id", value: userId)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Retrieved \(response.count) agencies")
            return response
        } catch {
            print("🔴 Error fetching agencies: \(error)")
            throw AgencyServiceError.fetchFailed(error)
        }
    }
    
    /// Get agency by ID
    func getAgency(id: UUID) async throws -> SupabaseAgency? {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseAgency] = try await supabase.database
                .from("agencies")
                .select()
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let agency = response.first {
                print("✅ Agency retrieved: \(agency.name)")
                return agency
            } else {
                print("⚠️ Agency not found: \(id)")
                return nil
            }
        } catch {
            print("🔴 Error fetching agency: \(error)")
            throw AgencyServiceError.fetchFailed(error)
        }
    }
    
    /// Update agency
    func updateAgency(id: UUID, _ request: UpdateAgencyRequest) async throws -> SupabaseAgency {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        do {
            let response: SupabaseAgency = try await supabase.database
                .from("agencies")
                .update(request)
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Agency updated: \(response.name)")
            return response
        } catch {
            print("🔴 Error updating agency: \(error)")
            throw AgencyServiceError.updateFailed(error)
        }
    }
    
    /// Delete agency (soft delete)
    func deleteAgency(id: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        do {
            let updateRequest = UpdateAgencyRequest(
                name: nil,
                contactPerson: nil,
                email: nil,
                phone: nil,
                address: nil,
                website: nil,
                industry: nil,
                notes: nil,
                isActive: false
            )
            
            try await supabase.database
                .from("agencies")
                .update(updateRequest)
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Agency soft deleted: \(id)")
        } catch {
            print("🔴 Error deleting agency: \(error)")
            throw AgencyServiceError.deleteFailed(error)
        }
    }
    
    /// Hard delete agency
    func hardDeleteAgency(id: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        do {
            try await supabase.database
                .from("agencies")
                .delete()
                .eq("id", value: id)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Agency hard deleted: \(id)")
        } catch {
            print("🔴 Error hard deleting agency: \(error)")
            throw AgencyServiceError.deleteFailed(error)
        }
    }
    
    /// Search agencies by name
    func searchAgencies(query: String) async throws -> [SupabaseAgency] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseAgency] = try await supabase.database
                .from("agencies")
                .select()
                .eq("user_id", value: userId)
                .eq("is_active", value: true)
                .ilike("name", pattern: "%\(query)%")
                .order("name", ascending: true)
                .execute()
                .value
            
            print("✅ Found \(response.count) agencies matching '\(query)'")
            return response
        } catch {
            print("🔴 Error searching agencies: \(error)")
            throw AgencyServiceError.fetchFailed(error)
        }
    }
    
    /// Create agency from onboarding
    func createAgencyFromOnboarding(name: String) async throws -> SupabaseAgency {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        let request = CreateAgencyRequest(
            userId: userId,
            name: name,
            contactPerson: "TBD",
            email: "contact@\(name.lowercased().replacingOccurrences(of: " ", with: "")).com",
            phone: nil,
            address: nil,
            website: nil,
            industry: "Entertainment",
            notes: "Created during onboarding",
            isActive: true
        )
        
        return try await createAgency(request)
    }
    
    /// Get agency performance statistics
    func getAgencyPerformance() async throws -> [(agency: SupabaseAgency, jobCount: Int, totalEarnings: Double)] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AgencyServiceError.notAuthenticated
        }
        
        // This would typically be done with a JOIN query or stored procedure
        // For now, we'll fetch agencies and jobs separately
        let agencies = try await getAllAgencies()
        var results: [(agency: SupabaseAgency, jobCount: Int, totalEarnings: Double)] = []
        
        // Note: In a real implementation, you'd want to do this with a single query
        for agency in agencies {
            // This is a simplified version - you'd want to implement JobService first
            results.append((agency: agency, jobCount: 0, totalEarnings: 0.0))
        }
        
        return results
    }
}

// MARK: - Error Handling
enum AgencyServiceError: LocalizedError {
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
            return "Failed to create agency: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch agencies: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update agency: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete agency: \(error.localizedDescription)"
        }
    }
}