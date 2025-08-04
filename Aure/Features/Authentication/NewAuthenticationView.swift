//
//  NewAuthenticationView.swift
//  Aure
//
//  Enhanced authentication flow with step-by-step sign-up and improved login
//

import SwiftUI

// MARK: - Main Authentication View
struct NewAuthenticationView: View {
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground,
                    Color.appSecondaryBackground.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showSignUp {
                SignUpFlowView(showSignUp: $showSignUp)
            } else {
                LoginView(showSignUp: $showSignUp)
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showSignUp: Bool
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var twoFactorCode = ""
    @State private var showTwoFactor = false
    @State private var isLoading = false
    
    private var isValidInput: Bool {
        !emailOrPhone.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "wrench.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Welcome Back")
                    .font(.pageTitle)
                    .foregroundColor(Color.appPrimaryText)
                
                Text("Sign in to your account")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            // Login Form
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    // Email or Phone Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email or Phone")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        TextField("Enter email or phone number", text: $emailOrPhone)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.appCardBackground)
                            .foregroundColor(Color.appPrimaryText)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    // Password Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                        
                        SecureField("Enter your password", text: $password)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.appCardBackground)
                            .foregroundColor(Color.appPrimaryText)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                            .textContentType(.password)
                    }
                    
                    // Two Factor Code (if needed)
                    if showTwoFactor {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2FA Code")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            
                            TextField("Enter 6-digit code", text: $twoFactorCode)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.appCardBackground)
                                .foregroundColor(Color.appPrimaryText)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                        }
                    }
                }
                
                // Sign In Button
                Button(action: handleSignIn) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Color.appButtonText)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(Color.appButtonText)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isValidInput ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
                }
                .disabled(!isValidInput || isLoading)
                
                // Forgot Password
                Button("Forgot Password?") {
                    // Handle forgot password
                }
                .font(.subheadline)
                .foregroundColor(Color.appAccentBlue)
                
                // Error Message
                if let errorMessage = appState.authError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(Color.appError)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Sign Up Link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(Color.appSecondaryText)
                
                Button("Sign Up") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSignUp = true
                    }
                }
                .foregroundColor(Color.appAccentBlue)
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.bottom, 32)
        }
    }
    
    private func handleSignIn() {
        isLoading = true
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            appState.signIn(email: emailOrPhone, password: password)
        }
    }
}

// MARK: - Sign Up Flow
struct SignUpFlowView: View {
    @Binding var showSignUp: Bool
    @State private var currentStep = 0
    @State private var signUpData = SignUpData()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep + 1), total: 4)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.appAccentBlue))
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                
                Text("Step \(currentStep + 1) of 4")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.top, 8)
                
                // Current Step View
                Group {
                    switch currentStep {
                    case 0:
                        EmailStepView(signUpData: $signUpData, onNext: nextStep)
                    case 1:
                        PhoneStepView(signUpData: $signUpData, onNext: nextStep)
                    case 2:
                        PasswordStepView(signUpData: $signUpData, onNext: nextStep)
                    case 3:
                        SMSVerificationStepView(signUpData: $signUpData, onComplete: completeSignUp)
                    default:
                        EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSignUp = false
                        }
                    }
                    .foregroundColor(Color.appAccentBlue)
                }
                
                if currentStep > 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") {
                            previousStep()
                        }
                        .foregroundColor(Color.appAccentBlue)
                    }
                }
            }
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
    
    private func completeSignUp() {
        // Handle sign up completion
        withAnimation(.easeInOut(duration: 0.3)) {
            showSignUp = false
        }
    }
}

// MARK: - Sign Up Data Model
class SignUpData: ObservableObject {
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var password = ""
    @Published var smsCode = ""
}

// MARK: - Email Step
struct EmailStepView: View {
    @Binding var signUpData: SignUpData
    let onNext: () -> Void
    
    private var isValidEmail: Bool {
        true
    }
    
    private var canContinue: Bool {
        true
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What's your email?")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("We'll use this to create your account")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TextField("Enter your email address", text: $signUpData.email)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isValidEmail ? Color.green : Color.appBorder, lineWidth: 1)
                    )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                
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

// MARK: - Phone Step
struct PhoneStepView: View {
    @Binding var signUpData: SignUpData
    let onNext: () -> Void
    
    private var isValidPhone: Bool {
        true
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Enter your phone number")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("One account per number")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            TextField("(555) 123-4567", text: $signUpData.phoneNumber)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.appCardBackground)
                .foregroundColor(Color.appPrimaryText)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValidPhone ? Color.green : Color.appBorder, lineWidth: 1)
                )
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .onChange(of: signUpData.phoneNumber) { newValue in
                    // Format phone number
                    signUpData.phoneNumber = formatPhoneNumber(newValue)
                }
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isValidPhone ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
            }
            .disabled(!isValidPhone)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "(XXX) XXX-XXXX"
        var result = ""
        var index = cleaned.startIndex
        
        for ch in mask where index < cleaned.endIndex {
            if ch == "X" {
                result.append(cleaned[index])
                index = cleaned.index(after: index)
            } else {
                result.append(ch)
            }
        }
        
        return result
    }
}

// MARK: - Password Step
struct PasswordStepView: View {
    @Binding var signUpData: SignUpData
    let onNext: () -> Void
    @State private var showPassword = false
    
    private var isValidPassword: Bool {
        true
    }
    
    private var passwordStrength: PasswordStrength {
        let password = signUpData.password
        if password.count < 8 { return .weak }
        if password.count >= 8 && password.rangeOfCharacter(from: .decimalDigits) != nil { return .medium }
        if password.count >= 8 && 
           password.rangeOfCharacter(from: .decimalDigits) != nil &&
           password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
           password.rangeOfCharacter(from: .lowercaseLetters) != nil { return .strong }
        return .medium
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Create a password")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("Must be at least 8 characters")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Group {
                        if showPassword {
                            TextField("Enter your password", text: $signUpData.password)
                        } else {
                            SecureField("Enter your password", text: $signUpData.password)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .textContentType(.newPassword)
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .padding(.trailing, 16)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValidPassword ? Color.green : Color.appBorder, lineWidth: 1)
                )
                .cornerRadius(12)
                
                // Password Strength Indicator
                if !signUpData.password.isEmpty {
                    HStack {
                        ForEach(0..<3, id: \.self) { index in
                            Rectangle()
                                .fill(index < passwordStrength.rawValue ? passwordStrength.color : Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Text(passwordStrength.description)
                        .font(.caption)
                        .foregroundColor(passwordStrength.color)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(Color.appButtonText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isValidPassword ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                    .cornerRadius(12)
            }
            .disabled(!isValidPassword)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

enum PasswordStrength: Int, CaseIterable {
    case weak = 1
    case medium = 2
    case strong = 3
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak password"
        case .medium: return "Medium strength"
        case .strong: return "Strong password"
        }
    }
}

// MARK: - SMS Verification Step
struct SMSVerificationStepView: View {
    @EnvironmentObject var appState: AppState
    @Binding var signUpData: SignUpData
    let onComplete: () -> Void
    @State private var timeRemaining = 60
    @State private var canResend = false
    @State private var isVerifying = false
    
    private var isValidCode: Bool {
        true
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appAccentBlue)
                
                Text("Enter verification code")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("We sent a 6-digit code to")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                Text(signUpData.phoneNumber)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimaryText)
            }
            
            VStack(spacing: 20) {
                // 6-digit code input
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitView(
                            digit: getDigit(at: index),
                            isFilled: index < signUpData.smsCode.count
                        )
                    }
                }
                .onTapGesture {
                    // Focus on hidden text field for easier input
                }
                
                // Hidden text field for actual input
                TextField("", text: $signUpData.smsCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .opacity(0)
                    .frame(height: 1)
                    .onChange(of: signUpData.smsCode) { newValue in
                        if newValue.count > 6 {
                            signUpData.smsCode = String(newValue.prefix(6))
                        }
                    }
                
                // Paste from clipboard
                Button("Paste from Clipboard") {
                    if let clipboardString = UIPasteboard.general.string,
                       clipboardString.count == 6,
                       clipboardString.allSatisfy({ $0.isNumber }) {
                        signUpData.smsCode = clipboardString
                    }
                }
                .font(.subheadline)
                .foregroundColor(Color.appAccentBlue)
                
                // Resend code
                HStack {
                    if canResend {
                        Button("Resend Code") {
                            resendCode()
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.appAccentBlue)
                    } else {
                        Text("Resend code in \(timeRemaining)s")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: verifyCode) {
                HStack {
                    if isVerifying {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Color.appButtonText)
                    } else {
                        Text("Verify")
                            .font(.headline)
                            .foregroundColor(Color.appButtonText)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isValidCode ? Color.appAccentBlue : Color.appAccentBlue.opacity(0.6))
                .cornerRadius(12)
            }
            .disabled(!isValidCode || isVerifying)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            startTimer()
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < signUpData.smsCode.count else { return "" }
        return String(signUpData.smsCode[signUpData.smsCode.index(signUpData.smsCode.startIndex, offsetBy: index)])
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    
    private func resendCode() {
        timeRemaining = 60
        canResend = false
        signUpData.smsCode = ""
        startTimer()
        // Handle resend logic
    }
    
    private func verifyCode() {
        isVerifying = true
        // Simulate verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isVerifying = false
            // Complete sign up with collected data
            appState.signUp(name: "User", email: signUpData.email, password: signUpData.password)
            onComplete()
        }
    }
}

struct CodeDigitView: View {
    let digit: String
    let isFilled: Bool
    
    var body: some View {
        Text(digit)
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(Color.appPrimaryText)
            .frame(width: 40, height: 50)
            .background(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFilled ? Color.appAccentBlue : Color.appBorder, lineWidth: 2)
            )
            .cornerRadius(8)
    }
}

#Preview {
    NewAuthenticationView()
        .environmentObject(AppState())
}