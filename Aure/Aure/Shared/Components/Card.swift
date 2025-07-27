//
//  Card.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 2
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 2, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.appCardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.3), radius: shadowRadius, x: 0, y: 1)
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
        }
    }
}

struct BalanceCard: View {
    let title: String
    let amount: String
    let subtitle: String?
    let color: Color
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Spacer()
                    
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                }
                
                Text(amount)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
        }
    }
}