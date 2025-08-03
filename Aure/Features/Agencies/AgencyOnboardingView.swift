//
//  AgencyOnboardingView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/10/25.
//

import SwiftUI
import SwiftData

struct AgencyOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var currentStep = 1
    @State private var agencyName = ""
    @State private var commissionRate = "20"
    @State private var selectedCurrency = "USD"
    @State private var isCreatingAgency = false
    
    private let totalSteps = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 16) {
                HStack {
                    Button(action: {
                        if currentStep == 1 {
                            dismiss()
                        } else {
                            currentStep -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.appPrimaryText)
                            .font(.title3)
                    }
                    
                    Spacer()
                    
                    Text("\(currentStep) of \(totalSteps)")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Progress bar
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
            
            // Content based on current step
            ScrollView {
                switch currentStep {
                case 1:
                    agencyNameStep
                case 2:
                    commissionRateStep
                case 3:
                    currencySelectionStep
                default:
                    EmptyView()
                }
            }
            
            Spacer()
            
            // Bottom action button
            VStack(spacing: 16) {
                if currentStep < totalSteps {
                    Button(action: {
                        currentStep += 1
                    }) {
                        HStack {
                            Text("Continue")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Image(systemName: "arrow.right")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isStepValid ? .blue : .gray)
                        .cornerRadius(8)
                    }
                    .disabled(!isStepValid)
                } else {
                    Button(action: {
                        createAgencyOnly()
                    }) {
                        HStack {
                            if isCreatingAgency {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                
                                Text("Adding...")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            } else {
                                Text("Complete Setup")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .cornerRadius(8)
                    }
                    .disabled(isCreatingAgency || !isStepValid)
                }
                
                if currentStep == 3 {
                    Button("Add Job Later") {
                        // Job can be added later using the unified flow
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.appCardBackground)
    }
    
    private var agencyNameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your modeling agency?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Enter the name of the agency you work with")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            TextField("e.g. Soul Artist Management", text: $agencyName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                )
        }
        .padding(.horizontal, 20)
    }
    
    private var commissionRateStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your commission rate?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Enter the percentage your agency takes")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            HStack {
                TextField("20", text: $commissionRate)
                    .font(.subheadline)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                
                Text("%")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.trailing, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var currencySelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What currency do you use?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Select your preferred currency")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            VStack(spacing: 12) {
                CurrencyOptionView(
                    code: "USD",
                    name: "US Dollar",
                    isSelected: selectedCurrency == "USD"
                ) {
                    selectedCurrency = "USD"
                }
                
                CurrencyOptionView(
                    code: "EUR",
                    name: "Euro",
                    isSelected: selectedCurrency == "EUR"
                ) {
                    selectedCurrency = "EUR"
                }
                
                CurrencyOptionView(
                    code: "GBP",
                    name: "British Pound",
                    isSelected: selectedCurrency == "GBP"
                ) {
                    selectedCurrency = "GBP"
                }
                
                CurrencyOptionView(
                    code: "CAD",
                    name: "Canadian Dollar",
                    isSelected: selectedCurrency == "CAD"
                ) {
                    selectedCurrency = "CAD"
                }
                
                CurrencyOptionView(
                    code: "AUD",
                    name: "Australian Dollar",
                    isSelected: selectedCurrency == "AUD"
                ) {
                    selectedCurrency = "AUD"
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    
    private var isStepValid: Bool {
        switch currentStep {
        case 1:
            return !agencyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !commissionRate.isEmpty && Int(commissionRate) != nil
        case 3:
            return !selectedCurrency.isEmpty
        default:
            return false
        }
    }
    
    
    private func createAgencyOnly() {
        isCreatingAgency = true
        
        let agency = Agency(
            name: agencyName,
            contactPerson: "Contact",
            email: "contact@\(agencyName.lowercased().replacingOccurrences(of: " ", with: "")).com"
        )
        
        modelContext.insert(agency)
        
        do {
            try modelContext.save()
            appState.showToast(message: "Agency added successfully!", type: .success)
            dismiss()
        } catch {
            appState.showToast(message: "Failed to save agency", type: .error)
        }
        
        isCreatingAgency = false
    }
}

struct CurrencyOptionView: View {
    let code: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(code) - \(name)")
                    .font(.subheadline)
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? .black : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    AgencyOnboardingView()
        .environmentObject(AppState())
        .modelContainer(for: [Agency.self, Job.self, Payment.self])
}