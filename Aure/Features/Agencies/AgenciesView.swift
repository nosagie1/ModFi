//
//  AgenciesView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI
import SwiftData

struct AgenciesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var agencies: [Agency]
    @State private var showingAddAgency = false
    @State private var selectedAgency: Agency?
    @State private var searchText = ""
    
    var filteredAgencies: [Agency] {
        if searchText.isEmpty {
            return agencies
        } else {
            return agencies.filter { agency in
                agency.name.localizedCaseInsensitiveContains(searchText) ||
                agency.contactPerson.localizedCaseInsensitiveContains(searchText) ||
                agency.industry?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchSection
                
                if filteredAgencies.isEmpty {
                    emptyStateView
                } else {
                    agenciesList
                }
            }
            .navigationTitle("Agencies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAgency = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddAgency) {
                AddAgencyView()
            }
            .fullScreenCover(item: $selectedAgency) { agency in
                NavigationStack {
                    AgencyDetailView(agency: agency)
                }
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search agencies...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.appCardBackground)
    }
    
    private var agenciesList: some View {
        List(filteredAgencies) { agency in
            AgencyRow(agency: agency)
                .onTapGesture {
                    selectedAgency = agency
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        deleteAgency(agency)
                    }
                }
        }
        .listStyle(PlainListStyle())
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80) // Space for tab bar
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Agencies Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
            
            Text("Add your first agency to start managing your client relationships")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                showingAddAgency = true
            }) {
                Text("Add Agency")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
            
            Spacer()
        }
    }
    
    private func deleteAgency(_ agency: Agency) {
        modelContext.delete(agency)
        try? modelContext.save()
    }
}

struct AgencyRow: View {
    let agency: Agency
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(agency.name)
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                Text(agency.contactPerson)
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                if let industry = agency.industry {
                    Text(industry)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(agency.jobs.count) jobs")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                
                Circle()
                    .fill(agency.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddAgencyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @State private var name = ""
    @State private var contactPerson = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var website = ""
    @State private var industry = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Agency Information") {
                    TextField("Agency Name", text: $name)
                    TextField("Contact Person", text: $contactPerson)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Additional Details") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...3)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Industry", text: $industry)
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Agency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAgency()
                    }
                    .disabled(name.isEmpty || contactPerson.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func saveAgency() {
        let agency = Agency(
            name: name,
            contactPerson: contactPerson,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address,
            website: website.isEmpty ? nil : website,
            industry: industry.isEmpty ? nil : industry,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(agency)
        
        do {
            try modelContext.save()
            appState.showToast(message: "Agency added successfully!", type: .success)
            dismiss()
        } catch {
            appState.showToast(message: "Failed to save agency", type: .error)
        }
    }
}

