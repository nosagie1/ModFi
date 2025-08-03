//
//  JobDetailView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI
import SwiftData

struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    let job: Job
    @State private var showingEditJob = false
    @State private var showingDeleteAlert = false
    @Namespace private var detailNamespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    
                    detailsSection
                    
                    if let agency = job.agency {
                        agencySection(agency: agency)
                    }
                    
                    pricingSection
                    
                    timelineSection
                    
                    if !job.skills.isEmpty {
                        skillsSection
                    }
                    
                    if !job.payments.isEmpty {
                        paymentsSection
                    }
                    
                    if let notes = job.notes {
                        notesSection(notes: notes)
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Job Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit") {
                            showingEditJob = true
                        }
                        
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingEditJob) {
                EditJobView(job: job)
            }
            .alert("Delete Job", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteJob()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this job? This action cannot be undone.")
            }
        }
        .darkTranslucentNavigationBar()
    }
    
    private var headerSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appPrimaryText)
                            .matchedGeometryEffect(id: "jobTitle-\(job.id)", in: detailNamespace)
                        
                        Text(job.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: job.status)
                }
                
                Text(job.jobDescription)
                    .font(.body)
                    .foregroundColor(Color.appPrimaryText)
                    .lineLimit(nil)
                
                if let location = job.location {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(Color.appSecondaryText)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
            }
        }
    }
    
    private func agencySection(agency: Agency) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Agency")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(agency.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text(agency.contactPerson)
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Handle contact agency
                    }) {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var detailsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Details")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                VStack(spacing: 8) {
                    DetailRow(label: "Job Type", value: job.type.displayName)
                    DetailRow(label: "Status", value: job.status.displayName)
                    DetailRow(label: "Created", value: job.createdAt.formatted(date: .abbreviated, time: .omitted))
                    
                    if let estimatedHours = job.estimatedHours {
                        DetailRow(label: "Estimated Hours", value: "\(estimatedHours) hours")
                    }
                }
            }
        }
    }
    
    private var pricingSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pricing")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                if let hourlyRate = job.hourlyRate {
                    HStack {
                        Text("Hourly Rate")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", hourlyRate))/hr")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                    }
                    
                    if let estimatedHours = job.estimatedHours {
                        HStack {
                            Text("Estimated Total")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", hourlyRate * Double(estimatedHours)))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.appPrimaryText)
                        }
                    }
                } else if let fixedPrice = job.fixedPrice {
                    HStack {
                        Text("Fixed Price")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", fixedPrice))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.appPrimaryText)
                    }
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Earned")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        CountUpCurrency(value: .constant(job.totalEarnings), duration: 1.0, animationDelay: 0.5)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .matchedGeometryEffect(id: "jobAmount-\(job.id)", in: detailNamespace)
                    }
                    
                    // Net Earnings calculation with flash animation
                    HStack {
                        Text("Net Earnings (After 35% deductions)")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        let netEarnings = job.totalEarnings * 0.65
                        Text("$\(String(format: "%.2f", netEarnings))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .scaleEffect(1.15)
                            .animation(.easeInOut(duration: 0.3).delay(1.5).repeatCount(1, autoreverses: true), value: job.totalEarnings)
                    }
                }
            }
            .animation(.snappy, value: job.totalEarnings)
        }
        .slideTransition(direction: .up, duration: 0.4, delay: 0.3)
    }
    
    private var timelineSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Timeline")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                VStack(spacing: 8) {
                    if let startDate = job.startDate {
                        DetailRow(label: "Start Date", value: startDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    if let endDate = job.endDate {
                        DetailRow(label: "End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
        }
    }
    
    private var skillsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Skills")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(job.skills, id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var paymentsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Payments")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Button("View All") {
                        // Handle view all payments
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                ForEach(job.payments.prefix(3)) { payment in
                    PaymentRow(payment: payment)
                }
            }
        }
    }
    
    private func notesSection(notes: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                Text(notes)
                    .font(.body)
                    .foregroundColor(Color.appPrimaryText)
                    .lineLimit(nil)
            }
        }
    }
    
    private func deleteJob() {
        modelContext.delete(job)
        do {
            try modelContext.save()
            appState.showToast(message: "Job deleted successfully", type: .success)
            dismiss()
        } catch {
            appState.showToast(message: "Failed to delete job", type: .error)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appPrimaryText)
        }
    }
}

struct PaymentRow: View {
    let payment: Payment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(String(format: "%.2f", payment.amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appPrimaryText)
                
                Text(payment.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
            
            PaymentStatusBadge(status: payment.status)
        }
    }
}

struct PaymentStatusBadge: View {
    let status: PaymentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange
        case .received:
            return .green
        case .invoiced:
            return .blue
        case .partiallyPaid:
            return .yellow
        case .overdue:
            return .red
        case .cancelled:
            return .gray
        }
    }
}