import Foundation
import SwiftUI

/// Simple view to test Supabase connection
struct SupabaseConnectionTestView: View {
    @State private var connectionStatus = "Testing..."
    @State private var isLoading = true
    @State private var credentialInfo = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Supabase Connection Test")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Credential Status:")
                    .font(.headline)
                
                Text(credentialInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 10) {
                if isLoading {
                    ProgressView("Testing connection...")
                } else {
                    Image(systemName: connectionStatus.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(connectionStatus.contains("Success") ? .green : .red)
                    
                    Text(connectionStatus)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            
            Button("Test Connection") {
                testConnection()
            }
            .disabled(isLoading)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadCredentialInfo()
            testConnection()
        }
    }
    
    private func loadCredentialInfo() {
        let manager = SecureCredentialManager.shared
        credentialInfo = """
        URL: \(manager.supabaseURL)
        Key: \(String(manager.supabaseAnonKey.prefix(20)))...
        Configured: \(manager.isConfigured ? "✅" : "❌")
        """
    }
    
    private func testConnection() {
        isLoading = true
        connectionStatus = "Testing..."
        
        Task {
            do {
                // Test basic connection
                let supabase = SupabaseManager.shared
                
                // Try to connect and get a simple response
                let result = try await supabase.database
                    .from("nonexistent_table")
                    .select("*")
                    .limit(1)
                    .execute()
                
                await MainActor.run {
                    // Even if table doesn't exist, getting a proper error means connection works
                    connectionStatus = "✅ Success! Supabase connection is working.\nReady to create database tables."
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("relation") || 
                       error.localizedDescription.contains("does not exist") {
                        // This is expected - table doesn't exist yet, but connection works!
                        connectionStatus = "✅ Success! Supabase connection is working.\nReady to create database tables."
                    } else {
                        connectionStatus = "❌ Connection failed:\n\(error.localizedDescription)"
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Helper function for debugging
extension SupabaseManager {
    func debugConnection() {
        print("🔍 Supabase Debug Info:")
        print("📍 URL: \(SecureCredentialManager.shared.supabaseURL)")
        print("🔑 Key: \(String(SecureCredentialManager.shared.supabaseAnonKey.prefix(20)))...")
        print("✅ Configured: \(SecureCredentialManager.shared.isConfigured)")
        
        SecureCredentialManager.shared.printCredentialStatus()
    }
}

#Preview {
    SupabaseConnectionTestView()
}