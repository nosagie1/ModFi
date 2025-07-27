import Foundation
import Supabase

/// Singleton manager for Supabase client
/// Provides centralized access to Supabase services throughout the app
class SupabaseManager: ObservableObject {
    // MARK: - Singleton
    static let shared = SupabaseManager()
    
    // MARK: - Properties
    let client: SupabaseClient
    
    // MARK: - Initialization
    private init() {
        // Use SecureCredentialManager for better credential management
        let credentialManager = SecureCredentialManager.shared
        
        // Validate credentials
        do {
            try credentialManager.validateCredentials()
        } catch {
            credentialManager.printSetupInstructions()
            fatalError("Supabase configuration error: \(error.localizedDescription)")
        }
        
        guard let url = URL(string: credentialManager.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(credentialManager.supabaseURL)")
        }
        
        // Initialize Supabase client with updated API
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: credentialManager.supabaseAnonKey
        )
        
        // Set up auth state listener
        setupAuthStateListener()
        
        print("✅ Supabase Manager initialized successfully")
    }
    
    // MARK: - Auth State Management
    private func setupAuthStateListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    handleAuthStateChange(event, session: session)
                }
            }
        }
    }
    
    @MainActor
    private func handleAuthStateChange(_ event: AuthChangeEvent, session: Session?) {
        switch event {
        case .initialSession:
            print("🔄 Initial session loaded")
        case .signedIn:
            print("✅ User signed in")
        case .signedOut:
            print("👋 User signed out")
        case .tokenRefreshed:
            print("🔄 Token refreshed")
        case .userUpdated:
            print("👤 User updated")
        case .passwordRecovery:
            print("🔑 Password recovery")
        case .mfaChallengeVerified:
            print("🔐 MFA challenge verified")
        @unknown default:
            print("❓ Unknown auth event: \(event)")
        }
    }
    
    // MARK: - Convenience Properties
    var auth: AuthClient {
        return client.auth
    }
    
    var database: PostgrestClient {
        return client.database
    }
    
    var storage: SupabaseStorageClient {
        return client.storage
    }
    
    var realtime: RealtimeClientV2 {
        return client.realtimeV2
    }
    
    // MARK: - Connection Testing
    func testConnection() async throws {
        // Simple test to verify connection
        let result = try await database
            .from("test")
            .select("1")
            .limit(1)
            .execute()
        
        print("✅ Supabase connection test successful")
    }
    
    // MARK: - Error Handling
    func handleSupabaseError(_ error: Error) {
        if let supabaseError = error as? PostgrestError {
            print("🔴 Supabase Database Error: \(supabaseError.localizedDescription)")
        } else if let authError = error as? GoTrueError {
            print("🔴 Supabase Auth Error: \(authError.localizedDescription)")
        } else {
            print("🔴 Supabase Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types
enum SupabaseManagerError: LocalizedError {
    case configurationMissing
    case invalidURL
    case connectionFailed
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "Supabase configuration is missing or invalid"
        case .invalidURL:
            return "Invalid Supabase URL provided"
        case .connectionFailed:
            return "Failed to connect to Supabase"
        case .authenticationRequired:
            return "User authentication is required for this operation"
        }
    }
}