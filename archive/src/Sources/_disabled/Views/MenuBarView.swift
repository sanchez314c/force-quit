import SwiftUI

// SWARM 2.0 ForceQUIT - Menu Bar Interface
// Quick access menu bar functionality

struct MenuBarView: View {
    @EnvironmentObject var processMonitor: ProcessMonitorViewModel
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    @State private var showingMainWindow: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // System status header
            systemStatusHeader
            
            Divider()
            
            // Quick actions
            quickActions
            
            if !processMonitor.processes.isEmpty {
                Divider()
                
                // Top memory consumers
                topMemoryConsumers
            }
            
            Divider()
            
            // Settings and quit
            bottomActions
        }
        .frame(width: 280)
    }
    
    // MARK: - System Status Header
    private var systemStatusHeader: some View {
        VStack(spacing: 8) {
            HStack {
                // System health indicator
                systemHealthIndicator
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ForceQUIT")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\\(processMonitor.processes.count) applications running")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Last update time
                Text(RelativeDateTimeFormatter().localizedString(for: processMonitor.lastUpdateTime, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // System resource overview
            systemResourceOverview
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var systemHealthIndicator: some View {
        Circle()
            .fill(processMonitor.systemHealth.color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(processMonitor.systemHealth.color.opacity(0.3), lineWidth: 4)
                    .scaleEffect(1.5)
            )
            .help("System Health: \\(processMonitor.systemHealth.rawValue)")
    }
    
    private var systemResourceOverview: some View {
        HStack(spacing: 16) {
            // Memory usage summary
            VStack(alignment: .leading, spacing: 2) {
                Text("Memory")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                let totalMemory = processMonitor.processes.reduce(0) { $0 + $1.memoryUsage }
                Text(ByteCountFormatter.string(fromByteCount: Int64(totalMemory), countStyle: .memory))
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Process count by type
            HStack(spacing: 12) {
                let grouped = Dictionary(grouping: processMonitor.processes) { $0.securityLevel }
                
                ForEach(ProcessInfo.SecurityLevel.allCases, id: \.self) { level in
                    if let count = grouped[level]?.count, count > 0 {
                        VStack(spacing: 2) {
                            Text("\\(count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(colorForSecurityLevel(level))
                            
                            Image(systemName: level.systemImage)
                                .font(.caption2)
                                .foregroundStyle(colorForSecurityLevel(level))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(spacing: 4) {
            Button {
                showingMainWindow = true
            } label: {
                HStack {
                    Image(systemName: "app.badge")
                    Text("Open ForceQUIT")
                    Spacer()
                    Text("⌘O")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("o", modifiers: .command)
            
            Button {
                Task {
                    await processMonitor.forceQuitSelectedProcesses()
                }
            } label: {
                HStack {
                    Image(systemName: "xmark.app")
                    Text("Force Quit Selected (\\(processMonitor.selectedProcesses.count))")
                    Spacer()
                    Text("⌘Q")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .disabled(processMonitor.selectedProcesses.isEmpty)
            .keyboardShortcut("q", modifiers: .command)
            
            if appSettings.enableSmartRestart {
                Button {
                    // Smart restart functionality
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Smart Restart")
                        Spacer()
                        Text("⌘R")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Top Memory Consumers
    private var topMemoryConsumers: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Top Memory Users")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
            
            let topProcesses = processMonitor.processes
                .sorted { $0.memoryUsage > $1.memoryUsage }
                .prefix(5)
            
            ForEach(Array(topProcesses.enumerated()), id: \.element.id) { index, process in
                ProcessMenuRow(
                    process: process,
                    rank: index + 1,
                    isSelected: processMonitor.selectedProcesses.contains(process.id),
                    onToggleSelection: {
                        processMonitor.toggleSelection(for: process)
                    },
                    onForceQuit: {
                        Task {
                            await processMonitor.forceQuitProcess(process)
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 4) {
            Button("Settings...") {
                // Open settings
            }
            .buttonStyle(.borderless)
            
            Button("Quit ForceQUIT") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q", modifiers: [.command, .option])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    private func colorForSecurityLevel(_ level: ProcessInfo.SecurityLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Process Menu Row
struct ProcessMenuRow: View {
    let process: ProcessInfo
    let rank: Int
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onForceQuit: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Rank number
            Text("\\(rank)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
                .frame(width: 16, alignment: .center)
            
            // Selection checkbox
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.borderless)
            
            // App info
            HStack(spacing: 6) {
                Group {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.quaternary)
                            .overlay(
                                Image(systemName: "app")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(process.name)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(process.memoryUsageFormatted)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Quick force quit button (shown on hover)
            if isHovered {
                Button {
                    onForceQuit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("Force quit \\(process.name)")
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? .blue.opacity(0.1) : (isHovered ? .quaternary.opacity(0.5) : .clear))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Force Quit", role: .destructive) {
                onForceQuit()
            }
            
            Button("Show in Main Window") {
                // Focus process in main window
            }
            
            if process.canSafelyRestart {
                Divider()
                Button("Smart Restart") {
                    // Smart restart action
                }
            }
        }
    }
}

// MARK: - Preview
struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(ProcessMonitorViewModel())
            .environmentObject(AppSettingsViewModel())
    }
}