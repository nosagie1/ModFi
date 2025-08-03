import SwiftUI
import SwiftData

struct UpcomingPaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Query private var localPayments: [Payment]
    
    // Supabase data
    @StateObject private var paymentService = PaymentService()
    @StateObject private var jobAmountService = JobAmountCalculationService()
    @State private var supabasePayments: [SupabasePayment] = []
    @State private var isLoading = false
    
    // Filter upcoming payments by status (pending, invoiced, partiallyPaid)
    private var upcomingPayments: [SupabasePayment] {
        supabasePayments.filter { payment in
            payment.paymentStatus == .pending || 
            payment.paymentStatus == .invoiced || 
            payment.paymentStatus == .partiallyPaid
        }
    }
    
    private var totalExpected: Double {
        return jobAmountService.upcomingPaymentsTotal
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                
                VStack(spacing: 24) {
                    if isLoading {
                        loadingSection
                    } else if upcomingPayments.isEmpty {
                        emptyStateSection
                    } else {
                        horizontalPaymentsSection
                        viewAllPaymentsButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 100) // Space for navigation and tab bar
                
                Spacer()
            }
            .background(Color.appBackground)
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUpcomingPayments()
        }
        .onChange(of: appState.dataRefreshTrigger) { _, _ in
            loadUpcomingPayments()
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading upcoming payments...")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func loadUpcomingPayments() {
        guard appState.authenticationState == .authenticated else { return }
        
        isLoading = true
        Task {
            do {
                let payments = try await paymentService.getAllPayments()
                await MainActor.run {
                    self.supabasePayments = payments
                    // Update the calculation service with fresh data
                    self.jobAmountService.calculateAmountsByPaymentStatus(payments: payments)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("🔴 Error loading upcoming payments: \(error)")
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(Color.appPrimaryText)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            HStack {
                Text("Upcoming Payments")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
    }
    
    
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
            
            VStack(spacing: 8) {
                Text("No upcoming payments")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("All your jobs are either completed or overdue.")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var horizontalPaymentsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(upcomingPayments.sorted { $0.dueDate < $1.dueDate }) { payment in
                    PaymentCardView(payment: payment)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var viewAllPaymentsButton: some View {
        Button(action: {
            // Navigate to all payments view
            print("View All Payments tapped")
        }) {
            HStack {
                Text("View All Payments")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.blue)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.3))
            )
        }
        .padding(.horizontal, 20)
    }
}

struct PaymentCardView: View {
    let payment: SupabasePayment
    
    private var isOverdue: Bool {
        payment.dueDate < Date()
    }
    
    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: payment.dueDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with profile image and job info
            HStack(spacing: 12) {
                // Circular profile image with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.8),
                                Color.pink.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String((payment.paymentDescription ?? "P").prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(payment.paymentDescription ?? "Payment")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Elite Models") // Placeholder for agency/client name
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Overdue indicator dot
                if isOverdue {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Bottom section with due date and amount
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(formattedDueDate)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Amount")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("$\(String(format: "%.0f", payment.amount))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
    }
}

struct UpcomingSupabasePaymentRowView: View {
    let payment: SupabasePayment
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: payment.dueDate).day ?? 0
    }
    
    private var isDueSoon: Bool {
        daysUntilDue <= 7
    }
    
    private var statusColor: Color {
        switch payment.paymentStatus {
        case .pending:
            return .blue
        case .invoiced:
            return .green
        case .partiallyPaid:
            return .orange
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch payment.paymentStatus {
        case .pending:
            return "Pending"
        case .invoiced:
            return "Invoiced"
        case .partiallyPaid:
            return "Partially Paid"
        default:
            return "Unknown"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payment.paymentDescription ?? "Payment")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", payment.amount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                HStack {
                    Text("Due: \(payment.dueDate, formatter: UpcomingSupabasePaymentRowView.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(statusColor)
                        )
                }
                
                if isDueSoon {
                    Text("⚠️ Due in \(daysUntilDue) days")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                } else {
                    Text("Due in \(daysUntilDue) days")
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct UpcomingPaymentRowView: View {
    let payment: Payment
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: payment.dueDate).day ?? 0
    }
    
    private var isDueSoon: Bool {
        daysUntilDue <= 7
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isDueSoon ? Color(.systemOrange) : Color(.systemBlue))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payment.paymentDescription ?? "Payment")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", payment.amount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                HStack {
                    Text("Due: \(payment.dueDate, formatter: UpcomingPaymentRowView.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    if isDueSoon {
                        Text("Due in \(daysUntilDue) days")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemOrange))
                            )
                    } else {
                        Text("In \(daysUntilDue) days")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBlue))
                            )
                    }
                }
                
                if let jobName = payment.job?.title {
                    Text("Job: \(jobName)")
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

extension UpcomingSupabasePaymentRowView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

extension UpcomingPaymentRowView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    UpcomingPaymentsView()
        .modelContainer(for: [Payment.self, Job.self])
}