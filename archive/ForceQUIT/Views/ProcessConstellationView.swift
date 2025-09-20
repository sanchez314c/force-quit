import SwiftUI

// SWARM 2.0 ForceQUIT - Process Constellation View
// 3D-style visualization of process relationships

struct ProcessConstellationView: View {
    let processes: [ProcessInfo]
    @Binding var selectedProcesses: Set<ProcessInfo.ID>
    let onForceQuit: (ProcessInfo) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var scale: Double = 1.0
    @State private var animationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background constellation effect
                backgroundStars
                
                // Process nodes
                ForEach(Array(processes.enumerated()), id: \\.element.id) { index, process in
                    ProcessNode(
                        process: process,
                        position: nodePosition(for: index, in: geometry.size),
                        isSelected: selectedProcesses.contains(process.id),
                        scale: scale,
                        onTap: {
                            toggleSelection(for: process)
                        },
                        onForceQuit: {
                            onForceQuit(process)
                        }
                    )
                }
                
                // Connection lines between related processes
                connectionLines
            }
        }
        .scaleEffect(scale)
        .offset(dragOffset)
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    },
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.5, min(2.0, value))
                    }
            )
        )
        .onAppear {
            startAnimation()
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
    
    // MARK: - Background Stars
    private var backgroundStars: some View {
        Canvas { context, size in
            for i in 0..<100 {
                let x = Double.random(in: 0...Double(size.width))
                let y = Double.random(in: 0...Double(size.height))
                let opacity = Double.random(in: 0.1...0.5)
                let twinkle = sin(animationPhase + Double(i) * 0.1) * 0.3 + 0.7
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(opacity * twinkle))
                )
            }
        }
    }
    
    // MARK: - Connection Lines
    private var connectionLines: some View {
        Canvas { context, size in
            let groupedProcesses = Dictionary(grouping: processes) { $0.securityLevel }
            
            // Draw connections within security level groups
            for (_, groupProcesses) in groupedProcesses {
                if groupProcesses.count > 1 {
                    let positions = groupProcesses.enumerated().map { index, process in
                        let processIndex = processes.firstIndex(where: { $0.id == process.id }) ?? 0
                        return nodePosition(for: processIndex, in: size)
                    }
                    
                    // Connect processes in the same group
                    for i in 0..<positions.count - 1 {
                        let start = positions[i]
                        let end = positions[i + 1]
                        
                        let path = Path { path in
                            path.move(to: start)
                            path.addLine(to: end)
                        }
                        
                        context.stroke(
                            path,
                            with: .color(.blue.opacity(0.2)),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Node Positioning
    private func nodePosition(for index: Int, in size: CGSize) -> CGPoint {
        let process = processes[index]
        let angle = Double(index) * (2 * .pi / Double(processes.count)) + animationPhase * 0.1
        let radius = min(size.width, size.height) * 0.3
        
        // Adjust radius based on security level
        let adjustedRadius = radius * (1.0 + Double(process.securityLevel.rawValue.count) * 0.1)
        
        let x = size.width / 2 + cos(angle) * adjustedRadius
        let y = size.height / 2 + sin(angle) * adjustedRadius
        
        return CGPoint(x: x, y: y)
    }
    
    private func toggleSelection(for process: ProcessInfo) {
        if selectedProcesses.contains(process.id) {
            selectedProcesses.remove(process.id)
        } else {
            selectedProcesses.insert(process.id)
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

// MARK: - Process Node
struct ProcessNode: View {
    let process: ProcessInfo
    let position: CGPoint
    let isSelected: Bool
    let scale: Double
    let onTap: () -> Void
    let onForceQuit: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var pulsePhase: Double = 0
    
    private var nodeSize: CGFloat {
        let baseSize: CGFloat = 40
        let memoryFactor = min(Double(process.memoryUsage) / (500 * 1024 * 1024), 2.0) // Max 2x for 500MB
        return baseSize * (1.0 + memoryFactor * 0.5)
    }
    
    private var nodeColor: Color {
        if isSelected { return .blue }
        
        switch process.securityLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(nodeColor.opacity(0.3), lineWidth: 2)
                .frame(width: nodeSize * 2, height: nodeSize * 2)
                .scaleEffect(1.0 + sin(pulsePhase) * 0.2)
                .opacity(isSelected || isHovered ? 1.0 : 0.5)
            
            // Main node circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            nodeColor.opacity(0.8),
                            nodeColor.opacity(0.4),
                            nodeColor.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: nodeSize / 2
                    )
                )
                .frame(width: nodeSize, height: nodeSize)
                .overlay(
                    Circle()
                        .stroke(nodeColor, lineWidth: isSelected ? 3 : 1)
                        .frame(width: nodeSize, height: nodeSize)
                )
            
            // App icon
            if let icon = process.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: nodeSize * 0.6, height: nodeSize * 0.6)
                    .clipShape(Circle())
            } else {
                Image(systemName: "app")
                    .font(.system(size: nodeSize * 0.3))
                    .foregroundStyle(.primary)
            }
            
            // Process name label (shown on hover)
            if isHovered || isSelected {
                VStack {
                    Spacer()
                    
                    Text(process.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .offset(y: nodeSize / 2 + 10)
                }
            }
            
            // Resource usage indicators
            if isHovered || isSelected {
                VStack {
                    HStack(spacing: 4) {
                        // Memory indicator
                        Circle()
                            .fill(memoryColor(for: process.memoryUsage))
                            .frame(width: 8, height: 8)
                        
                        // CPU indicator
                        Circle()
                            .fill(cpuColor(for: process.cpuUsage))
                            .frame(width: 8, height: 8)
                    }
                    .offset(y: -nodeSize / 2 - 15)
                    
                    Spacer()
                }
            }
        }
        .position(position)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Force Quit", role: .destructive) {
                onForceQuit()
            }
            
            Button("Show Details") {
                // Show process details
            }
            
            if process.canSafelyRestart {
                Divider()
                Button("Smart Restart") {
                    // Smart restart action
                }
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulsePhase = .pi
        }
    }
    
    // MARK: - Helper Methods
    private func memoryColor(for usage: UInt64) -> Color {
        let usageInMB = Double(usage) / (1024 * 1024)
        
        if usageInMB > 500 { return .red }
        else if usageInMB > 200 { return .orange }
        else if usageInMB > 50 { return .yellow }
        else { return .green }
    }
    
    private func cpuColor(for usage: Double) -> Color {
        if usage > 0.8 { return .red }
        else if usage > 0.5 { return .orange }
        else if usage > 0.2 { return .yellow }
        else { return .green }
    }
}

// MARK: - Constellation Legend
struct ConstellationLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.headline)
                .padding(.bottom, 4)
            
            LegendItem(color: .green, label: "User Applications", systemImage: "person.crop.circle")
            LegendItem(color: .orange, label: "Background Agents", systemImage: "gear")
            LegendItem(color: .red, label: "System Processes", systemImage: "lock.shield")
            
            Divider()
                .padding(.vertical, 4)
            
            Text("Node size indicates memory usage")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Drag to pan • Pinch to zoom")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview
struct ProcessConstellationView_Previews: PreviewProvider {
    @State static var selectedProcesses: Set<ProcessInfo.ID> = [1]
    
    static var previews: some View {
        ProcessConstellationView(
            processes: [
                ProcessInfo(id: 1, pid: 1, name: "Safari", bundleIdentifier: "com.apple.Safari", securityLevel: .low),
                ProcessInfo(id: 2, pid: 2, name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", securityLevel: .low),
                ProcessInfo(id: 3, pid: 3, name: "Activity Monitor", bundleIdentifier: "com.apple.ActivityMonitor", securityLevel: .medium),
                ProcessInfo(id: 4, pid: 4, name: "System Process", securityLevel: .high)
            ],
            selectedProcesses: $selectedProcesses
        ) { _ in }
        .frame(width: 800, height: 600)
        .preferredColorScheme(.dark)
    }
}