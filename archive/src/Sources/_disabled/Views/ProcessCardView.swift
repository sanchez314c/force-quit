import SwiftUI
import AppKit

// SWARM 2.0 ForceQUIT - Process Card View
// Advanced card interface with hover effects, state indicators, and gesture recognition

struct ProcessCardView: View {
    let process: ProcessInfo
    @Binding var isSelected: Bool
    @Binding var state: RGBProcessState
    
    let onForceQuit: (ProcessInfo) -> Void
    let onSafeRestart: (ProcessInfo) -> Void
    let onShowDetails: (ProcessInfo) -> Void
    
    // Animation states
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var glowPhase: Double = 0
    @State private var cardRotation: Double = 0
    @State private var energyLevel: Double = 0
    
    // Gesture states
    @State private var dragOffset: CGSize = .zero
    @State private var pressStartTime: Date?
    @State private var longPressTriggered: Bool = false
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 140
    
    var body: some View {
        ZStack {
            // Main card background
            cardBackground
            
            // Content overlay
            cardContent
            
            // Energy field overlay
            if isHovered || isSelected {
                energyField
            }
            
            // Selection indicators
            if isSelected {
                selectionIndicators
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        .rotationEffect(.degrees(cardRotation))
        .offset(dragOffset)
        .quantumGlow(
            color: state.color, 
            intensity: isHovered ? 0.8 : (isSelected ? 0.6 : 0.3)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
        
        // Gesture handling
        .simultaneousGesture(hoverGesture)
        .simultaneousGesture(tapGesture)
        .simultaneousGesture(dragGesture)
        .simultaneousGesture(longPressGesture)
        
        .contextMenu {
            contextMenuItems
        }
        
        .onAppear {
            startAnimations()
            updateProcessState()
        }
        .onChange(of: process.cpuUsage) { _ in
            updateProcessState()
        }
        .onChange(of: process.memoryUsage) { _ in
            updateProcessState()
        }
    }
    
    // MARK: - Card Background
    private var cardBackground: some View {
        ZStack {
            // Base card surface
            RoundedRectangle(cornerRadius: 16)
                .fill(DarkSpaceTheme.deepSpace)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            RadialGradient(
                                colors: [
                                    state.color.opacity(0.1),
                                    DarkSpaceTheme.voidBlack.opacity(0.8)
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: cardWidth
                            )
                        )
                }
            
            // Holographic border
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            state.color.opacity(0.8),
                            state.color.opacity(0.3),
                            state.color.opacity(0.8)
                        ],
                        startPoint: UnitPoint(x: sin(glowPhase) * 0.5 + 0.5, y: 0),
                        endPoint: UnitPoint(x: cos(glowPhase) * 0.5 + 0.5, y: 1)
                    ),
                    lineWidth: isHovered ? 2 : 1
                )
            
            // Scan lines effect
            if isHovered {
                scanLinesOverlay
            }
        }
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                // App icon with state indicator
                ZStack {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(state.color.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "app")
                                    .font(.system(size: 16))
                                    .foregroundStyle(state.color)
                            }
                    }
                    
                    // State indicator dot
                    Circle()
                        .fill(state.color)
                        .frame(width: 8, height: 8)
                        .quantumGlow(color: state.color, intensity: 0.8)
                        .offset(x: 16, y: -16)
                }
                
                // Process info
                VStack(alignment: .leading, spacing: 2) {
                    Text(process.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let bundleId = process.bundleIdentifier {
                        Text(bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("PID: \(process.pid)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Quick action buttons
                if isHovered || isSelected {
                    quickActionButtons
                        .transition(.opacity.combined(with: .scale))
                }
            }
            
            Spacer()
            
            // Resource usage indicators
            resourceUsageIndicators
            
            // Security level badge
            securityLevelBadge
        }
        .padding(16)
    }
    
    // MARK: - Quick Action Buttons
    private var quickActionButtons: some View {
        HStack(spacing: 8) {
            // Info button
            Button {
                onShowDetails(process)
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(DarkSpaceTheme.quantumBlue)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Safe restart (if available)
            if process.canSafelyRestart {
                Button {
                    onSafeRestart(process)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkSpaceTheme.plasmaGreen)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Force quit button
            Button {
                onForceQuit(process)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DarkSpaceTheme.stellarRed)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Resource Usage Indicators
    private var resourceUsageIndicators: some View {
        HStack(spacing: 16) {
            // CPU usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("CPU")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // CPU bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DarkSpaceTheme.stardustGrey)
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(cpuUsageColor)
                            .frame(width: geometry.size.width * CGFloat(process.cpuUsage), height: 4)
                            .quantumGlow(color: cpuUsageColor, intensity: 0.6)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 4)
                
                Text("\(Int(process.cpuUsage * 100))%")
                    .font(.caption2)
                    .foregroundStyle(cpuUsageColor)
            }
            
            // Memory usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "memorychip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("RAM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Memory bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DarkSpaceTheme.stardustGrey)
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(memoryUsageColor)
                            .frame(width: geometry.size.width * memoryUsageRatio, height: 4)
                            .quantumGlow(color: memoryUsageColor, intensity: 0.6)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 4)
                
                Text(formatMemoryUsage(process.memoryUsage))
                    .font(.caption2)
                    .foregroundStyle(memoryUsageColor)
            }
        }
    }
    
    // MARK: - Security Level Badge
    private var securityLevelBadge: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: securityIcon)
                    .font(.caption2)
                    .foregroundStyle(securityColor)
                
                Text(process.securityLevel.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(securityColor)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(securityColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(securityColor.opacity(0.3), lineWidth: 0.5)
            }
        }
    }
    
    // MARK: - Energy Field
    private var energyField: some View {
        ZStack {
            // Particle system
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(state.color.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(energyLevel + Double(i) * 0.8) * 40,
                        y: sin(energyLevel + Double(i) * 0.8) * 25
                    )
                    .opacity(sin(energyLevel + Double(i) * 0.5) * 0.5 + 0.5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                energyLevel = .pi * 2
            }
        }
    }
    
    // MARK: - Selection Indicators
    private var selectionIndicators: some View {
        ZStack {
            // Corner selection markers
            ForEach(0..<4, id: \.self) { corner in
                selectionCornerMarker
                    .rotationEffect(.degrees(Double(corner) * 90))
                    .offset(
                        x: corner % 2 == 0 ? -cardWidth/2 + 8 : cardWidth/2 - 8,
                        y: corner < 2 ? -cardHeight/2 + 8 : cardHeight/2 - 8
                    )
            }
        }
    }
    
    private var selectionCornerMarker: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DarkSpaceTheme.quantumBlue)
                .frame(width: 16, height: 2)
            
            Rectangle()
                .fill(DarkSpaceTheme.quantumBlue)
                .frame(width: 2, height: 16)
                .offset(x: -7)
        }
        .quantumGlow(color: DarkSpaceTheme.quantumBlue, intensity: 0.8)
    }
    
    // MARK: - Scan Lines Overlay
    private var scanLinesOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: Array(repeating: [Color.clear, state.color.opacity(0.1)], count: 20).flatMap { $0 },
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Show Details") {
            onShowDetails(process)
        }
        
        Divider()
        
        if process.canSafelyRestart {
            Button("Smart Restart") {
                onSafeRestart(process)
            }
        }
        
        Button("Force Quit", role: .destructive) {
            onForceQuit(process)
        }
        
        Divider()
        
        Button(isSelected ? "Deselect" : "Select") {
            isSelected.toggle()
        }
    }
    
    // MARK: - Gestures
    private var hoverGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isHovered {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = true
                    }
                }
            }
    }
    
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSelected.toggle()
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                
                // Subtle rotation based on drag
                let rotationAmount = Double(value.translation.width) * 0.05
                withAnimation(.easeInOut(duration: 0.1)) {
                    cardRotation = max(-5, min(5, rotationAmount))
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    dragOffset = .zero
                    cardRotation = 0
                }
            }
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onChanged { value in
                if value && !longPressTriggered {
                    longPressTriggered = true
                    
                    // Haptic feedback
                    let impactFeedback = NSHapticFeedbackManager.defaultPerformer
                    impactFeedback.perform(.levelChange, performanceTime: .default)
                    
                    // Visual feedback
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = false
                        }
                    }
                }
            }
            .onEnded { _ in
                longPressTriggered = false
                onShowDetails(process)
            }
    }
    
    // MARK: - Helper Properties
    private var cpuUsageColor: Color {
        let usage = process.cpuUsage
        if usage > 0.8 { return DarkSpaceTheme.stellarRed }
        else if usage > 0.5 { return DarkSpaceTheme.fusionOrange }
        else if usage > 0.2 { return DarkSpaceTheme.quantumBlue }
        else { return DarkSpaceTheme.plasmaGreen }
    }
    
    private var memoryUsageColor: Color {
        let usageInMB = Double(process.memoryUsage) / (1024 * 1024)
        if usageInMB > 1000 { return DarkSpaceTheme.stellarRed }
        else if usageInMB > 500 { return DarkSpaceTheme.fusionOrange }
        else if usageInMB > 200 { return DarkSpaceTheme.quantumBlue }
        else { return DarkSpaceTheme.plasmaGreen }
    }
    
    private var memoryUsageRatio: CGFloat {
        let usageInMB = Double(process.memoryUsage) / (1024 * 1024)
        return CGFloat(min(usageInMB / 2000.0, 1.0)) // Max out at 2GB
    }
    
    private var securityColor: Color {
        switch process.securityLevel {
        case .low: return DarkSpaceTheme.plasmaGreen
        case .medium: return DarkSpaceTheme.fusionOrange
        case .high: return DarkSpaceTheme.stellarRed
        }
    }
    
    private var securityIcon: String {
        switch process.securityLevel {
        case .low: return "person.crop.circle"
        case .medium: return "gear"
        case .high: return "lock.shield"
        }
    }
    
    // MARK: - Helper Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowPhase = .pi * 2
        }
    }
    
    private func updateProcessState() {
        let cpuUsage = process.cpuUsage
        let memoryUsageInMB = Double(process.memoryUsage) / (1024 * 1024)
        
        // Determine process state based on resource usage
        if !process.isResponding {
            state = .critical
        } else if cpuUsage > 0.8 || memoryUsageInMB > 1000 {
            state = .critical
        } else if cpuUsage > 0.5 || memoryUsageInMB > 500 {
            state = .warning
        } else if cpuUsage > 0.1 || memoryUsageInMB > 50 {
            state = .active
        } else {
            state = .idle
        }
    }
    
    private func formatMemoryUsage(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        
        if mb >= 1000 {
            let gb = mb / 1024
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.0f MB", mb)
        }
    }
}

// MARK: - Preview
struct ProcessCardView_Previews: PreviewProvider {
    @State static var isSelected = false
    @State static var state: RGBProcessState = .active
    
    static var previews: some View {
        VStack(spacing: 20) {
            ProcessCardView(
                process: ProcessInfo(
                    id: 1,
                    pid: 1234,
                    name: "Safari",
                    bundleIdentifier: "com.apple.Safari",
                    securityLevel: .low,
                    cpuUsage: 0.25,
                    memoryUsage: 512 * 1024 * 1024,
                    isResponding: true,
                    canSafelyRestart: true
                ),
                isSelected: $isSelected,
                state: $state,
                onForceQuit: { _ in },
                onSafeRestart: { _ in },
                onShowDetails: { _ in }
            )
            
            ProcessCardView(
                process: ProcessInfo(
                    id: 2,
                    pid: 5678,
                    name: "System Process",
                    bundleIdentifier: nil,
                    securityLevel: .high,
                    cpuUsage: 0.85,
                    memoryUsage: 1536 * 1024 * 1024,
                    isResponding: false,
                    canSafelyRestart: false
                ),
                isSelected: .constant(true),
                state: .constant(.critical),
                onForceQuit: { _ in },
                onSafeRestart: { _ in },
                onShowDetails: { _ in }
            )
        }
        .padding()
        .background(DarkSpaceTheme.voidBlack)
        .preferredColorScheme(.dark)
    }
}