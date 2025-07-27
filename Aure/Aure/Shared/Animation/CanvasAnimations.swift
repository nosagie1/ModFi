import SwiftUI

// Canvas-based sparkline with stroke animation
public struct AnimatedSparkline: View {
    let data: [Double]
    let lineColor: Color
    let strokeWidth: CGFloat
    let animationDuration: TimeInterval
    let animationDelay: TimeInterval
    
    @State private var trimEnd: CGFloat = 0
    
    public init(
        data: [Double],
        lineColor: Color = .blue,
        strokeWidth: CGFloat = 2,
        animationDuration: TimeInterval = 1.0,
        animationDelay: TimeInterval = 0.0
    ) {
        self.data = data
        self.lineColor = lineColor
        self.strokeWidth = strokeWidth
        self.animationDuration = animationDuration
        self.animationDelay = animationDelay
    }
    
    public var body: some View {
        Canvas { context, size in
            guard data.count > 1 else { return }
            
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue
            
            // Create path
            var path = Path()
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
                let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            // Draw the path with trim animation
            context.stroke(
                path.trimmedPath(from: 0, to: trimEnd),
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                withAnimation(.easeOut(duration: animationDuration)) {
                    trimEnd = 1.0
                }
            }
        }
        .onDisappear {
            trimEnd = 0
        }
    }
}

// Animated dashed border for "Add Account" card
public struct DashedBorderAnimation: View {
    let cornerRadius: CGFloat
    let dashLength: CGFloat
    let dashGap: CGFloat
    let lineWidth: CGFloat
    let color: Color
    let animationSpeed: TimeInterval
    
    @State private var phase: CGFloat = 0
    
    public init(
        cornerRadius: CGFloat = 12,
        dashLength: CGFloat = 8,
        dashGap: CGFloat = 4,
        lineWidth: CGFloat = 2,
        color: Color = .gray,
        animationSpeed: TimeInterval = 2.0
    ) {
        self.cornerRadius = cornerRadius
        self.dashLength = dashLength
        self.dashGap = dashGap
        self.lineWidth = lineWidth
        self.color = color
        self.animationSpeed = animationSpeed
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    dash: [dashLength, dashGap],
                    dashPhase: phase
                )
            )
            .onAppear {
                withAnimation(.linear(duration: animationSpeed).repeatForever(autoreverses: false)) {
                    phase = dashLength + dashGap
                }
            }
    }
}

// Breathe animation for gentle scaling effects
public struct BreatheAnimation: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: TimeInterval
    
    @State private var isAnimating = false
    
    public init(
        minScale: CGFloat = 0.98,
        maxScale: CGFloat = 1.02,
        duration: TimeInterval = 2.0
    ) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? maxScale : minScale)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// Pulse animation for status indicators
public struct PulseAnimation: ViewModifier {
    let intensity: CGFloat
    let duration: TimeInterval
    let repeatCount: Int?
    
    @State private var isPulsing = false
    @State private var currentCount = 0
    
    public init(
        intensity: CGFloat = 0.3,
        duration: TimeInterval = 1.0,
        repeatCount: Int? = nil
    ) {
        self.intensity = intensity
        self.duration = duration
        self.repeatCount = repeatCount
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 1.0 - intensity : 1.0)
            .animation(
                .easeInOut(duration: duration),
                value: isPulsing
            )
            .onAppear {
                startPulsing()
            }
    }
    
    private func startPulsing() {
        if let maxCount = repeatCount, currentCount >= maxCount {
            return
        }
        
        isPulsing = true
        currentCount += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isPulsing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                startPulsing()
            }
        }
    }
}

// Progress dots animation with matched geometry
public struct AnimatedProgressDots: View {
    let totalSteps: Int
    let currentStep: Int
    let dotSize: CGFloat
    let spacing: CGFloat
    let activeColor: Color
    let inactiveColor: Color
    
    @Namespace private var progressNamespace
    
    public init(
        totalSteps: Int,
        currentStep: Int,
        dotSize: CGFloat = 12,
        spacing: CGFloat = 16,
        activeColor: Color = .blue,
        inactiveColor: Color = .gray.opacity(0.3)
    ) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.dotSize = dotSize
        self.spacing = spacing
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? activeColor : inactiveColor)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(step == currentStep ? 1.3 : 1.0)
                    .matchedGeometryEffect(
                        id: step == currentStep ? "activeDot" : "dot\(step)",
                        in: progressNamespace
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
            }
        }
    }
}

// Chart bar grow animation with stagger
public struct AnimatedChartBar: View {
    let value: Double
    let maxValue: Double
    let width: CGFloat
    let color: Color
    let cornerRadius: CGFloat
    let animationDelay: TimeInterval
    let animationDuration: TimeInterval
    
    @State private var animatedHeight: CGFloat = 0
    
    public init(
        value: Double,
        maxValue: Double,
        width: CGFloat = 40,
        color: Color = .blue,
        cornerRadius: CGFloat = 6,
        animationDelay: TimeInterval = 0,
        animationDuration: TimeInterval = 0.8
    ) {
        self.value = value
        self.maxValue = maxValue
        self.width = width
        self.color = color
        self.cornerRadius = cornerRadius
        self.animationDelay = animationDelay
        self.animationDuration = animationDuration
    }
    
    private var targetHeight: CGFloat {
        maxValue > 0 ? CGFloat(value / maxValue) * 150 : 0
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.8), color],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: animatedHeight)
            .animation(.easeOut(duration: animationDuration), value: animatedHeight)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    animatedHeight = targetHeight
                }
            }
            .onDisappear {
                animatedHeight = 0
            }
    }
}

// Convenience extensions
public extension View {
    func breatheAnimation(
        minScale: CGFloat = 0.98,
        maxScale: CGFloat = 1.02,
        duration: TimeInterval = 2.0
    ) -> some View {
        modifier(BreatheAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    func pulseAnimation(
        intensity: CGFloat = 0.3,
        duration: TimeInterval = 1.0,
        repeatCount: Int? = nil
    ) -> some View {
        modifier(PulseAnimation(intensity: intensity, duration: duration, repeatCount: repeatCount))
    }
}

// Performance optimizations
public struct PerformanceOptimizedCanvas: View {
    let content: (GraphicsContext, CGSize) -> Void
    
    public init(content: @escaping (GraphicsContext, CGSize) -> Void) {
        self.content = content
    }
    
    public var body: some View {
        Canvas { context, size in
            // Render content directly without filters for better performance
            content(context, size)
        }
        .drawingGroup() // Composite into single layer for better performance
    }
}