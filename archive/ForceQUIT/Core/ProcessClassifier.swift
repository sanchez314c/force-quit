import Foundation
import AppKit
import os.log

/// SWARM 2.0 ForceQUIT - Intelligent Process Classifier
/// Advanced process classification system for security level determination
/// and safe restart capability assessment using machine learning approaches

class ProcessClassifier: ObservableObject {
    // MARK: - Singleton
    static let shared = ProcessClassifier()
    
    // MARK: - Properties
    @Published private(set) var classificationRules: [ClassificationRule] = []
    @Published private(set) var learnedBehaviors: [String: ProcessBehavior] = [:]
    
    private let logger = Logger(subsystem: "com.forcequit.app", category: "ProcessClassifier")
    
    // Classification databases
    private var systemProcessPatterns: [ProcessPattern] = []
    private var safeRestartProcesses: Set<String> = []
    private var dangerousProcesses: Set<String> = []
    private var browserProcesses: Set<String> = []
    private var mediaProcesses: Set<String> = []
    private var developerTools: Set<String> = []
    
    // Behavior learning
    private var processRestartHistory: [String: RestartHistory] = [:]
    private let maxHistoryEntries = 1000
    
    // MARK: - Initialization
    private init() {
        loadStaticClassificationData()
        loadLearnedBehaviors()
        setupClassificationRules()
    }
    
    // MARK: - Public Interface
    
    /// Determine security level for an NSRunningApplication
    func determineSecurityLevel(for app: NSRunningApplication) -> ProcessInfo.SecurityLevel {
        let bundleId = app.bundleIdentifier ?? ""
        let processName = app.localizedName ?? bundleId
        let pid = app.processIdentifier
        
        // Check against known dangerous patterns first
        if isDangerousProcess(name: processName, bundleId: bundleId) {
            return .high
        }
        
        // System processes
        if isSystemProcess(app) {
            return .high
        }
        
        // Background agents and daemons
        if isBackgroundAgent(app) {
            return .medium
        }
        
        // Check learned behaviors
        if let behavior = learnedBehaviors[bundleId],
           behavior.terminationFailureRate > 0.3 {
            return .medium
        }
        
        // Developer tools get medium security
        if isDeveloperTool(bundleId: bundleId, name: processName) {
            return .medium
        }
        
        // Default to low for user applications
        return .low
    }
    
    /// Determine security level for system process (non-NSRunningApplication)
    func classifySystemProcess(name: String, pid: pid_t) -> ProcessInfo.SecurityLevel {
        // Critical system processes
        if isCriticalSystemProcess(name: name, pid: pid) {
            return .high
        }
        
        // Kernel-related processes
        if isKernelProcess(name: name) {
            return .high
        }
        
        // System daemons
        if isSystemDaemon(name: name) {
            return .medium
        }
        
        // User-space system utilities
        if isSystemUtility(name: name) {
            return .medium
        }
        
        return .low
    }
    
    /// Check if process can be safely restarted
    func canSafelyRestart(_ app: NSRunningApplication) -> Bool {
        let bundleId = app.bundleIdentifier ?? ""
        let processName = app.localizedName ?? bundleId
        
        // Never restart system processes
        if isSystemProcess(app) {
            return false
        }
        
        // Check safe restart list
        if safeRestartProcesses.contains(bundleId) ||
           safeRestartProcesses.contains(processName.lowercased()) {
            return true
        }
        
        // Check learned behavior
        if let behavior = learnedBehaviors[bundleId] {
            return behavior.canSafelyRestart && behavior.restartSuccessRate > 0.8
        }
        
        // User applications are generally safe to restart
        if app.activationPolicy == .regular {
            return true
        }
        
        // Background applications need assessment
        if app.activationPolicy == .accessory {
            return isAccessoryAppSafeToRestart(bundleId: bundleId, name: processName)
        }
        
        return false
    }
    
    /// Check if system process can be safely restarted
    func canSafelyRestartSystemProcess(name: String) -> Bool {
        // Never restart critical system processes
        let criticalProcesses = [
            "kernel_task", "launchd", "kextd", "WindowServer",
            "loginwindow", "SystemUIServer", "securityd"
        ]
        
        return !criticalProcesses.contains(name)
    }
    
    /// Get process category for better UX grouping
    func getProcessCategory(_ app: NSRunningApplication) -> ProcessCategory {
        let bundleId = app.bundleIdentifier ?? ""
        let processName = app.localizedName ?? bundleId
        
        // Browser applications
        if browserProcesses.contains(bundleId) || 
           processName.lowercased().contains("browser") ||
           processName.lowercased().contains("safari") ||
           processName.lowercased().contains("chrome") ||
           processName.lowercased().contains("firefox") {
            return .browser
        }
        
        // Media applications
        if mediaProcesses.contains(bundleId) ||
           isMediaApplication(bundleId: bundleId, name: processName) {
            return .media
        }
        
        // Developer tools
        if developerTools.contains(bundleId) ||
           isDeveloperTool(bundleId: bundleId, name: processName) {
            return .development
        }
        
        // System utilities
        if isSystemUtilityApp(bundleId: bundleId, name: processName) {
            return .system
        }
        
        // Games
        if isGamingApplication(bundleId: bundleId, name: processName) {
            return .gaming
        }
        
        // Productivity
        if isProductivityApp(bundleId: bundleId, name: processName) {
            return .productivity
        }
        
        // Communication
        if isCommunicationApp(bundleId: bundleId, name: processName) {
            return .communication
        }
        
        return .other
    }
    
    /// Record process restart attempt for learning
    func recordRestartAttempt(bundleId: String?, name: String, success: Bool) {
        let identifier = bundleId ?? name
        
        var history = processRestartHistory[identifier] ?? RestartHistory()
        history.attemptCount += 1
        
        if success {
            history.successCount += 1
        }
        
        history.lastAttempt = Date()
        processRestartHistory[identifier] = history
        
        // Update learned behavior
        updateLearnedBehavior(for: identifier, restartHistory: history)
        
        // Trim history if needed
        trimProcessHistory()
    }
    
    /// Record termination attempt for learning
    func recordTerminationAttempt(bundleId: String?, name: String, success: Bool, method: String) {
        let identifier = bundleId ?? name
        
        var behavior = learnedBehaviors[identifier] ?? ProcessBehavior(identifier: identifier)
        behavior.terminationAttempts += 1
        
        if !success {
            behavior.terminationFailures += 1
        }
        
        behavior.lastTerminationMethod = method
        behavior.lastSeen = Date()
        
        learnedBehaviors[identifier] = behavior
        
        logger.debug("Recorded termination attempt for \(identifier, privacy: .public): success=\(success)")
    }
    
    /// Get recommendations for process termination
    func getTerminationRecommendation(for app: NSRunningApplication) -> TerminationRecommendation {
        let securityLevel = determineSecurityLevel(for: app)
        let canRestart = canSafelyRestart(app)
        let bundleId = app.bundleIdentifier ?? ""
        
        // Check learned behavior
        var recommendation: TerminationStrategy = .graceful
        var confidence: Double = 0.8
        
        if let behavior = learnedBehaviors[bundleId] {
            if behavior.terminationFailureRate > 0.5 {
                recommendation = .forceful
                confidence = 0.9
            } else if behavior.terminationFailureRate > 0.2 {
                recommendation = .escalating
                confidence = 0.85
            }
            
            if canRestart && behavior.restartSuccessRate > 0.8 {
                recommendation = .restart
                confidence = 0.95
            }
        }
        
        // Override based on security level
        if securityLevel == .high {
            recommendation = .graceful
            confidence = 1.0
        }
        
        return TerminationRecommendation(
            strategy: recommendation,
            confidence: confidence,
            reason: getRecommendationReason(securityLevel: securityLevel, canRestart: canRestart, behavior: learnedBehaviors[bundleId])
        )
    }
    
    // MARK: - Private Implementation
    
    private func loadStaticClassificationData() {
        // System processes that should never be terminated
        dangerousProcesses = [
            "kernel_task", "launchd", "kextd", "WindowServer",
            "loginwindow", "SystemUIServer", "securityd", "coreauthd",
            "UserEventAgent", "Dock", "Finder"
        ]
        
        // Processes safe to restart
        safeRestartProcesses = [
            "com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
            "com.microsoft.VSCode", "com.apple.TextEdit", "com.apple.Preview",
            "com.spotify.client", "com.apple.iTunes", "com.discord.Discord",
            "com.slack.Slack", "us.zoom.videomeetings"
        ]
        
        // Browser applications
        browserProcesses = [
            "com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
            "com.microsoft.edgemac", "com.operasoftware.Opera",
            "com.brave.Browser", "com.vivaldi.Vivaldi"
        ]
        
        // Media applications
        mediaProcesses = [
            "com.spotify.client", "com.apple.iTunes", "com.apple.Music",
            "com.apple.TV", "com.netflix.Netflix", "com.apple.QuickTimePlayerX",
            "com.adobe.Photoshop", "com.adobe.Premiere", "com.blackmagic-design.DaVinciResolve"
        ]
        
        // Developer tools
        developerTools = [
            "com.microsoft.VSCode", "com.apple.Xcode", "com.jetbrains.IntelliJ",
            "com.github.GitHubDesktop", "com.sublimetext.3", "com.panic.Terminal",
            "com.googlecode.iterm2", "com.docker.docker"
        ]
        
        setupProcessPatterns()
    }
    
    private func setupProcessPatterns() {
        systemProcessPatterns = [
            ProcessPattern(name: "^kernel", bundleId: nil, securityLevel: .high),
            ProcessPattern(name: "^com\\.apple\\.", bundleId: nil, securityLevel: .medium),
            ProcessPattern(name: "Helper$", bundleId: nil, securityLevel: .medium),
            ProcessPattern(name: "Agent$", bundleId: nil, securityLevel: .medium),
            ProcessPattern(name: "^/System/", bundleId: nil, securityLevel: .high),
            ProcessPattern(name: "^/usr/libexec/", bundleId: nil, securityLevel: .medium)
        ]
    }
    
    private func loadLearnedBehaviors() {
        // Load from persistent storage (UserDefaults for now)
        if let data = UserDefaults.standard.data(forKey: "ForceQUIT.LearnedBehaviors"),
           let behaviors = try? JSONDecoder().decode([String: ProcessBehavior].self, from: data) {
            learnedBehaviors = behaviors
            logger.info("Loaded \(behaviors.count) learned behaviors")
        }
    }
    
    private func saveLearnedBehaviors() {
        if let data = try? JSONEncoder().encode(learnedBehaviors) {
            UserDefaults.standard.set(data, forKey: "ForceQUIT.LearnedBehaviors")
            logger.debug("Saved \(self.learnedBehaviors.count) learned behaviors")
        }
    }
    
    private func setupClassificationRules() {
        classificationRules = [
            ClassificationRule(
                name: "System Process Rule",
                condition: { app in app.activationPolicy == .prohibited },
                securityLevel: .high,
                canRestart: false
            ),
            ClassificationRule(
                name: "Background Agent Rule", 
                condition: { app in app.activationPolicy == .accessory },
                securityLevel: .medium,
                canRestart: false
            ),
            ClassificationRule(
                name: "User Application Rule",
                condition: { app in app.activationPolicy == .regular },
                securityLevel: .low,
                canRestart: true
            )
        ]
    }
    
    private func isSystemProcess(_ app: NSRunningApplication) -> Bool {
        // System processes typically have prohibited activation policy
        if app.activationPolicy == .prohibited {
            return true
        }
        
        // Check bundle identifier patterns
        if let bundleId = app.bundleIdentifier {
            if bundleId.hasPrefix("com.apple.") && 
               (bundleId.contains("SystemUIServer") || 
                bundleId.contains("WindowServer") ||
                bundleId.contains("loginwindow")) {
                return true
            }
        }
        
        // Check process name patterns
        let processName = app.localizedName ?? ""
        return systemProcessPatterns.contains { pattern in
            pattern.matches(name: processName, bundleId: app.bundleIdentifier)
        }
    }
    
    private func isBackgroundAgent(_ app: NSRunningApplication) -> Bool {
        return app.activationPolicy == .accessory
    }
    
    private func isDangerousProcess(name: String, bundleId: String) -> Bool {
        return dangerousProcesses.contains(name) || dangerousProcesses.contains(bundleId)
    }
    
    private func isCriticalSystemProcess(name: String, pid: pid_t) -> Bool {
        let criticalProcesses = [
            "kernel_task", "launchd", "kextd", "WindowServer",
            "loginwindow", "SystemUIServer", "securityd"
        ]
        
        // Low PIDs are typically system processes
        return criticalProcesses.contains(name) || pid < 100
    }
    
    private func isKernelProcess(name: String) -> Bool {
        return name.hasPrefix("kernel") || name.contains("kext")
    }
    
    private func isSystemDaemon(name: String) -> Bool {
        return name.hasSuffix("d") || name.contains("daemon")
    }
    
    private func isSystemUtility(name: String) -> Bool {
        let utilities = ["syslogd", "cron", "mds", "mdworker", "spotlight"]
        return utilities.contains { name.contains($0) }
    }
    
    private func isDeveloperTool(bundleId: String, name: String) -> Bool {
        let devKeywords = ["code", "xcode", "git", "terminal", "iterm", "docker"]
        return devKeywords.contains { keyword in
            bundleId.lowercased().contains(keyword) || name.lowercased().contains(keyword)
        }
    }
    
    private func isAccessoryAppSafeToRestart(bundleId: String, name: String) -> Bool {
        // Some accessory apps are safe to restart
        let safeAccessoryPatterns = ["helper", "updater", "agent"]
        return safeAccessoryPatterns.contains { pattern in
            bundleId.lowercased().contains(pattern) || name.lowercased().contains(pattern)
        }
    }
    
    private func isMediaApplication(bundleId: String, name: String) -> Bool {
        let mediaKeywords = ["music", "video", "player", "spotify", "itunes", "vlc"]
        return mediaKeywords.contains { keyword in
            bundleId.lowercased().contains(keyword) || name.lowercased().contains(keyword)
        }
    }
    
    private func isSystemUtilityApp(bundleId: String, name: String) -> Bool {
        return bundleId.hasPrefix("com.apple.") && !browserProcesses.contains(bundleId)
    }
    
    private func isGamingApplication(bundleId: String, name: String) -> Bool {
        let gameKeywords = ["game", "steam", "epic", "blizzard", "riot"]
        return gameKeywords.contains { keyword in
            bundleId.lowercased().contains(keyword) || name.lowercased().contains(keyword)
        }
    }
    
    private func isProductivityApp(bundleId: String, name: String) -> Bool {
        let productivityKeywords = ["office", "word", "excel", "powerpoint", "pages", "numbers", "keynote"]
        return productivityKeywords.contains { keyword in
            bundleId.lowercased().contains(keyword) || name.lowercased().contains(keyword)
        }
    }
    
    private func isCommunicationApp(bundleId: String, name: String) -> Bool {
        let commKeywords = ["mail", "message", "slack", "discord", "zoom", "teams", "skype"]
        return commKeywords.contains { keyword in
            bundleId.lowercased().contains(keyword) || name.lowercased().contains(keyword)
        }
    }
    
    private func updateLearnedBehavior(for identifier: String, restartHistory: RestartHistory) {
        var behavior = learnedBehaviors[identifier] ?? ProcessBehavior(identifier: identifier)
        
        behavior.canSafelyRestart = restartHistory.successRate > 0.7
        behavior.restartSuccessRate = restartHistory.successRate
        behavior.lastSeen = Date()
        
        learnedBehaviors[identifier] = behavior
        
        // Persist changes
        saveLearnedBehaviors()
    }
    
    private func trimProcessHistory() {
        if processRestartHistory.count > maxHistoryEntries {
            // Remove oldest entries
            let sortedEntries = processRestartHistory.sorted { $0.value.lastAttempt < $1.value.lastAttempt }
            let toRemove = sortedEntries.prefix(processRestartHistory.count - maxHistoryEntries)
            
            for (key, _) in toRemove {
                processRestartHistory.removeValue(forKey: key)
            }
        }
    }
    
    private func getRecommendationReason(securityLevel: ProcessInfo.SecurityLevel, 
                                       canRestart: Bool, 
                                       behavior: ProcessBehavior?) -> String {
        if securityLevel == .high {
            return "High security process - use graceful termination only"
        }
        
        if canRestart {
            return "Process can be safely restarted"
        }
        
        if let behavior = behavior, behavior.terminationFailureRate > 0.5 {
            return "Process has high termination failure rate - use forceful method"
        }
        
        return "Standard user process - graceful termination recommended"
    }
}

// MARK: - Supporting Types

struct ProcessPattern {
    let nameRegex: NSRegularExpression?
    let bundleIdRegex: NSRegularExpression?
    let securityLevel: ProcessInfo.SecurityLevel
    
    init(name: String?, bundleId: String?, securityLevel: ProcessInfo.SecurityLevel) {
        if let name = name {
            self.nameRegex = try? NSRegularExpression(pattern: name, options: .caseInsensitive)
        } else {
            self.nameRegex = nil
        }
        
        if let bundleId = bundleId {
            self.bundleIdRegex = try? NSRegularExpression(pattern: bundleId, options: .caseInsensitive)
        } else {
            self.bundleIdRegex = nil
        }
        
        self.securityLevel = securityLevel
    }
    
    func matches(name: String, bundleId: String?) -> Bool {
        if let nameRegex = nameRegex {
            let nameRange = NSRange(location: 0, length: name.utf16.count)
            if nameRegex.firstMatch(in: name, options: [], range: nameRange) != nil {
                return true
            }
        }
        
        if let bundleIdRegex = bundleIdRegex, let bundleId = bundleId {
            let bundleIdRange = NSRange(location: 0, length: bundleId.utf16.count)
            if bundleIdRegex.firstMatch(in: bundleId, options: [], range: bundleIdRange) != nil {
                return true
            }
        }
        
        return false
    }
}

struct ClassificationRule {
    let name: String
    let condition: (NSRunningApplication) -> Bool
    let securityLevel: ProcessInfo.SecurityLevel
    let canRestart: Bool
}

struct ProcessBehavior: Codable {
    let identifier: String
    var canSafelyRestart: Bool = false
    var restartSuccessRate: Double = 0.0
    var terminationAttempts: Int = 0
    var terminationFailures: Int = 0
    var lastTerminationMethod: String = ""
    var lastSeen: Date = Date()
    
    var terminationFailureRate: Double {
        guard terminationAttempts > 0 else { return 0.0 }
        return Double(terminationFailures) / Double(terminationAttempts)
    }
    
    init(identifier: String) {
        self.identifier = identifier
    }
}

struct RestartHistory {
    var attemptCount: Int = 0
    var successCount: Int = 0
    var lastAttempt: Date = Date()
    
    var successRate: Double {
        guard attemptCount > 0 else { return 0.0 }
        return Double(successCount) / Double(attemptCount)
    }
}

enum ProcessCategory: String, CaseIterable {
    case browser = "Browser"
    case media = "Media"
    case development = "Development"
    case system = "System"
    case gaming = "Gaming"
    case productivity = "Productivity"
    case communication = "Communication"
    case other = "Other"
    
    var systemImage: String {
        switch self {
        case .browser: return "globe"
        case .media: return "play.rectangle"
        case .development: return "hammer"
        case .system: return "gear"
        case .gaming: return "gamecontroller"
        case .productivity: return "doc.text"
        case .communication: return "message"
        case .other: return "app"
        }
    }
    
    var description: String {
        switch self {
        case .browser: return "Web browsers and related applications"
        case .media: return "Audio, video, and media applications"
        case .development: return "Development tools and IDEs"
        case .system: return "System utilities and preferences"
        case .gaming: return "Games and gaming platforms"
        case .productivity: return "Productivity and office applications"
        case .communication: return "Communication and messaging apps"
        case .other: return "Other applications"
        }
    }
}

struct TerminationRecommendation {
    let strategy: TerminationStrategy
    let confidence: Double
    let reason: String
    
    var isHighConfidence: Bool {
        confidence > 0.8
    }
}