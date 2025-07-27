//
//  NewOnboardingView.swift
//  Aure
//
//  Enhanced onboarding flow: Currency → Permissions → Agency → Confirmation
//

import SwiftUI

// MARK: - Main Onboarding View
struct NewOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var onboardingData = OnboardingData()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground,
                    Color.appSecondaryBackground.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep + 1), total: 4)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.appAccentBlue))
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                
                Text("Step \(currentStep + 1) of 4")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.top, 8)
                
                // Current Step View
                Group {
                    switch currentStep {
                    case 0:
                        CurrencySelectionView(onboardingData: $onboardingData, onNext: nextStep)
                    case 1:
                        PermissionsView(onboardingData: $onboardingData, onNext: nextStep)
                    case 2:
                        AgencySetupView(onboardingData: $onboardingData, onNext: nextStep)
                    case 3:
                        ConfirmationView(onboardingData: $onboardingData, onComplete: completeOnboarding)
                    default:
                        EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func completeOnboarding() {
        // Save onboarding data and complete
        appState.completeOnboarding()
    }
}

// MARK: - Onboarding Data Model
class OnboardingData: ObservableObject {
    @Published var selectedCurrency: Currency = .usd
    @Published var faceIDEnabled = false
    @Published var notificationsEnabled = false
    @Published var agencyName = ""
    @Published var skipFirstJob = false
}

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "C$"
        case .aud: return "A$"
        }
    }
    
    var flag: String {
        switch self {
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .gbp: return "🇬🇧"
        case .cad: return "🇨🇦"
        case .aud: return "🇦🇺"
        }
    }
    
    var fullName: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        }
    }
}

// MARK: - Currency Selection View
struct CurrencySelectionView: View {
    @Binding var onboardingData: OnboardingData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Choose your currency")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("This will be used for all your earnings")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    OnboardingCurrencyOptionView(
                        currency: currency,
                        isSelected: onboardingData.selectedCurrency == currency
                    ) {
                        onboardingData.selectedCurrency = currency
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Complete Setup")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct OnboardingCurrencyOptionView: View {
    let currency: Currency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(currency.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text(currency.fullName)
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.appAccentBlue)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appAccentBlue : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @Binding var onboardingData: OnboardingData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Set up permissions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("Help us keep your account secure and updated")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Face ID Toggle
                PermissionToggleView(
                    icon: "faceid",
                    title: "Log in with Face ID",
                    description: "Use biometric authentication for quick access",
                    isEnabled: $onboardingData.faceIDEnabled
                )
                
                // Notifications Toggle
                PermissionToggleView(
                    icon: "bell.fill",
                    title: "Get notifications",
                    description: "Stay updated on payments and deadlines",
                    isEnabled: $onboardingData.notificationsEnabled
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.appAccentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct PermissionToggleView: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.appAccentBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color.appAccentBlue))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Agency Setup View
struct AgencySetupView: View {
    @Binding var onboardingData: OnboardingData
    let onNext: () -> Void
    
    private var canContinue: Bool {
        true
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Agency Setup")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("Add your modeling agency to get started")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Agency Name")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                TextField("e.g., Greenpoint Agency", text: $onboardingData.agencyName)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(canContinue ? Color.green : Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canContinue ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
            }
            .disabled(!canContinue)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Confirmation View
struct ConfirmationView: View {
    @Binding var onboardingData: OnboardingData
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You've added your first agency!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    Text("Agency: \(onboardingData.agencyName)")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text("Currency: \(onboardingData.selectedCurrency.symbol) \(onboardingData.selectedCurrency.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: onComplete) {
                    Text("Add Your First Job")
                        .font(.headline)
                        .foregroundColor(Color.appButtonText)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.appAccentBlue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    onboardingData.skipFirstJob = true
                    onComplete()
                }) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NewOnboardingView()
        .environmentObject(AppState())
}