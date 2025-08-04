//
//  ProfileRow.swift
//  Aure
//
//  Profile row component for settings and navigation items
//

import SwiftUI

struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String?
    let showChevron: Bool
    let action: (() -> Void)?
    
    @State private var isPressed = false
    @State private var chevronOffset: CGFloat = 10
    @State private var chevronOpacity: Double = 0
    
    init(icon: String, title: String, value: String? = nil, showChevron: Bool = true, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.appAccentBlue)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.appPrimaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appSecondaryText)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appSecondaryText)
                        .opacity(chevronOpacity)
                        .offset(x: chevronOffset)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                chevronOffset = 0
                chevronOpacity = 0.6
            }
        }
    }
}

// MARK: - Toggle Row for Preferences
struct ProfileToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.appAccentBlue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color.appPrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.appAccentBlue))
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    VStack(spacing: 0) {
        ProfileRow(
            icon: "envelope",
            title: "Email",
            value: "olivia@example.com"
        ) {
            print("Email tapped")
        }
        
        Divider()
        
        ProfileRow(
            icon: "phone",
            title: "Phone",
            value: "+1 (234) 567-8900"
        ) {
            print("Phone tapped")
        }
        
        Divider()
        
        ProfileToggleRow(
            icon: "bell",
            title: "Notifications",
            isOn: .constant(true)
        )
    }
    .background(Color.appBackground)
    .padding()
}