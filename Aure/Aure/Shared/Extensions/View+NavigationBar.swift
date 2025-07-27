import SwiftUI
import UIKit

extension View {
    /// Configures navigation bar with translucent appearance
    func translucentNavigationBar() -> some View {
        self.onAppear {
            configureTranslucentNavigationBar()
        }
    }
    
    /// Configures navigation bar with custom translucent style and colors
    func customTranslucentNavigationBar(
        backgroundColor: UIColor = UIColor.systemBackground.withAlphaComponent(0.8),
        titleColor: UIColor = .label,
        tintColor: UIColor = .systemBlue
    ) -> some View {
        self.onAppear {
            configureCustomTranslucentNavigationBar(
                backgroundColor: backgroundColor,
                titleColor: titleColor,
                tintColor: tintColor
            )
        }
    }
}

private func configureTranslucentNavigationBar() {
    let appearance = UINavigationBarAppearance()
    
    // Configure translucent background
    appearance.configureWithDefaultBackground()
    appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
    
    // Enable blur effect
    appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
    
    // Configure title appearance
    appearance.titleTextAttributes = [
        .foregroundColor: UIColor.label,
        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
    ]
    
    appearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor.label,
        .font: UIFont.systemFont(ofSize: 34, weight: .bold)
    ]
    
    // Apply to all navigation bar states
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    
    // Configure translucency
    UINavigationBar.appearance().isTranslucent = true
    UINavigationBar.appearance().tintColor = .systemBlue
}

private func configureCustomTranslucentNavigationBar(
    backgroundColor: UIColor,
    titleColor: UIColor, 
    tintColor: UIColor
) {
    let appearance = UINavigationBarAppearance()
    
    // Configure translucent background with custom color
    appearance.configureWithDefaultBackground()
    appearance.backgroundColor = backgroundColor
    
    // Enable blur effect for translucency
    appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
    
    // Configure title appearance with custom colors
    appearance.titleTextAttributes = [
        .foregroundColor: titleColor,
        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
    ]
    
    appearance.largeTitleTextAttributes = [
        .foregroundColor: titleColor,
        .font: UIFont.systemFont(ofSize: 34, weight: .bold)
    ]
    
    // Apply to all navigation bar states
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance  
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    
    // Configure translucency and tint
    UINavigationBar.appearance().isTranslucent = true
    UINavigationBar.appearance().tintColor = tintColor
}

// Dark theme specific navigation bar
extension View {
    func darkTranslucentNavigationBar() -> some View {
        self.customTranslucentNavigationBar(
            backgroundColor: UIColor.black.withAlphaComponent(0.7),
            titleColor: .white,
            tintColor: .systemBlue
        )
    }
}