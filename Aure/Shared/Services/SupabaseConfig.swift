import Foundation

struct SupabaseConfig {
    // MARK: - Configuration
    static var supabaseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            fatalError("SUPABASE_URL not found in Info.plist")
        }
        return url
    }
    
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist")
        }
        return key
    }
    
    // MARK: - Validation
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_") && !supabaseAnonKey.contains("YOUR_")
    }
    
    static func validateConfiguration() {
        guard isConfigured else {
            fatalError("""
            ⚠️ Supabase Configuration Required ⚠️
            
            Please update your Info.plist with your Supabase credentials:
            
            1. Go to your Supabase project dashboard
            2. Navigate to Settings > API
            3. Copy your Project URL and Anon Key
            4. Add them to Info.plist as SUPABASE_URL and SUPABASE_ANON_KEY
            
            Current values:
            - URL: \(supabaseURL)
            - Key: \(supabaseAnonKey.prefix(20))...
            """)
        }
    }
}

