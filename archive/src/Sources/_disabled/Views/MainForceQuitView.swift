import SwiftUI
import AppKit

// SWARM 2.0 ForceQUIT - Main Interface View  
// Mission Control aesthetics with avant-garde dark design

struct MainForceQuitView: View {
    @EnvironmentObject var processMonitor: ProcessMonitorViewModel
    @EnvironmentObject var appSettings: AppSettingsViewModel
    @EnvironmentObject var animationController: AnimationControllerViewModel
    @EnvironmentObject var privilegeManager: PrivilegeManager
    
    @State private var searchText: String = ""
    @State private var selectedSortCriteria: ProcessSortCriteria = .name
    @State private var sortAscending: Bool = true
    @State private var showingSettings: Bool = false
    @State private var showingConfirmDialog: Bool = false
    @State private var selectedViewMode: ViewMode = .list
    
    var body: some View {
        ZStack {
            // Background with Mission Control aesthetics
            backgroundLayer
            
            VStack(spacing: 0) {
                // Top Header Bar
                headerBar
                
                // Main Content Area
                contentArea
                
                // Bottom Control Bar  
                controlBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(appSettings.preferredColorScheme)
        .alert("Confirm Force Quit", isPresented: $showingConfirmDialog) {
            confirmationDialog
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appSettings)
        }
        .onAppear {
            animationController.resetToIdle()
        }
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Base background - Void Black (#0A0A0B)
            appSettings.backgroundStyle.background
                .ignoresSafeArea(.all)
            
            // Animated gradient overlay
            AnimatedBackgroundView()
                .opacity(0.3)
                .ignoresSafeArea(.all)
            
            // Glassmorphism overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea(.all)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            // App Title with System Health Indicator
            HStack(spacing: 12) {
                systemHealthIndicator
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ForceQUIT")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Mission Control • \(processMonitor.processes.count) Applications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Search and Controls
            HStack(spacing: 12) {
                searchBar
                viewModeSelector
                settingsButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var systemHealthIndicator: some View {
        ZStack {
            Circle()
                .fill(processMonitor.systemHealth.color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(processMonitor.systemHealth.color, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .opacity(0.3)
                        .scaleEffect(animationController.glowIntensity)
                        .animation(.easeInOut(duration: 2.0).repeatForever(), value: animationController.glowIntensity)
                )
        }
        .help("System Health: \(processMonitor.systemHealth.rawValue)")
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search applications...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(width: 200)
    }
    
    private var viewModeSelector: some View {
        Picker("View Mode", selection: $selectedViewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Image(systemName: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
    }
    
    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Settings")
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            switch selectedViewMode {
            case .list:
                ProcessListView(
                    processes: filteredAndSortedProcesses,
                    selectedProcesses: $processMonitor.selectedProcesses,
                    onForceQuit: forceQuitProcess
                )
            case .grid:
                ProcessGridView(
                    processes: filteredAndSortedProcesses,
                    selectedProcesses: $processMonitor.selectedProcesses,
                    onForceQuit: forceQuitProcess
                )
            case .constellation:
                ProcessConstellationView(
                    processes: filteredAndSortedProcesses,
                    selectedProcesses: $processMonitor.selectedProcesses,
                    onForceQuit: forceQuitProcess
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Control Bar
    private var controlBar: some View {
        HStack {
            // Selection Info
            selectionInfo
            
            Spacer()
            
            // Sort Controls
            sortControls
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var selectionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(processMonitor.selectedProcesses.count) selected")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if !processMonitor.selectedProcesses.isEmpty {
                let selectedProcesses = processMonitor.processes.filter { 
                    processMonitor.selectedProcesses.contains($0.id) 
                }
                let totalMemory = selectedProcesses.reduce(0) { $0 + $1.memoryUsage }
                
                Text("Memory: \(ByteCountFormatter.string(fromByteCount: Int64(totalMemory), countStyle: .memory))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var sortControls: some View {
        HStack(spacing: 8) {
            Text("Sort:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("Sort by", selection: $selectedSortCriteria) {
                ForEach(ProcessSortCriteria.allCases, id: \.self) { criteria in
                    HStack {
                        Image(systemName: criteria.systemImage)
                        Text(criteria.rawValue)
                    }
                    .tag(criteria)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            
            Button {
                sortAscending.toggle()
            } label: {
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Select All/None
            Button {
                if processMonitor.selectedProcesses.count == processMonitor.processes.count {
                    processMonitor.deselectAllProcesses()
                } else {
                    processMonitor.selectAllProcesses()
                }
            } label: {
                Text(processMonitor.selectedProcesses.count == processMonitor.processes.count ? "Deselect All" : "Select All")
            }
            .buttonStyle(.bordered)
            .disabled(processMonitor.processes.isEmpty)
            
            // Force Quit Selected
            Button {
                if appSettings.confirmBeforeForceQuit {
                    showingConfirmDialog = true
                } else {
                    forceQuitSelectedProcesses()
                }
            } label: {
                HStack {
                    Image(systemName: "xmark.app")
                    Text("Force Quit (\(processMonitor.selectedProcesses.count))")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(processMonitor.selectedProcesses.isEmpty)
            
            // Smart Restart (if enabled and supported)
            if appSettings.enableSmartRestart {
                Button {
                    smartRestartSelectedProcesses()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Smart Restart")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!canSmartRestart)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredAndSortedProcesses: [ProcessInfo] {
        processMonitor.processes
            .filtered(by: searchText)
            .sorted(by: selectedSortCriteria, ascending: sortAscending)
    }
    
    private var canSmartRestart: Bool {
        let selectedProcesses = processMonitor.processes.filter { 
            processMonitor.selectedProcesses.contains($0.id) 
        }
        return selectedProcesses.contains { $0.canSafelyRestart }
    }
    
    // MARK: - Confirmation Dialog
    private var confirmationDialog: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Force Quit", role: .destructive) {
                forceQuitSelectedProcesses()
            }
        } message: {
            Text("Are you sure you want to force quit \(processMonitor.selectedProcesses.count) application(s)? Any unsaved work will be lost.")
        }
    }
    
    // MARK: - Actions
    private func forceQuitProcess(_ processInfo: ProcessInfo) {
        Task { @MainActor in
            animationController.animateForceQuit(
                for: processInfo.name,
                at: CGPoint(x: 400, y: 300)
            )
            await processMonitor.forceQuitProcess(processInfo)
        }
    }
    
    private func forceQuitSelectedProcesses() {
        let count = processMonitor.selectedProcesses.count
        
        Task { @MainActor in
            if count > 1 {
                animationController.animateBatchForceQuit(processCount: count)
            }
            await processMonitor.forceQuitSelectedProcesses()
        }
    }
    
    private func smartRestartSelectedProcesses() {
        // Implementation for smart restart functionality
        // This would use the SafeRestartEngine
        Task { @MainActor in
            animationController.animateScanning()
            // Smart restart logic would go here
            animationController.animateSuccess()
        }
    }
}

// MARK: - View Mode Enum
enum ViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
    case constellation = "Constellation"
    
    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "grid"
        case .constellation: return "star.circle"
        }
    }
}

// MARK: - Preview
struct MainForceQuitView_Previews: PreviewProvider {
    static var previews: some View {
        MainForceQuitView()
            .environmentObject(ProcessMonitorViewModel())
            .environmentObject(AppSettingsViewModel())
            .environmentObject(AnimationControllerViewModel())
            .environmentObject(PrivilegeManager())
            .frame(width: 1000, height: 700)
    }
}