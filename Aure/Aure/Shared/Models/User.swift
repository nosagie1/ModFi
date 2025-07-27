//
//  User.swift
//  Aure
//
//  User models for both SwiftData (local) and Supabase (remote)
//

import Foundation
import SwiftData

// MARK: - SwiftData User Model (Local Storage)
@Model
final class User {
    var id: UUID
    var name: String
    var email: String
    var phone: String?
    var currency: String
    var faceIdEnabled: Bool
    var notificationsEnabled: Bool
    var profileImageURL: String?
    var isOnboarded: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String? = nil, name: String, email: String, phone: String? = nil, currency: String = "USD", faceIdEnabled: Bool = false, notificationsEnabled: Bool = true, profileImageURL: String? = nil, isOnboarded: Bool = false) {
        self.id = id != nil ? UUID(uuidString: id!)! : UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.currency = currency
        self.faceIdEnabled = faceIdEnabled
        self.notificationsEnabled = notificationsEnabled
        self.profileImageURL = profileImageURL
        self.isOnboarded = isOnboarded
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supabase User Model (Remote Storage)
struct SupabaseUser: Codable, Identifiable {
    let id: UUID
    var name: String?
    var email: String?
    var phone: String?
    var currency: String
    var faceIdEnabled: Bool
    var notificationsEnabled: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case currency
        case faceIdEnabled = "face_id_enabled"
        case notificationsEnabled = "notifications_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), name: String? = nil, email: String? = nil, phone: String? = nil, currency: String = "USD", faceIdEnabled: Bool = false, notificationsEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.currency = currency
        self.faceIdEnabled = faceIdEnabled
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to SwiftData User
    func toLocalUser() -> User {
        return User(
            id: id.uuidString,
            name: name ?? "",
            email: email ?? "",
            phone: phone,
            currency: currency,
            faceIdEnabled: faceIdEnabled,
            notificationsEnabled: notificationsEnabled,
            isOnboarded: true
        )
    }
}

// MARK: - User DTOs for API
struct CreateUserRequest: Codable {
    let id: UUID
    let name: String?
    let email: String?
    let phone: String?
    let currency: String
    let faceIdEnabled: Bool
    let notificationsEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case currency
        case faceIdEnabled = "face_id_enabled"
        case notificationsEnabled = "notifications_enabled"
    }
}

struct UpdateUserRequest: Codable {
    let name: String?
    let phone: String?
    let currency: String?
    let faceIdEnabled: Bool?
    let notificationsEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case phone
        case currency
        case faceIdEnabled = "face_id_enabled"
        case notificationsEnabled = "notifications_enabled"
    }
}