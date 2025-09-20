import Foundation
import SwiftUI
import Combine

// SWARM 2.0 ForceQUIT - Animation Controller
// Manages all visual effects, particle systems, and transitions

@MainActor
class AnimationControllerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentAnimationState: AnimationState = .idle
    @Published var particleEffects: [ParticleEffect] = []
    @Published var glowIntensity: Double = 0.7
    @Published var backgroundAnimation: BackgroundAnimation = .staticGradient
    @Published var isAnimating: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let animationQueue = DispatchQueue(label: "com.forceQUIT.animations", qos: .userInitiated)
    private var activeAnimations: Set<UUID> = []
    private let performanceOptimizer = PerformanceOptimizer.shared
    private var displayLink: CADisplayLink?
    private var isAnimationLoopActive = false
    
    // Performance monitoring
    private var frameRate: Double = 60.0
    private var lastFrameTime: Date = Date()
    
    init() {
        setupAnimationLoop()
        setupPerformanceOptimizationListeners()
    }
    
    // MARK: - Animation States
    enum AnimationState {
        case idle
        case scanning
        case forceQuitting(processName: String)
        case batchProcessing
        case systemCritical
        case success
        case error
    }
    
    // MARK: - Animation Setup
    private func setupAnimationLoop() {
        // Demand-driven animation loop - only runs when needed
        // CADisplayLink provides better performance than Timer
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimations))
        displayLink?.preferredFramesPerSecond = 60 // Will be dynamically adjusted
        displayLink?.isPaused = true // Start paused - activate only when needed
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func setupPerformanceOptimizationListeners() {
        // Listen for particle effect limits
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LimitParticleEffects"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let maxCount = notification.userInfo?["maxCount"] as? Int {
                self?.limitParticleEffects(to: maxCount)
            }
        }
        
        // Listen for clear effects command
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearAllEffects"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearAllEffects()
        }
        
        // Monitor performance optimizer state
        performanceOptimizer.$frameRate
            .sink { [weak self] frameRate in
                self?.adjustFrameRate(to: frameRate)
            }
            .store(in: &cancellables)
    }
    
    @objc private func updateAnimations() {
        let now = Date()
        let deltaTime = now.timeIntervalSince(lastFrameTime)
        lastFrameTime = now
        
        // Update frame rate calculation
        frameRate = 1.0 / deltaTime
        
        // Update particle effects
        particleEffects = particleEffects.compactMap { effect in
            effect.update(deltaTime: deltaTime)
        }
        
        // Clean up finished effects
        particleEffects.removeAll { $0.isFinished }
        
        // Update background animation
        updateBackgroundAnimation(deltaTime: deltaTime)
        
        // Update glow intensity based on system state
        updateGlowIntensity()
        
        // Auto-pause animation loop when no effects are active
        if particleEffects.isEmpty && currentAnimationState == .idle {
            stopAnimationLoop()
        }
    }
    
    // MARK: - Performance Optimization Methods
    private func startAnimationLoop() {
        guard !isAnimationLoopActive else { return }
        isAnimationLoopActive = true
        displayLink?.isPaused = false
    }
    
    private func stopAnimationLoop() {
        guard isAnimationLoopActive else { return }
        isAnimationLoopActive = false
        displayLink?.isPaused = true
    }
    
    private func adjustFrameRate(to frameRate: Double) {
        displayLink?.preferredFramesPerSecond = Int(frameRate)
        
        // Auto-pause when frame rate drops to minimum
        if frameRate <= 1.0 {
            stopAnimationLoop()
        } else if !isAnimationLoopActive && !particleEffects.isEmpty {
            startAnimationLoop()
        }
    }
    
    private func limitParticleEffects(to maxCount: Int) {
        if particleEffects.count > maxCount {
            // Keep the most recent effects
            particleEffects = Array(particleEffects.suffix(maxCount))
        }
    }
    
    private func clearAllEffects() {
        particleEffects.removeAll()
        stopAnimationLoop()
        
        // Reset animation state
        withAnimation(.easeOut(duration: 0.3)) {
            currentAnimationState = .idle
            glowIntensity = 0.3
        }
    }
    
    // MARK: - Force Quit Animation
    func animateForceQuit(for processName: String, at position: CGPoint) {
        currentAnimationState = .forceQuitting(processName: processName)
        
        // Create particle explosion effect
        let explosionEffect = ParticleEffect(
            id: UUID(),
            type: .explosion,
            position: position,
            color: .red,
            particleCount: 50,
            duration: 2.0
        )
        
        particleEffects.append(explosionEffect)
        
        // Start animation loop for effects
        startAnimationLoop()
        
        // Animate UI feedback
        withAnimation(.easeOut(duration: 0.5)) {
            glowIntensity = 1.0
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.resetToIdle()
        }
    }
    
    func animateBatchForceQuit(processCount: Int) {
        currentAnimationState = .batchProcessing
        
        // Create multiple particle effects
        for i in 0..<min(processCount, 10) { // Limit visual effects
            let delay = Double(i) * 0.1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                let randomPosition = CGPoint(
                    x: Double.random(in: 100...700),
                    y: Double.random(in: 100...500)
                )
                
                let effect = ParticleEffect(
                    id: UUID(),
                    type: .sparkles,
                    position: randomPosition,
                    color: .orange,
                    particleCount: 20,
                    duration: 1.5
                )
                
                self?.particleEffects.append(effect)
                self?.startAnimationLoop()
            }
        }
        
        // Reset after all animations
        let totalDuration = Double(min(processCount, 10)) * 0.1 + 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.resetToIdle()
        }
    }
    
    // MARK: - System State Animations
    func animateSystemCritical() {
        currentAnimationState = .systemCritical
        backgroundAnimation = .pulsing
        
        // Red pulsing glow effect
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
    
    func animateScanning() {
        currentAnimationState = .scanning
        backgroundAnimation = .sweeping
        
        // Subtle blue glow
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            glowIntensity = 0.5
        }
    }
    
    func animateSuccess() {
        currentAnimationState = .success
        
        // Green success particle burst
        let successEffect = ParticleEffect(
            id: UUID(),
            type: .success,
            position: CGPoint(x: 400, y: 300), // Center of screen
            color: .green,
            particleCount: 30,
            duration: 3.0
        )
        
        particleEffects.append(successEffect)
        startAnimationLoop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.resetToIdle()
        }
    }
    
    func animateError(message: String) {
        currentAnimationState = .error
        
        // Red error shake effect
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            // Shake animation would be handled by the view
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.resetToIdle()
        }
    }
    
    // MARK: - Background Animation
    private func updateBackgroundAnimation(deltaTime: TimeInterval) {
        // Update background animation based on current style
        // This would control gradient movement, particle systems, etc.
    }
    
    private func updateGlowIntensity() {
        // Dynamically adjust glow based on system state and user preferences
        let baseIntensity: Double
        
        switch currentAnimationState {
        case .idle:
            baseIntensity = 0.3
        case .scanning:
            baseIntensity = 0.5
        case .forceQuitting:
            baseIntensity = 1.0
        case .batchProcessing:
            baseIntensity = 0.8
        case .systemCritical:
            baseIntensity = 1.0
        case .success:
            baseIntensity = 0.7
        case .error:
            baseIntensity = 0.9
        }
        
        // Smooth interpolation to target intensity
        if abs(glowIntensity - baseIntensity) > 0.01 {
            withAnimation(.easeInOut(duration: 0.3)) {
                glowIntensity = baseIntensity
            }
        }
    }
    
    // MARK: - State Management
    private func resetToIdle() {
        withAnimation(.easeOut(duration: 0.5)) {
            currentAnimationState = .idle
            backgroundAnimation = .staticGradient
            glowIntensity = 0.7
        }
    }
    
    // MARK: - Performance Monitoring
    var currentFrameRate: Double {
        return frameRate
    }
    
    var activeEffectCount: Int {
        return particleEffects.count
    }
    
    func optimizeForPerformance() {
        // Reduce particle count and effects for better performance
        particleEffects = Array(particleEffects.prefix(5))
        
        // Switch to lower quality animations
        backgroundAnimation = .staticGradient
    }
}

// MARK: - Particle Effect Model
struct ParticleEffect: Identifiable {
    let id: UUID
    let type: ParticleType
    var position: CGPoint
    let color: Color
    let particleCount: Int
    let duration: TimeInterval
    private(set) var elapsedTime: TimeInterval = 0
    
    var isFinished: Bool {
        return elapsedTime >= duration
    }
    
    var progress: Double {
        return min(elapsedTime / duration, 1.0)
    }
    
    mutating func update(deltaTime: TimeInterval) -> ParticleEffect? {
        elapsedTime += deltaTime
        return isFinished ? nil : self
    }
    
    enum ParticleType {
        case explosion
        case sparkles
        case success
        case warning
        case smoke
    }
}

// MARK: - Background Animation Types
enum BackgroundAnimation {
    case staticGradient
    case pulsing
    case sweeping
    case particleField
    case waves
    
    var description: String {
        switch self {
        case .staticGradient: return "Static gradient background"
        case .pulsing: return "Pulsing gradient animation"
        case .sweeping: return "Sweeping light effect"
        case .particleField: return "Floating particle field"
        case .waves: return "Animated wave patterns"
        }
    }
}