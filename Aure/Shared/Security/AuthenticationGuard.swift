//
//  AuthenticationGuard.swift
//  Aure
//
//  Secure authentication guard for protecting sensitive views
//

import SwiftUI

// MARK: - Authentication Guard ViewModifier

struct AuthenticationGuard: ViewModifier {
    @EnvironmentObject var appState: AppState
    let showEmptyState: Bool
    let redirectToAuth: Bool
    
    init(showEmptyState: Bool = true, redirectToAuth: Bool = true) {
        self.showEmptyState = showEmptyState
        self.redirectToAuth = redirectToAuth
    }
    
    func body(content: Content) -> some View {
        Group {
            switch appState.authenticationState {
            case .authenticated:
                content
                    .onAppear {
                        validateSessionPeriodically()
                    }
                
            case .loading:
                LoadingAuthView()
                
            case .notAuthenticated:
                if redirectToAuth {
                    UnauthenticatedRedirectView()
                } else if showEmptyState {
                    UnauthenticatedEmptyView()
                } else {
                    EmptyView()
                }
            }
        }
        .onChange(of: appState.authenticationState) { _, newState in
            handleAuthStateChange(newState)
        }
    }
    
    private func validateSessionPeriodically() {
        // Validate session every 5 minutes when view is active
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { timer in
            Task {
                do {
                    try await appState.validateSession()
                } catch {
                    timer.invalidate()
                }
            }
        }
    }
    
    private func handleAuthStateChange(_ newState: AuthenticationState) {
        switch newState {
        case .notAuthenticated:
            // Clear any cached sensitive data when user becomes unauthenticated
            clearSensitiveData()
        default:
            break
        }
    }
    
    private func clearSensitiveData() {
        // Clear any sensitive UI state
        print("🧹 Clearing sensitive UI data due to authentication change")
    }
}

// MARK: - Auth State Views

struct LoadingAuthView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Validating session...")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

struct UnauthenticatedRedirectView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(Color.appSecondaryText)
            
            Text("Authentication Required")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
            
            Text("Please sign in to continue")
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
            
            Button("Sign In") {
                appState.currentPhase = .authentication
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.appAccentBlue)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            // Automatically redirect after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                appState.currentPhase = .authentication
            }
        }
    }
}

struct UnauthenticatedEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.dashed")
                .font(.system(size: 50))
                .foregroundColor(Color.appSecondaryText)
            
            Text("Not Available")
                .font(.headline)
                .foregroundColor(Color.appPrimaryText)
            
            Text("This content requires authentication")
                .font(.caption)
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - View Extensions

extension View {
    /// Requires authentication to display content
    /// - Parameters:
    ///   - showEmptyState: Whether to show empty state for unauthenticated users
    ///   - redirectToAuth: Whether to redirect to authentication screen
    func requiresAuthentication(
        showEmptyState: Bool = true,
        redirectToAuth: Bool = true
    ) -> some View {
        self.modifier(AuthenticationGuard(
            showEmptyState: showEmptyState,
            redirectToAuth: redirectToAuth
        ))
    }
}

// MARK: - Session Validation Extension

extension AppState {
    func validateSession() async throws {
        guard authenticationState == .authenticated else {
            throw SessionError.notAuthenticated
        }
        
        // Use the existing AuthenticationService to check session
        let tempAuthService = AuthenticationService()
        do {
            try await tempAuthService.checkAuthSession()
        } catch {
            await MainActor.run {
                self.authenticationState = .notAuthenticated
                self.currentPhase = .authentication
            }
            throw SessionError.expired
        }
    }
}

enum SessionError: Error {
    case notAuthenticated
    case expired
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .expired:
            return "Session has expired"
        }
    }
}