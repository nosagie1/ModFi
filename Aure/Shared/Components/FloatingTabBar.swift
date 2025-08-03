import SwiftUI

// MARK: - FloatingTabBar Component
struct FloatingTabBar: View {
    @Binding var selection: Int
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 32) {
                    // Home Tab Button
                    TabButton(
                        icon: "house.fill",
                        isSelected: selection == 0,
                        accessibilityLabel: "Home"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = 0
                        }
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                    
                    // Dashboard Tab Button
                    TabButton(
                        icon: "rectangle.3.offgrid",
                        isSelected: selection == 1,
                        accessibilityLabel: "Dashboard"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = 1
                        }
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width - 48, height: 64)
            .background(
                // Capsule background with ultra thin material
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 64)
    }
}

// MARK: - TabButton Subview
struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let accessibilityLabel: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 44, height: 44)
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Demo ContentView
struct FloatingTabBarContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedTab) {
                // Home View
                VStack {
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Welcome to the home screen")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .tag(0)
                
                // Dashboard View
                VStack {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your analytics and insights")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .overlay(
                // Floating Tab Bar Overlay
                VStack {
                    Spacer()
                    
                    FloatingTabBar(selection: $selectedTab)
                        .padding(.horizontal, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
            )
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

#Preview {
    FloatingTabBarContentView()
}