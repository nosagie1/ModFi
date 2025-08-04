//
//  DatabaseService.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import Foundation
import SwiftData

class DatabaseService {
    static let shared = DatabaseService()
    
    private init() {}
    
    func resetDatabase(modelContext: ModelContext) {
        do {
            // Delete all existing data
            let jobDescriptor = FetchDescriptor<Job>()
            let jobs = try modelContext.fetch(jobDescriptor)
            for job in jobs {
                modelContext.delete(job)
            }
            
            let agencyDescriptor = FetchDescriptor<Agency>()
            let agencies = try modelContext.fetch(agencyDescriptor)
            for agency in agencies {
                modelContext.delete(agency)
            }
            
            let paymentDescriptor = FetchDescriptor<Payment>()
            let payments = try modelContext.fetch(paymentDescriptor)
            for payment in payments {
                modelContext.delete(payment)
            }
            
            let userDescriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(userDescriptor)
            for user in users {
                modelContext.delete(user)
            }
            
            try modelContext.save()
            print("Database reset successfully")
        } catch {
            print("Failed to reset database: \(error)")
        }
    }
}