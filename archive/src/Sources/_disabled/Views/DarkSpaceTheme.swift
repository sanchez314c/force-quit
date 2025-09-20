import SwiftUI
import AppKit

// SWARM 2.0 ForceQUIT - Dark Space Theme System
// Avant-garde dark mode visual system with RGB state indicators

// MARK: - Dark Space Color Palette
struct DarkSpaceTheme {
    // Base colors - Deep space blacks and greys
    static let voidBlack = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let deepSpace = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let stardustGrey = Color(red: 0.12, green: 0.12, blue: 0.16)
    static let nebulaGrey = Color(red: 0.16, green: 0.16, blue: 0.20)
    static let cosmicMist = Color(red: 0.20, green: 0.20, blue: 0.24)
    
    // Accent colors - Bright cosmic elements
    static let quantumBlue = Color(red: 0.0, green: 0.7, blue: 1.0)
    static let plasmaGreen = Color(red: 0.0, green: 1.0, blue: 0.6)
    static let fusionOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let antimatterPurple = Color(red: 0.6, green: 0.0, blue: 1.0)
    static let stellarRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    // Surface materials
    static let glassMorphism = Material.ultraThinMaterial
    static let controlSurface = Material.thinMaterial
    static let backgroundMaterial = Material.thickMaterial
    
    // Gradients
    static let voidGradient = LinearGradient(
        colors: [voidBlack, deepSpace, stardustGrey],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let energyGradient = LinearGradient(
        colors: [quantumBlue, plasmaGreen, fusionOrange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [fusionOrange, stellarRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let criticalGradient = LinearGradient(
        colors: [stellarRed, antimatterPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - RGB State System (4-Color Process States)
enum RGBProcessState: CaseIterable {
    case idle       // Green - Low activity
    case active     // Blue - Normal operation
    case warning    // Orange - High resource usage
    case critical   // Red - Critical state or unresponsive
    
    var color: Color {
        switch self {
        case .idle:
            return DarkSpaceTheme.plasmaGreen
        case .active:
            return DarkSpaceTheme.quantumBlue
        case .warning:
            return DarkSpaceTheme.fusionOrange
        case .critical:
            return DarkSpaceTheme.stellarRed
        }
    }
    
    var glowColor: Color {
        color.opacity(0.6)
    }
    
    var name: String {
        switch self {
        case .idle: return "Idle"
        case .active: return "Active"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
    
    var description: String {
        switch self {
        case .idle: return "Low activity, minimal resources"
        case .active: return "Normal operation"
        case .warning: return "High resource usage"
        case .critical: return "Critical state or unresponsive"
        }
    }
}

// MARK: - Quantum Glow Modifier
struct QuantumGlowModifier: ViewModifier {
    let color: Color
    let intensity: Double
    @State private var glowPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.6), radius: 4)
            .shadow(color: color.opacity(intensity * 0.4), radius: 8)
            .shadow(color: color.opacity(intensity * 0.2), radius: 16)
            .scaleEffect(1.0 + sin(glowPhase) * 0.02)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPhase = .pi
                }
            }
    }
}

extension View {
    func quantumGlow(color: Color, intensity: Double = 1.0) -> some View {
        self.modifier(QuantumGlowModifier(color: color, intensity: intensity))
    }
}

// MARK: - Holographic Border
struct HolographicBorder: ViewModifier {
    @State private var shimmerPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DarkSpaceTheme.quantumBlue.opacity(0.8),
                                DarkSpaceTheme.plasmaGreen.opacity(0.6),
                                DarkSpaceTheme.quantumBlue.opacity(0.8)
                            ],
                            startPoint: UnitPoint(x: shimmerPhase, y: 0),
                            endPoint: UnitPoint(x: shimmerPhase + 0.3, y: 1)
                        ),
                        lineWidth: 2
                    )
                    .onAppear {
                        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                            shimmerPhase = 1.3
                        }
                    }
            }
    }
}

extension View {
    func holographicBorder() -> some View {
        self.modifier(HolographicBorder())
    }
}

// MARK: - Neon Button Style
struct NeonButtonStyle: ButtonStyle {
    let color: Color
    let isDestructive: Bool
    
    init(color: Color = DarkSpaceTheme.quantumBlue, isDestructive: Bool = false) {
        self.color = isDestructive ? DarkSpaceTheme.stellarRed : color
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 1)
                    }
            }
            .foregroundStyle(color)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .quantumGlow(color: color, intensity: configuration.isPressed ? 0.8 : 0.4)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Cosmic Toggle Style
struct CosmicToggleStyle: ToggleStyle {
    let onColor: Color
    let offColor: Color
    
    init(onColor: Color = DarkSpaceTheme.plasmaGreen, 
         offColor: Color = DarkSpaceTheme.stardustGrey) {
        self.onColor = onColor
        self.offColor = offColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                // Track
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? onColor.opacity(0.3) : offColor.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(configuration.isOn ? onColor : offColor, lineWidth: 1)
                    }
                
                // Thumb
                Circle()
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 24, height: 24)
                    .quantumGlow(color: configuration.isOn ? onColor : offColor, intensity: 0.6)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Matrix Rain Background
struct MatrixRainView: View {
    @State private var rainDrops: [RainDrop] = []
    @State private var animationTimer: Timer?
    
    private let columns = 30
    private let maxDropsPerColumn = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DarkSpaceTheme.voidBlack
                
                ForEach(rainDrops.indices, id: \.self) { index in
                    if index < rainDrops.count {
                        Text(rainDrops[index].character)
                            .font(.system(size: 12, family: .monospaced))
                            .foregroundStyle(rainDrops[index].color)
                            .position(
                                x: rainDrops[index].x,
                                y: rainDrops[index].y
                            )
                            .opacity(rainDrops[index].opacity)
                    }
                }
            }
        }
        .onAppear {
            startMatrixRain()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func startMatrixRain() {
        // Initialize rain drops
        for column in 0..<columns {
            let columnX = CGFloat(column) * 25 + 12.5
            
            for _ in 0..<Int.random(in: 3...maxDropsPerColumn) {
                rainDrops.append(RainDrop(
                    x: columnX,
                    y: CGFloat.random(in: -500...0),
                    character: String(format: "%02X", Int.random(in: 0...255)),
                    color: DarkSpaceTheme.plasmaGreen.opacity(Double.random(in: 0.1...0.8)),
                    opacity: Double.random(in: 0.3...1.0)
                ))
            }
        }
        
        // Animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateRainDrops()
        }
    }
    
    private func updateRainDrops() {
        for index in rainDrops.indices {
            rainDrops[index].y += CGFloat.random(in: 15...30)
            
            if rainDrops[index].y > UIScreen.main.bounds.height + 100 {
                rainDrops[index].y = CGFloat.random(in: -200...0)
                rainDrops[index].character = String(format: "%02X", Int.random(in: 0...255))
                rainDrops[index].opacity = Double.random(in: 0.3...1.0)
            }
        }
    }
}

struct RainDrop {
    var x: CGFloat
    var y: CGFloat
    var character: String
    var color: Color
    var opacity: Double
}

// MARK: - Starfield Background
struct StarfieldView: View {
    @State private var stars: [Star] = []
    @State private var animationPhase: Double = 0
    
    private let starCount = 200
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DarkSpaceTheme.voidBlack
                
                Canvas { context, size in
                    for star in stars {
                        let twinkle = sin(animationPhase + star.phase) * 0.5 + 0.5
                        let opacity = star.baseOpacity * twinkle
                        
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: star.x - star.size/2,
                                y: star.y - star.size/2,
                                width: star.size,
                                height: star.size
                            )),
                            with: .color(.white.opacity(opacity))
                        )
                        
                        // Add cross-hairs to brighter stars
                        if star.baseOpacity > 0.6 {
                            let crossSize = star.size * 3
                            
                            // Horizontal line
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: star.x - crossSize/2, y: star.y))
                                    path.addLine(to: CGPoint(x: star.x + crossSize/2, y: star.y))
                                },
                                with: .color(.white.opacity(opacity * 0.3)),
                                style: StrokeStyle(lineWidth: 0.5)
                            )
                            
                            // Vertical line
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: star.x, y: star.y - crossSize/2))
                                    path.addLine(to: CGPoint(x: star.x, y: star.y + crossSize/2))
                                },
                                with: .color(.white.opacity(opacity * 0.3)),
                                style: StrokeStyle(lineWidth: 0.5)
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            generateStars()
            startTwinkling()
        }
    }
    
    private func generateStars() {
        let size = UIScreen.main.bounds.size
        
        for _ in 0..<starCount {
            stars.append(Star(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 0.5...2.5),
                baseOpacity: Double.random(in: 0.1...0.9),
                phase: Double.random(in: 0...(.pi * 2))
            ))
        }
    }
    
    private func startTwinkling() {
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

struct Star {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let baseOpacity: Double
    let phase: Double
}

// MARK: - Theme Extensions
extension Color {
    // Process state colors with RGB mapping
    static let processIdle = DarkSpaceTheme.plasmaGreen      // Green
    static let processActive = DarkSpaceTheme.quantumBlue    // Blue
    static let processWarning = DarkSpaceTheme.fusionOrange  // Orange
    static let processCritical = DarkSpaceTheme.stellarRed   // Red
}

// MARK: - Animated Background Components
struct CosmicEnergyView: View {
    @State private var energyPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw energy waves
                for wave in 0..<5 {
                    let waveOffset = Double(wave) * 0.8
                    let amplitude = 30.0 + Double(wave) * 10.0
                    
                    let path = Path { path in
                        path.move(to: CGPoint(x: 0, y: size.height / 2))
                        
                        for x in stride(from: 0, through: size.width, by: 2) {
                            let normalizedX = Double(x) / Double(size.width)
                            let y = size.height / 2 + sin(energyPhase + normalizedX * .pi * 4 + waveOffset) * amplitude
                            
                            if x == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    
                    let gradient = LinearGradient(
                        colors: [
                            DarkSpaceTheme.quantumBlue.opacity(0.1),
                            DarkSpaceTheme.plasmaGreen.opacity(0.05),
                            DarkSpaceTheme.fusionOrange.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    context.stroke(
                        path,
                        with: .linearGradient(
                            gradient.gradient,
                            startPoint: CGPoint(x: 0, y: size.height / 2),
                            endPoint: CGPoint(x: size.width, y: size.height / 2)
                        ),
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                energyPhase = .pi * 4
            }
        }
    }
}