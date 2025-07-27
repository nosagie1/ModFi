import SwiftUI
import SwiftData

struct JobDetailModalView: View {
    @Environment(\.dismiss) private var dismiss
    let job: Job
    @State private var showingEditJob = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    jobDetailsSection
                    
                    paymentDetailsSection
                    
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
            .background(Color.appBackground)
        }
        .sheet(isPresented: $showingEditJob) {
            EditJobView(job: job)
        }
        .alert("Delete Job", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle delete
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this job? This action cannot be undone.")
        }
        .darkTranslucentNavigationBar()
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(Color.appPrimaryText)
            }
            
            Spacer()
            
            VStack {
                Text("Job Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
            }
            
            Spacer()
            
            Button(action: {
                showingEditJob = true
            }) {
                Text("Edit")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var jobDetailsSection: some View {
        VStack(spacing: 16) {
            // Job Title and Agency
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(.purple)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(job.agency?.name.prefix(1).uppercased() ?? "S")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text(job.agency?.name ?? "Unknown Agency")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        StatusBadge(status: job.status)
                    }
                    
                    Spacer()
                }
            }
            
            // Job Information Grid
            VStack(spacing: 16) {
                HStack {
                    DetailRowView(
                        title: "Job Type",
                        value: job.type.displayName,
                        icon: "briefcase.fill"
                    )
                    
                    Spacer()
                    
                    DetailRowView(
                        title: "Payment",
                        value: "$\(String(format: "%.2f", job.fixedPrice ?? 0))",
                        icon: "dollarsign.circle.fill"
                    )
                }
                
                HStack {
                    DetailRowView(
                        title: "Start Date",
                        value: job.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set",
                        icon: "calendar"
                    )
                    
                    Spacer()
                    
                    DetailRowView(
                        title: "End Date",
                        value: job.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set",
                        icon: "calendar.badge.checkmark"
                    )
                }
                
                if let location = job.location, !location.isEmpty {
                    HStack {
                        DetailRowView(
                            title: "Location",
                            value: location,
                            icon: "location.fill"
                        )
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var paymentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Information")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Amount")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        Text("$\(String(format: "%.2f", job.fixedPrice ?? 0))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appPrimaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Agency Fee (20%)")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        Text("-$\(String(format: "%.2f", (job.fixedPrice ?? 0) * 0.2))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Net Earnings")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", (job.fixedPrice ?? 0) * 0.8))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingEditJob = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Job")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBlue))
                .cornerRadius(12)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Job")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemRed))
                .cornerRadius(12)
            }
            
            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
        }
    }
}

struct DetailRowView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    JobDetailModalView(job: Job(
        title: "Fashion Shoot",
        description: "Summer collection photoshoot",
        location: "New York, NY",
        fixedPrice: 4000,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        status: .completed,
        type: .contract
    ))
    .modelContainer(for: [Job.self, Agency.self])
}