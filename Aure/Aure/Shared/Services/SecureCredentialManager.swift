import Foundation

/// Secure credential manager for handling sensitive configuration data
class SecureCredentialManager {
    
    // MARK: - Singleton
    static let shared = SecureCredentialManager()
    private init() {}
    
    // MARK: - Credential Loading
    private lazy var credentials: [String: String] = {
        loadCredentials()
    }()
    
    /// Load credentials from SupabaseCredentials.plist or fallback to SupabaseConfig
    private func loadCredentials() -> [String: String] {
        var creds: [String: String] = [:]
        
        // Try to load from SupabaseCredentials.plist first
        if let path = Bundle.main.path(forResource: "SupabaseCredentials", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            
            creds["SUPABASE_URL"] = plist["SUPABASE_URL"] as? String
            creds["SUPABASE_ANON_KEY"] = plist["SUPABASE_ANON_KEY"] as? String
            creds["SUPABASE_SERVICE_ROLE_KEY"] = plist["SUPABASE_SERVICE_ROLE_KEY"] as? String
            
            print("✅ Loaded credentials from SupabaseCredentials.plist")
        } else {
            // Fallback to main Info.plist
            let bundle = Bundle.main
            creds["SUPABASE_URL"] = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            creds["SUPABASE_ANON_KEY"] = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
            creds["SUPABASE_SERVICE_ROLE_KEY"] = bundle.object(forInfoDictionaryKey: "SUPABASE_SERVICE_ROLE_KEY") as? String
            
            print("✅ Loaded credentials from Info.plist")
        }
        
        return creds
    }
    
    // MARK: - Public API
    var supabaseURL: String {
        return credentials["SUPABASE_URL"] ?? SupabaseConfig.supabaseURL
    }
    
    var supabaseAnonKey: String {
        return credentials["SUPABASE_ANON_KEY"] ?? SupabaseConfig.supabaseAnonKey
    }
    
    var supabaseServiceRoleKey: String? {
        return credentials["SUPABASE_SERVICE_ROLE_KEY"]
    }
    
    // MARK: - Validation
    var isConfigured: Bool {
        let url = supabaseURL
        let key = supabaseAnonKey
        
        return !url.contains("YOUR_") && 
               !key.contains("YOUR_") &&
               !url.isEmpty && 
               !key.isEmpty &&
               URL(string: url) != nil
    }
    
    func validateCredentials() throws {
        guard isConfigured else {
            throw CredentialError.missingOrInvalid
        }
        
        guard URL(string: supabaseURL) != nil else {
            throw CredentialError.invalidURL
        }
        
        guard supabaseAnonKey.count > 20 else {
            throw CredentialError.invalidKey
        }
    }
    
    // MARK: - Debug Information
    func printCredentialStatus() {
        print("""
        📊 Supabase Credential Status:
        ✅ URL: \(supabaseURL.isEmpty ? "❌ Missing" : "✅ Set")
        ✅ Anon Key: \(supabaseAnonKey.isEmpty ? "❌ Missing" : "✅ Set (\(supabaseAnonKey.prefix(10))...)")
        ✅ Service Key: \(supabaseServiceRoleKey?.isEmpty == false ? "✅ Set" : "⚠️ Optional - Not Set")
        ✅ Valid URL: \(URL(string: supabaseURL) != nil ? "✅ Yes" : "❌ No")
        ✅ Configured: \(isConfigured ? "✅ Yes" : "❌ No")
        """)
    }
}

// MARK: - Error Types
enum CredentialError: LocalizedError {
    case missingOrInvalid
    case invalidURL
    case invalidKey
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .missingOrInvalid:
            return """
            Supabase credentials are missing or invalid.
            Please check SupabaseCredentials.plist or SupabaseConfig.swift
            """
        case .invalidURL:
            return "Supabase URL is not a valid URL format"
        case .invalidKey:
            return "Supabase API key appears to be invalid (too short)"
        case .fileNotFound:
            return "SupabaseCredentials.plist file not found"
        }
    }
}

// MARK: - Development Helper
#if DEBUG
extension SecureCredentialManager {
    func printSetupInstructions() {
        guard !isConfigured else { return }
        
        print("""
        
        🔧 SUPABASE SETUP REQUIRED 🔧
        
        You have several options to configure your Supabase credentials:
        
        OPTION 1: SupabaseCredentials.plist (Recommended)
        1. Open SupabaseCredentials.plist in Xcode
        2. Replace YOUR_SUPABASE_PROJECT_URL with your project URL
        3. Replace YOUR_SUPABASE_ANON_KEY with your anon key
        4. Replace YOUR_SUPABASE_SERVICE_ROLE_KEY with your service role key (optional)
        
        OPTION 2: SupabaseConfig.swift
        1. Open SupabaseConfig.swift
        2. Update the static constants with your credentials
        
        OPTION 3: Info.plist
        1. Add SUPABASE_URL and SUPABASE_ANON_KEY to your Info.plist
        
        Get your credentials from: https://app.supabase.com/project/YOUR_PROJECT/settings/api
        
        """)
    }
}
#endif