//
//  ToastView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct ToastView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(Color.appButtonText)
            
            Text(appState.toastMessage)
                .font(.subheadline)
                .foregroundColor(Color.appButtonText)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 4)
    }
    
    private var iconName: String {
        switch appState.toastType {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch appState.toastType {
        case .success:
            return Color.appSuccess
        case .error:
            return Color.appError
        case .warning:
            return Color.appWarning
        case .info:
            return Color.appAccentBlue
        }
    }
}