//
//  ProfileView.swift
//  Aure
//
//  Comprehensive profile view with earnings, documents, and preferences
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataService = SupabaseDataService()
    @StateObject private var jobAmountService = JobAmountCalculationService()
    
    // Profile data
    @State private var notificationsEnabled = true
    @State private var selectedCurrency = "USD"
    @State private var showingTaxDocs = false
    @State private var userProfile: SupabaseProfile?
    @State private var isLoadingProfile = false
    @State private var isLoadingEarnings = false
    
    // Editable profile fields
    @State private var isEditingProfile = false
    @State private var editableName = ""
    @State private var editableAgency = ""
    @State private var editableEmail = ""
    @State private var editablePhone = ""
    
    // Earnings data - now comes from real user data
    private var totalEarnings: Double {
        return jobAmountService.receivedAmount
    }
    
    private var averageJobRate: Double {
        // Calculate average from actual job data
        let receivedJobs = jobAmountService.monthlyBreakdown.flatMap { $0.jobs }
        guard !receivedJobs.isEmpty else { return 0 }
        let totalAmount = receivedJobs.reduce(0) { $0 + $1.amount }
        return totalAmount / Double(receivedJobs.count)
    }
    
    private var upcomingPaymentsTotal: Double {
        return jobAmountService.pendingAmount + jobAmountService.invoicedAmount + jobAmountService.partiallyPaidAmount
    }
    
    private var nextPaymentDate: String {
        // This would need to be calculated from upcoming payments
        return "Aug 23" // Placeholder - you'd want to calculate this from actual upcoming payments
    }
    
    // Animation states
    @State private var avatarScale: CGFloat = 0.8
    @State private var avatarOpacity: Double = 0
    @State private var showEarnings = false
    
    // Navigation context detection
    @Environment(\.presentationMode) private var presentationMode
    
    private let currencies = ["USD", "EUR", "GBP", "CAD"]
    
    // Dynamic top padding based on presentation context
    private func topPadding(for geometry: GeometryProxy) -> CGFloat {
        // Base safe area padding + buffer for edit button
        return geometry.safeAreaInsets.top + 100
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    editButtonSection
                    headerSection
                    earningsSection
                    documentsSection
                    preferencesSection
                    referralSection
                    dangerZoneSection
                }
                .padding(.horizontal, 20)
                .padding(.top, topPadding(for: geometry))
                .padding(.bottom, 120) // Space for tab bar
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(Color.appBackground)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTaxDocs) {
            TaxDocsView()
        }
        .onAppear {
            animateOnAppear()
            loadUserProfile()
            loadEarningsData()
        }
    }
    
    // MARK: - Edit Button Section
    private var editButtonSection: some View {
        HStack {
            // Back button when accessed via navigation
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.appPrimaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.appCardBackground.opacity(0.6))
                    )
            }
            
            Spacer()
            
            Button(action: {
                if isEditingProfile {
                    saveProfileChanges()
                } else {
                    isEditingProfile = true
                }
            }) {
                Text(isEditingProfile ? "Save" : "Edit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appAccentBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.appAccentBlue, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.appAccentBlue.opacity(0.1))
                            )
                    )
            }
            
            if isEditingProfile {
                Button(action: {
                    cancelEditing()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appSecondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Header Section with Avatar and Info
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Avatar
            Button(action: {
                // Handle avatar tap
            }) {
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
                    .frame(width: 96, height: 96)
                    .overlay(
                        Text(displayedName.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(avatarScale)
                    .opacity(avatarOpacity)
            }
            
            VStack(spacing: 8) {
                // Name
                if isEditingProfile {
                    TextField("Full Name", text: $editableName)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                } else {
                    Text(displayedName)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Color.appPrimaryText)
                }
                
                // Agency
                if isEditingProfile {
                    TextField("Agency", text: $editableAgency)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appSecondaryText)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appCardBackground)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                } else {
                    Text(displayedAgency)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appSecondaryText)
                }
            }
            
            // Contact Info
            VStack(spacing: 12) {
                editableContactRow(
                    icon: "envelope",
                    text: isEditingProfile ? $editableEmail : .constant(editableEmail.isEmpty ? userEmail : editableEmail),
                    isEditing: isEditingProfile,
                    placeholder: "Email address"
                )
                
                editableContactRow(
                    icon: "phone",
                    text: isEditingProfile ? $editablePhone : .constant(editablePhone.isEmpty ? userPhone : editablePhone),
                    isEditing: isEditingProfile,
                    placeholder: "Phone number"
                )
            }
            
        }
    }
    
    // MARK: - Earnings Section
    private var earningsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Earnings")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 16) {
                earningsRow(
                    title: "Total Earnings",
                    value: totalEarnings,
                    format: .currency,
                    animated: showEarnings
                )
                
                Divider()
                    .background(Color.appBorder)
                
                earningsRow(
                    title: "Average Job Rate",
                    value: averageJobRate,
                    format: .currency,
                    animated: showEarnings
                )
                
                Divider()
                    .background(Color.appBorder)
                
                HStack {
                    Text("Upcoming Payments")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    if isLoadingEarnings {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(formatCurrency(upcomingPaymentsTotal))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.appPrimaryText)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appCardBackground)
            )
        }
    }
    
    // MARK: - Documents Section
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Documents")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "building.columns",
                    title: "Bank Account",
                    showChevron: true
                ) {
                    // Navigate to bank account view
                }
                
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, 20)
                
                ProfileRow(
                    icon: "doc.text",
                    title: "Tax Documents",
                    showChevron: true
                ) {
                    showingTaxDocs = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appCardBackground)
            )
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 0) {
                ProfileToggleRow(
                    icon: "bell",
                    title: "Notifications",
                    isOn: $notificationsEnabled
                )
                
                Divider()
                    .background(Color.appBorder)
                
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appAccentBlue)
                        .frame(width: 24, height: 24)
                    
                    Text("Currency")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.appPrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Menu {
                        ForEach(currencies, id: \.self) { currency in
                            Button(action: {
                                selectedCurrency = currency
                            }) {
                                HStack {
                                    Text(currency)
                                    if currency == selectedCurrency {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCurrency)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appSecondaryText)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appCardBackground)
            )
        }
    }
    
    // MARK: - Referral Section
    private var referralSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Text("Referral Code")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Text(generateReferralCode())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.appAccentBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appAccentBlue.opacity(0.1))
                        )
                }
                
                Button(action: {
                    // Share referral link
                    shareReferralLink()
                }) {
                    Text("Share link")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appAccentBlue)
                        )
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appCardBackground)
            )
        }
    }
    
    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                // Show delete account confirmation
                showDeleteAccountAlert()
            }) {
                Text("Delete Account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.05))
                            )
                    )
            }
        }
    }
    
    // MARK: - Helper Views
    private func contactRow(icon: String, text: String, copyable: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appSecondaryText)
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.appSecondaryText)
            
            if copyable {
                Button(action: {
                    UIPasteboard.general.string = text
                    // Show toast confirmation
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appAccentBlue)
                }
            }
        }
    }
    
    
    private func earningsRow(title: String, value: Double, format: EarningsFormat, animated: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color.appSecondaryText)
            
            Spacer()
            
            if animated {
                if format == .currency {
                    CountUpCurrency(
                        value: .constant(value),
                        duration: 0.6
                    )
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appPrimaryText)
                } else {
                    CountUpText(
                        value: .constant(value),
                        format: "%.0f",
                        duration: 0.6
                    )
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appPrimaryText)
                }
            } else {
                Text(formatValue(value, format: format))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appPrimaryText)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    private var userName: String {
        return userProfile?.name ?? "User"
    }
    
    private var displayedName: String {
        if isEditingProfile && !editableName.isEmpty {
            return editableName
        }
        return userName
    }
    
    private var displayedAgency: String {
        if isEditingProfile && !editableAgency.isEmpty {
            return editableAgency
        }
        return userAgency
    }
    
    private var userEmail: String {
        return SupabaseManager.shared.auth.currentUser?.email ?? "user@example.com"
    }
    
    private var userPhone: String {
        return userProfile?.phone ?? ""
    }
    
    private var userAgency: String {
        // You might want to add agency info to the profile or fetch separately
        return "Elite Models" // This could be fetched from a related agency table
    }
    
    // MARK: - Helper Functions
    private func generateReferralCode() -> String {
        let name = displayedName.isEmpty ? "USER" : displayedName
        let firstLetter = name.prefix(1).uppercased()
        let lastPart = name.count >= 4 ? String(name.suffix(4)).uppercased() : name.uppercased()
        return firstLetter + lastPart
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func animateOnAppear() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            avatarScale = 1.0
            avatarOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            showEarnings = true
        }
    }
    
    private func formatValue(_ value: Double, format: EarningsFormat) -> String {
        switch format {
        case .currency:
            return String(format: "$%.0f", value)
        case .number:
            return String(format: "%.0f", value)
        }
    }
    
    private func shareReferralLink() {
        let referralCode = generateReferralCode()
        let text = "Join Aure with my referral code \(referralCode) and start tracking your modeling jobs!"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
    
    private func showDeleteAccountAlert() {
        // Show confirmation alert for account deletion
        print("Delete account confirmation needed")
    }
    
    // MARK: - Profile Data Management
    private func loadEarningsData() {
        guard appState.authenticationState == .authenticated else { return }
        
        isLoadingEarnings = true
        Task {
            do {
                // Fetch jobs and payments from Supabase
                let jobService = JobService()
                let paymentService = PaymentService()
                
                let jobs = try await jobService.getAllJobs()
                let payments = try await paymentService.getAllPayments()
                
                await MainActor.run {
                    // Calculate job amounts using the same service as dashboard
                    jobAmountService.calculateJobAmounts(from: jobs, payments: payments)
                    isLoadingEarnings = false
                }
            } catch {
                print("Error loading earnings data: \(error)")
                await MainActor.run {
                    isLoadingEarnings = false
                }
            }
        }
    }
    
    private func loadUserProfile() {
        guard appState.authenticationState == .authenticated else { return }
        
        isLoadingProfile = true
        Task {
            do {
                let profile = try await dataService.getCurrentUserProfile()
                print("📥 Loaded profile from Supabase: \(profile?.name ?? "nil")")
                await MainActor.run {
                    userProfile = profile
                    loadProfileData()
                    isLoadingProfile = false
                }
            } catch {
                print("🔴 Error loading user profile: \(error)")
                await MainActor.run {
                    isLoadingProfile = false
                }
            }
        }
    }
    
    private func loadProfileData() {
        // Load current user data into editable fields (only if they're not already being edited)
        if !isEditingProfile {
            editableName = userName
            editableEmail = userEmail
            editableAgency = userAgency
            editablePhone = userPhone.isEmpty ? "+1 (234) 567-8900" : userPhone
        }
        print("📋 Profile data loaded - Name: \(userName), Editable Name: \(editableName)")
    }
    
    private func saveProfileChanges() {
        Task {
            do {
                print("💾 Saving profile changes - Name: '\(editableName)', Phone: '\(editablePhone)'")
                
                // Update profile in Supabase
                try await dataService.updateUserProfile(
                    name: editableName.isEmpty ? nil : editableName,
                    phone: editablePhone.isEmpty ? nil : editablePhone
                )
                
                // Refresh the profile data
                await loadUserProfile()
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditingProfile = false
                    }
                    print("Profile changes saved successfully")
                }
            } catch {
                print("Error saving profile changes: \(error)")
                // You might want to show an error alert here
            }
        }
    }
    
    private func cancelEditing() {
        // Revert to original values
        loadProfileData()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditingProfile = false
        }
    }
    
    // MARK: - Editable Contact Row
    private func editableContactRow(icon: String, text: Binding<String>, isEditing: Bool, placeholder: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appSecondaryText)
                .frame(width: 20, height: 20)
            
            if isEditing {
                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.appPrimaryText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appCardBackground)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            } else {
                Text(text.wrappedValue)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.appSecondaryText)
                
                Button(action: {
                    UIPasteboard.general.string = text.wrappedValue
                    // Show toast confirmation
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appAccentBlue)
                }
            }
        }
    }
    
    // MARK: - Editable Measurement Item
    private func editableMeasurementItem(title: String, value: Binding<String>, placeholder: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appSecondaryText)
            
            TextField(placeholder, text: value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appCardBackground)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

enum EarningsFormat {
    case currency
    case number
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}