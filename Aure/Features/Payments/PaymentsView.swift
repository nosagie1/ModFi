//
//  PaymentsView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct PaymentsView: View {
    @State private var showingUpcoming = false
    @State private var showingOverdue = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text("Track your upcoming and overdue payments")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Payment Cards
                    VStack(spacing: 16) {
                        // Upcoming Payments Card
                        PaymentOverviewCard(
                            title: "Upcoming Payments",
                            subtitle: "Scheduled payments",
                            icon: "calendar.circle.fill",
                            iconColor: .blue,
                            action: {
                                showingUpcoming = true
                            }
                        )
                        
                        // Overdue Payments Card
                        PaymentOverviewCard(
                            title: "Overdue Payments",
                            subtitle: "Past due payments",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .red,
                            action: {
                                showingOverdue = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 100) // Space for tab bar
            }
            .navigationTitle("Payments")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingUpcoming) {
                UpcomingPaymentsView()
            }
            .sheet(isPresented: $showingOverdue) {
                OverduePaymentsView()
            }
        }
    }
}

struct PaymentOverviewCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Color.appSecondaryText)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}