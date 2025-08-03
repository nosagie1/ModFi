# SwiftUI Animation Performance Optimization Guide

## Overview
This guide provides performance optimization strategies for the buttery-smooth animations implemented in the Aure payment tracker app.

## Performance Targets
- **Frame Rate**: Maintain 60fps (< 16.67ms per frame)
- **Main Thread Time**: < 8ms per frame on iPhone 12
- **Memory Usage**: Efficient animation state management
- **Battery Impact**: Minimize GPU/CPU intensive operations

## Core Optimization Strategies

### 1. Implicit SwiftUI Animations (Preferred)
```swift
// ✅ GOOD: Use SwiftUI's implicit animations
.animation(.easeOut(duration: 0.8), value: animatedValue)

// ❌ AVOID: Manual animation timers
Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
    // Manual animation loop
}
```

### 2. Timeline-Based Animations
```swift
// ✅ GOOD: Use TimelineView for count-up animations
TimelineView(.animation(minimumInterval: 1.0/60.0, paused: false)) { context in
    Text(String(format: format, animatedValue))
}

// Set to low frequency when idle
TimelineView(.animation(minimumInterval: 1.0/30.0, paused: true)) { context in
    // Reduced frequency for idle states
}
```

### 3. Off-Thread Lottie Rendering
```swift
// ✅ GOOD: Use UIViewRepresentable for Lottie
public func makeUIView(context: Context) -> UIView {
    // Lottie animations run on separate thread
    let animationView = LottieAnimationView(name: animationName)
    animationView.backgroundBehavior = .pauseAndRestore
    return containerView
}
```

### 4. Canvas Optimizations
```swift
// ✅ GOOD: Use drawingGroup() for complex drawings
Canvas { context, size in
    // Complex drawing operations
}
.drawingGroup() // Composites into single layer
```

### 5. Matched Geometry Effect Best Practices
```swift
// ✅ GOOD: Use specific IDs and limit scope
.matchedGeometryEffect(id: "jobTitle-\(job.id)", in: detailNamespace)

// ❌ AVOID: Generic IDs that cause conflicts
.matchedGeometryEffect(id: "title", in: namespace)
```

## Animation-Specific Optimizations

### CountUpText Performance
- Use `TimelineView(.animation)` instead of manual timers
- Set `minimumInterval` based on animation needs
- Pause timeline when view is off-screen

### Card Depth Effects
- Use `shadow()` modifier instead of multiple layers
- Limit shadow radius and opacity
- Consider using `.compositingGroup()` for complex shadows

### List Animations
- Use `staggeredAnimation()` with reasonable delays (< 0.1s)
- Avoid animating large lists (> 50 items) simultaneously
- Implement cell recycling for long lists

### Canvas Animations
- Use `Canvas` for custom drawings requiring animation
- Implement `drawingGroup()` for performance
- Cache complex paths when possible

## Profiling and Monitoring

### Instruments Integration
1. **SwiftUI → View Body Impact**: Monitor view update frequency
2. **Time Profiler**: Identify main thread bottlenecks
3. **Core Animation**: Track layer composition issues
4. **Energy Log**: Monitor battery impact

### Performance Checklist
- [ ] Animations maintain 60fps during scrolling
- [ ] No dropped frames during transitions
- [ ] Memory usage stable during repeated animations
- [ ] CPU usage < 30% during heavy animations
- [ ] Battery impact classified as "Low" in Energy gauge

### Common Performance Issues

#### Issue 1: Animation Stuttering
```swift
// ❌ PROBLEM: Animating too many properties
.animation(.default, value: state)

// ✅ SOLUTION: Animate specific properties
.animation(.easeOut(duration: 0.3), value: position)
.animation(.spring(), value: scale)
```

#### Issue 2: Memory Leaks in Animations
```swift
// ❌ PROBLEM: Retaining animation state
@State private var animationTimer: Timer?

// ✅ SOLUTION: Use SwiftUI lifecycle
.onAppear { startAnimation() }
.onDisappear { stopAnimation() }
```

#### Issue 3: Excessive Redraws
```swift
// ❌ PROBLEM: Unnecessary view updates
.onReceive(timer) { _ in
    // Updates entire view hierarchy
}

// ✅ SOLUTION: Localized state updates
.onChange(of: animatedValue) { _, newValue in
    // Only affected views update
}
```

## SF Symbols Optimization
```swift
// ✅ GOOD: Use palette rendering mode
Image(systemName: "star.fill")
    .renderingMode(.palette)
    .symbolRenderingMode(.palette)
    .foregroundStyle(.primary, .secondary)
```

## Animation State Management
```swift
// ✅ GOOD: Clean animation state
.onDisappear {
    animationValue = 0
    isAnimating = false
}

// Group related animations
struct AnimationState {
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var offset: CGFloat = 0
}
```

## Battery Optimization
- Use `.lowPowerMode` environment to reduce animations
- Implement animation duration scaling based on device performance
- Pause animations when app backgrounds
- Use efficient easing curves (avoid complex bezier curves)

## Testing Performance
```swift
// Performance testing helper
struct PerformanceMonitor: View {
    @State private var frameCount = 0
    @State private var lastTime = CACurrentMediaTime()
    
    var body: some View {
        TimelineView(.animation) { context in
            let currentTime = CACurrentMediaTime()
            let deltaTime = currentTime - lastTime
            let fps = 1.0 / deltaTime
            
            Text("FPS: \(Int(fps))")
                .onAppear {
                    lastTime = currentTime
                }
        }
    }
}
```

## Accessibility Considerations
- Respect `UIAccessibility.isReduceMotionEnabled`
- Provide non-animated alternatives
- Ensure animations don't interfere with VoiceOver

## Future iOS 18 Optimizations
- Plan migration to Interactive Transitions API
- Utilize enhanced Metal performance shaders
- Implement SwiftUI 6.0 animation improvements

## Performance Monitoring Script
```bash
#!/bin/bash
# Run performance monitoring during development
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.apple.CoreAnimation"' | grep -E "(dropped|hitch)"
```

This guide ensures the Aure app maintains buttery-smooth 60fps animations while preserving battery life and providing an exceptional user experience.