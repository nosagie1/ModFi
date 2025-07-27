//
//  AppState.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import Foundation
import Combine
import Supabase

enum AppPhase {
    case splash
    case onboarding
    case authentication
    case main
}

enum AuthenticationState {
    case notAuthenticated
    case authenticated
    case loading
    
    var errorMessage: String? {
        return nil
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var currentPhase: AppPhase = .splash
    @Published var authenticationState: AuthenticationState = .notAuthenticated
    @Published var authError: String?
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastType: ToastType = .info
    @Published var dataRefreshTrigger = UUID() // For triggering data refresh across views
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthenticationService()
    
    @Published var dataCoordinator = AppDataCoordinator()
    
    // Trigger data refresh across all views
    func triggerDataRefresh() {
        dataRefreshTrigger = UUID()
    }
    
    init() {
        setupAppFlow()
        setupAuthSubscription()
    }
    
    private func setupAppFlow() {
        Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.checkAuthenticationState()
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthSubscription() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.authenticationState = .authenticated
                    self?.currentPhase = .main
                } else {
                    self?.authenticationState = .notAuthenticated
                    self?.currentPhase = .authentication
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAuthenticationState() {
        // Check for existing session instead of forcing re-authentication
        Task {
            do {
                try await authService.checkAuthSession()
                // AuthService will update isAuthenticated, which will trigger setupAuthSubscription
            } catch {
                await MainActor.run {
                    self.currentPhase = .authentication
                    self.authenticationState = .notAuthenticated
                }
            }
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        currentPhase = .authentication
    }
    
    func signIn(email: String, password: String) {
        authenticationState = .loading
        authError = nil
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                await MainActor.run {
                    self.currentPhase = .main
                    self.authError = nil
                    self.showToast(message: "Welcome back!", type: .success)
                }
                
                // Load user data after successful sign in
                await dataCoordinator.loadAllData()
            } catch {
                await MainActor.run {
                    self.authenticationState = .notAuthenticated
                    self.authError = error.localizedDescription
                }
            }
        }
    }
    
    func signUp(name: String, email: String, password: String) {
        authenticationState = .loading
        authError = nil
        
        Task {
            do {
                try await authService.signUp(email: email, password: password, fullName: name)
                await MainActor.run {
                    self.currentPhase = .main
                    self.authError = nil
                    self.showToast(message: "Account created successfully!", type: .success)
                }
                
                // Load user data after successful sign up
                await dataCoordinator.loadAllData()
            } catch {
                await MainActor.run {
                    self.authenticationState = .notAuthenticated
                    self.authError = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                await MainActor.run {
                    self.currentPhase = .authentication
                    self.showToast(message: "Signed out successfully", type: .info)
                }
            } catch {
                await MainActor.run {
                    self.showToast(message: "Sign out failed: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showToast = false
        }
    }
    
    // REMOVED: Mock user function - no dummy data allowed
    // All user data must come from authenticated sessions
}

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var color: String {
        switch self {
        case .success: return "green"
        case .error: return "red"
        case .warning: return "orange"
        case .info: return "blue"
        }
    }
}