import SwiftUI

// SWARM 2.0 ForceQUIT - Settings Interface
// Comprehensive configuration panel

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    @Environment(\\.dismiss) private var dismiss
    
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationView {
            // Settings sidebar
            settingsSidebar
            
            // Settings content
            settingsContent
        }
        .frame(width: 700, height: 500)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Settings Sidebar
    private var settingsSidebar: some View {
        List(SettingsTab.allCases, id: \\.self, selection: $selectedTab) { tab in
            Label(tab.title, systemImage: tab.systemImage)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        Group {
            switch selectedTab {
            case .general:
                GeneralSettingsView()
            case .appearance:
                AppearanceSettingsView()
            case .performance:
                PerformanceSettingsView()
            case .security:
                SecuritySettingsView()
            case .shortcuts:
                ShortcutsSettingsView()
            case .advanced:
                AdvancedSettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

// MARK: - Settings Tabs
enum SettingsTab: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case performance = "Performance"
    case security = "Security"
    case shortcuts = "Shortcuts"
    case advanced = "Advanced"
    
    var title: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .performance: return "speedometer"
        case .security: return "lock.shield"
        case .shortcuts: return "keyboard"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("Application Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at login", isOn: $appSettings.launchAtLogin)
                    Toggle("Show in menu bar", isOn: $appSettings.showInMenuBar)
                    Toggle("Confirm before force quit", isOn: $appSettings.confirmBeforeForceQuit)
                    Toggle("Enable smart restart", isOn: $appSettings.enableSmartRestart)
                    Toggle("Show resource usage", isOn: $appSettings.showResourceUsage)
                }
            }
            
            GroupBox("Interface") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Auto-refresh interval:")
                        Spacer()
                        Picker("Refresh Interval", selection: $appSettings.autoRefreshInterval) {
                            Text("0.5s").tag(0.5)
                            Text("1s").tag(1.0)
                            Text("2s").tag(2.0)
                            Text("5s").tag(5.0)
                            Text("10s").tag(10.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                    
                    Toggle("Use global shortcuts", isOn: $appSettings.useGlobalShortcuts)
                    Toggle("Enable advanced mode", isOn: $appSettings.enableAdvancedMode)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("Theme") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Background style:")
                        Spacer()
                        Picker("Background", selection: $appSettings.backgroundStyle) {
                            ForEach(BackgroundStyle.allCases, id: \\.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Accent color:")
                        Spacer()
                        Picker("Accent", selection: $appSettings.accentColor) {
                            ForEach(AccentColorOption.allCases, id: \\.self) { color in
                                HStack {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 12, height: 12)
                                    Text(color.rawValue)
                                }
                                .tag(color)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
            }
            
            GroupBox("Visual Effects") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable particle effects", isOn: $appSettings.enableParticleEffects)
                    Toggle("Enable sound effects", isOn: $appSettings.enableSoundEffects)
                    
                    HStack {
                        Text("Glow intensity:")
                        Slider(value: $appSettings.glowIntensity, in: 0.0...1.0) {
                            Text("Glow")
                        } minimumValueLabel: {
                            Text("0%")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("100%")
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("Animation quality:")
                        Spacer()
                        Picker("Quality", selection: $appSettings.animationQuality) {
                            ForEach(AnimationQuality.allCases, id: \\.self) { quality in
                                Text(quality.rawValue).tag(quality)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Performance Settings
struct PerformanceSettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("Rendering") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Metal rendering", isOn: $appSettings.enableMetalRendering)
                        .help("Uses GPU acceleration for smoother animations")
                    
                    HStack {
                        Text("Max particle count:")
                        Slider(value: Binding(
                            get: { Double(appSettings.maxParticleCount) },
                            set: { appSettings.maxParticleCount = Int($0) }
                        ), in: 10...200, step: 10) {
                            Text("Particles")
                        } minimumValueLabel: {
                            Text("10")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("200")
                                .font(.caption)
                        }
                        
                        Text("\\(appSettings.maxParticleCount)")
                            .font(.caption)
                            .frame(width: 30)
                    }
                }
            }
            
            GroupBox("Power Management") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Adapt to low power mode", isOn: $appSettings.adaptToLowPowerMode)
                        .help("Automatically reduces visual effects when on battery")
                    
                    Toggle("Enable thermal throttling", isOn: $appSettings.enableThermalThrottling)
                        .help("Reduces performance under high system load")
                }
            }
            
            GroupBox("System Resources") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Memory usage:")
                                .font(.subheadline)
                            Text("< 20MB typical")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Low Impact")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("CPU usage:")
                                .font(.subheadline)
                            Text("< 2% when active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Minimal")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Security Settings
struct SecuritySettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Security")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("Process Access") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Require admin for system processes", isOn: $appSettings.requireAdminForSystemProcesses)
                        .help("Requires administrator authentication to terminate system processes")
                    
                    Toggle("Show protected processes", isOn: $appSettings.showProtectedProcesses)
                        .help("Display system-critical processes in the interface (they cannot be terminated)")
                    
                    Toggle("Enable audit logging", isOn: $appSettings.enableAuditLogging)
                        .help("Log all force quit operations for security audit")
                }
            }
            
            GroupBox("Safety Features") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Multi-tier security architecture")
                                .font(.subheadline)
                            Text("Sandboxed operations for maximum safety")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("System Integrity Protection")
                                .font(.subheadline)
                            Text("Full SIP compliance and respect")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Shortcuts Settings
struct ShortcutsSettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("Global Shortcuts") {
                VStack(alignment: .leading, spacing: 12) {
                    ShortcutRow(label: "Open ForceQUIT", shortcut: "⌘⌥⌃F")
                    ShortcutRow(label: "Crisis mode", shortcut: "⌘⌥⌃F + Shift")
                    ShortcutRow(label: "Quick force quit", shortcut: "⌘⌥⌃Q")
                }
            }
            
            GroupBox("Application Shortcuts") {
                VStack(alignment: .leading, spacing: 12) {
                    ShortcutRow(label: "Force quit selected", shortcut: "⌘Q")
                    ShortcutRow(label: "Smart restart", shortcut: "⌘R")
                    ShortcutRow(label: "Select all", shortcut: "⌘A")
                    ShortcutRow(label: "Refresh list", shortcut: "⌘R")
                    ShortcutRow(label: "Settings", shortcut: "⌘,")
                }
            }
            
            GroupBox("Alternative Activation") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Three-finger force touch")
                        Spacer()
                        Text("Enabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Shake to activate")
                        Spacer()
                        Text("3 quick shakes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Voice command")
                        Spacer()
                        Text("\\"Hey ForceQUIT, crisis mode\\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Advanced Settings
struct AdvancedSettingsView: View {
    @EnvironmentObject var appSettings: AppSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("Developer Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Reset to Defaults") {
                        appSettings.resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export Settings") {
                        // Export settings functionality
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Import Settings") {
                        // Import settings functionality
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            GroupBox("Debug Information") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Version:")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("System:")
                        Spacer()
                        Text("macOS 14.0+")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Architecture:")
                        Spacer()
                        Text("Universal Binary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Shortcut Row
struct ShortcutRow: View {
    let label: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettingsViewModel())
    }
}