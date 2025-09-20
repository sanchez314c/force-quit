import SwiftUI

// SWARM 2.0 ForceQUIT - Animated Background
// Mission Control aesthetic with avant-garde dark design

struct AnimatedBackgroundView: View {
    @State private var animationPhase: Double = 0
    @State private var particleOffset: CGSize = .zero
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Base animated gradient
            animatedGradient
            
            // Floating particles
            particleField
            
            // Subtle grid overlay
            gridOverlay
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animated Gradient
    private var animatedGradient: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.8),
                .blue.opacity(0.1),
                .purple.opacity(0.05),
                .black.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(gradientRotation))
        .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: gradientRotation)
    }
    
    // MARK: - Particle Field
    private var particleField: some View {
        Canvas { context, size in
            for i in 0..<50 {
                let x = Double(i) * size.width / 50 + particleOffset.width
                let y = sin(animationPhase + Double(i) * 0.5) * 30 + size.height / 2
                
                let opacity = sin(animationPhase + Double(i) * 0.3) * 0.5 + 0.5
                
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: x.truncatingRemainder(dividingBy: size.width),
                        y: y,
                        width: 2,
                        height: 2
                    )),
                    with: .color(.white.opacity(opacity * 0.3))
                )
            }
        }
        .blendMode(.screen)
        .animation(.linear(duration: 30).repeatForever(autoreverses: false), value: particleOffset)
    }
    
    // MARK: - Grid Overlay
    private var gridOverlay: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 40
            let lineWidth: CGFloat = 0.5
            let opacity = 0.1
            
            // Vertical lines
            for i in stride(from: 0, to: size.width, by: gridSpacing) {
                let path = Path { path in
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: size.height))
                }
                context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: lineWidth)
            }
            
            // Horizontal lines
            for i in stride(from: 0, to: size.height, by: gridSpacing) {
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: size.width, y: i))
                }
                context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: lineWidth)
            }
        }
        .blendMode(.overlay)
    }
    
    // MARK: - Animation Control
    private func startAnimations() {
        // Continuous animation phase for particle movement
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 4
        }
        
        // Particle field drift
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            particleOffset = CGSize(width: 100, height: 0)
        }
        
        // Gradient rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    let effect: ParticleEffect
    
    @State private var particles: [BackgroundParticle] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x - particle.size / 2,
                    y: particle.position.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particle.color.opacity(particle.opacity))
                )
                
                // Add glow effect for explosion particles
                if effect.type == .explosion {
                    context.addFilter(.blur(radius: particle.size * 0.5))
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(particle.opacity * 0.3))
                    )
                }
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func generateParticles() {
        particles = []
        
        for _ in 0..<effect.particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 1...5)
            let size = Double.random(in: 2...8)
            
            let particle = BackgroundParticle(
                position: effect.position,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                color: effect.color,
                size: size,
                opacity: 1.0,
                life: effect.duration
            )
            
            particles.append(particle)
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func updateParticles() {
        let deltaTime = 1.0/60.0
        
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.dx * deltaTime * 10
            particles[i].position.y += particles[i].velocity.dy * deltaTime * 10
            
            // Apply gravity for explosion effects
            if effect.type == .explosion {
                particles[i].velocity.dy += 2.0 * deltaTime // Gravity
            }
            
            // Fade out over time
            particles[i].life -= deltaTime
            particles[i].opacity = max(0, particles[i].life / effect.duration)
            
            // Shrink particles over time
            particles[i].size *= 0.995
        }
        
        // Remove dead particles
        particles.removeAll { $0.life <= 0 }
    }
}

// MARK: - Background Particle Model
struct BackgroundParticle {
    var position: CGPoint
    var velocity: CGVector
    let color: Color
    var size: Double
    var opacity: Double
    var life: TimeInterval
}

// MARK: - Glassmorphism Effect
struct GlassmorphismBackground: View {
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    .white.opacity(0.1),
                    .clear,
                    .black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(intensity)
            
            // Border highlight
            Rectangle()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Pulsing Indicator
struct PulsingIndicator: View {
    let color: Color
    let size: CGFloat
    
    @State private var isPulsing: Bool = false
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 0 : 1)
            
            // Inner circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview
struct AnimatedBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AnimatedBackgroundView()
            
            VStack {
                Text("ForceQUIT")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
                
                PulsingIndicator(color: .blue, size: 20)
            }
        }
        .frame(width: 800, height: 600)
        .preferredColorScheme(.dark)
    }
}