//
//  OnboardingView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    let onboardingPages = [
        OnboardingPage(
            title: "Track Your Jobs",
            description: "Easily manage all your freelance projects and contracts in one place",
            imageName: "folder.fill"
        ),
        OnboardingPage(
            title: "Manage Agencies",
            description: "Keep track of your client relationships and agency contacts",
            imageName: "building.2.fill"
        ),
        OnboardingPage(
            title: "Monitor Payments",
            description: "Never miss a payment deadline with our tracking system",
            imageName: "creditcard.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)
                
                HStack {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        if currentPage < onboardingPages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            appState.completeOnboarding()
                        }
                    }) {
                        Text(currentPage < onboardingPages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        appState.completeOnboarding()
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}