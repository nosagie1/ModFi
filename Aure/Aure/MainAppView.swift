//
//  MainAppView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Dark background for entire app
            Color.appBackground
                .ignoresSafeArea(.all)
            
            Group {
                switch appState.currentPhase {
                case .splash:
                    SplashView()
                case .onboarding:
                    NewOnboardingView()
                case .authentication:
                    NewAuthenticationView()
                case .main:
                    MainTabView()
                }
            }
        }
        .overlay(
            ToastView()
                .opacity(appState.showToast ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: appState.showToast)
                .padding(.top, 50)
                .padding(.horizontal, 20),
            alignment: .top
        )
        .preferredColorScheme(.dark)
        .darkTranslucentNavigationBar()
    }
}