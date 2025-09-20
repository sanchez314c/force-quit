import SwiftUI
import AppKit

// SWARM 2.0 ForceQUIT - Enhanced Process Constellation View  
// Advanced 3D visualization with mission control interface

struct ProcessConstellation3DView: View {
    let processes: [ProcessInfo]
    @Binding var selectedProcesses: Set<ProcessInfo.ID>
    let onForceQuit: (ProcessInfo) -> Void
    let onSafeRestart: (ProcessInfo) -> Void
    let onShowDetails: (ProcessInfo) -> Void
    
    // 3D viewport controls
    @State private var cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 500)
    @State private var rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    @State private var zoom: Float = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero
    
    // Animation states
    @State private var animationPhase: Double = 0
    @State private var constellationRotation: Double = 0
    @State private var energyPulse: Double = 0
    @State private var showConnectionLines: Bool = true
    @State private var viewMode: ConstellationViewMode = .sphere
    
    // Interaction states
    @State private var hoveredProcess: ProcessInfo.ID?
    @State private var selectedCluster: ProcessCluster?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 3D starfield background
                starfield3D
                
                // Main constellation view
                constellation3D(in: geometry.size)
                
                // Connection network
                if showConnectionLines {
                    connectionNetwork(in: geometry.size)
                }
                
                // Energy field effects
                energyFieldOverlay
                
                // UI overlay
                VStack {
                    // Top controls
                    constellationControls
                    
                    Spacer()
                    
                    // Bottom info panel
                    if let hovered = hoveredProcess,
                       let process = processes.first(where: { $0.id == hovered }) {
                        processInfoPanel(for: process)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding()
                
                // Constellation legend
                VStack {
                    Spacer()
                    HStack {
                        constellationLegend
                        Spacer()
                    }
                }
                .padding()
            }
        }
        .background(DarkSpaceTheme.voidBlack)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(DarkSpaceTheme.quantumBlue.opacity(0.3), lineWidth: 1)
        }
        .simultaneousGesture(panGesture)
        .simultaneousGesture(magnificationGesture)
        .simultaneousGesture(rotationGesture)
        .onAppear {
            startAnimations()
        }
        .onChange(of: processes) { _ in
            updateClusters()
        }
    }
    
    // MARK: - 3D Starfield Background
    private var starfield3D: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Create 3D star field
            for i in 0..<300 {
                let starId = Float(i)
                
                // 3D star position
                let x = sin(starId * 0.3 + Float(animationPhase)) * 200 * zoom
                let y = cos(starId * 0.7 + Float(animationPhase)) * 150 * zoom
                let z = sin(starId * 0.5 + Float(constellationRotation)) * 100 + 200
                
                // Project to 2D with perspective
                let perspective = 400 / (z + 400)
                let screenX = centerX + CGFloat(x * perspective)
                let screenY = centerY + CGFloat(y * perspective)
                
                // Skip stars outside viewport
                guard screenX >= 0 && screenX <= size.width &&
                      screenY >= 0 && screenY <= size.height else { continue }
                
                // Star properties based on distance
                let brightness = Double(perspective * perspective)
                let starSize = CGFloat(1 + brightness * 2)
                let alpha = min(brightness * 0.8, 0.9)
                
                // Twinkle effect
                let twinkle = sin(animationPhase + Double(starId) * 0.1) * 0.3 + 0.7
                
                // Draw star
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: screenX - starSize/2,
                        y: screenY - starSize/2,
                        width: starSize,
                        height: starSize
                    )),
                    with: .color(.white.opacity(alpha * twinkle))
                )
                
                // Add cross effect for bright stars
                if brightness > 0.7 {
                    let crossSize = starSize * 3
                    
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: screenX - crossSize/2, y: screenY))
                            path.addLine(to: CGPoint(x: screenX + crossSize/2, y: screenY))
                            path.move(to: CGPoint(x: screenX, y: screenY - crossSize/2))
                            path.addLine(to: CGPoint(x: screenX, y: screenY + crossSize/2))
                        },
                        with: .color(.white.opacity(alpha * 0.5)),
                        style: StrokeStyle(lineWidth: 0.5)
                    )
                }
            }
        }
    }
    
    // MARK: - 3D Constellation
    private func constellation3D(in size: CGSize) -> some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            for (index, process) in processes.enumerated() {
                let node3D = calculate3DPosition(for: index, process: process, totalCount: processes.count)
                
                // Project to 2D
                let perspective = 400 / (node3D.z + 400)
                let screenX = centerX + CGFloat(node3D.x * perspective)
                let screenY = centerY + CGFloat(node3D.y * perspective)
                
                // Skip nodes outside viewport
                guard screenX >= 0 && screenX <= size.width &&
                      screenY >= 0 && screenY <= size.height else { continue }
                
                // Node properties
                let nodeState = determineProcessState(process)
                let isSelected = selectedProcesses.contains(process.id)
                let isHovered = hoveredProcess == process.id
                
                // Base node size adjusted by memory usage and distance
                let memoryFactor = min(Double(process.memoryUsage) / (500 * 1024 * 1024), 2.0)
                let baseSize = 20.0 + memoryFactor * 15.0
                let nodeSize = CGFloat(baseSize * Double(perspective))
                
                // Glow rings
                if isSelected || isHovered {
                    for ring in 1...3 {
                        let ringSize = nodeSize * CGFloat(1.0 + Double(ring) * 0.4)
                        let ringAlpha = 0.3 / Double(ring)
                        
                        context.stroke(
                            Path(ellipseIn: CGRect(
                                x: screenX - ringSize/2,
                                y: screenY - ringSize/2,
                                width: ringSize,
                                height: ringSize
                            )),
                            with: .color(nodeState.color.opacity(ringAlpha)),
                            style: StrokeStyle(lineWidth: 2.0 / CGFloat(ring))
                        )
                    }
                }
                
                // Main node
                let gradient = RadialGradient(
                    colors: [
                        nodeState.color.opacity(0.9),
                        nodeState.color.opacity(0.6),
                        nodeState.color.opacity(0.2)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: nodeSize/2
                )
                
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: screenX - nodeSize/2,
                        y: screenY - nodeSize/2,
                        width: nodeSize,
                        height: nodeSize
                    )),
                    with: .radialGradient(
                        gradient.gradient,
                        center: CGPoint(x: screenX, y: screenY),
                        startRadius: 0,
                        endRadius: nodeSize/2
                    )
                )
                
                // Node border
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: screenX - nodeSize/2,
                        y: screenY - nodeSize/2,
                        width: nodeSize,
                        height: nodeSize
                    )),
                    with: .color(nodeState.color),
                    style: StrokeStyle(lineWidth: isSelected ? 3 : 1)
                )
                
                // Process icon (if available and node is large enough)
                if nodeSize > 25, let icon = process.icon {
                    let iconSize = nodeSize * 0.6
                    context.draw(
                        Image(nsImage: icon),
                        in: CGRect(
                            x: screenX - iconSize/2,
                            y: screenY - iconSize/2,
                            width: iconSize,
                            height: iconSize
                        )
                    )
                }
                
                // Process label (on hover or selection)
                if (isHovered || isSelected) && nodeSize > 15 {
                    let labelY = screenY + nodeSize/2 + 15
                    
                    context.draw(
                        Text(process.name)
                            .font(.caption)
                            .foregroundStyle(.white),
                        at: CGPoint(x: screenX, y: labelY)
                    )
                }
                
                // Resource usage indicators
                if isHovered || isSelected {
                    drawResourceIndicators(
                        context: context,
                        at: CGPoint(x: screenX, y: screenY - nodeSize/2 - 15),
                        for: process
                    )
                }
            }
        }
        .onTapGesture { location in
            handleTap(at: location, in: size)
        }
        .onHover { hovering in
            if !hovering {
                hoveredProcess = nil
            }
        }
    }
    
    // MARK: - Connection Network
    private func connectionNetwork(in size: CGSize) -> some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Group processes by security level
            let groupedProcesses = Dictionary(grouping: processes) { $0.securityLevel }
            
            // Draw connections within groups
            for (securityLevel, groupProcesses) in groupedProcesses {
                guard groupProcesses.count > 1 else { continue }
                
                let connectionColor = securityLevelColor(securityLevel)
                
                // Calculate 3D positions for group
                let positions3D = groupProcesses.enumerated().map { index, process in
                    let processIndex = processes.firstIndex(where: { $0.id == process.id }) ?? 0
                    return calculate3DPosition(for: processIndex, process: process, totalCount: processes.count)
                }
                
                // Draw connections between nearby nodes
                for i in 0..<positions3D.count {
                    for j in (i+1)..<positions3D.count {
                        let pos1 = positions3D[i]
                        let pos2 = positions3D[j]
                        
                        // Calculate distance
                        let distance = sqrt(
                            pow(pos1.x - pos2.x, 2) +
                            pow(pos1.y - pos2.y, 2) +
                            pow(pos1.z - pos2.z, 2)
                        )
                        
                        // Only connect nearby nodes
                        guard distance < 200 else { continue }
                        
                        // Project to 2D
                        let perspective1 = 400 / (pos1.z + 400)
                        let perspective2 = 400 / (pos2.z + 400)
                        
                        let screen1 = CGPoint(
                            x: centerX + CGFloat(pos1.x * perspective1),
                            y: centerY + CGFloat(pos1.y * perspective1)
                        )
                        let screen2 = CGPoint(
                            x: centerX + CGFloat(pos2.x * perspective2),
                            y: centerY + CGFloat(pos2.y * perspective2)
                        )
                        
                        // Connection strength based on distance
                        let strength = Double(1.0 - distance / 200.0)
                        let alpha = strength * 0.4
                        
                        // Animated flow effect
                        let flowPhase = sin(animationPhase * 2 + Double(i + j)) * 0.5 + 0.5
                        let flowAlpha = alpha * flowPhase
                        
                        context.stroke(
                            Path { path in
                                path.move(to: screen1)
                                path.addLine(to: screen2)
                            },
                            with: .color(connectionColor.opacity(flowAlpha)),
                            style: StrokeStyle(
                                lineWidth: CGFloat(strength * 2),
                                dash: [CGFloat(strength * 10), CGFloat(strength * 5)]
                            )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Energy Field Overlay
    private var energyFieldOverlay: some View {
        Canvas { context, size in
            // Energy waves emanating from selected processes
            for processId in selectedProcesses {
                guard let process = processes.first(where: { $0.id == processId }),
                      let index = processes.firstIndex(where: { $0.id == processId }) else { continue }
                
                let node3D = calculate3DPosition(for: index, process: process, totalCount: processes.count)
                let perspective = 400 / (node3D.z + 400)
                
                let centerX = size.width / 2 + CGFloat(node3D.x * perspective)
                let centerY = size.height / 2 + CGFloat(node3D.y * perspective)
                
                // Energy rings
                for ring in 1...5 {
                    let ringRadius = CGFloat(ring * 20) * CGFloat(sin(energyPulse + Double(ring) * 0.5) * 0.3 + 0.7)
                    let ringAlpha = (0.5 / Double(ring)) * sin(energyPulse + Double(ring) * 0.3)
                    
                    guard ringAlpha > 0 else { continue }
                    
                    let state = determineProcessState(process)
                    
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: centerX - ringRadius,
                            y: centerY - ringRadius,
                            width: ringRadius * 2,
                            height: ringRadius * 2
                        )),
                        with: .color(state.color.opacity(ringAlpha)),
                        style: StrokeStyle(lineWidth: 2.0 / CGFloat(ring))
                    )
                }
            }
        }
    }
    
    // MARK: - Constellation Controls
    private var constellationControls: some View {
        HStack {
            // View mode selector
            Picker("View Mode", selection: $viewMode) {
                ForEach(ConstellationViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showConnectionLines.toggle()
                    }
                } label: {
                    Image(systemName: showConnectionLines ? "link" : "link.slash")
                        .foregroundStyle(showConnectionLines ? DarkSpaceTheme.quantumBlue : .secondary)
                }
                .buttonStyle(NeonButtonStyle(color: DarkSpaceTheme.quantumBlue))
                
                Button("Reset View") {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                        rotation = SIMD3<Float>(0, 0, 0)
                        zoom = 1.0
                        cameraPosition = SIMD3<Float>(0, 0, 500)
                    }
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
        .padding()
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .holographicBorder()
    }
    
    // MARK: - Process Info Panel
    private func processInfoPanel(for process: ProcessInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = process.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(process.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let bundleId = process.bundleIdentifier {
                        Text(bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // State indicator
                let state = determineProcessState(process)
                Circle()
                    .fill(state.color)
                    .frame(width: 12, height: 12)
                    .quantumGlow(color: state.color, intensity: 0.8)
            }
            
            // Resource usage
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CPU: \(Int(process.cpuUsage * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: process.cpuUsage)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory: \(formatMemoryUsage(process.memoryUsage))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    let memoryRatio = min(Double(process.memoryUsage) / (2000 * 1024 * 1024), 1.0)
                    ProgressView(value: memoryRatio)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 80)
                }
            }
        }
        .padding()
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .holographicBorder()
    }
    
    // MARK: - Constellation Legend
    private var constellationLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Process States")
                .font(.headline)
                .foregroundStyle(.primary)
            
            ForEach(RGBProcessState.allCases, id: \.self) { state in
                HStack(spacing: 8) {
                    Circle()
                        .fill(state.color)
                        .frame(width: 12, height: 12)
                        .quantumGlow(color: state.color, intensity: 0.6)
                    
                    Text(state.name)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    
                    Text(state.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
                .background(DarkSpaceTheme.stardustGrey)
            
            Text("Interactions")
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Text("• Drag to rotate view")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("• Pinch to zoom")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("• Tap nodes to select")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .holographicBorder()
    }
    
    // MARK: - Gestures
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let sensitivity: Float = 0.01
                let deltaX = Float(value.translation.x - lastDragValue.x) * sensitivity
                let deltaY = Float(value.translation.y - lastDragValue.y) * sensitivity
                
                rotation.y += deltaX
                rotation.x -= deltaY
                
                lastDragValue = value.translation
            }
            .onEnded { _ in
                lastDragValue = .zero
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoom = max(0.5, min(3.0, Float(value)))
            }
    }
    
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                rotation.z = Float(value.radians) * 0.5
            }
    }
    
    // MARK: - Helper Methods
    private func calculate3DPosition(for index: Int, process: ProcessInfo, totalCount: Int) -> SIMD3<Float> {
        let baseRadius: Float = 150.0 * zoom
        let time = Float(animationPhase)
        
        switch viewMode {
        case .sphere:
            // Spherical arrangement
            let phi = Float(index) * 2.0 * .pi / Float(totalCount) + time * 0.1
            let theta = acos(1.0 - 2.0 * Float(index) / Float(totalCount))
            
            let radius = baseRadius * (1.0 + Float(process.securityLevel.rawValue.count) * 0.2)
            
            return SIMD3<Float>(
                radius * sin(theta) * cos(phi + rotation.y),
                radius * sin(theta) * sin(phi + rotation.y) * cos(rotation.x) - radius * cos(theta) * sin(rotation.x),
                radius * sin(theta) * sin(phi + rotation.y) * sin(rotation.x) + radius * cos(theta) * cos(rotation.x)
            )
            
        case .helix:
            // Helical arrangement
            let angle = Float(index) * 0.5 + time * 0.1 + rotation.y
            let height = Float(index - totalCount/2) * 20.0
            
            let radius = baseRadius * (1.0 + sin(Float(index) * 0.1 + time) * 0.2)
            
            return SIMD3<Float>(
                radius * cos(angle),
                height * cos(rotation.x) - radius * sin(angle) * sin(rotation.x),
                height * sin(rotation.x) + radius * sin(angle) * cos(rotation.x)
            )
            
        case .grid:
            // 3D grid arrangement
            let gridSize = Int(ceil(sqrt(Double(totalCount))))
            let x = index % gridSize
            let y = index / gridSize
            let z = Int(Float(process.securityLevel.rawValue.count))
            
            let spacing: Float = 80.0 * zoom
            
            return SIMD3<Float>(
                (Float(x) - Float(gridSize) * 0.5) * spacing,
                (Float(y) - Float(gridSize) * 0.5) * spacing + sin(time + Float(x)) * 20.0,
                Float(z) * spacing * 0.5
            )
        }
    }
    
    private func determineProcessState(_ process: ProcessInfo) -> RGBProcessState {
        if !process.isResponding {
            return .critical
        }
        
        let cpuUsage = process.cpuUsage
        let memoryUsageInMB = Double(process.memoryUsage) / (1024 * 1024)
        
        if cpuUsage > 0.8 || memoryUsageInMB > 1000 {
            return .critical
        } else if cpuUsage > 0.5 || memoryUsageInMB > 500 {
            return .warning
        } else if cpuUsage > 0.1 || memoryUsageInMB > 50 {
            return .active
        } else {
            return .idle
        }
    }
    
    private func securityLevelColor(_ level: ProcessInfo.SecurityLevel) -> Color {
        switch level {
        case .low: return DarkSpaceTheme.plasmaGreen
        case .medium: return DarkSpaceTheme.fusionOrange
        case .high: return DarkSpaceTheme.stellarRed
        }
    }
    
    private func drawResourceIndicators(context: GraphicsContext, at point: CGPoint, for process: ProcessInfo) {
        let spacing: CGFloat = 16
        
        // CPU indicator
        let cpuColor = cpuUsageColor(process.cpuUsage)
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - spacing, y: point.y, width: 8, height: 8)),
            with: .color(cpuColor)
        )
        
        // Memory indicator  
        let memoryColor = memoryUsageColor(process.memoryUsage)
        context.fill(
            Path(ellipseIn: CGRect(x: point.x + spacing - 8, y: point.y, width: 8, height: 8)),
            with: .color(memoryColor)
        )
    }
    
    private func cpuUsageColor(_ usage: Double) -> Color {
        if usage > 0.8 { return DarkSpaceTheme.stellarRed }
        else if usage > 0.5 { return DarkSpaceTheme.fusionOrange }
        else if usage > 0.2 { return DarkSpaceTheme.quantumBlue }
        else { return DarkSpaceTheme.plasmaGreen }
    }
    
    private func memoryUsageColor(_ bytes: UInt64) -> Color {
        let usageInMB = Double(bytes) / (1024 * 1024)
        if usageInMB > 1000 { return DarkSpaceTheme.stellarRed }
        else if usageInMB > 500 { return DarkSpaceTheme.fusionOrange }
        else if usageInMB > 200 { return DarkSpaceTheme.quantumBlue }
        else { return DarkSpaceTheme.plasmaGreen }
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
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Find closest node to tap location
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        var closestProcess: ProcessInfo.ID?
        
        for (index, process) in processes.enumerated() {
            let node3D = calculate3DPosition(for: index, process: process, totalCount: processes.count)
            let perspective = 400 / (node3D.z + 400)
            
            let screenX = centerX + CGFloat(node3D.x * perspective)
            let screenY = centerY + CGFloat(node3D.y * perspective)
            
            let distance = sqrt(pow(screenX - location.x, 2) + pow(screenY - location.y, 2))
            
            if distance < closestDistance && distance < 50 { // 50 point tap tolerance
                closestDistance = distance
                closestProcess = process.id
            }
        }
        
        if let processId = closestProcess {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedProcesses.contains(processId) {
                    selectedProcesses.remove(processId)
                } else {
                    selectedProcesses.insert(processId)
                }
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 60.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 4
        }
        
        withAnimation(.linear(duration: 45.0).repeatForever(autoreverses: false)) {
            constellationRotation = .pi * 2
        }
        
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            energyPulse = .pi * 2
        }
    }
    
    private func updateClusters() {
        // Update process clusters based on current processes
        // This could group processes by app bundle, security level, resource usage, etc.
    }
}

// MARK: - Supporting Types
enum ConstellationViewMode: String, CaseIterable {
    case sphere = "sphere"
    case helix = "helix"
    case grid = "grid"
}

struct ProcessCluster {
    let id: UUID = UUID()
    let processes: [ProcessInfo.ID]
    let clusterType: ClusterType
    let centerPosition: SIMD3<Float>
    
    enum ClusterType {
        case security(ProcessInfo.SecurityLevel)
        case application(String) // Bundle identifier
        case resource(ResourceType)
        
        enum ResourceType {
            case highCPU
            case highMemory
            case idle
        }
    }
}

// MARK: - Preview
struct ProcessConstellation3DView_Previews: PreviewProvider {
    @State static var selectedProcesses: Set<ProcessInfo.ID> = [1, 3]
    
    static var previews: some View {
        ProcessConstellation3DView(
            processes: [
                ProcessInfo(id: 1, pid: 1, name: "Safari", bundleIdentifier: "com.apple.Safari", securityLevel: .low),
                ProcessInfo(id: 2, pid: 2, name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", securityLevel: .low),
                ProcessInfo(id: 3, pid: 3, name: "Activity Monitor", bundleIdentifier: "com.apple.ActivityMonitor", securityLevel: .medium),
                ProcessInfo(id: 4, pid: 4, name: "System Process", securityLevel: .high),
                ProcessInfo(id: 5, pid: 5, name: "Mail", bundleIdentifier: "com.apple.Mail", securityLevel: .low),
                ProcessInfo(id: 6, pid: 6, name: "Finder", bundleIdentifier: "com.apple.finder", securityLevel: .medium)
            ],
            selectedProcesses: $selectedProcesses,
            onForceQuit: { _ in },
            onSafeRestart: { _ in },
            onShowDetails: { _ in }
        )
        .frame(width: 1000, height: 700)
        .preferredColorScheme(.dark)
    }
}