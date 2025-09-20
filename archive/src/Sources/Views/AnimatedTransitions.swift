import SwiftUI
import AppKit
import AppKit

// SWARM 2.0 ForceQUIT - Animated Transitions and Gesture System
// Advanced animation and gesture recognition for Mission Control interface

// MARK: - Custom Transitions
struct MissionControlTransitions {
    // Quantum fade transition with particle effects
    static let quantumFade = AnyTransition.asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.8)),
        removal: .opacity.combined(with: .scale(scale: 1.2))
    )
    
    // Holographic slide transition
    static let holographicSlide = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    // Matrix dissolve effect
    static let matrixDissolve = AnyTransition.modifier(
        active: MatrixDissolveModifier(progress: 1.0),
        identity: MatrixDissolveModifier(progress: 0.0)
    )
    
    // Energy field expansion
    static let energyExpansion = AnyTransition.modifier(
        active: EnergyExpansionModifier(progress: 1.0),
        identity: EnergyExpansionModifier(progress: 0.0)
    )
    
    // Constellation zoom
    static let constellationZoom = AnyTransition.scale(scale: 0.1, anchor: .center)
        .combined(with: .opacity)
        .animation(.spring(response: 0.8, dampingFraction: 0.6))
}

// MARK: - Matrix Dissolve Modifier
struct MatrixDissolveModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(1.0 - progress)
            .scaleEffect(1.0 + progress * 0.2)
            .overlay {
                // Matrix-style digital rain effect during transition
                if progress > 0 {
                    DigitalRainOverlay(intensity: progress)
                }
            }
    }
}

struct DigitalRainOverlay: View {
    let intensity: Double
    @State private var rainPhase: Double = 0
    
    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / 20)
            
            for column in 0..<columns {
                let x = CGFloat(column) * 20 + 10
                let drops = Int(intensity * 10) + 1
                
                for drop in 0..<drops {
                    let y = CGFloat(drop) * 30 + CGFloat(rainPhase).truncatingRemainder(dividingBy: size.height)
                    let alpha = (1.0 - Double(drop) / Double(drops)) * intensity
                    
                    context.draw(
                        Text(String(format: "%X", Int.random(in: 0...15)))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.green.opacity(alpha)),
                        at: CGPoint(x: x, y: y)
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rainPhase = 1000
            }
        }
    }
}

// MARK: - Energy Expansion Modifier
struct EnergyExpansionModifier: ViewModifier {
    let progress: Double
    @State private var energyRings: [EnergyRing] = []
    
    func body(content: Content) -> some View {
        content
            .opacity(1.0 - progress)
            .overlay {
                // Energy rings expanding outward
                ForEach(energyRings.indices, id: \.self) { index in
                    if index < energyRings.count {
                        Circle()
                            .stroke(
                                .cyan.opacity(energyRings[index].opacity),
                                lineWidth: 2
                            )
                            .scaleEffect(energyRings[index].scale)
                            .position(x: energyRings[index].position.x, y: energyRings[index].position.y)
                    }
                }
            }
            .onAppear {
                generateEnergyRings()
                animateEnergyRings()
            }
    }
    
    private func generateEnergyRings() {
        energyRings = (0..<5).map { i in
            EnergyRing(
                scale: 0.1,
                opacity: 0.8,
                position: CGPoint(x: 100, y: 100),
                delay: Double(i) * 0.2
            )
        }
    }
    
    private func animateEnergyRings() {
        for (index, ring) in energyRings.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + ring.delay) {
                withAnimation(.easeOut(duration: 1.5)) {
                    energyRings[index].scale = 3.0
                    energyRings[index].opacity = 0.0
                }
            }
        }
    }
}

struct EnergyRing {
    var scale: CGFloat
    var opacity: Double
    var position: CGPoint
    let delay: Double
}

// MARK: - Multi-Modal Gesture Recognizer
class MissionControlGestureRecognizer: NSGestureRecognizer {
    enum GestureType {
        case tap
        case doubleTap
        case longPress
        case swipe(direction: SwipeDirection)
        case pinch(scale: CGFloat)
        case rotate(angle: CGFloat)
        case multiTouch(touches: Int)
    }
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    var gestureCallback: ((GestureType) -> Void)?
    
    private var initialTouchCount = 0
    private var touchStartTime: Date?
    private var initialLocation: CGPoint = .zero
    private var lastScale: CGFloat = 1.0
    private var lastRotation: CGFloat = 0.0
    
    // Mouse event handling for macOS
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        initialTouchCount = 1
        touchStartTime = Date()
        initialLocation = event.locationInWindow
        
        state = .began
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let currentLocation = event.locationInWindow
        
        state = .changed
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        guard let startTime = touchStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        let endLocation = event.locationInWindow
        let deltaX = endLocation.x - initialLocation.x
        let deltaY = endLocation.y - initialLocation.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        
        // Determine gesture type based on duration and movement
        if duration < 0.2 && distance < 10 {
            // Quick tap
            gestureCallback?(.tap)
        } else if duration < 0.5 && distance > 50 {
            // Swipe gesture
            let swipeDirection: SwipeDirection
            if abs(deltaX) > abs(deltaY) {
                swipeDirection = deltaX > 0 ? .right : .left
            } else {
                swipeDirection = deltaY > 0 ? .down : .up
            }
            gestureCallback?(.swipe(direction: swipeDirection))
        } else if duration >= 0.5 && distance < 20 {
            // Long press
            gestureCallback?(.longPress)
        }
        
        state = .ended
    }
    
    // Handle cancelled gestures
    override func reset() {
        super.reset()
        state = .cancelled
        touchStartTime = nil
        initialLocation = .zero
        lastScale = 1.0
        lastRotation = 0.0
    }
    
    // MARK: - Trackpad and Multi-Touch Support
    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        
        let scale = 1.0 + event.magnification
        if abs(scale - lastScale) > 0.05 {
            gestureCallback?(.pinch(scale: CGFloat(scale)))
            lastScale = CGFloat(scale)
        }
        
        state = .changed
    }
    
    override func rotate(with event: NSEvent) {
        super.rotate(with: event)
        
        let rotation = event.rotation
        if abs(CGFloat(rotation) - lastRotation) > 0.1 {
            gestureCallback?(.rotate(angle: CGFloat(rotation)))
            lastRotation = CGFloat(rotation)
        }
        
        state = .changed
    }
    
    // Handle scroll events as swipe gestures
    func handleScrollWheel(with event: NSEvent) {
        
        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        
        // Only handle significant scroll movements
        if abs(deltaX) > 10 || abs(deltaY) > 10 {
            let swipeDirection: SwipeDirection
            if abs(deltaX) > abs(deltaY) {
                swipeDirection = deltaX > 0 ? .right : .left
            } else {
                swipeDirection = deltaY > 0 ? .up : .down
            }
            gestureCallback?(.swipe(direction: swipeDirection))
        }
        
        state = .changed
    }
}

// MARK: - SwiftUI Gesture Extensions
extension View {
    // Advanced multi-modal gesture support
    func multiModalGestures(
        onTap: @escaping () -> Void = {},
        onDoubleTap: @escaping () -> Void = {},
        onLongPress: @escaping () -> Void = {},
        onSwipe: @escaping (MissionControlGestureRecognizer.SwipeDirection) -> Void = { _ in },
        onPinch: @escaping (CGFloat) -> Void = { _ in },
        onRotate: @escaping (CGFloat) -> Void = { _ in },
        onMultiTouch: @escaping (Int) -> Void = { _ in }
    ) -> some View {
        self.gesture(
            SimultaneousGesture(
                // Tap gesture
                TapGesture()
                    .onEnded { onTap() },
                
                SimultaneousGesture(
                    // Long press gesture
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in onLongPress() },
                    
                    SimultaneousGesture(
                        // Magnification gesture
                        MagnificationGesture()
                            .onChanged { scale in onPinch(scale) },
                        
                        // Rotation gesture
                        RotationGesture()
                            .onChanged { angle in onRotate(CGFloat(angle.radians)) }
                    )
                )
            )
        )
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
    
    // Quantum state transition
    func quantumTransition<V: Equatable>(
        _ value: V,
        animation: Animation = .spring(response: 0.5, dampingFraction: 0.7)
    ) -> some View {
        self.animation(animation, value: value)
            .transition(MissionControlTransitions.quantumFade)
    }
    
    // Holographic appearance
    func holographicAppearance() -> some View {
        self.transition(MissionControlTransitions.holographicSlide)
            .animation(.spring(response: 0.6, dampingFraction: 0.8))
    }
    
    // Matrix-style entrance
    func matrixEntrance() -> some View {
        self.transition(MissionControlTransitions.matrixDissolve)
            .animation(.easeInOut(duration: 1.2))
    }
}

// MARK: - Haptic Feedback System
class MissionControlHaptics {
    static let shared = MissionControlHaptics()
    private let feedbackGenerator = NSHapticFeedbackManager.defaultPerformer
    
    private init() {}
    
    func playSelectionFeedback() {
        feedbackGenerator.perform(.levelChange, performanceTime: .default)
    }
    
    func playImpactFeedback() {
        feedbackGenerator.perform(.generic, performanceTime: .default)
    }
    
    func playWarningFeedback() {
        feedbackGenerator.perform(.alignment, performanceTime: .default)
    }
    
    func playErrorFeedback() {
        // Custom pattern for errors
        DispatchQueue.main.async {
            self.feedbackGenerator.perform(.generic, performanceTime: .default)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.feedbackGenerator.perform(.generic, performanceTime: .default)
            }
        }
    }
    
    func playSuccessFeedback() {
        feedbackGenerator.perform(.levelChange, performanceTime: .default)
    }
}

// MARK: - Particle System for Animations
struct ParticleSystemView: View {
    @State private var particles: [MissionControlParticle] = []
    @State private var animationTimer: Timer?
    
    let particleCount: Int
    let emissionRate: Double
    let particleLifetime: Double
    let colors: [Color]
    let particleSize: CGFloat
    let velocity: CGPoint
    let acceleration: CGPoint
    
    init(
        particleCount: Int = 50,
        emissionRate: Double = 10,
        particleLifetime: Double = 3.0,
        colors: [Color] = [.cyan, .green],
        particleSize: CGFloat = 3.0,
        velocity: CGPoint = CGPoint(x: 0, y: -50),
        acceleration: CGPoint = CGPoint(x: 0, y: 10)
    ) {
        self.particleCount = particleCount
        self.emissionRate = emissionRate
        self.particleLifetime = particleLifetime
        self.colors = colors
        self.particleSize = particleSize
        self.velocity = velocity
        self.acceleration = acceleration
    }
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let alpha = max(0, 1.0 - particle.age / particleLifetime)
                let particleColor = particle.color.opacity(alpha)
                
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: particle.position.x - particleSize/2,
                        y: particle.position.y - particleSize/2,
                        width: particleSize,
                        height: particleSize
                    )),
                    with: .color(particleColor)
                )
            }
        }
        .onAppear {
            startParticleSystem()
        }
        .onDisappear {
            stopParticleSystem()
        }
    }
    
    private func startParticleSystem() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateParticles()
            
            // Emit new particles
            if particles.count < particleCount && Double.random(in: 0...60) < emissionRate {
                let newParticle = MissionControlParticle(
                    position: CGPoint(x: 200, y: 300), // Center emission
                    velocity: CGPoint(
                        x: velocity.x + Double.random(in: -20...20),
                        y: velocity.y + Double.random(in: -10...10)
                    ),
                    acceleration: acceleration,
                    color: colors.randomElement() ?? .white,
                    age: 0
                )
                particles.append(newParticle)
            }
        }
    }
    
    private func stopParticleSystem() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateParticles() {
        let deltaTime = 1.0/60.0
        
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            
            // Update physics
            updatedParticle.velocity.x += acceleration.x * deltaTime
            updatedParticle.velocity.y += acceleration.y * deltaTime
            
            updatedParticle.position.x += updatedParticle.velocity.x * deltaTime
            updatedParticle.position.y += updatedParticle.velocity.y * deltaTime
            
            updatedParticle.age += deltaTime
            
            // Remove dead particles
            return updatedParticle.age < particleLifetime ? updatedParticle : nil
        }
    }
}

struct MissionControlParticle {
    var position: CGPoint
    var velocity: CGPoint
    var acceleration: CGPoint
    var color: Color
    var age: Double
}

// MARK: - Interactive Animation Controllers
class InteractiveAnimationController: ObservableObject {
    @Published var transitionProgress: Double = 0.0
    @Published var isAnimating: Bool = false
    @Published var currentGesture: MissionControlGestureRecognizer.GestureType?
    
    private var displayLink: Timer?
    private var startTime: CFTimeInterval = 0
    private var duration: Double = 1.0

    func startTransition(duration: Double = 1.0, completion: @escaping () -> Void = {}) {
        self.duration = duration
        self.isAnimating = true
        self.startTime = CACurrentMediaTime()

        displayLink?.invalidate()
        // Use Timer instead of CADisplayLink (not available on macOS)
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
        
        // Completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isAnimating = false
            self.transitionProgress = 1.0
            self.displayLink?.invalidate()
            completion()
        }
    }
    
    @objc private func updateAnimation() {
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - startTime
        let progress = min(elapsed / duration, 1.0)
        
        // Easing function for smooth animation
        let easedProgress = easeInOutCubic(progress)
        
        DispatchQueue.main.async {
            self.transitionProgress = easedProgress
        }
        
        if progress >= 1.0 {
            displayLink?.invalidate()
        }
    }
    
    private func easeInOutCubic(_ t: Double) -> Double {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
    
    func handleGesture(_ gesture: MissionControlGestureRecognizer.GestureType) {
        currentGesture = gesture
        
        // Trigger haptic feedback based on gesture
        switch gesture {
        case .tap:
            MissionControlHaptics.shared.playSelectionFeedback()
        case .doubleTap:
            MissionControlHaptics.shared.playImpactFeedback()
        case .longPress:
            MissionControlHaptics.shared.playWarningFeedback()
        case .swipe:
            MissionControlHaptics.shared.playImpactFeedback()
        case .pinch, .rotate:
            // No haptic for continuous gestures
            break
        case .multiTouch:
            MissionControlHaptics.shared.playSuccessFeedback()
        }
        
        // Clear gesture after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentGesture = nil
        }
    }
}