import Foundation

struct SupabaseConfig {
    // MARK: - Configuration
    // Supabase credentials for Aure Finance App
    static let supabaseURL = "https://lstmuffaaydjofypfiir.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzdG11ZmZhYXlkam9meXBmaWlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMDk1MDcsImV4cCI6MjA2Nzc4NTUwN30.WbsuqpFWHdL6Isula83vCjgz8NMeGFUV76hwUuzHZZ0"
    
    // MARK: - Validation
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_") && !supabaseAnonKey.contains("YOUR_")
    }
    
    static func validateConfiguration() {
        guard isConfigured else {
            fatalError("""
            ⚠️ Supabase Configuration Required ⚠️
            
            Please update SupabaseConfig.swift with your Supabase credentials:
            
            1. Go to your Supabase project dashboard
            2. Navigate to Settings > API
            3. Copy your Project URL and Anon Key
            4. Replace the placeholder values in SupabaseConfig.swift
            
            Current values:
            - URL: \(supabaseURL)
            - Key: \(supabaseAnonKey.prefix(20))...
            """)
        }
    }
}

// MARK: - Alternative: Environment-based Configuration
extension SupabaseConfig {
    // If you prefer using Info.plist or environment variables
    static var urlFromPlist: String? {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
    }
    
    static var keyFromPlist: String? {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
    }
    
    // Use this if you set up Info.plist configuration
    static var urlSafe: String {
        return urlFromPlist ?? supabaseURL
    }
    
    static var keySafe: String {
        return keyFromPlist ?? supabaseAnonKey
    }
}