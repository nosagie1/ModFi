//
//  JobCreationModels.swift
//  Aure
//
//  Shared models for job creation flow
//

import Foundation
import SwiftUI

// MARK: - Job Data Model
public class SimpleJobData: ObservableObject {
    @Published public var clientName = ""
    @Published public var jobTitle = ""
    @Published public var amount: Double = 0
    @Published public var commissionPercentage: Int = 20
    @Published public var bookedBy = ""
    @Published public var jobDate = Date()
    @Published public var paymentTerms: PaymentTerms = .net30
    @Published public var paymentDueDate = Date()
    @Published public var paymentStatus: PaymentStatus = .pending
    @Published public var notes = ""
    @Published public var uploadedFiles: [URL] = []
    @Published public var uploadedFileNames: [String] = []
    
    public init() {
        updateDueDate()
    }
    
    public func updateDueDate() {
        let calendar = Calendar.current
        switch paymentTerms {
        case .net30:
            paymentDueDate = calendar.date(byAdding: .day, value: 30, to: jobDate) ?? jobDate
        case .net60:
            paymentDueDate = calendar.date(byAdding: .day, value: 60, to: jobDate) ?? jobDate
        case .net90:
            paymentDueDate = calendar.date(byAdding: .day, value: 90, to: jobDate) ?? jobDate
        case .immediately:
            paymentDueDate = jobDate
        case .custom:
            // Keep current due date
            break
        }
    }
    
    public var netAmount: Double {
        return amount * (1.0 - Double(commissionPercentage) / 100.0)
    }
    
    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Payment Terms Enum
public enum PaymentTerms: String, CaseIterable {
    case immediately = "Immediately"
    case net30 = "Net 30"
    case net60 = "Net 60" 
    case net90 = "Net 90"
    case custom = "Custom"
    
    public var description: String {
        switch self {
        case .immediately:
            return "Payment due immediately"
        case .net30:
            return "Payment due in 30 days"
        case .net60:
            return "Payment due in 60 days"
        case .net90:
            return "Payment due in 90 days"
        case .custom:
            return "Custom due date"
        }
    }
}