import SwiftUI

public struct SpringyButtonStyle: ButtonStyle {
    let liftHeight: CGFloat
    let scaleEffect: CGFloat
    let hapticFeedback: Bool
    let animationDuration: TimeInterval
    
    public init(
        liftHeight: CGFloat = 6,
        scaleEffect: CGFloat = 0.95,
        hapticFeedback: Bool = true,
        animationDuration: TimeInterval = 0.15
    ) {
        self.liftHeight = liftHeight
        self.scaleEffect = scaleEffect
        self.hapticFeedback = hapticFeedback
        self.animationDuration = animationDuration
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .offset(y: configuration.isPressed ? liftHeight : 0)
            .shadow(
                color: Color.black.opacity(0.3),
                radius: configuration.isPressed ? 2 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 8
            )
            .animation(.spring(response: animationDuration, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hapticFeedback {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
    }
}

// Convenience extension
public extension ButtonStyle where Self == SpringyButtonStyle {
    static var springy: SpringyButtonStyle {
        SpringyButtonStyle()
    }
    
    static func springy(
        liftHeight: CGFloat = 6,
        scaleEffect: CGFloat = 0.95,
        hapticFeedback: Bool = true,
        animationDuration: TimeInterval = 0.15
    ) -> SpringyButtonStyle {
        SpringyButtonStyle(
            liftHeight: liftHeight,
            scaleEffect: scaleEffect,
            hapticFeedback: hapticFeedback,
            animationDuration: animationDuration
        )
    }
}

// Ripple effect modifier for additional visual feedback
public struct RippleEffect: View {
    @State private var isAnimating = false
    let trigger: Bool
    let color: Color
    let size: CGFloat
    
    public init(trigger: Bool, color: Color = .white.opacity(0.3), size: CGFloat = 50) {
        self.trigger = trigger
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: isAnimating ? size : 0, height: isAnimating ? size : 0)
            .scaleEffect(isAnimating ? 1.5 : 0)
            .opacity(isAnimating ? 0 : 1)
            .animation(.easeOut(duration: 0.4), value: isAnimating)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    isAnimating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isAnimating = false
                    }
                }
            }
    }
}

// Mini ripple button style with ripple effect
public struct SpringyRippleButtonStyle: ButtonStyle {
    let liftHeight: CGFloat
    let scaleEffect: CGFloat
    let hapticFeedback: Bool
    let animationDuration: TimeInterval
    let rippleColor: Color
    
    @State private var showRipple = false
    
    public init(
        liftHeight: CGFloat = 6,
        scaleEffect: CGFloat = 0.95,
        hapticFeedback: Bool = true,
        animationDuration: TimeInterval = 0.15,
        rippleColor: Color = .white.opacity(0.3)
    ) {
        self.liftHeight = liftHeight
        self.scaleEffect = scaleEffect
        self.hapticFeedback = hapticFeedback
        self.animationDuration = animationDuration
        self.rippleColor = rippleColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .offset(y: configuration.isPressed ? liftHeight : 0)
            .shadow(
                color: Color.black.opacity(0.3),
                radius: configuration.isPressed ? 2 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 8
            )
            .overlay(
                RippleEffect(trigger: showRipple, color: rippleColor)
                    .allowsHitTesting(false)
            )
            .animation(.spring(response: animationDuration, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    showRipple = true
                    if hapticFeedback {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
    }
}

public extension ButtonStyle where Self == SpringyRippleButtonStyle {
    static var springyRipple: SpringyRippleButtonStyle {
        SpringyRippleButtonStyle()
    }
    
    static func springyRipple(
        liftHeight: CGFloat = 6,
        scaleEffect: CGFloat = 0.95,
        hapticFeedback: Bool = true,
        animationDuration: TimeInterval = 0.15,
        rippleColor: Color = .white.opacity(0.3)
    ) -> SpringyRippleButtonStyle {
        SpringyRippleButtonStyle(
            liftHeight: liftHeight,
            scaleEffect: scaleEffect,
            hapticFeedback: hapticFeedback,
            animationDuration: animationDuration,
            rippleColor: rippleColor
        )
    }
}