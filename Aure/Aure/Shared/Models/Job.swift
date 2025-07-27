//
//  Job.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import Foundation
import SwiftData

enum JobStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    case onHold = "on_hold"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .onHold: return "On Hold"
        }
    }
}

enum JobType: String, CaseIterable, Codable {
    case fullTime = "full_time"
    case partTime = "part_time"
    case contract = "contract"
    case freelance = "freelance"
    case temporary = "temporary"
    
    var displayName: String {
        switch self {
        case .fullTime: return "Full Time"
        case .partTime: return "Part Time"
        case .contract: return "Contract"
        case .freelance: return "Freelance"
        case .temporary: return "Temporary"
        }
    }
}

// MARK: - SwiftData Job Model (Local Storage)
@Model
final class Job {
    var id: UUID
    var title: String
    var jobDescription: String
    var location: String?
    var hourlyRate: Double?
    var fixedPrice: Double?
    var estimatedHours: Int?
    var startDate: Date?
    var endDate: Date?
    var status: JobStatus
    var type: JobType
    var skillsString: String // Store as comma-separated string
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var agency: Agency?
    
    @Relationship(deleteRule: .cascade, inverse: \Payment.job)
    var payments: [Payment] = []
    
    // Computed property to work with skills as an array
    var skills: [String] {
        get {
            if skillsString.isEmpty {
                return []
            }
            return skillsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            skillsString = newValue.joined(separator: ", ")
        }
    }
    
    init(title: String, description: String, location: String? = nil, hourlyRate: Double? = nil, fixedPrice: Double? = nil, estimatedHours: Int? = nil, startDate: Date? = nil, endDate: Date? = nil, status: JobStatus = .active, type: JobType = .contract, skills: [String] = [], notes: String? = nil) {
        self.id = UUID()
        self.title = title
        self.jobDescription = description
        self.location = location
        self.hourlyRate = hourlyRate
        self.fixedPrice = fixedPrice
        self.estimatedHours = estimatedHours
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.type = type
        self.skillsString = skills.joined(separator: ", ")
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var totalEarnings: Double {
        payments.reduce(0) { $0 + $1.amount }
    }
    
    var isActive: Bool {
        status == .active
    }
}

// MARK: - Supabase Job Model (Remote Storage)
struct SupabaseJob: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let agencyId: UUID?
    var title: String
    var jobDescription: String
    var location: String?
    var hourlyRate: Double?
    var fixedPrice: Double?
    var estimatedHours: Int?
    var startDate: Date?
    var endDate: Date?
    var status: String
    var type: String
    var skillsString: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case agencyId = "agency_id"
        case title
        case jobDescription = "job_description"
        case location
        case hourlyRate = "hourly_rate"
        case fixedPrice = "fixed_price"
        case estimatedHours = "estimated_hours"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case type
        case skillsString = "skills_string"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        agencyId = try container.decodeIfPresent(UUID.self, forKey: .agencyId)
        title = try container.decode(String.self, forKey: .title)
        jobDescription = try container.decode(String.self, forKey: .jobDescription)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
        fixedPrice = try container.decodeIfPresent(Double.self, forKey: .fixedPrice)
        estimatedHours = try container.decodeIfPresent(Int.self, forKey: .estimatedHours)
        status = try container.decode(String.self, forKey: .status)
        type = try container.decode(String.self, forKey: .type)
        skillsString = try container.decodeIfPresent(String.self, forKey: .skillsString)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Custom date decoding with multiple format support
        let dateFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        
        // Decode startDate
        if let startDateString = try container.decodeIfPresent(String.self, forKey: .startDate) {
            if let date = dateFormatter.date(from: startDateString) {
                startDate = date
            } else if let date = fallbackFormatter.date(from: startDateString) {
                startDate = date
            } else {
                startDate = nil
            }
        } else {
            startDate = nil
        }
        
        // Decode endDate
        if let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate) {
            if let date = dateFormatter.date(from: endDateString) {
                endDate = date
            } else if let date = fallbackFormatter.date(from: endDateString) {
                endDate = date
            } else {
                endDate = nil
            }
        } else {
            endDate = nil
        }
        
        // Decode timestamps
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        } else {
            updatedAt = Date()
        }
    }
    
    init(id: UUID = UUID(), userId: UUID, agencyId: UUID? = nil, title: String, jobDescription: String, location: String? = nil, hourlyRate: Double? = nil, fixedPrice: Double? = nil, estimatedHours: Int? = nil, startDate: Date? = nil, endDate: Date? = nil, status: JobStatus = .pending, type: JobType = .contract, skillsString: String? = nil, notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.agencyId = agencyId
        self.title = title
        self.jobDescription = jobDescription
        self.location = location
        self.hourlyRate = hourlyRate
        self.fixedPrice = fixedPrice
        self.estimatedHours = estimatedHours
        self.startDate = startDate
        self.endDate = endDate
        self.status = status.rawValue
        self.type = type.rawValue
        self.skillsString = skillsString
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Helper properties for enum conversion
    var jobStatus: JobStatus {
        JobStatus(rawValue: status) ?? .pending
    }
    
    var jobType: JobType {
        JobType(rawValue: type) ?? .contract
    }
    
    var skills: [String] {
        guard let skillsString = skillsString, !skillsString.isEmpty else { return [] }
        return skillsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // Convert to SwiftData Job
    func toLocalJob() -> Job {
        return Job(
            title: title,
            description: jobDescription,
            location: location,
            hourlyRate: hourlyRate,
            fixedPrice: fixedPrice,
            estimatedHours: estimatedHours,
            startDate: startDate,
            endDate: endDate,
            status: jobStatus,
            type: jobType,
            skills: skills,
            notes: notes
        )
    }
}

// MARK: - Job DTOs for API
struct CreateJobRequest: Codable {
    let userId: UUID
    let agencyId: UUID?
    let title: String
    let jobDescription: String
    let location: String?
    let hourlyRate: Double?
    let fixedPrice: Double?
    let estimatedHours: Int?
    let startDate: Date?
    let endDate: Date?
    let status: String
    let type: String
    let skillsString: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case agencyId = "agency_id"
        case title
        case jobDescription = "job_description"
        case location
        case hourlyRate = "hourly_rate"
        case fixedPrice = "fixed_price"
        case estimatedHours = "estimated_hours"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case type
        case skillsString = "skills_string"
        case notes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(agencyId, forKey: .agencyId)
        try container.encode(title, forKey: .title)
        try container.encode(jobDescription, forKey: .jobDescription)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(hourlyRate, forKey: .hourlyRate)
        try container.encodeIfPresent(fixedPrice, forKey: .fixedPrice)
        try container.encodeIfPresent(estimatedHours, forKey: .estimatedHours)
        try container.encode(status, forKey: .status)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(skillsString, forKey: .skillsString)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        // Custom date encoding to ensure ISO 8601 format
        let dateFormatter = ISO8601DateFormatter()
        if let startDate = startDate {
            try container.encode(dateFormatter.string(from: startDate), forKey: .startDate)
        }
        if let endDate = endDate {
            try container.encode(dateFormatter.string(from: endDate), forKey: .endDate)
        }
    }
}

struct UpdateJobRequest: Codable {
    let title: String?
    let jobDescription: String?
    let location: String?
    let hourlyRate: Double?
    let fixedPrice: Double?
    let estimatedHours: Int?
    let startDate: Date?
    let endDate: Date?
    let status: String?
    let type: String?
    let skillsString: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case jobDescription = "job_description"
        case location
        case hourlyRate = "hourly_rate"
        case fixedPrice = "fixed_price"
        case estimatedHours = "estimated_hours"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case type
        case skillsString = "skills_string"
        case notes
    }
}