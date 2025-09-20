import SwiftUI

// SWARM 2.0 ForceQUIT - Process Grid View
// Card-based grid layout for visual process management

struct ProcessGridView: View {
    let processes: [ProcessInfo]
    @Binding var selectedProcesses: Set<ProcessInfo.ID>
    let onForceQuit: (ProcessInfo) -> Void
    
    private let columns = Array(repeating: GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16), count: 1)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(processes) { process in
                    ProcessCard(
                        process: process,
                        isSelected: selectedProcesses.contains(process.id),
                        onSelect: {
                            toggleSelection(for: process)
                        },
                        onForceQuit: {
                            onForceQuit(process)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
    
    private func toggleSelection(for process: ProcessInfo) {
        if selectedProcesses.contains(process.id) {
            selectedProcesses.remove(process.id)
        } else {
            selectedProcesses.insert(process.id)
        }
    }
}

// MARK: - Process Card
struct ProcessCard: View {
    let process: ProcessInfo
    let isSelected: Bool
    let onSelect: () -> Void
    let onForceQuit: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var showingDetails: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and selection
            HStack {
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                // App icon
                Group {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .overlay(
                                Image(systemName: "app")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Actions menu (shown on hover)
                Menu {
                    Button("Force Quit", role: .destructive) {
                        onForceQuit()
                    }
                    
                    Button("Show Details") {
                        showingDetails = true
                    }
                    
                    if process.canSafelyRestart {
                        Button("Smart Restart") {
                            // Smart restart action
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .opacity(isHovered || isSelected ? 1.0 : 0.0)
            }
            
            // App name and bundle ID
            VStack(spacing: 4) {
                Text(process.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let bundleId = process.bundleIdentifier {
                    Text(bundleId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Resource usage indicators
            VStack(spacing: 8) {
                // Memory usage
                HStack {
                    Text("Memory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(process.memoryUsageFormatted)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                
                ProgressView(value: Double(process.memoryUsage), total: 1_000_000_000) // 1GB scale
                    .progressViewStyle(LinearProgressViewStyle(tint: memoryColor(for: process.memoryUsage)))
                
                // CPU usage
                HStack {
                    Text("CPU")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(process.cpuUsageFormatted)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                
                ProgressView(value: process.cpuUsage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: cpuColor(for: process.cpuUsage)))
            }
            
            // Status indicators
            HStack {
                // Security level
                Label(process.securityLevel.rawValue, systemImage: process.securityLevel.systemImage)
                    .font(.caption)
                    .foregroundStyle(process.statusColor)
                
                Spacer()
                
                // Active status
                Label(process.isActive ? "Active" : "Background", systemImage: process.isActive ? "circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(process.isActive ? .green : .secondary)
                
                // Restart indicator
                if process.canSafelyRestart {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .help("Supports safe restart")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? .blue.opacity(0.1) : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thickMaterial.opacity(isHovered ? 0.3 : 0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .blue : (isHovered ? .primary.opacity(0.3) : .quaternary), lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
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
                showingDetails = true
            }
            
            if process.canSafelyRestart {
                Divider()
                Button("Smart Restart") {
                    // Smart restart action
                }
            }
            
            Divider()
            Button("Show in Activity Monitor") {
                NSWorkspace.shared.launchApplication("Activity Monitor")
            }
        }
        .sheet(isPresented: $showingDetails) {
            ProcessDetailsView(process: process)
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

// MARK: - Process Details View
struct ProcessDetailsView: View {
    let process: ProcessInfo
    @Environment(\\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Group {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .overlay(
                                Image(systemName: "app")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(process.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let bundleId = process.bundleIdentifier {
                        Text(bundleId)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Label("PID: \\(process.pid)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Process Information
            VStack(alignment: .leading, spacing: 16) {
                DetailRow(label: "Security Level", 
                         value: process.securityLevel.rawValue,
                         systemImage: process.securityLevel.systemImage,
                         color: process.statusColor)
                
                DetailRow(label: "Status", 
                         value: process.isActive ? "Active" : "Background",
                         systemImage: process.isActive ? "circle.fill" : "circle",
                         color: process.isActive ? .green : .secondary)
                
                DetailRow(label: "Memory Usage", 
                         value: process.memoryUsageFormatted,
                         systemImage: "memorychip",
                         color: memoryColor(for: process.memoryUsage))
                
                DetailRow(label: "CPU Usage", 
                         value: process.cpuUsageFormatted,
                         systemImage: "cpu",
                         color: cpuColor(for: process.cpuUsage))
                
                DetailRow(label: "Safe Restart", 
                         value: process.canSafelyRestart ? "Supported" : "Not supported",
                         systemImage: process.canSafelyRestart ? "checkmark.circle" : "xmark.circle",
                         color: process.canSafelyRestart ? .green : .secondary)
                
                DetailRow(label: "Created", 
                         value: DateFormatter.localizedString(from: process.createdAt, dateStyle: .none, timeStyle: .medium),
                         systemImage: "clock",
                         color: .secondary)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 400, height: 500)
        .background(.regularMaterial)
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

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(label, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview
struct ProcessGridView_Previews: PreviewProvider {
    @State static var selectedProcesses: Set<ProcessInfo.ID> = [1]
    
    static var previews: some View {
        ProcessGridView(
            processes: [
                ProcessInfo(id: 1, pid: 1, name: "Safari", bundleIdentifier: "com.apple.Safari"),
                ProcessInfo(id: 2, pid: 2, name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode"),
                ProcessInfo(id: 3, pid: 3, name: "Activity Monitor", bundleIdentifier: "com.apple.ActivityMonitor")
            ],
            selectedProcesses: $selectedProcesses
        ) { _ in }
        .frame(width: 800, height: 600)
        .preferredColorScheme(.dark)
    }
}