import Foundation
import SwiftUI
import Combine

// SWARM 2.0 ForceQUIT - Application Settings Management
// Dark mode, avant-garde design configuration

@MainActor
class AppSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var preferredColorScheme: ColorScheme = .dark
    @Published var animationQuality: AnimationQuality = .high
    @Published var enableParticleEffects: Bool = true
    @Published var enableSoundEffects: Bool = true
    @Published var autoRefreshInterval: TimeInterval = 2.0
    @Published var showResourceUsage: Bool = true
    @Published var confirmBeforeForceQuit: Bool = true
    @Published var enableSmartRestart: Bool = true
    @Published var launchAtLogin: Bool = false
    @Published var showInMenuBar: Bool = true
    @Published var useGlobalShortcuts: Bool = true
    @Published var enableAdvancedMode: Bool = false
    
    // MARK: - Theme Settings
    @Published var accentColor: AccentColorOption = .blue
    @Published var backgroundStyle: BackgroundStyle = .voidBlack
    @Published var glowIntensity: Double = 0.7
    
    // MARK: - Performance Settings
    @Published var enableMetalRendering: Bool = true
    @Published var maxParticleCount: Int = 100
    @Published var adaptToLowPowerMode: Bool = true
    @Published var enableThermalThrottling: Bool = true
    
    // MARK: - Security Settings  
    @Published var requireAdminForSystemProcesses: Bool = true
    @Published var enableAuditLogging: Bool = true
    @Published var showProtectedProcesses: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupAutoSave()
        adaptToSystemConditions()
    }
    
    // MARK: - Settings Persistence
    private func loadSettings() {
        // Color scheme
        if let colorSchemeString = userDefaults.object(forKey: "preferredColorScheme") as? String,
           let colorScheme = ColorScheme(rawValue: colorSchemeString) {
            self.preferredColorScheme = colorScheme
        }
        
        // Animation quality
        if let qualityString = userDefaults.object(forKey: "animationQuality") as? String,
           let quality = AnimationQuality(rawValue: qualityString) {
            self.animationQuality = quality
        }
        
        // Boolean settings
        self.enableParticleEffects = userDefaults.object(forKey: "enableParticleEffects") as? Bool ?? true
        self.enableSoundEffects = userDefaults.object(forKey: "enableSoundEffects") as? Bool ?? true
        self.showResourceUsage = userDefaults.object(forKey: "showResourceUsage") as? Bool ?? true
        self.confirmBeforeForceQuit = userDefaults.object(forKey: "confirmBeforeForceQuit") as? Bool ?? true
        self.enableSmartRestart = userDefaults.object(forKey: "enableSmartRestart") as? Bool ?? true
        self.launchAtLogin = userDefaults.object(forKey: "launchAtLogin") as? Bool ?? false
        self.showInMenuBar = userDefaults.object(forKey: "showInMenuBar") as? Bool ?? true
        self.useGlobalShortcuts = userDefaults.object(forKey: "useGlobalShortcuts") as? Bool ?? true
        self.enableAdvancedMode = userDefaults.object(forKey: "enableAdvancedMode") as? Bool ?? false
        
        // Numeric settings
        self.autoRefreshInterval = userDefaults.object(forKey: "autoRefreshInterval") as? TimeInterval ?? 2.0
        self.glowIntensity = userDefaults.object(forKey: "glowIntensity") as? Double ?? 0.7
        self.maxParticleCount = userDefaults.object(forKey: "maxParticleCount") as? Int ?? 100
        
        // Theme settings
        if let accentString = userDefaults.object(forKey: "accentColor") as? String,
           let accent = AccentColorOption(rawValue: accentString) {
            self.accentColor = accent
        }
        
        if let backgroundString = userDefaults.object(forKey: "backgroundStyle") as? String,
           let background = BackgroundStyle(rawValue: backgroundString) {
            self.backgroundStyle = background
        }
        
        // Performance settings
        self.enableMetalRendering = userDefaults.object(forKey: "enableMetalRendering") as? Bool ?? true
        self.adaptToLowPowerMode = userDefaults.object(forKey: "adaptToLowPowerMode") as? Bool ?? true
        self.enableThermalThrottling = userDefaults.object(forKey: "enableThermalThrottling") as? Bool ?? true
        
        // Security settings
        self.requireAdminForSystemProcesses = userDefaults.object(forKey: "requireAdminForSystemProcesses") as? Bool ?? true
        self.enableAuditLogging = userDefaults.object(forKey: "enableAuditLogging") as? Bool ?? true
        self.showProtectedProcesses = userDefaults.object(forKey: "showProtectedProcesses") as? Bool ?? false
    }
    
    private func setupAutoSave() {
        // Auto-save settings changes
        Publishers.CombineLatest4(
            $preferredColorScheme,
            $animationQuality,
            $enableParticleEffects,
            $enableSoundEffects
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.saveSettings()
        }
        .store(in: &cancellables)
        
        Publishers.CombineLatest4(
            $showResourceUsage,
            $confirmBeforeForceQuit,
            $enableSmartRestart,
            $launchAtLogin
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.saveSettings()
        }
        .store(in: &cancellables)
    }
    
    private func saveSettings() {
        userDefaults.set(preferredColorScheme.rawValue, forKey: "preferredColorScheme")
        userDefaults.set(animationQuality.rawValue, forKey: "animationQuality")
        userDefaults.set(enableParticleEffects, forKey: "enableParticleEffects")
        userDefaults.set(enableSoundEffects, forKey: "enableSoundEffects")
        userDefaults.set(showResourceUsage, forKey: "showResourceUsage")
        userDefaults.set(confirmBeforeForceQuit, forKey: "confirmBeforeForceQuit")
        userDefaults.set(enableSmartRestart, forKey: "enableSmartRestart")
        userDefaults.set(launchAtLogin, forKey: "launchAtLogin")
        userDefaults.set(showInMenuBar, forKey: "showInMenuBar")
        userDefaults.set(useGlobalShortcuts, forKey: "useGlobalShortcuts")
        userDefaults.set(enableAdvancedMode, forKey: "enableAdvancedMode")
        userDefaults.set(autoRefreshInterval, forKey: "autoRefreshInterval")
        userDefaults.set(glowIntensity, forKey: "glowIntensity")
        userDefaults.set(maxParticleCount, forKey: "maxParticleCount")
        userDefaults.set(accentColor.rawValue, forKey: "accentColor")
        userDefaults.set(backgroundStyle.rawValue, forKey: "backgroundStyle")
        userDefaults.set(enableMetalRendering, forKey: "enableMetalRendering")
        userDefaults.set(adaptToLowPowerMode, forKey: "adaptToLowPowerMode")
        userDefaults.set(enableThermalThrottling, forKey: "enableThermalThrottling")
        userDefaults.set(requireAdminForSystemProcesses, forKey: "requireAdminForSystemProcesses")
        userDefaults.set(enableAuditLogging, forKey: "enableAuditLogging")
        userDefaults.set(showProtectedProcesses, forKey: "showProtectedProcesses")
    }
    
    // MARK: - System Adaptation
    private func adaptToSystemConditions() {
        // Monitor system conditions and adapt settings
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAndAdaptToSystemConditions()
            }
            .store(in: &cancellables)
    }
    
    private func checkAndAdaptToSystemConditions() {
        let processInfo = ProcessInfo.processInfo
        
        // Adapt to low power mode
        if adaptToLowPowerMode && processInfo.isLowPowerModeEnabled {
            if animationQuality != .disabled {
                animationQuality = .low
                enableParticleEffects = false
                maxParticleCount = 20
            }
        }
        
        // Adapt to thermal conditions
        if enableThermalThrottling {
            switch processInfo.thermalState {
            case .critical:
                animationQuality = .disabled
                enableParticleEffects = false
                enableMetalRendering = false
            case .serious:
                animationQuality = .low
                maxParticleCount = 20
            case .fair:
                animationQuality = .medium
                maxParticleCount = 50
            case .nominal:
                // Use user preferences
                break
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
        preferredColorScheme = .dark
        animationQuality = .high
        enableParticleEffects = true
        enableSoundEffects = true
        autoRefreshInterval = 2.0
        showResourceUsage = true
        confirmBeforeForceQuit = true
        enableSmartRestart = true
        launchAtLogin = false
        showInMenuBar = true
        useGlobalShortcuts = true
        enableAdvancedMode = false
        
        accentColor = .blue
        backgroundStyle = .voidBlack
        glowIntensity = 0.7
        
        enableMetalRendering = true
        maxParticleCount = 100
        adaptToLowPowerMode = true
        enableThermalThrottling = true
        
        requireAdminForSystemProcesses = true
        enableAuditLogging = true
        showProtectedProcesses = false
        
        saveSettings()
    }
}

// MARK: - Settings Enums
enum AnimationQuality: String, CaseIterable {
    case disabled = "Disabled"
    case low = "Low"
    case medium = "Medium"  
    case high = "High"
    case ultra = "Ultra"
    
    var description: String {
        switch self {
        case .disabled: return "No animations"
        case .low: return "Basic transitions"
        case .medium: return "Smooth animations"
        case .high: return "Rich effects"
        case .ultra: return "Maximum fidelity"
        }
    }
    
    var frameRate: Int {
        switch self {
        case .disabled: return 0
        case .low: return 30
        case .medium: return 60
        case .high: return 120
        case .ultra: return 120
        }
    }
}

enum AccentColorOption: String, CaseIterable {
    case blue = "Blue"
    case orange = "Orange"
    case red = "Red"
    case green = "Green"
    case purple = "Purple"
    case pink = "Pink"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .orange: return .orange
        case .red: return .red
        case .green: return .green
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

enum BackgroundStyle: String, CaseIterable {
    case voidBlack = "Void Black"
    case spaceGray = "Space Gray"
    case deepBlue = "Deep Blue"
    case carbonFiber = "Carbon Fiber"
    
    var background: Color {
        switch self {
        case .voidBlack: return Color(red: 0.04, green: 0.04, blue: 0.043) // #0A0A0B
        case .spaceGray: return Color(red: 0.11, green: 0.11, blue: 0.118) // #1C1C1E
        case .deepBlue: return Color(red: 0.02, green: 0.04, blue: 0.08) // #050A14
        case .carbonFiber: return Color(red: 0.08, green: 0.08, blue: 0.08) // #141414
        }
    }
}