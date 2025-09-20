import SwiftUI

// SWARM 2.0 ForceQUIT - Process List View
// Elegant table-based interface for process management

struct ProcessListView: View {
    let processes: [ProcessInfo]
    @Binding var selectedProcesses: Set<ProcessInfo.ID>
    let onForceQuit: (ProcessInfo) -> Void
    
    @State private var hoveredProcess: ProcessInfo.ID?
    @State private var sortOrder = [KeyPathComparator(\\ProcessInfo.name)]
    
    var body: some View {
        Table(processes, selection: $selectedProcesses, sortOrder: $sortOrder) {
            // App Icon and Name
            TableColumn("Application") { process in
                HStack(spacing: 12) {
                    // App icon
                    Group {
                        if let icon = process.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: "app")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(process.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let bundleId = process.bundleIdentifier {
                            Text(bundleId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .width(min: 200, ideal: 250, max: 350)
            
            // Security Level
            TableColumn("Security") { process in
                HStack(spacing: 6) {
                    Image(systemName: process.securityLevel.systemImage)
                        .foregroundStyle(process.statusColor)
                    
                    Text(process.securityLevel.rawValue)
                        .font(.caption)
                        .foregroundStyle(process.statusColor)
                }
            }
            .width(min: 80, ideal: 100, max: 120)
            
            // Memory Usage
            TableColumn("Memory", value: \\ProcessInfo.memoryUsage) { process in
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.memoryUsageFormatted)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    // Memory usage bar
                    ProgressView(value: Double(process.memoryUsage), total: 1_000_000_000) // 1GB scale
                        .progressViewStyle(LinearProgressViewStyle(tint: memoryColor(for: process.memoryUsage)))
                        .frame(width: 60, height: 4)
                }
            }
            .width(min: 80, ideal: 100, max: 120)
            
            // CPU Usage
            TableColumn("CPU", value: \\ProcessInfo.cpuUsage) { process in
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.cpuUsageFormatted)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    // CPU usage bar
                    ProgressView(value: process.cpuUsage, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: cpuColor(for: process.cpuUsage)))
                        .frame(width: 60, height: 4)
                }
            }
            .width(min: 80, ideal: 100, max: 120)
            
            // Status and Actions
            TableColumn("Status") { process in
                HStack(spacing: 8) {
                    // Active status indicator
                    Circle()
                        .fill(process.isActive ? .green : .secondary)
                        .frame(width: 8, height: 8)
                    
                    Text(process.isActive ? "Active" : "Background")
                        .font(.caption)
                        .foregroundStyle(process.isActive ? .primary : .secondary)
                    
                    // Safe restart indicator
                    if process.canSafelyRestart {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .help("Supports safe restart")
                    }
                }
            }
            .width(min: 100, ideal: 120, max: 150)
            
            // Quick Actions
            TableColumn("Actions") { process in
                HStack(spacing: 4) {
                    // Force quit button
                    Button {
                        onForceQuit(process)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Force quit \\(process.name)")
                    .opacity(hoveredProcess == process.id ? 1.0 : 0.3)
                    
                    // Info button
                    Button {
                        showProcessInfo(process)
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                    .help("Process information")
                    .opacity(hoveredProcess == process.id ? 1.0 : 0.3)
                }
            }
            .width(min: 80, ideal: 100, max: 120)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
        .onHover { isHovering in
            if !isHovering {
                hoveredProcess = nil
            }
        }
        .contextMenu(forSelectionType: ProcessInfo.ID.self) { selection in
            if selection.isEmpty {
                // No selection context menu
                Button("Refresh") {
                    // Trigger refresh
                }
            } else {
                // Selected items context menu
                Button("Force Quit Selected") {
                    // Force quit selected processes
                }
                
                if processes.filter({ selection.contains($0.id) }).allSatisfy({ $0.canSafelyRestart }) {
                    Button("Smart Restart Selected") {
                        // Smart restart selected processes
                    }
                }
                
                Divider()
                
                Button("Show in Activity Monitor") {
                    openActivityMonitor()
                }
            }
        }
        .onChange(of: sortOrder) { _, newSortOrder in
            // Handle sort order changes
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
    
    private func showProcessInfo(_ process: ProcessInfo) {
        // Show detailed process information in a sheet or popover
        // This would be implemented based on requirements
    }
    
    private func openActivityMonitor() {
        NSWorkspace.shared.launchApplication("Activity Monitor")
    }
}

// MARK: - Process Row View (Alternative Implementation)
struct ProcessRowView: View {
    let process: ProcessInfo
    let isSelected: Bool
    let onSelect: () -> Void
    let onForceQuit: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection indicator
            Button {
                onSelect()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            
            // App icon and info
            HStack(spacing: 12) {
                Group {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .overlay(
                                Image(systemName: "app")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(process.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let bundleId = process.bundleIdentifier {
                        Text(bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        Label(process.securityLevel.rawValue, systemImage: process.securityLevel.systemImage)
                            .font(.caption2)
                            .foregroundStyle(process.statusColor)
                        
                        if process.canSafelyRestart {
                            Label("Restartable", systemImage: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Resource usage
            VStack(alignment: .trailing, spacing: 4) {
                Text(process.memoryUsageFormatted)
                    .font(.caption)
                    .foregroundStyle(.primary)
                
                Text(process.cpuUsageFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            
            // Actions (shown on hover)
            if isHovered || isSelected {
                HStack(spacing: 8) {
                    Button {
                        onForceQuit()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Force quit")
                    
                    Menu {
                        Button("Show Info") { }
                        Button("Show in Finder") { }
                        if process.canSafelyRestart {
                            Button("Smart Restart") { }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .menuStyle(.borderlessButton)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? .blue.opacity(0.1) : (isHovered ? .quaternary.opacity(0.5) : .clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? .blue : .clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
struct ProcessListView_Previews: PreviewProvider {
    @State static var selectedProcesses: Set<ProcessInfo.ID> = []
    
    static var previews: some View {
        ProcessListView(
            processes: [
                ProcessInfo(id: 1, pid: 1, name: "Safari", bundleIdentifier: "com.apple.Safari"),
                ProcessInfo(id: 2, pid: 2, name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode"),
                ProcessInfo(id: 3, pid: 3, name: "Activity Monitor", bundleIdentifier: "com.apple.ActivityMonitor")
            ],
            selectedProcesses: $selectedProcesses
        ) { _ in }
        .frame(width: 800, height: 500)
    }
}