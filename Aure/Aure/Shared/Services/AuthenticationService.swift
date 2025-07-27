import Foundation
import Supabase

@MainActor
class AuthenticationService: ObservableObject {
    private let supabase = SupabaseManager.shared
    private let userService = UserService()
    
    @Published var user: SupabaseUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        checkAuthSessionOnInit()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            
            // Create user profile in database
            let authUser = response.user
            let profile = try await userService.createProfileFromOnboarding(
                name: fullName,
                email: email,
                phone: nil,
                currency: "USD",
                faceIdEnabled: false,
                notificationsEnabled: true
            )
            
            self.user = profile
            self.isAuthenticated = true
            
            self.isLoading = false
            print("✅ User signed up: \(email)")
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            print("🔴 Sign up error: \(error)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Get user profile from database
            if let profile = try await userService.getCurrentProfile() {
                self.user = profile
                self.isAuthenticated = true
            } else {
                // Create profile if it doesn't exist
                let profile = try await userService.createProfileFromOnboarding(
                    name: response.user.userMetadata["full_name"]?.stringValue ?? "User",
                    email: email,
                    phone: nil,
                    currency: "USD",
                    faceIdEnabled: false,
                    notificationsEnabled: true
                )
                self.user = profile
                self.isAuthenticated = true
            }
            
            self.isLoading = false
            print("✅ User signed in: \(email)")
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            print("🔴 Sign in error: \(error)")
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            self.user = nil
            self.isAuthenticated = false
            self.isLoading = false
            print("✅ User signed out")
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            print("🔴 Sign out error: \(error)")
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            self.isLoading = false
            print("✅ Password reset sent to: \(email)")
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            print("🔴 Password reset error: \(error)")
            throw error
        }
    }
    
    // MARK: - Session Management
    
    func checkAuthSession() async throws {
        do {
            let session = try await supabase.auth.session
            
            // Get user profile from database
            if let profile = try await userService.getCurrentProfile() {
                await MainActor.run {
                    self.user = profile
                    self.isAuthenticated = true
                }
                print("✅ Session restored for user: \(profile.email ?? "unknown")")
            } else {
                await MainActor.run {
                    self.user = nil
                    self.isAuthenticated = false
                }
                print("⚠️ No user profile found")
            }
        } catch {
            await MainActor.run {
                self.user = nil
                self.isAuthenticated = false
            }
            print("ℹ️ No active session: \(error)")
            throw error
        }
    }
    
    private func checkAuthSessionOnInit() {
        Task {
            do {
                let session = try await supabase.auth.session
                
                // Get user profile from database
                if let profile = try await userService.getCurrentProfile() {
                    await MainActor.run {
                        self.user = profile
                        self.isAuthenticated = true
                    }
                    print("✅ Session restored for user: \(profile.email ?? "unknown")")
                } else {
                    await MainActor.run {
                        self.user = nil
                        self.isAuthenticated = false
                    }
                    print("⚠️ No user profile found")
                }
            } catch {
                await MainActor.run {
                    self.user = nil
                    self.isAuthenticated = false
                }
                print("ℹ️ No active session: \(error)")
            }
        }
    }
    
    func getCurrentUser() async throws -> SupabaseUser? {
        do {
            let session = try await supabase.auth.session
            return try await userService.getCurrentProfile()
        } catch {
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    func updateProfile(name: String?, phone: String?, currency: String?, faceIdEnabled: Bool?, notificationsEnabled: Bool?) async throws {
        guard isAuthenticated else {
            throw AuthenticationError.notAuthenticated
        }
        
        let request = UpdateUserRequest(
            name: name,
            phone: phone,
            currency: currency,
            faceIdEnabled: faceIdEnabled,
            notificationsEnabled: notificationsEnabled
        )
        
        do {
            let updatedProfile = try await userService.updateProfile(request)
            self.user = updatedProfile
            print("✅ Profile updated")
        } catch {
            self.errorMessage = error.localizedDescription
            print("🔴 Profile update error: \(error)")
            throw error
        }
    }
    
    func completeOnboarding(name: String, phone: String?, currency: String, faceIdEnabled: Bool, notificationsEnabled: Bool) async throws {
        try await updateProfile(
            name: name,
            phone: phone,
            currency: currency,
            faceIdEnabled: faceIdEnabled,
            notificationsEnabled: notificationsEnabled
        )
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError {
    case notAuthenticated
    case profileCreationFailed
    case profileUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .profileCreationFailed:
            return "Failed to create user profile"
        case .profileUpdateFailed:
            return "Failed to update user profile"
        }
    }
}