//
//  MainTabView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea(.all)
                
                // Custom view switching without swipe gestures
                ZStack {
                    Group {
                        switch selectedTab {
                        case 0:
                            DashboardView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                        case 1:
                            ReportsView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                        case 2:
                            CalendarView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                        case 3:
                            ProfileView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                        default:
                            DashboardView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
                .overlay(
                    VStack {
                        Spacer()
                        
                        CustomFloatingTabBar(selection: $selectedTab)
                            .padding(.horizontal, 24)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    }
                )
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

// MARK: - Custom Floating Tab Bar for Main App
struct CustomFloatingTabBar: View {
    @Binding var selection: Int
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 16) {
                    // Dashboard Tab Button
                    CustomTabButton(
                        customIcon: selection == 0 ? AnyView(CustomHomeIconFilled(size: 16)) : AnyView(CustomHomeIcon(size: 16)),
                        isSelected: selection == 0,
                        accessibilityLabel: "Dashboard"
                    ) {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                            selection = 0
                        }
                        hapticFeedback()
                    }
                    
                    // Jobs Tab Button
                    CustomTabButton(
                        customIcon: selection == 1 ? AnyView(CustomJobsIconFilled(size: 16)) : AnyView(CustomJobsIcon(size: 16)),
                        isSelected: selection == 1,
                        accessibilityLabel: "Jobs"
                    ) {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                            selection = 1
                        }
                        hapticFeedback()
                    }
                    
                    // Calendar Tab Button
                    CustomTabButton(
                        customIcon: selection == 2 ? AnyView(CustomCalendarIconFilled(size: 16)) : AnyView(CustomCalendarIcon(size: 16)),
                        isSelected: selection == 2,
                        accessibilityLabel: "Calendar"
                    ) {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                            selection = 2
                        }
                        hapticFeedback()
                    }
                    
                    // Profile Tab Button
                    CustomTabButton(
                        customIcon: selection == 3 ? AnyView(CustomProfileIconFilled(size: 16)) : AnyView(CustomProfileIcon(size: 16)),
                        isSelected: selection == 3,
                        accessibilityLabel: "Profile"
                    ) {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                            selection = 3
                        }
                        hapticFeedback()
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width - 48, height: 48)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial, style: FillStyle())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 48)
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Custom Tab Button
struct CustomTabButton: View {
    let icon: String?
    let customIcon: AnyView?
    let isSelected: Bool
    let accessibilityLabel: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    // Convenience initializer for system icons
    init(icon: String, isSelected: Bool, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.customIcon = nil
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    // Initializer for custom icons
    init<Content: View>(customIcon: Content, isSelected: Bool, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = nil
        self.customIcon = AnyView(customIcon)
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if let customIcon = customIcon {
                    customIcon
                        .foregroundColor(isSelected ? Color.appAccentBlue : Color.appTertiaryText)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.newYork(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? Color.appAccentBlue : Color.appTertiaryText)
                }
            }
            .frame(width: 36, height: 36)
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.7, blendDuration: 0.1), value: isPressed)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8, blendDuration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}