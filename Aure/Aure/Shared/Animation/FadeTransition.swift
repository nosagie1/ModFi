import SwiftUI

public struct FadeTransition: ViewModifier {
    let duration: TimeInterval
    let delay: TimeInterval
    let scale: CGFloat
    
    @State private var isVisible = false
    
    public init(
        duration: TimeInterval = 0.2,
        delay: TimeInterval = 0.0,
        scale: CGFloat = 0.92
    ) {
        self.duration = duration
        self.delay = delay
        self.scale = scale
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : scale)
            .animation(.easeInOut(duration: duration), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

// Screen transition modifier with enhanced effects
public struct ScreenTransition: ViewModifier {
    let duration: TimeInterval
    let delay: TimeInterval
    let scale: CGFloat
    let offset: CGFloat
    
    @State private var isVisible = false
    
    public init(
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0.0,
        scale: CGFloat = 0.92,
        offset: CGFloat = 20
    ) {
        self.duration = duration
        self.delay = delay
        self.scale = scale
        self.offset = offset
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : scale)
            .offset(y: isVisible ? 0 : offset)
            .animation(.easeOut(duration: duration), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

// Staggered animation for lists
public struct StaggeredAnimation: ViewModifier {
    let index: Int
    let itemDelay: TimeInterval
    let baseDuration: TimeInterval
    let baseDelay: TimeInterval
    
    @State private var isVisible = false
    
    public init(
        index: Int,
        itemDelay: TimeInterval = 0.05,
        baseDuration: TimeInterval = 0.3,
        baseDelay: TimeInterval = 0.1
    ) {
        self.index = index
        self.itemDelay = itemDelay
        self.baseDuration = baseDuration
        self.baseDelay = baseDelay
    }
    
    private var totalDelay: TimeInterval {
        baseDelay + (Double(index) * itemDelay)
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.easeOut(duration: baseDuration), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

// Slide transition for modal presentations
public struct SlideTransition: ViewModifier {
    let direction: SlideDirection
    let duration: TimeInterval
    let delay: TimeInterval
    
    @State private var isVisible = false
    
    public enum SlideDirection {
        case left, right, up, down
    }
    
    public init(
        direction: SlideDirection = .up,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0.0
    ) {
        self.direction = direction
        self.duration = duration
        self.delay = delay
    }
    
    private var offsetValue: CGSize {
        switch direction {
        case .left:
            return CGSize(width: isVisible ? 0 : -50, height: 0)
        case .right:
            return CGSize(width: isVisible ? 0 : 50, height: 0)
        case .up:
            return CGSize(width: 0, height: isVisible ? 0 : -50)
        case .down:
            return CGSize(width: 0, height: isVisible ? 0 : 50)
        }
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(offsetValue)
            .animation(.easeOut(duration: duration), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

// Convenience extensions
public extension View {
    func fadeTransition(
        duration: TimeInterval = 0.2,
        delay: TimeInterval = 0.0,
        scale: CGFloat = 0.92
    ) -> some View {
        modifier(FadeTransition(duration: duration, delay: delay, scale: scale))
    }
    
    func screenTransition(
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0.0,
        scale: CGFloat = 0.92,
        offset: CGFloat = 20
    ) -> some View {
        modifier(ScreenTransition(duration: duration, delay: delay, scale: scale, offset: offset))
    }
    
    func staggeredAnimation(
        index: Int,
        itemDelay: TimeInterval = 0.05,
        baseDuration: TimeInterval = 0.3,
        baseDelay: TimeInterval = 0.1
    ) -> some View {
        modifier(StaggeredAnimation(
            index: index,
            itemDelay: itemDelay,
            baseDuration: baseDuration,
            baseDelay: baseDelay
        ))
    }
    
    func slideTransition(
        direction: SlideTransition.SlideDirection = .up,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0.0
    ) -> some View {
        modifier(SlideTransition(direction: direction, duration: duration, delay: delay))
    }
}