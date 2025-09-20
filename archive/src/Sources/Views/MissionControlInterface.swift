import SwiftUI
import AppKit

// SWARM 2.0 ForceQUIT - Mission Control Interface
// Complete visual interface integrating all components with dark space theme

struct MissionControlInterface: View {
    @StateObject private var processMonitor = ProcessMonitorViewModel()
    @StateObject private var animationController = InteractiveAnimationController()
    @StateObject private var appSettings = AppSettingsViewModel()
    
    // Interface states
    @State private var selectedProcesses: Set<ProcessInfo.ID> = []
    @State private var viewMode: InterfaceViewMode = .constellation
    @State private var showDetailPanel: Bool = false
    @State private var isFullscreen: Bool = false
    @State private var showSettings: Bool = false
    
    // Interaction states
    @State private var hoveredProcess: ProcessInfo?
    @State private var commandPaletteVisible: Bool = false
    @State private var globalFilter: ProcessFilter = .all
    
    // Animation states
    @State private var interfaceScale: CGFloat = 1.0
    @State private var backgroundIntensity: Double = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                animatedBackground
                
                // Main interface content
                mainContent(geometry: geometry)
                
                // Floating UI elements
                floatingInterface
                
                // Command palette overlay
                if commandPaletteVisible {
                    commandPalette
                        .transition(MissionControlTransitions.holographicSlide)
                }
                
                // Detail panel
                if showDetailPanel {
                    detailPanel
                        .transition(MissionControlTransitions.quantumFade)
                }
                
                // Settings overlay
                if showSettings {
                    settingsOverlay
                        .transition(MissionControlTransitions.matrixDissolve)
                }
            }
        }
        .background(DarkSpaceTheme.voidBlack)
        .scaleEffect(interfaceScale)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: interfaceScale)
        .onAppear {
            startInterface()
        }
        .multiModalGestures(
            onTap: { handleTapGesture() },
            onDoubleTap: { handleDoubleTapGesture() },
            onLongPress: { handleLongPressGesture() },
            onSwipe: { direction in handleSwipeGesture(direction) },
            onPinch: { scale in handlePinchGesture(scale) },
            onRotate: { angle in handleRotateGesture(angle) },
            onMultiTouch: { count in handleMultiTouchGesture(count) }
        )
        .keyboardShortcut(.init(.space), modifiers: [.command]) {
            toggleCommandPalette()
        }
        .keyboardShortcut(.init(.escape)) {
            handleEscapeKey()
        }
        .keyboardShortcut(.init(.f), modifiers: [.command]) {
            toggleFullscreen()
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base starfield
            StarfieldView()
                .opacity(backgroundIntensity * 0.6)
            
            // Energy waves
            CosmicEnergyView()
                .opacity(backgroundIntensity * 0.4)
            
            // Matrix rain (when in intense mode)
            if backgroundIntensity > 0.9 {
                MatrixRainView()
                    .opacity(0.3)
            }
            
            // Particle effects for selected processes
            if !selectedProcesses.isEmpty {
                ParticleSystemView(
                    particleCount: selectedProcesses.count * 10,
                    colors: [
                        DarkSpaceTheme.quantumBlue,
                        DarkSpaceTheme.plasmaGreen,
                        DarkSpaceTheme.fusionOrange
                    ]
                )
                .opacity(0.6)
            }
        }
    }
    
    // MARK: - Main Content
    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top navigation bar
            navigationBar
            
            // Main view area
            ZStack {
                switch viewMode {
                case .constellation:
                    constellationView(geometry: geometry)
                case .grid:
                    gridView
                case .list:
                    listView
                case .analytics:
                    analyticsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom action bar
            if !selectedProcesses.isEmpty {
                actionBar
                    .transition(MissionControlTransitions.holographicSlide)
            }
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Logo and title
            HStack(spacing: 12) {
                Image(systemName: "command.circle.fill")
                    .font(.title2)
                    .foregroundStyle(DarkSpaceTheme.quantumBlue)
                    .quantumGlow(color: DarkSpaceTheme.quantumBlue, intensity: 0.8)
                
                Text("ForceQUIT Mission Control")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // View mode selector
            Picker("View Mode", selection: $viewMode) {
                ForEach(InterfaceViewMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 8) {
                // Filter button
                Menu {
                    ForEach(ProcessFilter.allCases, id: \.self) { filter in
                        Button(filter.displayName) {
                            globalFilter = filter
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.title3)
                        .foregroundStyle(globalFilter == .all ? .secondary : DarkSpaceTheme.quantumBlue)
                }
                .buttonStyle(NeonButtonStyle(color: DarkSpaceTheme.quantumBlue))
                
                // Settings button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSettings.toggle()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(showSettings ? DarkSpaceTheme.fusionOrange : .secondary)
                }
                .buttonStyle(NeonButtonStyle(color: DarkSpaceTheme.fusionOrange))
                
                // Fullscreen toggle
                Button {
                    toggleFullscreen()
                } label: {
                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .holographicBorder()
    }
    
    // MARK: - Constellation View
    private func constellationView(geometry: GeometryProxy) -> some View {
        ProcessConstellationView(
            processes: filteredProcesses,
            selectedProcesses: $selectedProcesses,
            onForceQuit: { process in
                handleForceQuit(process)
            },
            onSafeRestart: { process in
                handleSafeRestart(process)
            },
            onShowDetails: { process in
                hoveredProcess = process
                showDetailPanel = true
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Grid View
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(filteredProcesses, id: \.id) { process in
                    ProcessCardView(
                        process: process,
                        isSelected: .constant(selectedProcesses.contains(process.id)),
                        state: .constant(determineProcessState(process)),
                        onForceQuit: { handleForceQuit($0) },
                        onSafeRestart: { handleSafeRestart($0) },
                        onShowDetails: { handleShowDetails($0) }
                    )
                    .onTapGesture {
                        toggleSelection(for: process)
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        VStack(spacing: 0) {
            // List header
            HStack {
                Text("Process")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("CPU")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 60)
                
                Text("Memory")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 80)
                
                Text("Status")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 80)
                
                Text("Actions")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 100)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(DarkSpaceTheme.controlSurface)
            
            Divider()
                .background(DarkSpaceTheme.stardustGrey)
            
            // Process list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredProcesses, id: \.id) { process in
                        ProcessListRowView(
                            process: process,
                            isSelected: selectedProcesses.contains(process.id),
                            onToggleSelection: { toggleSelection(for: process) },
                            onForceQuit: { handleForceQuit(process) },
                            onSafeRestart: { handleSafeRestart(process) },
                            onShowDetails: { handleShowDetails(process) }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Analytics View
    private var analyticsView: some View {
        VStack(spacing: 24) {
            // System overview
            systemOverviewCards
            
            // Process analytics
            processAnalyticsGrid
        }
        .padding(24)
    }
    
    // MARK: - System Overview Cards
    private var systemOverviewCards: some View {
        HStack(spacing: 20) {
            // CPU Usage Card
            AnalyticsCard(
                title: "CPU Usage",
                value: "\(Int(processMonitor.totalCPUUsage * 100))%",
                color: cpuUsageColor(processMonitor.totalCPUUsage),
                icon: "cpu"
            )
            
            // Memory Usage Card
            AnalyticsCard(
                title: "Memory Usage",
                value: formatMemoryUsage(processMonitor.totalMemoryUsage),
                color: memoryUsageColor(processMonitor.totalMemoryUsage),
                icon: "memorychip"
            )
            
            // Process Count Card
            AnalyticsCard(
                title: "Active Processes",
                value: "\(processMonitor.processes.count)",
                color: DarkSpaceTheme.quantumBlue,
                icon: "app.badge"
            )
            
            // Security Alert Card
            AnalyticsCard(
                title: "Security Alerts",
                value: "\(processMonitor.highSecurityProcesses.count)",
                color: DarkSpaceTheme.stellarRed,
                icon: "exclamationmark.shield"
            )
        }
    }
    
    // MARK: - Process Analytics Grid
    private var processAnalyticsGrid: some View {
        HStack(spacing: 20) {
            // Resource usage chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Resource Usage Over Time")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Simplified chart placeholder
                Rectangle()
                    .fill(DarkSpaceTheme.deepSpace)
                    .frame(height: 200)
                    .overlay {
                        Text("Resource Chart\n(Implementation needed)")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Top processes
            VStack(alignment: .leading, spacing: 12) {
                Text("Top Resource Consumers")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    ForEach(topResourceConsumers, id: \.id) { process in
                        HStack {
                            if let icon = process.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                            
                            Text(process.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int(process.cpuUsage * 100))%")
                                .font(.caption)
                                .foregroundStyle(cpuUsageColor(process.cpuUsage))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
    
    // MARK: - Floating Interface
    private var floatingInterface: some View {
        VStack {
            HStack {
                Spacer()
                
                // Floating process counter
                Text("\(selectedProcesses.count) selected")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 16))
                    .opacity(selectedProcesses.isEmpty ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: selectedProcesses.isEmpty)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 16) {
            // Selection info
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DarkSpaceTheme.plasmaGreen)
                
                Text("\(selectedProcesses.count) processes selected")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Smart Restart All") {
                    handleSmartRestartAll()
                }
                .buttonStyle(NeonButtonStyle(color: DarkSpaceTheme.plasmaGreen))
                .disabled(selectedProcesses.isEmpty || !canSafelyRestartSelected)
                
                Button("Force Quit All") {
                    handleForceQuitAll()
                }
                .buttonStyle(NeonButtonStyle(color: DarkSpaceTheme.stellarRed, isDestructive: true))
                .disabled(selectedProcesses.isEmpty)
                
                Button("Clear Selection") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedProcesses.removeAll()
                    }
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .holographicBorder()
    }
    
    // MARK: - Command Palette
    private var commandPalette: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search processes or enter command...", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
            }
            .padding()
            .background(DarkSpaceTheme.deepSpace)
            
            Divider()
                .background(DarkSpaceTheme.stardustGrey)
            
            // Command suggestions
            ScrollView {
                VStack(spacing: 0) {
                    CommandPaletteItem(
                        title: "Force Quit All Selected",
                        subtitle: "⌘+Q",
                        icon: "xmark.circle",
                        action: { handleForceQuitAll() }
                    )
                    
                    CommandPaletteItem(
                        title: "Smart Restart Selected",
                        subtitle: "⌘+R",
                        icon: "arrow.clockwise",
                        action: { handleSmartRestartAll() }
                    )
                    
                    CommandPaletteItem(
                        title: "Toggle View Mode",
                        subtitle: "⌘+T",
                        icon: "square.grid.2x2",
                        action: { toggleViewMode() }
                    )
                    
                    CommandPaletteItem(
                        title: "Show Analytics",
                        subtitle: "⌘+A",
                        icon: "chart.bar",
                        action: { viewMode = .analytics }
                    )
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 400)
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .holographicBorder()
        .position(x: UIScreen.main.bounds.width / 2, y: 200)
    }
    
    // MARK: - Detail Panel
    private var detailPanel: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if let process = hoveredProcess {
                    ProcessDetailPanel(
                        process: process,
                        onClose: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showDetailPanel = false
                                hoveredProcess = nil
                            }
                        },
                        onForceQuit: { handleForceQuit($0) },
                        onSafeRestart: { handleSafeRestart($0) }
                    )
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .background(.ultraThinMaterial)
        .onTapGesture {
            showDetailPanel = false
            hoveredProcess = nil
        }
    }
    
    // MARK: - Settings Overlay
    private var settingsOverlay: some View {
        VStack {
            Spacer()
            
            SettingsPanel(
                appSettings: appSettings,
                onClose: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSettings = false
                    }
                }
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onTapGesture {
            showSettings = false
        }
    }
    
    // MARK: - Computed Properties
    private var filteredProcesses: [ProcessInfo] {
        processMonitor.processes.filter { process in
            switch globalFilter {
            case .all:
                return true
            case .userApps:
                return process.securityLevel == .low
            case .systemProcesses:
                return process.securityLevel == .high
            case .highCPU:
                return process.cpuUsage > 0.5
            case .highMemory:
                return process.memoryUsage > 500 * 1024 * 1024
            case .unresponsive:
                return !process.isResponding
            }
        }
    }
    
    private var topResourceConsumers: [ProcessInfo] {
        processMonitor.processes
            .sorted { $0.cpuUsage > $1.cpuUsage }
            .prefix(5)
            .map { $0 }
    }
    
    private var canSafelyRestartSelected: Bool {
        selectedProcesses.allSatisfy { id in
            processMonitor.processes.first { $0.id == id }?.canSafelyRestart ?? false
        }
    }
    
    // MARK: - Helper Methods
    private func startInterface() {
        processMonitor.startMonitoring()
        
        // Initial animation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.5)) {
            backgroundIntensity = 0.8
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
    
    private func toggleSelection(for process: ProcessInfo) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedProcesses.contains(process.id) {
                selectedProcesses.remove(process.id)
            } else {
                selectedProcesses.insert(process.id)
            }
        }
        
        MissionControlHaptics.shared.playSelectionFeedback()
    }
    
    private func handleForceQuit(_ process: ProcessInfo) {
        processMonitor.forceQuitProcess(process)
        MissionControlHaptics.shared.playWarningFeedback()
    }
    
    private func handleSafeRestart(_ process: ProcessInfo) {
        processMonitor.safeRestartProcess(process)
        MissionControlHaptics.shared.playSuccessFeedback()
    }
    
    private func handleShowDetails(_ process: ProcessInfo) {
        hoveredProcess = process
        showDetailPanel = true
    }
    
    private func handleForceQuitAll() {
        let processesToQuit = selectedProcesses.compactMap { id in
            processMonitor.processes.first { $0.id == id }
        }
        
        for process in processesToQuit {
            processMonitor.forceQuitProcess(process)
        }
        
        selectedProcesses.removeAll()
        MissionControlHaptics.shared.playErrorFeedback()
    }
    
    private func handleSmartRestartAll() {
        let processesToRestart = selectedProcesses.compactMap { id in
            processMonitor.processes.first { $0.id == id }
        }.filter { $0.canSafelyRestart }
        
        for process in processesToRestart {
            processMonitor.safeRestartProcess(process)
        }
        
        selectedProcesses.removeAll()
        MissionControlHaptics.shared.playSuccessFeedback()
    }
    
    private func toggleCommandPalette() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            commandPaletteVisible.toggle()
        }
    }
    
    private func toggleFullscreen() {
        isFullscreen.toggle()
        // Implement fullscreen toggle logic
    }
    
    private func toggleViewMode() {
        let modes = InterfaceViewMode.allCases
        let currentIndex = modes.firstIndex(of: viewMode) ?? 0
        let nextIndex = (currentIndex + 1) % modes.count
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            viewMode = modes[nextIndex]
        }
    }
    
    private func handleEscapeKey() {
        if commandPaletteVisible {
            commandPaletteVisible = false
        } else if showDetailPanel {
            showDetailPanel = false
            hoveredProcess = nil
        } else if showSettings {
            showSettings = false
        } else if !selectedProcesses.isEmpty {
            selectedProcesses.removeAll()
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleTapGesture() {
        // Handle general tap
    }
    
    private func handleDoubleTapGesture() {
        toggleCommandPalette()
    }
    
    private func handleLongPressGesture() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            backgroundIntensity = backgroundIntensity > 0.9 ? 0.5 : 1.0
        }
    }
    
    private func handleSwipeGesture(_ direction: MissionControlGestureRecognizer.SwipeDirection) {
        switch direction {
        case .left, .right:
            toggleViewMode()
        case .up:
            if !selectedProcesses.isEmpty {
                handleSmartRestartAll()
            }
        case .down:
            selectedProcesses.removeAll()
        }
    }
    
    private func handlePinchGesture(_ scale: CGFloat) {
        interfaceScale = max(0.8, min(1.2, scale))
    }
    
    private func handleRotateGesture(_ angle: CGFloat) {
        // Handle rotation - could affect 3D constellation view
    }
    
    private func handleMultiTouchGesture(_ touchCount: Int) {
        if touchCount >= 3 {
            // Emergency force quit all
            handleForceQuitAll()
        }
    }
    
    // Helper color functions
    private func cpuUsageColor(_ usage: Double) -> Color {
        if usage > 0.8 { return DarkSpaceTheme.stellarRed }
        else if usage > 0.5 { return DarkSpaceTheme.fusionOrange }
        else if usage > 0.2 { return DarkSpaceTheme.quantumBlue }
        else { return DarkSpaceTheme.plasmaGreen }
    }
    
    private func memoryUsageColor(_ bytes: UInt64) -> Color {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb > 8 { return DarkSpaceTheme.stellarRed }
        else if gb > 4 { return DarkSpaceTheme.fusionOrange }
        else if gb > 2 { return DarkSpaceTheme.quantumBlue }
        else { return DarkSpaceTheme.plasmaGreen }
    }
    
    private func formatMemoryUsage(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.0f MB", mb)
        }
    }
}

// MARK: - Supporting Views and Types
enum InterfaceViewMode: String, CaseIterable {
    case constellation = "constellation"
    case grid = "grid"
    case list = "list"
    case analytics = "analytics"
    
    var displayName: String {
        switch self {
        case .constellation: return "Constellation"
        case .grid: return "Grid"
        case .list: return "List"
        case .analytics: return "Analytics"
        }
    }
    
    var iconName: String {
        switch self {
        case .constellation: return "circle.hexagongrid"
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .analytics: return "chart.bar"
        }
    }
}

enum ProcessFilter: String, CaseIterable {
    case all = "all"
    case userApps = "user"
    case systemProcesses = "system"
    case highCPU = "cpu"
    case highMemory = "memory"
    case unresponsive = "unresponsive"
    
    var displayName: String {
        switch self {
        case .all: return "All Processes"
        case .userApps: return "User Applications"
        case .systemProcesses: return "System Processes"
        case .highCPU: return "High CPU Usage"
        case .highMemory: return "High Memory Usage"
        case .unresponsive: return "Unresponsive"
        }
    }
}

// MARK: - Supporting View Components
struct AnalyticsCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkSpaceTheme.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

struct CommandPaletteItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(DarkSpaceTheme.quantumBlue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            // Add hover effect
        }
    }
}

// MARK: - Preview
struct MissionControlInterface_Previews: PreviewProvider {
    static var previews: some View {
        MissionControlInterface()
            .frame(width: 1200, height: 800)
            .preferredColorScheme(.dark)
    }
}