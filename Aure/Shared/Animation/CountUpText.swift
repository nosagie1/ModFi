import SwiftUI

public struct CountUpText: View {
    @Binding var value: Double
    let format: String
    let duration: TimeInterval
    let animationDelay: TimeInterval
    
    @State private var animatedValue: Double = 0
    @State private var isInitialized = false
    
    public init(
        value: Binding<Double>,
        format: String = "%.0f",
        duration: TimeInterval = 0.8,
        animationDelay: TimeInterval = 0.0
    ) {
        self._value = value
        self.format = format
        self.duration = duration
        self.animationDelay = animationDelay
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0, paused: false)) { context in
            Text(String(format: format, animatedValue))
                .onAppear {
                    if !isInitialized {
                        isInitialized = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                            withAnimation(.easeOut(duration: duration)) {
                                animatedValue = value
                            }
                        }
                    }
                }
                .onChange(of: value) { _, newValue in
                    withAnimation(.easeOut(duration: duration)) {
                        animatedValue = newValue
                    }
                }
        }
    }
}

// Currency-specific CountUp
public struct CountUpCurrency: View {
    @Binding var value: Double
    let duration: TimeInterval
    let animationDelay: TimeInterval
    let useDigitalFont: Bool
    
    public init(
        value: Binding<Double>,
        duration: TimeInterval = 0.8,
        animationDelay: TimeInterval = 0.0,
        useDigitalFont: Bool = false
    ) {
        self._value = value
        self.duration = duration
        self.animationDelay = animationDelay
        self.useDigitalFont = useDigitalFont
    }
    
    public var body: some View {
        if useDigitalFont {
            CountUpDigitalCurrency(
                value: $value,
                duration: duration,
                animationDelay: animationDelay
            )
        } else {
            CountUpText(
                value: $value,
                format: "$%.0f",
                duration: duration,
                animationDelay: animationDelay
            )
        }
    }
}

// Digital/Monospace Currency CountUp with comma formatting
public struct CountUpDigitalCurrency: View {
    @Binding var value: Double
    let duration: TimeInterval
    let animationDelay: TimeInterval
    
    @State private var animatedValue: Double = 0
    @State private var isInitialized = false
    
    public init(
        value: Binding<Double>,
        duration: TimeInterval = 0.8,
        animationDelay: TimeInterval = 0.0
    ) {
        self._value = value
        self.duration = duration
        self.animationDelay = animationDelay
    }
    
    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        let number = NSNumber(value: animatedValue)
        return "$" + (formatter.string(from: number) ?? "0")
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0, paused: false)) { context in
            Text(formattedValue)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .kerning(-1.0) // Tighten letter spacing for digital look
                .onAppear {
                    if !isInitialized {
                        isInitialized = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                            withAnimation(.easeOut(duration: duration)) {
                                animatedValue = value
                            }
                        }
                    }
                }
                .onChange(of: value) { _, newValue in
                    withAnimation(.easeOut(duration: duration)) {
                        animatedValue = newValue
                    }
                }
        }
    }
}

// Percentage-specific CountUp
public struct CountUpPercentage: View {
    @Binding var value: Double
    let duration: TimeInterval
    let animationDelay: TimeInterval
    
    public init(
        value: Binding<Double>,
        duration: TimeInterval = 0.8,
        animationDelay: TimeInterval = 0.0
    ) {
        self._value = value
        self.duration = duration
        self.animationDelay = animationDelay
    }
    
    public var body: some View {
        CountUpText(
            value: $value,
            format: "%.1f%%",
            duration: duration,
            animationDelay: animationDelay
        )
    }
}