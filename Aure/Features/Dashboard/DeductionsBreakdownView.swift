//
//  DeductionsBreakdownView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/12/25.
//

import SwiftUI

struct DeductionsBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddDeduction = false
    @State private var deductions: [DeductionItem] = [
        DeductionItem(name: "Agency Commission", amount: 9000.0, percentage: 20.0, type: .commission),
        DeductionItem(name: "Tax Withholding", amount: 6750.0, percentage: 15.0, type: .tax)
    ]
    
    private var totalDeductions: Double {
        deductions.reduce(0.0) { $0 + $1.amount }
    }
    
    private var grossEarnings: Double {
        45000.0 // This would come from the actual data
    }
    
    private var netEarnings: Double {
        grossEarnings - totalDeductions
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    summarySection
                    
                    deductionsListSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("Deductions Breakdown")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddDeduction = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(Color.appAccentBlue)
                    }
                }
            }
            .background(Color.appBackground)
        }
        .sheet(isPresented: $showingAddDeduction) {
            AddDeductionView { newDeduction in
                deductions.append(newDeduction)
            }
        }
    }
    
    private var summarySection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Text("Gross Earnings")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", grossEarnings))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                HStack {
                    Text("Total Deductions")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Spacer()
                    
                    Text("-$\(String(format: "%.2f", totalDeductions))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
                
                HStack {
                    Text("Net Earnings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", netEarnings))")
                        .font(.subheadline)
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
    
    private var deductionsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Deductions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(deductions) { deduction in
                    DeductionRowView(deduction: deduction) {
                        // Handle delete
                        if let index = deductions.firstIndex(where: { $0.id == deduction.id }) {
                            deductions.remove(at: index)
                        }
                    }
                }
            }
        }
    }
}

struct DeductionItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let amount: Double
    let percentage: Double
    let type: DeductionType
}

enum DeductionType: String, CaseIterable, Codable {
    case commission = "Commission"
    case tax = "Tax"
    case expense = "Expense"
    case insurance = "Insurance"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .commission:
            return "building.2.fill"
        case .tax:
            return "percent"
        case .expense:
            return "creditcard.fill"
        case .insurance:
            return "shield.fill"
        case .other:
            return "doc.text.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .commission:
            return .blue
        case .tax:
            return .red
        case .expense:
            return .orange
        case .insurance:
            return .green
        case .other:
            return .purple
        }
    }
}

struct DeductionRowView: View {
    let deduction: DeductionItem
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(deduction.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appPrimaryText)
                
                Text(deduction.type.rawValue)
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("-$\(String(format: "%.2f", deduction.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("\(String(format: "%.1f", deduction.percentage))%")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        )
        .alert("Delete Deduction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this deduction?")
        }
    }
}

struct AddDeductionView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (DeductionItem) -> Void
    
    @State private var name = ""
    @State private var amount = ""
    @State private var percentage = ""
    @State private var selectedType: DeductionType = .expense
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    formSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("Add Deduction")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.appPrimaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addDeduction()
                    }
                    .foregroundColor(Color.appAccentBlue)
                    .disabled(!isFormValid)
                }
            }
            .background(Color.appBackground)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Deduction Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appPrimaryText)
                
                TextField("Enter deduction name", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appPrimaryText)
                
                Picker("Type", selection: $selectedType) {
                    ForEach(DeductionType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appCardBackground)
                        .foregroundColor(Color.appPrimaryText)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Percentage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    TextField("0.0%", text: $percentage)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appCardBackground)
                        .foregroundColor(Color.appPrimaryText)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !amount.isEmpty && !percentage.isEmpty
    }
    
    private func addDeduction() {
        guard let amountValue = Double(amount),
              let percentageValue = Double(percentage) else { return }
        
        let newDeduction = DeductionItem(
            name: name,
            amount: amountValue,
            percentage: percentageValue,
            type: selectedType
        )
        
        onAdd(newDeduction)
        dismiss()
    }
}

#Preview {
    DeductionsBreakdownView()
}