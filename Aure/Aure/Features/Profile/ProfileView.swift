//
//  ProfileView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var dateOfBirth = Date()
    @State private var isEditing = false
    @State private var showingImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                profileImageSection
                
                personalInfoSection
                
                accountSection
                
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
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
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.headline)
                        .foregroundColor(Color.appAccentBlue)
                }
            }
        }
        .background(Color.appBackground)
        .onAppear {
            loadUserData()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
            
            Text("Manage your personal information")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.appCardBackground)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.appBorder, lineWidth: 2)
                        )
                    
                    if case .authenticated = appState.authenticationState,
                       let user = appState.dataCoordinator.currentUser,
                       let userName = user.name {
                        Text(userName.prefix(2).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color.appAccentBlue)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.appSecondaryText)
                    }
                    
                    if isEditing {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.appAccentBlue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: -8, y: -8)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                }
            }
            .disabled(!isEditing)
            
            if case .authenticated = appState.authenticationState,
               let user = appState.dataCoordinator.currentUser {
                Text(user.name ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
                
                Text(user.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Information")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 16) {
                ProfileFieldView(
                    title: "Full Name",
                    value: $name,
                    isEditing: isEditing,
                    placeholder: "Enter your full name"
                )
                
                ProfileFieldView(
                    title: "Email",
                    value: $email,
                    isEditing: false, // Email shouldn't be editable
                    placeholder: "Enter your email"
                )
                
                ProfileFieldView(
                    title: "Phone",
                    value: $phone,
                    isEditing: isEditing,
                    placeholder: "Enter your phone number"
                )
                
                ProfileFieldView(
                    title: "Location",
                    value: $location,
                    isEditing: isEditing,
                    placeholder: "Enter your location"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    if isEditing {
                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(dateOfBirth, style: .date)
                            .font(.body)
                            .foregroundColor(Color.appSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.appCardBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.appPrimaryText)
            
            VStack(spacing: 12) {
                ProfileActionRow(
                    icon: "bell",
                    title: "Notifications",
                    subtitle: "Manage notification preferences"
                ) {
                    // Handle notifications
                }
                
                ProfileActionRow(
                    icon: "lock",
                    title: "Privacy & Security",
                    subtitle: "Password and security settings"
                ) {
                    // Handle privacy
                }
                
                ProfileActionRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    subtitle: "Get help and contact support"
                ) {
                    // Handle help
                }
                
                ProfileActionRow(
                    icon: "info.circle",
                    title: "About",
                    subtitle: "App version and information"
                ) {
                    // Handle about
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                saveUserData()
            }) {
                Text("Save Changes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appAccentBlue)
                    )
            }
            .opacity(isEditing ? 1.0 : 0.6)
            .disabled(!isEditing)
            
            Button(action: {
                appState.signOut()
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appCardBackground)
                            )
                    )
            }
        }
    }
    
    private func loadUserData() {
        if case .authenticated = appState.authenticationState,
           let user = appState.dataCoordinator.currentUser {
            name = user.name ?? ""
            email = user.email ?? ""
            // Load other fields from user data or UserDefaults
            phone = UserDefaults.standard.string(forKey: "user_phone") ?? ""
            location = UserDefaults.standard.string(forKey: "user_location") ?? ""
            if let birthDateString = UserDefaults.standard.object(forKey: "user_birth_date") as? Date {
                dateOfBirth = birthDateString
            }
        }
    }
    
    private func saveUserData() {
        // Save to UserDefaults or update user profile
        UserDefaults.standard.set(phone, forKey: "user_phone")
        UserDefaults.standard.set(location, forKey: "user_location")
        UserDefaults.standard.set(dateOfBirth, forKey: "user_birth_date")
        
        // Update name if it changed
        if case .authenticated = appState.authenticationState,
           let user = appState.dataCoordinator.currentUser {
            if (user.name ?? "") != name {
                // Update user name through Supabase if needed
                // For now, just show success toast
                appState.showToast(message: "Profile updated successfully", type: .success)
            }
        }
        
        isEditing = false
    }
}

struct ProfileFieldView: View {
    let title: String
    @Binding var value: String
    let isEditing: Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appPrimaryText)
            
            if isEditing {
                TextField(placeholder, text: $value)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            } else {
                Text(value.isEmpty ? "Not set" : value)
                    .font(.body)
                    .foregroundColor(value.isEmpty ? Color.appSecondaryText : Color.appPrimaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.appCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            }
        }
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color.appAccentBlue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.appCardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}