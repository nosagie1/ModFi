//
//  Statement.swift
//  Aure
//
//  Statement models for uploaded documents
//

import Foundation
import SwiftData

// MARK: - SwiftData Statement Model (Local Storage)
@Model
final class Statement {
    var id: UUID
    var fileName: String
    var filePath: String
    var fileSize: Int?
    var fileType: String?
    var statementDate: Date?
    var amount: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var agency: Agency?
    
    @Relationship
    var job: Job?
    
    init(fileName: String, filePath: String, fileSize: Int? = nil, fileType: String? = nil, statementDate: Date? = nil, amount: Double? = nil, notes: String? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.fileType = fileType
        self.statementDate = statementDate
        self.amount = amount
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supabase Statement Model (Remote Storage)
struct SupabaseStatement: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let agencyId: UUID?
    let jobId: UUID?
    var fileName: String
    var filePath: String
    var fileSize: Int?
    var fileType: String?
    var statementDate: Date?
    var amount: Double?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case agencyId = "agency_id"
        case jobId = "job_id"
        case fileName = "file_name"
        case filePath = "file_path"
        case fileSize = "file_size"
        case fileType = "file_type"
        case statementDate = "statement_date"
        case amount
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, agencyId: UUID? = nil, jobId: UUID? = nil, fileName: String, filePath: String, fileSize: Int? = nil, fileType: String? = nil, statementDate: Date? = nil, amount: Double? = nil, notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.agencyId = agencyId
        self.jobId = jobId
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.fileType = fileType
        self.statementDate = statementDate
        self.amount = amount
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to SwiftData Statement
    func toLocalStatement() -> Statement {
        return Statement(
            fileName: fileName,
            filePath: filePath,
            fileSize: fileSize,
            fileType: fileType,
            statementDate: statementDate,
            amount: amount,
            notes: notes
        )
    }
}

// MARK: - Statement DTOs for API
struct CreateStatementRequest: Codable {
    let userId: UUID
    let agencyId: UUID?
    let jobId: UUID?
    let fileName: String
    let filePath: String
    let fileSize: Int?
    let fileType: String?
    let statementDate: Date?
    let amount: Double?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case agencyId = "agency_id"
        case jobId = "job_id"
        case fileName = "file_name"
        case filePath = "file_path"
        case fileSize = "file_size"
        case fileType = "file_type"
        case statementDate = "statement_date"
        case amount
        case notes
    }
}

struct UpdateStatementRequest: Codable {
    let fileName: String?
    let statementDate: Date?
    let amount: Double?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case statementDate = "statement_date"
        case amount
        case notes
    }
}