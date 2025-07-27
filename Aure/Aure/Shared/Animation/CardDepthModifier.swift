import SwiftUI

public struct CardDepthModifier: ViewModifier {
    let depth: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    
    public init(
        depth: CGFloat = 8,
        shadowRadius: CGFloat = 12,
        shadowOpacity: Double = 0.3
    ) {
        self.depth = depth
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
    }
    
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: depth
            )
    }
}

public struct InteractiveCardDepthModifier: ViewModifier {
    @State private var isPressed = false
    @State private var isHovered = false
    
    let normalDepth: CGFloat
    let pressedDepth: CGFloat
    let hoverDepth: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let animationDuration: TimeInterval
    
    public init(
        normalDepth: CGFloat = 8,
        pressedDepth: CGFloat = 2,
        hoverDepth: CGFloat = 12,
        shadowRadius: CGFloat = 12,
        shadowOpacity: Double = 0.3,
        animationDuration: TimeInterval = 0.2
    ) {
        self.normalDepth = normalDepth
        self.pressedDepth = pressedDepth
        self.hoverDepth = hoverDepth
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.animationDuration = animationDuration
    }
    
    private var currentDepth: CGFloat {
        if isPressed {
            return pressedDepth
        } else if isHovered {
            return hoverDepth
        } else {
            return normalDepth
        }
    }
    
    private var currentScale: CGFloat {
        if isPressed {
            return 0.98
        } else if isHovered {
            return 1.02
        } else {
            return 1.0
        }
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(currentScale)
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: currentDepth
            )
            .animation(.easeInOut(duration: animationDuration), value: currentDepth)
            .animation(.easeInOut(duration: animationDuration), value: currentScale)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// Convenience extension for easy use
public extension View {
    func cardDepth(
        depth: CGFloat = 8,
        shadowRadius: CGFloat = 12,
        shadowOpacity: Double = 0.3
    ) -> some View {
        modifier(CardDepthModifier(
            depth: depth,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity
        ))
    }
    
    func interactiveCardDepth(
        normalDepth: CGFloat = 8,
        pressedDepth: CGFloat = 2,
        hoverDepth: CGFloat = 12,
        shadowRadius: CGFloat = 12,
        shadowOpacity: Double = 0.3,
        animationDuration: TimeInterval = 0.2
    ) -> some View {
        modifier(InteractiveCardDepthModifier(
            normalDepth: normalDepth,
            pressedDepth: pressedDepth,
            hoverDepth: hoverDepth,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity,
            animationDuration: animationDuration
        ))
    }
}