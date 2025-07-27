//
//  Agency.swift
//  Aure
//
//  Agency models for both SwiftData (local) and Supabase (remote)
//

import Foundation
import SwiftData

// MARK: - SwiftData Agency Model (Local Storage)
@Model
final class Agency {
    var id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var phone: String?
    var address: String?
    var website: String?
    var industry: String?
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Job.agency)
    var jobs: [Job] = []
    
    init(name: String, contactPerson: String, email: String, phone: String? = nil, address: String? = nil, website: String? = nil, industry: String? = nil, notes: String? = nil, isActive: Bool = true) {
        self.id = UUID()
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.website = website
        self.industry = industry
        self.notes = notes
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supabase Agency Model (Remote Storage)
struct SupabaseAgency: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var contactPerson: String
    var email: String
    var phone: String?
    var address: String?
    var website: String?
    var industry: String?
    var notes: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case contactPerson = "contact_person"
        case email
        case phone
        case address
        case website
        case industry
        case notes
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, name: String, contactPerson: String, email: String, phone: String? = nil, address: String? = nil, website: String? = nil, industry: String? = nil, notes: String? = nil, isActive: Bool = true) {
        self.id = id
        self.userId = userId
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.website = website
        self.industry = industry
        self.notes = notes
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to SwiftData Agency
    func toLocalAgency() -> Agency {
        return Agency(
            name: name,
            contactPerson: contactPerson,
            email: email,
            phone: phone,
            address: address,
            website: website,
            industry: industry,
            notes: notes,
            isActive: isActive
        )
    }
}

// MARK: - Agency DTOs for API
struct CreateAgencyRequest: Codable {
    let userId: UUID
    let name: String
    let contactPerson: String
    let email: String
    let phone: String?
    let address: String?
    let website: String?
    let industry: String?
    let notes: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case contactPerson = "contact_person"
        case email
        case phone
        case address
        case website
        case industry
        case notes
        case isActive = "is_active"
    }
}

struct UpdateAgencyRequest: Codable {
    let name: String?
    let contactPerson: String?
    let email: String?
    let phone: String?
    let address: String?
    let website: String?
    let industry: String?
    let notes: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case contactPerson = "contact_person"
        case email
        case phone
        case address
        case website
        case industry
        case notes
        case isActive = "is_active"
    }
}