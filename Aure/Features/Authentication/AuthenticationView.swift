//
//  AuthenticationView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isSignIn = true
    
    var body: some View {
        ZStack {
            // Dark background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground,
                    Color.appSecondaryBackground.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.appAccentBlue)
                    
                    Text("Aure")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appPrimaryText)
                }
                
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignIn = true
                            }
                        }) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(isSignIn ? Color.appButtonText : Color.appAccentBlue)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(isSignIn ? Color.appAccentBlue : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appAccentBlue, lineWidth: isSignIn ? 0 : 1)
                                )
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignIn = false
                            }
                        }) {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(!isSignIn ? Color.appButtonText : Color.appAccentBlue)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(!isSignIn ? Color.appAccentBlue : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appAccentBlue, lineWidth: !isSignIn ? 0 : 1)
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    if isSignIn {
                        SignInView()
                    } else {
                        SignUpView()
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textContentType(.password)
            }
            .padding(.horizontal, 32)
            
            Button(action: {
                appState.signIn(email: email, password: password)
            }) {
                if case .loading = appState.authenticationState {
                    ProgressView()
                        .tint(Color.appButtonText)
                } else {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(Color.appButtonText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.appAccentBlue)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .disabled(email.isEmpty || password.isEmpty)
            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            
            if let errorMessage = appState.authError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Color.appError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                TextField("Full Name", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.words)
                
                TextField("Email", text: $email)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .textContentType(.newPassword)
            }
            .padding(.horizontal, 32)
            
            Button(action: {
                appState.signUp(name: name, email: email, password: password)
            }) {
                if case .loading = appState.authenticationState {
                    ProgressView()
                        .tint(Color.appButtonText)
                } else {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(Color.appButtonText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.appAccentBlue)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .disabled(name.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword)
            .opacity((name.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword) ? 0.6 : 1.0)
            
            if let errorMessage = appState.authError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Color.appError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
        }
    }
}