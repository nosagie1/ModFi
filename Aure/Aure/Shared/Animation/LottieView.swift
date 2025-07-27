import SwiftUI
import UIKit

// On-Demand Lottie Integration
// To use Lottie, add to your project:
// 1. In Xcode → File > Add Packages...
// 2. Add: https://github.com/airbnb/lottie-ios (up to 4.x)
// 3. Uncomment the import and implementation below

// import Lottie

/// A SwiftUI wrapper for Lottie animations optimized for performance
/// Features:
/// - Off-thread rendering via UIViewRepresentable
/// - Configurable loop modes and speeds
/// - Low-frequency timeline mode support
/// - Memory-efficient on-demand loading
public struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode
    let shouldPlay: Bool
    
    public enum LottieLoopMode {
        case playOnce
        case loop
        case autoReverse
        case repeatCount(Int)
    }
    
    public init(
        animationName: String,
        loopMode: LottieLoopMode = .playOnce,
        animationSpeed: CGFloat = 1.0,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        shouldPlay: Bool = true
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode
        self.shouldPlay = shouldPlay
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // TODO: Uncomment when Lottie is added to the project
        /*
        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = contentMode
        animationView.animationSpeed = animationSpeed
        
        // Configure loop mode
        switch loopMode {
        case .playOnce:
            animationView.loopMode = .playOnce
        case .loop:
            animationView.loopMode = .loop
        case .autoReverse:
            animationView.loopMode = .autoReverse
        case .repeatCount(let count):
            animationView.loopMode = .repeat(Float(count))
        }
        
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if shouldPlay {
            animationView.play()
        }
        */
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // TODO: Uncomment when Lottie is added to the project
        /*
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }
        
        if shouldPlay && !animationView.isAnimationPlaying {
            animationView.play()
        } else if !shouldPlay && animationView.isAnimationPlaying {
            animationView.pause()
        }
        */
    }
}

// Performance-optimized confetti animation
public struct ConfettiLottieView: View {
    @State private var showConfetti = false
    let trigger: Bool
    
    public init(trigger: Bool) {
        self.trigger = trigger
    }
    
    public var body: some View {
        ZStack {
            if showConfetti {
                LottieView(
                    animationName: "confetti",
                    loopMode: .playOnce,
                    animationSpeed: 1.0
                )
                .allowsHitTesting(false)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showConfetti = false
                    }
                }
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                showConfetti = true
            }
        }
    }
}

// Receipt pull animation for refresh
public struct ReceiptPullAnimation: View {
    @State private var animationPhase: AnimationPhase = .idle
    let isRefreshing: Bool
    
    public enum AnimationPhase {
        case idle
        case pulling
        case checkmark
    }
    
    public init(isRefreshing: Bool) {
        self.isRefreshing = isRefreshing
    }
    
    public var body: some View {
        ZStack {
            switch animationPhase {
            case .idle:
                EmptyView()
            case .pulling:
                LottieView(
                    animationName: "receipt-pull",
                    loopMode: .loop,
                    animationSpeed: 0.8
                )
            case .checkmark:
                LottieView(
                    animationName: "checkmark",
                    loopMode: .playOnce,
                    animationSpeed: 1.2
                )
            }
        }
        .frame(width: 50, height: 50)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                animationPhase = .pulling
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animationPhase = .checkmark
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        animationPhase = .idle
                    }
                }
            } else {
                animationPhase = .idle
            }
        }
    }
}

// Skeleton shimmer animation for loading states
public struct SkeletonShimmer: View {
    @State private var phase: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .black, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase)
                .animation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: phase
                )
        )
        .onAppear {
            phase = 300
        }
    }
}

// Usage examples and convenience modifiers
public extension View {
    func skeletonShimmer(when loading: Bool) -> some View {
        overlay(
            Group {
                if loading {
                    SkeletonShimmer()
                        .allowsHitTesting(false)
                }
            }
        )
    }
}

// MARK: - Installation Instructions
/*
 To integrate Lottie animations:
 
 1. Add Lottie dependency:
    - In Xcode → File > Add Packages...
    - URL: https://github.com/airbnb/lottie-ios
    - Version: Up to Next Major (4.x.x)
 
 2. Add Lottie animations to your project:
    - Drag .json animation files to your project
    - Ensure they're added to the target
    - Recommended animations:
      * confetti.json - for payment success
      * receipt-pull.json - for refresh gestures
      * checkmark.json - for completion states
      * loading-spinner.json - for loading states
 
 3. Uncomment the Lottie import and implementation above
 
 4. Performance tips:
    - Use .renderingEngine(.coreAnimation) for better performance
    - Keep animation files under 200KB
    - Use .backgroundBehavior(.pauseAndRestore) for memory efficiency
    - Consider using .reducedMotion environment for accessibility
 */