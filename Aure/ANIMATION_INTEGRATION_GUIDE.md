# Aure Animation Integration Guide

## Overview
This guide provides step-by-step instructions for integrating buttery-smooth animations into your SwiftUI payment tracker app.

## 1. Lottie Integration (Optional)

### SPM Installation
```bash
# In Xcode → File > Add Packages...
https://github.com/airbnb/lottie-ios
# Select: Up to Next Major Version 4.x.x
```

### Recommended Animations
Add these Lottie files to your project:
- `confetti.json` - Payment success celebration
- `receipt-pull.json` - Refresh gesture animation  
- `checkmark.json` - Completion confirmations
- `loading-spinner.json` - Loading states

## 2. Project Configuration

### Build Settings
```swift
// Target iOS 17+ for full SwiftUI animation support
IPHONEOS_DEPLOYMENT_TARGET = 17.0

// Enable Metal performance shaders for smooth animations
ENABLE_METAL_PERFORMANCE_SHADERS = YES
```

### Info.plist Settings (Optional)
```xml
<key>UIUserInterfaceStyleForceDark</key>
<true/>
<!-- Ensures consistent dark theme animations -->
```

## 3. Animation Helper Files Structure

Your project should include these files in `Shared/Animation/`:

```
Shared/Animation/
├── CountUpText.swift          # Timeline-based number animations
├── CardDepthModifier.swift    # Interactive depth effects
├── SpringyButtonStyle.swift   # Haptic feedback buttons
├── FadeTransition.swift       # Screen transitions
├── LottieView.swift          # Lottie integration wrapper
└── CanvasAnimations.swift    # Custom Canvas animations
```

## 4. Screen-by-Screen Implementation

### Dashboard (DashboardView.swift)
```swift
// Import animation helpers at top of file
// No additional imports needed - files are part of target

// 1. Replace static currency display
Text(netValue.formatAsCurrency)
// With animated CountUp:
CountUpCurrency(value: .constant(netValue), duration: 0.8)

// 2. Add bar chart stagger animation
Chart {
    ForEach(Array(data.enumerated()), id: \.element.period) { index, data in
        BarMark(...)
            .opacity(1.0) // Animated via onAppear stagger
    }
}
.onAppear {
    for (index, _) in data.enumerated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
            // 40ms stagger between bars
        }
    }
}

// 3. Enhance agency cards with depth
AgencyCard()
    .interactiveCardDepth()

// 4. Add breathing animation to "Add Account" card
AddAccountCard()
    .breatheAnimation(duration: 3.0)
```

### Jobs List (JobsView.swift)
```swift
// 1. Add staggered row animations
List(Array(jobs.enumerated()), id: \.element.id) { index, job in
    JobRow(job: job)
        .staggeredAnimation(index: index, itemDelay: 0.05)
}

// 2. Add Lottie refresh animation (if using Lottie)
.overlay(
    ReceiptPullAnimation(isRefreshing: isLoading)
        .opacity(isLoading ? 1 : 0),
    alignment: .top
)

// 3. Enhance buttons with haptic feedback
Button("Add Job") { ... }
    .buttonStyle(.springyRipple)

// 4. Add pulse to status pills
StatusBadge(status: job.status)
    .pulseAnimation(intensity: 0.2, duration: 0.8, repeatCount: 1)
```

### Job Detail Modal (JobDetailView.swift)
```swift
struct JobDetailView: View {
    // 1. Add matched geometry namespace
    @Namespace private var detailNamespace
    
    var body: some View {
        ScrollView {
            VStack {
                // 2. Add matched geometry to key elements
                Text(job.title)
                    .matchedGeometryEffect(id: "jobTitle-\(job.id)", in: detailNamespace)
                
                // 3. Animate earnings with count-up
                CountUpCurrency(value: .constant(job.totalEarnings))
                    .matchedGeometryEffect(id: "jobAmount-\(job.id)", in: detailNamespace)
                
                // 4. Add slide transition to sections
                pricingSection
                    .slideTransition(direction: .up, duration: 0.4, delay: 0.3)
            }
        }
    }
}
```

### Job Creation Wizard (SimpleJobCreationView.swift)
```swift
// 1. Replace static progress dots
AnimatedProgressDots(
    totalSteps: 2,
    currentStep: currentScreen - 1,
    dotSize: 12,
    activeColor: .blue
)

// 2. Enhance form buttons
Button("Continue to Summary") { ... }
    .buttonStyle(.springyRipple)

// 3. Add shimmer to file upload rows
Text(fileName)
    .skeletonShimmer(when: isLoadingMetadata)
```

### Calendar (CalendarView.swift)
```swift
// 1. Add bounce animation to selected dates
if isSelected {
    RoundedRectangle(cornerRadius: 8)
        .fill(Color.blue)
        .scaleEffect(1.1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
}

// 2. Add dot fade animation
Circle()
    .fill(eventColor)
    .opacity(isSelected ? 0.7 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: isSelected)

// 3. Add pulse to Connect button
Button("Connect") { ... }
    .pulseAnimation(duration: 6.0) // Pulse every 6s until linked
```

## 5. Global Navigation Transitions

### MainTabView.swift Enhancement
```swift
TabView {
    // Add fade transitions between tabs
    DashboardView()
        .fadeTransition()
    
    JobsView()
        .fadeTransition()
    
    CalendarView()
        .fadeTransition()
}
.animation(.easeInOut(duration: 0.2), value: selectedTab)
```

### MainAppView.swift Enhancement
```swift
Group {
    switch appState.currentPhase {
    case .splash:
        SplashView()
            .screenTransition()
    case .main:
        MainTabView()
            .screenTransition(delay: 0.3)
    }
}
```

## 6. Confetti Success Animation (If Using Lottie)

### When Payment Marked as Paid
```swift
.overlay(
    ConfettiLottieView(trigger: paymentMarkedAsPaid)
        .allowsHitTesting(false)
)
```

## 7. Performance Integration

### Add to Main App
```swift
// In development builds only
#if DEBUG
.overlay(
    PerformanceMonitor()
        .opacity(showPerformanceMonitor ? 1 : 0),
    alignment: .topTrailing
)
#endif
```

### Environment-Based Animation Control
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animationDuration: TimeInterval {
    reduceMotion ? 0.1 : 0.8
}
```

## 8. Testing Your Animations

### Performance Testing
1. Enable GPU Frame Capture in Xcode
2. Run on physical device (iPhone 12 minimum)
3. Monitor via Instruments:
   - Time Profiler
   - Core Animation
   - SwiftUI profiling

### Animation Testing Checklist
- [ ] All animations maintain 60fps
- [ ] No memory leaks during repeated animations  
- [ ] Smooth transitions between screens
- [ ] Proper animation cleanup on view disappear
- [ ] Respect accessibility settings (reduce motion)
- [ ] Battery impact remains "Low" in Energy gauge

## 9. Customization Examples

### Custom CountUp Formats
```swift
// Percentage CountUp
CountUpPercentage(value: .constant(progressPercent))

// Custom format CountUp  
CountUpText(value: .constant(value), format: "%.1fK", duration: 1.0)
```

### Custom Card Depths
```swift
// Subtle depth for secondary cards
.cardDepth(depth: 4, shadowRadius: 8, shadowOpacity: 0.15)

// Prominent depth for primary actions
.cardDepth(depth: 12, shadowRadius: 20, shadowOpacity: 0.4)
```

### Custom Button Styles
```swift
// Light haptic feedback
.buttonStyle(.springy(hapticFeedback: true, animationDuration: 0.1))

// Heavy haptic with longer animation
.buttonStyle(.springy(liftHeight: 8, scaleEffect: 0.92, animationDuration: 0.2))
```

## 10. Troubleshooting

### Common Issues
1. **Animations not appearing**: Ensure animation files are in correct target
2. **Performance drops**: Check for animation conflicts or excessive nesting
3. **Matched geometry issues**: Verify unique IDs and proper namespace scope
4. **Lottie not loading**: Confirm animation files are added to bundle

### Debug Mode
```swift
// Add to any animated view for debugging
.onAppear {
    print("🎬 Animation started: \(Self.self)")
}
.onDisappear {
    print("🛑 Animation stopped: \(Self.self)")
}
```

## 11. Extension Guide for Future Features

### Adding New CountUp Variants
```swift
// Create specialized CountUp for your data type
public struct CountUpHours: View {
    @Binding var value: Double
    
    public var body: some View {
        CountUpText(
            value: $value,
            format: "%.1f hrs",
            duration: 0.6
        )
    }
}
```

### iOS 18 Future Enhancements
- Plan migration to Interactive Transitions API
- Utilize enhanced SwiftUI 6.0 animation modifiers
- Implement Metal-accelerated custom transitions

This integration guide ensures smooth implementation of all animation features while maintaining performance and user experience standards.