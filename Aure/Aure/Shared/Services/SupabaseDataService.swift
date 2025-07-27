import Foundation
import Supabase

// Codable models for Supabase communication

struct ProfileUpdateData: Codable {
    let name: String?
    let phone: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case name, phone
        case updatedAt = "updated_at"
    }
}

struct AgencyInsertData: Codable {
    let userId: String
    let name: String
    let contactPerson: String
    let email: String
    let phone: String?
    let address: String?
    let website: String?
    let industry: String?
    let notes: String?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case contactPerson = "contact_person"
        case email, phone, address, website, industry, notes
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct JobInsertData: Codable {
    let userId: String
    let agencyId: String?
    let title: String
    let description: String
    let location: String?
    let hourlyRate: Double?
    let fixedPrice: Double?
    let estimatedHours: Int?
    let startDate: String?
    let endDate: String?
    let status: String
    let type: String
    let skills: String
    let notes: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case agencyId = "agency_id"
        case title, description, location
        case hourlyRate = "hourly_rate"
        case fixedPrice = "fixed_price"
        case estimatedHours = "estimated_hours"
        case startDate = "start_date"
        case endDate = "end_date"
        case status, type, skills, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct JobStatusUpdateData: Codable {
    let status: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

struct PaymentInsertData: Codable {
    let userId: String
    let jobId: String?
    let amount: Double
    let currency: String
    let description: String?
    let dueDate: String
    let status: String
    let type: String
    let invoiceNumber: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case jobId = "job_id"
        case amount, currency, description
        case dueDate = "due_date"
        case status, type
        case invoiceNumber = "invoice_number"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PaymentStatusUpdateData: Codable {
    let status: String
    let paidDate: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case paidDate = "paid_date"
        case updatedAt = "updated_at"
    }
}
struct SupabaseProfile: Codable {
    let id: String
    let name: String?
    let phone: String?
    let profileImageUrl: String?
    let isOnboarded: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, phone
        case profileImageUrl = "profile_image_url"
        case isOnboarded = "is_onboarded"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


class SupabaseDataService: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    // MARK: - User Profile Methods
    
    func getCurrentUserProfile() async throws -> SupabaseProfile? {
        let response: [SupabaseProfile] = try await supabase.database
            .from("profiles")
            .select()
            .eq("id", value: try await supabase.auth.session.user.id)
            .execute()
            .value
        
        return response.first
    }
    
    func updateUserProfile(name: String?, phone: String?) async throws {
        let userId = try await supabase.auth.session.user.id
        
        let updateData = ProfileUpdateData(
            name: name,
            phone: phone,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.database
            .from("profiles")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Agency Methods
    
    func fetchAgencies() async throws -> [SupabaseAgency] {
        let userId = try await supabase.auth.session.user.id
        
        let response: [SupabaseAgency] = try await supabase.database
            .from("agencies")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createAgency(
        name: String,
        contactPerson: String,
        email: String,
        phone: String? = nil,
        address: String? = nil,
        website: String? = nil,
        industry: String? = nil,
        notes: String? = nil
    ) async throws -> SupabaseAgency {
        let userId = try await supabase.auth.session.user.id
        
        let agencyData = AgencyInsertData(
            userId: userId.uuidString,
            name: name,
            contactPerson: contactPerson,
            email: email,
            phone: phone,
            address: address,
            website: website,
            industry: industry,
            notes: notes,
            isActive: true,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let response: [SupabaseAgency] = try await supabase.database
            .from("agencies")
            .insert(agencyData)
            .select()
            .execute()
            .value
        
        guard let agency = response.first else {
            throw NSError(domain: "SupabaseDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create agency"])
        }
        
        return agency
    }
    
    // MARK: - Job Methods
    
    func fetchJobs() async throws -> [SupabaseJob] {
        let userId = try await supabase.auth.session.user.id
        
        let response: [SupabaseJob] = try await supabase.database
            .from("jobs")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createJob(
        title: String,
        description: String,
        agencyId: String? = nil,
        location: String? = nil,
        hourlyRate: Double? = nil,
        fixedPrice: Double? = nil,
        estimatedHours: Int? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: String = "active",
        type: String = "contract",
        skills: [String] = [],
        notes: String? = nil
    ) async throws -> SupabaseJob {
        let userId = try await supabase.auth.session.user.id
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let jobData = JobInsertData(
            userId: userId.uuidString,
            agencyId: agencyId,
            title: title,
            description: description,
            location: location,
            hourlyRate: hourlyRate,
            fixedPrice: fixedPrice,
            estimatedHours: estimatedHours,
            startDate: startDate.map { dateFormatter.string(from: $0) },
            endDate: endDate.map { dateFormatter.string(from: $0) },
            status: status,
            type: type,
            skills: skills.joined(separator: ", "),
            notes: notes,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let response: [SupabaseJob] = try await supabase.database
            .from("jobs")
            .insert(jobData)
            .select()
            .execute()
            .value
        
        guard let job = response.first else {
            throw NSError(domain: "SupabaseDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create job"])
        }
        
        return job
    }
    
    func updateJobStatus(jobId: String, status: String) async throws {
        let updateData = JobStatusUpdateData(
            status: status,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.database
            .from("jobs")
            .update(updateData)
            .eq("id", value: jobId)
            .execute()
    }
    
    // MARK: - Payment Methods
    
    func fetchPayments() async throws -> [SupabasePayment] {
        let userId = try await supabase.auth.session.user.id
        
        let response: [SupabasePayment] = try await supabase.database
            .from("payments")
            .select()
            .eq("user_id", value: userId)
            .order("due_date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createPayment(
        jobId: String?,
        amount: Double,
        currency: String = "USD",
        description: String?,
        dueDate: Date,
        status: String = "pending",
        type: String = "milestone",
        invoiceNumber: String? = nil,
        notes: String? = nil
    ) async throws -> SupabasePayment {
        let userId = try await supabase.auth.session.user.id
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let paymentData = PaymentInsertData(
            userId: userId.uuidString,
            jobId: jobId,
            amount: amount,
            currency: currency,
            description: description,
            dueDate: dateFormatter.string(from: dueDate),
            status: status,
            type: type,
            invoiceNumber: invoiceNumber,
            notes: notes,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let response: [SupabasePayment] = try await supabase.database
            .from("payments")
            .insert(paymentData)
            .select()
            .execute()
            .value
        
        guard let payment = response.first else {
            throw NSError(domain: "SupabaseDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create payment"])
        }
        
        return payment
    }
    
    func updatePaymentStatus(paymentId: String, status: String, paidDate: Date? = nil) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let updateData = PaymentStatusUpdateData(
            status: status,
            paidDate: paidDate.map { dateFormatter.string(from: $0) },
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.database
            .from("payments")
            .update(updateData)
            .eq("id", value: paymentId)
            .execute()
    }
}