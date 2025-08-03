//
//  SupabaseFileService.swift
//  Aure
//
//  Helper service for Supabase file operations
//

import Foundation
import Supabase

struct FileInfo {
    let name: String
    let url: URL
    let size: Int64?
    let uploadDate: Date?
}

@MainActor
class SupabaseFileService: ObservableObject {
    private let supabaseClient = SupabaseManager.shared.client
    private let bucketName = "documents"
    
    // MARK: - Tax Documents
    func listTaxDocuments() async -> [FileInfo] {
        do {
            // Get current user ID
            guard let userId = getCurrentUserId() else {
                print("No authenticated user found")
                return []
            }
            
            let path = "taxDocs/\(userId)/"
            
            // List files in the user's tax documents folder
            let files = try await supabaseClient.storage
                .from(bucketName)
                .list(path: path)
            
            var fileInfos: [FileInfo] = []
            
            for file in files {
                // Get download URL
                if let downloadURL = try await getDownloadURL(path: "\(path)\(file.name)") {
                    let fileInfo = FileInfo(
                        name: file.name,
                        url: downloadURL,
                        size: file.metadata?["size"] as? Int64,
                        uploadDate: file.createdAt
                    )
                    fileInfos.append(fileInfo)
                }
            }
            
            return fileInfos
        } catch {
            print("Error listing tax documents: \(error)")
            return []
        }
    }
    
    func uploadTaxDocument(fileData: Data, fileName: String) async throws -> URL {
        guard let userId = getCurrentUserId() else {
            throw FileServiceError.noAuthenticatedUser
        }
        
        let path = "taxDocs/\(userId)/\(fileName)"
        
        try await supabaseClient.storage
            .from(bucketName)
            .upload(path: path, file: fileData)
        
        guard let downloadURL = try await getDownloadURL(path: path) else {
            throw FileServiceError.failedToGetDownloadURL
        }
        
        return downloadURL
    }
    
    func deleteFile(at url: URL) async {
        do {
            // Extract path from URL
            guard let path = extractPathFromURL(url) else {
                print("Could not extract path from URL: \(url)")
                return
            }
            
            try await supabaseClient.storage
                .from(bucketName)
                .remove(paths: [path])
            
            print("Successfully deleted file at path: \(path)")
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentUserId() -> String? {
        // Get current user from Supabase auth
        return supabaseClient.auth.currentUser?.id.uuidString
    }
    
    private func getDownloadURL(path: String) async throws -> URL? {
        let response = try await supabaseClient.storage
            .from(bucketName)
            .createSignedURL(path: path, expiresIn: 3600) // 1 hour expiry
        
        return response
    }
    
    private func extractPathFromURL(_ url: URL) -> String? {
        // Extract the path from a Supabase storage URL
        // This is a simplified version - you may need to adjust based on your URL structure
        let urlString = url.absoluteString
        
        // Look for the pattern after the bucket name
        if let range = urlString.range(of: "/\(bucketName)/") {
            let pathStart = range.upperBound
            return String(urlString[pathStart...])
        }
        
        return nil
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

// MARK: - Error Types
enum FileServiceError: LocalizedError {
    case noAuthenticatedUser
    case failedToGetDownloadURL
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user found"
        case .failedToGetDownloadURL:
            return "Failed to get download URL"
        case .invalidURL:
            return "Invalid URL provided"
        }
    }
}

// MARK: - Mock Implementation for Preview/Testing
extension SupabaseFileService {
    static func mockTaxDocuments() -> [FileInfo] {
        [
            FileInfo(
                name: "1099-NEC-2023.pdf",
                url: URL(string: "https://example.com/1099-2023.pdf")!,
                size: 245760,
                uploadDate: Date()
            ),
            FileInfo(
                name: "1099-NEC-2022.pdf",
                url: URL(string: "https://example.com/1099-2022.pdf")!,
                size: 198432,
                uploadDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())
            ),
            FileInfo(
                name: "W-9-Form.pdf",
                url: URL(string: "https://example.com/w9.pdf")!,
                size: 156789,
                uploadDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())
            )
        ]
    }
}