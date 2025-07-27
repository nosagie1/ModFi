import SwiftUI

extension Font {
    // MARK: - New York Font System
    
    // New York Large Titles
    static var newYorkLargeTitle: Font {
        .custom("NewYorkLarge-Regular", size: 34)
    }
    
    static var newYorkLargeTitleBold: Font {
        .custom("NewYorkLarge-Bold", size: 34)
    }
    
    // New York Titles
    static var newYorkTitle: Font {
        .custom("NewYorkMedium-Regular", size: 28)
    }
    
    static var newYorkTitleBold: Font {
        .custom("NewYorkMedium-Bold", size: 28)
    }
    
    static var newYorkTitle2: Font {
        .custom("NewYorkMedium-Regular", size: 22)
    }
    
    static var newYorkTitle2Bold: Font {
        .custom("NewYorkMedium-Bold", size: 22)
    }
    
    static var newYorkTitle3: Font {
        .custom("NewYorkMedium-Regular", size: 20)
    }
    
    static var newYorkTitle3Bold: Font {
        .custom("NewYorkMedium-Bold", size: 20)
    }
    
    // New York Headlines
    static var newYorkHeadline: Font {
        .custom("NewYorkMedium-Semibold", size: 17)
    }
    
    static var newYorkHeadlineBold: Font {
        .custom("NewYorkMedium-Bold", size: 17)
    }
    
    // New York Body Text
    static var newYorkBody: Font {
        .custom("NewYorkSmall-Regular", size: 17)
    }
    
    static var newYorkBodyBold: Font {
        .custom("NewYorkSmall-Bold", size: 17)
    }
    
    static var newYorkBodySemibold: Font {
        .custom("NewYorkSmall-Semibold", size: 17)
    }
    
    // New York Subheadlines
    static var newYorkSubheadline: Font {
        .custom("NewYorkSmall-Regular", size: 15)
    }
    
    static var newYorkSubheadlineBold: Font {
        .custom("NewYorkSmall-Bold", size: 15)
    }
    
    static var newYorkSubheadlineSemibold: Font {
        .custom("NewYorkSmall-Semibold", size: 15)
    }
    
    // New York Callouts
    static var newYorkCallout: Font {
        .custom("NewYorkSmall-Regular", size: 16)
    }
    
    static var newYorkCalloutBold: Font {
        .custom("NewYorkSmall-Bold", size: 16)
    }
    
    // New York Footnotes
    static var newYorkFootnote: Font {
        .custom("NewYorkSmall-Regular", size: 13)
    }
    
    static var newYorkFootnoteBold: Font {
        .custom("NewYorkSmall-Bold", size: 13)
    }
    
    // New York Captions
    static var newYorkCaption: Font {
        .custom("NewYorkSmall-Regular", size: 12)
    }
    
    static var newYorkCaptionBold: Font {
        .custom("NewYorkSmall-Bold", size: 12)
    }
    
    static var newYorkCaption2: Font {
        .custom("NewYorkSmall-Regular", size: 11)
    }
    
    // Custom size New York fonts
    static func newYork(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .ultraLight, .thin, .light:
            return .custom("NewYorkSmall-Regular", size: size)
        case .regular:
            return .custom("NewYorkSmall-Regular", size: size)
        case .medium:
            return .custom("NewYorkMedium-Regular", size: size)
        case .semibold:
            return .custom("NewYorkSmall-Semibold", size: size)
        case .bold:
            return .custom("NewYorkSmall-Bold", size: size)
        case .heavy, .black:
            return .custom("NewYorkSmall-Bold", size: size)
        default:
            return .custom("NewYorkSmall-Regular", size: size)
        }
    }
    
    // MARK: - Convenience Methods for Common App Text Styles
    
    // Dashboard specific fonts
    static var dashboardLargeNumber: Font {
        .custom("NewYorkLarge-Bold", size: 48)
    }
    
    static var dashboardMediumNumber: Font {
        .custom("NewYorkMedium-Bold", size: 32)
    }
    
    static var dashboardSmallNumber: Font {
        .custom("NewYorkMedium-Regular", size: 24)
    }
    
    // Card and section titles
    static var cardTitle: Font {
        .custom("NewYorkMedium-Bold", size: 24)
    }
    
    static var sectionTitle: Font {
        .custom("NewYorkMedium-Semibold", size: 20)
    }
    
    // Form and input fonts
    static var formLabel: Font {
        .custom("NewYorkSmall-Semibold", size: 15)
    }
    
    static var formInput: Font {
        .custom("NewYorkSmall-Regular", size: 17)
    }
    
    // Button fonts
    static var buttonText: Font {
        .custom("NewYorkSmall-Semibold", size: 17)
    }
    
    static var smallButtonText: Font {
        .custom("NewYorkSmall-Semibold", size: 15)
    }
    
    // MARK: - Serif Header Font System (Georgia-based)
    
    // Serif Headers - Semi-bold weight for elegance
    static var serifLargeTitle: Font {
        .custom("Georgia-Bold", size: 34)
    }
    
    static var serifTitle: Font {
        .custom("Georgia-Bold", size: 28)
    }
    
    static var serifTitle2: Font {
        .custom("Georgia-Bold", size: 22)
    }
    
    static var serifTitle3: Font {
        .custom("Georgia-Bold", size: 20)
    }
    
    static var serifHeadline: Font {
        .custom("Georgia-Bold", size: 17)
    }
    
    // Custom size serif fonts - always bold for headers (semi-bold effect)
    static func serif(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size)
    }
    
    // Header-specific serif fonts for different sections
    static var pageTitle: Font {
        .custom("Georgia-Bold", size: 32)
    }
    
    static var sectionHeader: Font {
        .custom("Georgia-Bold", size: 24)
    }
    
    static var cardHeader: Font {
        .custom("Georgia-Bold", size: 20)
    }
    
    static var subHeader: Font {
        .custom("Georgia-Bold", size: 18)
    }
}

// MARK: - Text Style Extension for Consistency
extension Text {
    func newYorkStyle(_ font: Font) -> some View {
        self.font(font)
    }
}