//
//  UserService.swift
//  Aure
//
//  Service for managing user profiles with Supabase
//

import Foundation
import Supabase

@MainActor
class UserService: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    // MARK: - User Profile Operations
    
    /// Create a new user profile
    func createProfile(_ request: CreateUserRequest) async throws -> SupabaseUser {
        do {
            let response: SupabaseUser = try await supabase.database
                .from("profiles")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ User profile created: \(response.id)")
            return response
        } catch {
            print("🔴 Error creating user profile: \(error)")
            throw UserServiceError.createFailed(error)
        }
    }
    
    /// Get current user profile
    func getCurrentProfile() async throws -> SupabaseUser? {
        guard let userId = supabase.auth.currentUser?.id else {
            throw UserServiceError.notAuthenticated
        }
        
        do {
            let response: [SupabaseUser] = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let profile = response.first {
                print("✅ User profile retrieved: \(profile.id)")
                return profile
            } else {
                print("⚠️ No user profile found for ID: \(userId)")
                return nil
            }
        } catch {
            print("🔴 Error fetching user profile: \(error)")
            throw UserServiceError.fetchFailed(error)
        }
    }
    
    /// Update user profile
    func updateProfile(_ request: UpdateUserRequest) async throws -> SupabaseUser {
        guard let userId = supabase.auth.currentUser?.id else {
            throw UserServiceError.notAuthenticated
        }
        
        do {
            let response: SupabaseUser = try await supabase.database
                .from("profiles")
                .update(request)
                .eq("id", value: userId)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ User profile updated: \(response.id)")
            return response
        } catch {
            print("🔴 Error updating user profile: \(error)")
            throw UserServiceError.updateFailed(error)
        }
    }
    
    /// Delete user profile
    func deleteProfile() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw UserServiceError.notAuthenticated
        }
        
        do {
            try await supabase.database
                .from("profiles")
                .delete()
                .eq("id", value: userId)
                .execute()
            
            print("✅ User profile deleted: \(userId)")
        } catch {
            print("🔴 Error deleting user profile: \(error)")
            throw UserServiceError.deleteFailed(error)
        }
    }
    
    /// Check if user profile exists
    func profileExists() async throws -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            return false
        }
        
        do {
            let count = try await supabase.database
                .from("profiles")
                .select("id", head: true, count: .exact)
                .eq("id", value: userId)
                .execute()
                .count
            
            return (count ?? 0) > 0
        } catch {
            print("🔴 Error checking if profile exists: \(error)")
            throw UserServiceError.fetchFailed(error)
        }
    }
    
    /// Create profile from onboarding data
    func createProfileFromOnboarding(name: String, email: String, phone: String?, currency: String, faceIdEnabled: Bool, notificationsEnabled: Bool) async throws -> SupabaseUser {
        guard let userId = supabase.auth.currentUser?.id else {
            throw UserServiceError.notAuthenticated
        }
        
        let request = CreateUserRequest(
            id: userId,
            name: name,
            email: email,
            phone: phone,
            currency: currency,
            faceIdEnabled: faceIdEnabled,
            notificationsEnabled: notificationsEnabled
        )
        
        return try await createProfile(request)
    }
}

// MARK: - Error Handling
enum UserServiceError: LocalizedError {
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
            return "Failed to create user profile: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch user profile: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update user profile: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete user profile: \(error.localizedDescription)"
        }
    }
}