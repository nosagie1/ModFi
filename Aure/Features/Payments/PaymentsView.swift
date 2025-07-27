import SwiftUI
import SwiftData

struct PaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var payments: [Payment]
    @Query private var jobs: [Job]
    @State private var selectedTab = 0
    
    private var upcomingPayments: [Payment] {
        payments.filter { $0.status == .pending && $0.dueDate > Date() }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var overduePayments: [Payment] {
        payments.filter { $0.status == .pending && $0.dueDate <= Date() }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var totalUpcoming: Double {
        upcomingPayments.reduce(0) { $0 + $1.amount }
    }
    
    private var totalOverdue: Double {
        overduePayments.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Payment Summary Cards
                HStack(spacing: 16) {
                    PaymentSummaryCard(
                        title: "Upcoming",
                        amount: totalUpcoming,
                        subtitle: "Next 30 days",
                        color: .blue,
                        isSelected: selectedTab == 0
                    )
                    .onTapGesture {
                        selectedTab = 0
                    }
                    
                    PaymentSummaryCard(
                        title: "Overdue",
                        amount: totalOverdue,
                        subtitle: "Needs attention",
                        color: .red,
                        isSelected: selectedTab == 1
                    )
                    .onTapGesture {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Payment List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if selectedTab == 0 {
                            ForEach(upcomingPayments) { payment in
                                PaymentRow(payment: payment)
                            }
                        } else {
                            ForEach(overduePayments) { payment in
                                PaymentRow(payment: payment)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                if (selectedTab == 0 ? upcomingPayments : overduePayments).isEmpty {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: selectedTab == 0 ? "clock" : "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text(selectedTab == 0 ? "No upcoming payments" : "No overdue payments")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Payments")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PaymentSummaryCard: View {
    let title: String
    let amount: Double
    let subtitle: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if title == "Overdue" {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Text("$\(amount, specifier: "%.2f")")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
        )
    }
}

struct PaymentRow: View {
    let payment: Payment
    
    private var isOverdue: Bool {
        payment.status == .pending && payment.dueDate <= Date()
    }
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: payment.dueDate).day ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let job = payment.job {
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let agency = job.agency {
                        Text(agency.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Unknown Job")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Due: \(payment.dueDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(isOverdue ? .red : .secondary)
                    
                    if isOverdue {
                        Text("• \(abs(daysUntilDue)) days overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if daysUntilDue <= 7 {
                        Text("• \(daysUntilDue) days left")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(payment.amount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(payment.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    PaymentsView()
        .modelContainer(for: [Payment.self, Job.self, Agency.self])
}