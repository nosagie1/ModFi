//
//  Payment.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import Foundation
import SwiftData
import SwiftUI

public enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case invoiced = "invoiced"
    case partiallyPaid = "partiallyPaid"
    case received = "received"
    case overdue = "overdue"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .invoiced: return "Invoiced"
        case .partiallyPaid: return "Partially Paid"
        case .received: return "Received"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var color: Color {
        switch self {
        case .pending: return .orange
        case .invoiced: return .blue
        case .partiallyPaid: return .yellow
        case .received: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .invoiced: return "doc.text.fill"
        case .partiallyPaid: return "dollarsign.circle.fill"
        case .received: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

enum PaymentType: String, CaseIterable, Codable {
    case milestone = "milestone"
    case hourly = "hourly"
    case fixed = "fixed"
    case bonus = "bonus"
    
    var displayName: String {
        switch self {
        case .milestone: return "Milestone"
        case .hourly: return "Hourly"
        case .fixed: return "Fixed"
        case .bonus: return "Bonus"
        }
    }
}

// MARK: - SwiftData Payment Model (Local Storage)
@Model
final class Payment {
    var id: UUID
    var amount: Double
    var currency: String
    var paymentDescription: String?
    var dueDate: Date
    var paidDate: Date?
    var status: PaymentStatus
    var type: PaymentType
    var invoiceNumber: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var job: Job?
    
    init(amount: Double, currency: String = "USD", description: String? = nil, dueDate: Date, paidDate: Date? = nil, status: PaymentStatus = .pending, type: PaymentType = .milestone, invoiceNumber: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.paymentDescription = description
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.status = status
        self.type = type
        self.invoiceNumber = invoiceNumber
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        (status == .pending || status == .invoiced) && dueDate < Date()
    }
    
    var isUpcoming: Bool {
        (status == .pending || status == .invoiced) && dueDate >= Date()
    }
}

// MARK: - Supabase Payment Model (Remote Storage)
struct SupabasePayment: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let jobId: UUID
    var amount: Double
    var currency: String
    var paymentDescription: String?
    var dueDate: Date
    var paidDate: Date?
    var status: String
    var type: String
    var invoiceNumber: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case jobId = "job_id"
        case amount
        case currency
        case paymentDescription = "payment_description"
        case dueDate = "due_date"
        case paidDate = "paid_date"
        case status
        case type
        case invoiceNumber = "invoice_number"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        jobId = try container.decode(UUID.self, forKey: .jobId)
        amount = try container.decode(Double.self, forKey: .amount)
        currency = try container.decode(String.self, forKey: .currency)
        paymentDescription = try container.decodeIfPresent(String.self, forKey: .paymentDescription)
        status = try container.decode(String.self, forKey: .status)
        type = try container.decode(String.self, forKey: .type)
        invoiceNumber = try container.decodeIfPresent(String.self, forKey: .invoiceNumber)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Custom date decoding with multiple format support
        let dateFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        
        // Decode dueDate
        if let dueDateString = try container.decodeIfPresent(String.self, forKey: .dueDate) {
            if let date = dateFormatter.date(from: dueDateString) {
                dueDate = date
            } else if let date = fallbackFormatter.date(from: dueDateString) {
                dueDate = date
            } else {
                dueDate = Date()
            }
        } else {
            dueDate = Date()
        }
        
        // Decode paidDate
        if let paidDateString = try container.decodeIfPresent(String.self, forKey: .paidDate) {
            if let date = dateFormatter.date(from: paidDateString) {
                paidDate = date
            } else if let date = fallbackFormatter.date(from: paidDateString) {
                paidDate = date
            } else {
                paidDate = nil
            }
        } else {
            paidDate = nil
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
    
    init(id: UUID = UUID(), userId: UUID, jobId: UUID, amount: Double, currency: String = "USD", paymentDescription: String? = nil, dueDate: Date, paidDate: Date? = nil, status: PaymentStatus = .pending, type: PaymentType = .milestone, invoiceNumber: String? = nil, notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.jobId = jobId
        self.amount = amount
        self.currency = currency
        self.paymentDescription = paymentDescription
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.status = status.rawValue
        self.type = type.rawValue
        self.invoiceNumber = invoiceNumber
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Helper properties for enum conversion
    var paymentStatus: PaymentStatus {
        PaymentStatus(rawValue: status) ?? .pending
    }
    
    var paymentType: PaymentType {
        PaymentType(rawValue: type) ?? .milestone
    }
    
    var isOverdue: Bool {
        (paymentStatus == .pending || paymentStatus == .invoiced) && dueDate < Date()
    }
    
    var isUpcoming: Bool {
        (paymentStatus == .pending || paymentStatus == .invoiced) && dueDate >= Date()
    }
    
    // Convert to SwiftData Payment
    func toLocalPayment() -> Payment {
        return Payment(
            amount: amount,
            currency: currency,
            description: paymentDescription,
            dueDate: dueDate,
            paidDate: paidDate,
            status: paymentStatus,
            type: paymentType,
            invoiceNumber: invoiceNumber,
            notes: notes
        )
    }
}

// MARK: - Payment DTOs for API
struct CreatePaymentRequest: Codable {
    let userId: UUID
    let jobId: UUID
    let amount: Double
    let currency: String
    let paymentDescription: String?
    let dueDate: Date
    let paidDate: Date?
    let status: String
    let type: String
    let invoiceNumber: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case jobId = "job_id"
        case amount
        case currency
        case paymentDescription = "payment_description"
        case dueDate = "due_date"
        case paidDate = "paid_date"
        case status
        case type
        case invoiceNumber = "invoice_number"
        case notes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        try container.encode(jobId, forKey: .jobId)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
        try container.encodeIfPresent(paymentDescription, forKey: .paymentDescription)
        try container.encode(status, forKey: .status)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(invoiceNumber, forKey: .invoiceNumber)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        // Custom date encoding to ensure ISO 8601 format
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: dueDate), forKey: .dueDate)
        
        if let paidDate = paidDate {
            try container.encode(dateFormatter.string(from: paidDate), forKey: .paidDate)
        }
    }
}

struct UpdatePaymentRequest: Codable {
    let amount: Double?
    let currency: String?
    let paymentDescription: String?
    let dueDate: Date?
    let paidDate: Date?
    let status: String?
    let type: String?
    let invoiceNumber: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case paymentDescription = "payment_description"
        case dueDate = "due_date"
        case paidDate = "paid_date"
        case status
        case type
        case invoiceNumber = "invoice_number"
        case notes
    }
}