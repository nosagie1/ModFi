import SwiftUI

extension Color {
    // MARK: - Dark Theme Colors
    
    // Background Colors
    static let darkBackground = Color(red: 0.06, green: 0.06, blue: 0.06) // #0F0F0F
    static let darkSecondaryBackground = Color(red: 0.11, green: 0.11, blue: 0.11) // #1C1C1C
    static let darkCardBackground = Color(red: 0.15, green: 0.15, blue: 0.15) // #262626
    
    // Text Colors
    static let darkPrimaryText = Color.white
    static let darkSecondaryText = Color(red: 0.8, green: 0.8, blue: 0.8) // #CCCCCC
    static let darkTertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    
    // Accent Colors (keeping some brand colors visible)
    static let darkAccentBlue = Color(red: 0.2, green: 0.6, blue: 1.0) // Brighter blue for dark mode
    static let darkAccentPurple = Color(red: 0.6, green: 0.4, blue: 1.0) // Brighter purple for dark mode
    static let darkSuccess = Color(red: 0.2, green: 0.8, blue: 0.4) // Bright green
    static let darkWarning = Color(red: 1.0, green: 0.8, blue: 0.2) // Bright yellow
    static let darkError = Color(red: 1.0, green: 0.4, blue: 0.4) // Bright red
    
    // Border and Divider Colors
    static let darkBorder = Color(red: 0.25, green: 0.25, blue: 0.25) // #404040
    static let darkDivider = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    
    // Button Colors
    static let darkButtonBackground = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    static let darkButtonText = Color.white
    
    // MARK: - Theme-aware computed properties
    
    static var appBackground: Color {
        return darkBackground
    }
    
    static var appSecondaryBackground: Color {
        return darkSecondaryBackground
    }
    
    static var appCardBackground: Color {
        return darkCardBackground
    }
    
    static var appPrimaryText: Color {
        return darkPrimaryText
    }
    
    static var appSecondaryText: Color {
        return darkSecondaryText
    }
    
    static var appTertiaryText: Color {
        return darkTertiaryText
    }
    
    static var appAccentBlue: Color {
        return darkAccentBlue
    }
    
    static var appAccentPurple: Color {
        return darkAccentPurple
    }
    
    static var appSuccess: Color {
        return darkSuccess
    }
    
    static var appWarning: Color {
        return darkWarning
    }
    
    static var appError: Color {
        return darkError
    }
    
    static var appBorder: Color {
        return darkBorder
    }
    
    static var appDivider: Color {
        return darkDivider
    }
    
    static var appButtonBackground: Color {
        return darkButtonBackground
    }
    
    static var appButtonText: Color {
        return darkButtonText
    }
}