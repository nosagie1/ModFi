import SwiftUI
import SwiftData

struct OverduePaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Query private var localPayments: [Payment]
    
    // Supabase data
    @StateObject private var paymentService = PaymentService()
    @StateObject private var jobAmountService = JobAmountCalculationService()
    @State private var supabasePayments: [SupabasePayment] = []
    @State private var isLoading = false
    
    // Filter overdue payments by status
    private var overduePayments: [SupabasePayment] {
        supabasePayments.filter { payment in
            payment.paymentStatus == .overdue
        }
    }
    
    private var totalOverdue: Double {
        return jobAmountService.overdueAmount
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        summarySection
                        
                        if isLoading {
                            loadingSection
                        } else if overduePayments.isEmpty {
                            emptyStateSection
                        } else {
                            paymentsListSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Space for navigation and tab bar
                }
                .background(Color.appBackground)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOverduePayments()
        }
        .onChange(of: appState.dataRefreshTrigger) { _, _ in
            loadOverduePayments()
        }
    }
    
    private func loadOverduePayments() {
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
                    print("🔴 Error loading overdue payments: \(error)")
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
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Overdue Payments")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                }
                
                Text("Payments past due date")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
    }
    
    private var summarySection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    
                    Text("Total Overdue")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                Text("$\(String(format: "%.2f", totalOverdue))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                
                Text("\(overduePayments.count) overdue payments")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
            
            VStack(spacing: 8) {
                Text("No overdue payments")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("All your payments are up to date!")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var paymentsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Overdue Payments")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(overduePayments.sorted { $0.dueDate < $1.dueDate }) { payment in
                    OverdueSupabasePaymentRowView(payment: payment)
                }
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading overdue payments...")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct OverdueSupabasePaymentRowView: View {
    let payment: SupabasePayment
    
    private var daysPastDue: Int {
        Calendar.current.dateComponents([.day], from: payment.dueDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(.systemRed))
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
                    Text("Due: \(payment.dueDate, formatter: OverdueSupabasePaymentRowView.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text("\(daysPastDue) days overdue")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemRed))
                        )
                }
                
                Text("Status: Overdue")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
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

extension OverdueSupabasePaymentRowView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct PaymentRowView: View {
    let payment: Payment
    let isOverdue: Bool
    
    private var daysPastDue: Int {
        Calendar.current.dateComponents([.day], from: payment.dueDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isOverdue ? Color(.systemRed) : Color(.systemBlue))
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
                    Text("Due: \(payment.dueDate, formatter: Self.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    if isOverdue {
                        Text("\(daysPastDue) days overdue")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemRed))
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

extension PaymentRowView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    OverduePaymentsView()
        .modelContainer(for: [Payment.self, Job.self])
}