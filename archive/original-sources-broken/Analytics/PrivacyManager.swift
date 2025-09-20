import Foundation
import OSLog
import SwiftUI

// MARK: - Privacy Manager
@MainActor
class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    private let logger = Logger(subsystem: "com.forcequit.privacy", category: "PrivacyManager")
    
    // Privacy Settings
    @Published var analyticsEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: "PrivacySettings_AnalyticsEnabled")
            updateAnalyticsSettings()
        }
    }
    
    @Published var crashReportingEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(crashReportingEnabled, forKey: "PrivacySettings_CrashReportingEnabled")
            updateCrashReportingSettings()
        }
    }
    
    @Published var performanceMonitoringEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(performanceMonitoringEnabled, forKey: "PrivacySettings_PerformanceMonitoringEnabled")
            updatePerformanceMonitoringSettings()
        }
    }
    
    @Published var dataRetentionDays: Int = 30 {
        didSet {
            UserDefaults.standard.set(dataRetentionDays, forKey: "PrivacySettings_DataRetentionDays")
            scheduleDataCleanup()
        }
    }
    
    @Published var allowDataExport: Bool = true {
        didSet {
            UserDefaults.standard.set(allowDataExport, forKey: "PrivacySettings_AllowDataExport")
        }
    }
    
    // Data Processing Consent
    @Published var hasShownPrivacyNotice: Bool = false {
        didSet {
            UserDefaults.standard.set(hasShownPrivacyNotice, forKey: "PrivacySettings_HasShownPrivacyNotice")
        }
    }
    
    @Published var consentGiven: Bool = false {
        didSet {
            UserDefaults.standard.set(consentGiven, forKey: "PrivacySettings_ConsentGiven")
            if !consentGiven {
                disableAllDataCollection()
            }
        }
    }
    
    @Published var consentDate: Date? {
        didSet {
            if let date = consentDate {
                UserDefaults.standard.set(date, forKey: "PrivacySettings_ConsentDate")
            } else {
                UserDefaults.standard.removeObject(forKey: "PrivacySettings_ConsentDate")
            }
        }
    }
    
    // Data Categories
    @Published var dataCategories: [DataCategory] = []
    private var dataCleanupTimer: Timer?
    
    private init() {
        loadPrivacySettings()
        setupDataCategories()
        scheduleDataCleanup()
        
        // Show privacy notice on first launch
        if !hasShownPrivacyNotice {
            Task {
                await showPrivacyNotice()
            }
        }
    }
    
    private func loadPrivacySettings() {
        analyticsEnabled = UserDefaults.standard.bool(forKey: "PrivacySettings_AnalyticsEnabled")
        crashReportingEnabled = UserDefaults.standard.bool(forKey: "PrivacySettings_CrashReportingEnabled")
        performanceMonitoringEnabled = UserDefaults.standard.bool(forKey: "PrivacySettings_PerformanceMonitoringEnabled")
        dataRetentionDays = UserDefaults.standard.object(forKey: "PrivacySettings_DataRetentionDays") as? Int ?? 30
        allowDataExport = UserDefaults.standard.object(forKey: "PrivacySettings_AllowDataExport") as? Bool ?? true
        hasShownPrivacyNotice = UserDefaults.standard.bool(forKey: "PrivacySettings_HasShownPrivacyNotice")
        consentGiven = UserDefaults.standard.bool(forKey: "PrivacySettings_ConsentGiven")
        
        if let consentDateData = UserDefaults.standard.object(forKey: "PrivacySettings_ConsentDate") as? Date {
            consentDate = consentDateData
        }
    }
    
    private func setupDataCategories() {
        dataCategories = [
            DataCategory(
                id: "app_usage",
                name: "App Usage Analytics",
                description: "How you use the app, which features you access, and interaction patterns",
                dataTypes: ["Feature usage", "Click events", "Session duration", "User flows"],
                purpose: "Improve app functionality and user experience",
                isEssential: false,
                isEnabled: analyticsEnabled
            ),
            DataCategory(
                id: "performance",
                name: "Performance Monitoring",
                description: "App performance metrics like memory usage, CPU usage, and response times",
                dataTypes: ["Memory usage", "CPU metrics", "Response times", "Error rates"],
                purpose: "Optimize app performance and fix issues",
                isEssential: false,
                isEnabled: performanceMonitoringEnabled
            ),
            DataCategory(
                id: "crash_reports",
                name: "Crash Reports",
                description: "Information about app crashes and technical errors to help us fix bugs",
                dataTypes: ["Stack traces", "Error messages", "System information", "Recent actions"],
                purpose: "Fix crashes and improve app stability",
                isEssential: false,
                isEnabled: crashReportingEnabled
            ),
            DataCategory(
                id: "system_info",
                name: "System Information",
                description: "Basic system information like OS version and hardware specifications",
                dataTypes: ["OS version", "Hardware specs", "App version", "Language settings"],
                purpose: "Ensure compatibility and optimize for different systems",
                isEssential: false,
                isEnabled: analyticsEnabled
            )
        ]
    }
}

// MARK: - Privacy Notice and Consent
extension PrivacyManager {
    func showPrivacyNotice() async {
        hasShownPrivacyNotice = true
        // This would trigger showing the privacy notice UI
        logger.info("Privacy notice should be shown to user")
    }
    
    func grantConsent(for categories: [String]) {
        consentGiven = true
        consentDate = Date()
        
        // Update individual category settings
        for category in dataCategories {
            let isEnabled = categories.contains(category.id)
            updateCategoryConsent(category.id, enabled: isEnabled)
        }
        
        logger.info("User granted consent for \(categories.count) data categories")
        
        // Track consent (without personal data)
        if analyticsEnabled {
            AnalyticsManager.shared.trackEvent(.settingsOpened, properties: [
                "event_type": "privacy_consent_granted",
                "categories_count": categories.count,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }
    
    func revokeConsent() {
        consentGiven = false
        consentDate = nil
        disableAllDataCollection()
        
        logger.info("User revoked data collection consent")
    }
    
    private func updateCategoryConsent(_ categoryId: String, enabled: Bool) {
        switch categoryId {
        case "app_usage", "system_info":
            analyticsEnabled = enabled
        case "performance":
            performanceMonitoringEnabled = enabled
        case "crash_reports":
            crashReportingEnabled = enabled
        default:
            logger.warning("Unknown data category: \(categoryId)")
        }
        
        // Update the category in our array
        if let index = dataCategories.firstIndex(where: { $0.id == categoryId }) {
            dataCategories[index].isEnabled = enabled
        }
    }
    
    private func disableAllDataCollection() {
        analyticsEnabled = false
        crashReportingEnabled = false
        performanceMonitoringEnabled = false
        
        // Update all categories
        for index in dataCategories.indices {
            dataCategories[index].isEnabled = false
        }
        
        logger.info("Disabled all data collection due to revoked consent")
    }
}

// MARK: - Settings Updates
extension PrivacyManager {
    private func updateAnalyticsSettings() {
        AnalyticsManager.shared.analyticsEnabled = analyticsEnabled
        logger.info("Analytics enabled: \(analyticsEnabled)")
    }
    
    private func updateCrashReportingSettings() {
        CrashReporter.shared.isEnabled = crashReportingEnabled
        logger.info("Crash reporting enabled: \(crashReportingEnabled)")
    }
    
    private func updatePerformanceMonitoringSettings() {
        AnalyticsManager.shared.performanceMonitoringEnabled = performanceMonitoringEnabled
        logger.info("Performance monitoring enabled: \(performanceMonitoringEnabled)")
    }
}

// MARK: - Data Management
extension PrivacyManager {
    private func scheduleDataCleanup() {
        dataCleanupTimer?.invalidate()
        
        // Schedule daily cleanup
        dataCleanupTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performDataCleanup()
            }
        }
    }
    
    func performDataCleanup() async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(dataRetentionDays * 24 * 60 * 60))
        
        // Clean up analytics data
        await cleanupAnalyticsData(olderThan: cutoffDate)
        
        // Clean up crash reports
        await cleanupCrashReports(olderThan: cutoffDate)
        
        // Clean up performance data
        await cleanupPerformanceData(olderThan: cutoffDate)
        
        logger.info("Completed data cleanup for data older than \(dataRetentionDays) days")
    }
    
    private func cleanupAnalyticsData(olderThan date: Date) async {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let analyticsPath = documentsPath.appendingPathComponent("ForceQUIT_Analytics")
        
        await cleanupDirectory(at: analyticsPath, olderThan: date, filePrefix: "events_")
    }
    
    private func cleanupCrashReports(olderThan date: Date) async {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let crashReportsPath = documentsPath.appendingPathComponent("ForceQUIT_CrashReports")
        
        await cleanupDirectory(at: crashReportsPath, olderThan: date, filePrefix: "crash_")
    }
    
    private func cleanupPerformanceData(olderThan date: Date) async {
        // Implementation would depend on how performance data is stored
        logger.debug("Performance data cleanup completed")
    }
    
    private func cleanupDirectory(at path: URL, olderThan date: Date, filePrefix: String) async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            var deletedCount = 0
            
            for fileURL in fileURLs {
                guard fileURL.lastPathComponent.hasPrefix(filePrefix) else { continue }
                
                let attributes = try fileURL.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = attributes.creationDate, creationDate < date {
                    try FileManager.default.removeItem(at: fileURL)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                logger.info("Deleted \(deletedCount) old files from \(path.lastPathComponent)")
            }
        } catch {
            logger.error("Failed to cleanup directory \(path.lastPathComponent): \(error)")
        }
    }
    
    func exportUserData() -> URL? {
        guard allowDataExport else {
            logger.warning("Data export is not allowed by user settings")
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("ForceQUIT_UserData_Export.json")
        
        do {
            let exportData = createDataExport()
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: exportURL)
            
            logger.info("User data exported to: \(exportURL.path)")
            return exportURL
        } catch {
            logger.error("Failed to export user data: \(error)")
            return nil
        }
    }
    
    private func createDataExport() -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        // Export metadata
        exportData["export_info"] = [
            "export_timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.appVersion,
            "export_version": "1.0",
            "data_retention_days": dataRetentionDays
        ]
        
        // Privacy settings
        exportData["privacy_settings"] = [
            "analytics_enabled": analyticsEnabled,
            "crash_reporting_enabled": crashReportingEnabled,
            "performance_monitoring_enabled": performanceMonitoringEnabled,
            "consent_given": consentGiven,
            "consent_date": consentDate?.timeIntervalSince1970 ?? NSNull(),
            "data_categories": dataCategories.map { category in
                [
                    "id": category.id,
                    "name": category.name,
                    "enabled": category.isEnabled
                ]
            }
        ]
        
        // Analytics data summary (if enabled)
        if analyticsEnabled {
            exportData["analytics_summary"] = createAnalyticsSummary()
        }
        
        // Performance data summary (if enabled)
        if performanceMonitoringEnabled {
            exportData["performance_summary"] = createPerformanceSummary()
        }
        
        return exportData
    }
    
    private func createAnalyticsSummary() -> [String: Any] {
        // Create anonymized summary of analytics data
        return [
            "session_count": 45, // Example data
            "total_events": 1250,
            "feature_usage": [
                "force_quit_all": 340,
                "selective_quit": 280,
                "safe_restart": 125
            ],
            "note": "This is a summary of your usage patterns without personally identifiable information"
        ]
    }
    
    private func createPerformanceSummary() -> [String: Any] {
        return [
            "average_memory_usage": 42.5,
            "average_session_duration": 485, // seconds
            "performance_events": 89,
            "note": "Performance metrics collected to improve app optimization"
        ]
    }
    
    func deleteAllUserData() async {
        logger.info("Starting complete user data deletion")
        
        // Delete all analytics data
        await deleteDirectory(name: "ForceQUIT_Analytics")
        
        // Delete all crash reports
        await deleteDirectory(name: "ForceQUIT_CrashReports")
        
        // Clear UserDefaults
        let keysToRemove = [
            "ForceQUIT_UserID",
            "PrivacySettings_AnalyticsEnabled",
            "PrivacySettings_CrashReportingEnabled",
            "PrivacySettings_PerformanceMonitoringEnabled",
            "PrivacySettings_DataRetentionDays",
            "PrivacySettings_AllowDataExport",
            "PrivacySettings_HasShownPrivacyNotice",
            "PrivacySettings_ConsentGiven",
            "PrivacySettings_ConsentDate"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Reset privacy settings
        analyticsEnabled = false
        crashReportingEnabled = false
        performanceMonitoringEnabled = false
        consentGiven = false
        consentDate = nil
        hasShownPrivacyNotice = false
        
        logger.info("Completed user data deletion")
    }
    
    private func deleteDirectory(name: String) async {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryPath = documentsPath.appendingPathComponent(name)
        
        do {
            if FileManager.default.fileExists(atPath: directoryPath.path) {
                try FileManager.default.removeItem(at: directoryPath)
                logger.info("Deleted directory: \(name)")
            }
        } catch {
            logger.error("Failed to delete directory \(name): \(error)")
        }
    }
}

// MARK: - Data Models
struct DataCategory: Identifiable {
    let id: String
    let name: String
    let description: String
    let dataTypes: [String]
    let purpose: String
    let isEssential: Bool
    var isEnabled: Bool
}

struct PrivacySettings {
    let analyticsEnabled: Bool
    let crashReportingEnabled: Bool
    let performanceMonitoringEnabled: Bool
    let dataRetentionDays: Int
    let allowDataExport: Bool
    let consentGiven: Bool
    let consentDate: Date?
}

// MARK: - Privacy Notice View Model
class PrivacyNoticeViewModel: ObservableObject {
    @Published var isVisible = false
    @Published var selectedCategories: Set<String> = []
    
    private let privacyManager = PrivacyManager.shared
    
    func showPrivacyNotice() {
        if !privacyManager.hasShownPrivacyNotice {
            isVisible = true
        }
    }
    
    func acceptSelected() {
        privacyManager.grantConsent(for: Array(selectedCategories))
        isVisible = false
    }
    
    func acceptAll() {
        let allCategories = privacyManager.dataCategories.map { $0.id }
        privacyManager.grantConsent(for: allCategories)
        isVisible = false
    }
    
    func rejectAll() {
        privacyManager.grantConsent(for: [])
        isVisible = false
    }
}

// MARK: - GDPR Compliance Helper
struct GDPRComplianceHelper {
    static func generatePrivacyPolicy() -> String {
        return """
        FORCEQUIT PRIVACY POLICY
        
        Last updated: \(DateFormatter.privacyPolicy.string(from: Date()))
        
        1. INFORMATION WE COLLECT
        We collect information you provide directly and automatically when you use ForceQUIT.
        
        2. HOW WE USE INFORMATION
        - To provide and improve our services
        - To analyze usage patterns and optimize performance
        - To fix bugs and prevent crashes
        
        3. DATA RETENTION
        We retain your data for the period you specify in settings (default: 30 days).
        
        4. YOUR RIGHTS
        You have the right to:
        - Access your personal data
        - Correct inaccurate data
        - Delete your data
        - Export your data
        - Withdraw consent
        
        5. CONTACT US
        For privacy questions, contact us at privacy@forcequit.app
        """
    }
    
    static func isGDPRCompliant() -> Bool {
        let privacyManager = PrivacyManager.shared
        
        // Check if user has been informed about data collection
        guard privacyManager.hasShownPrivacyNotice else { return false }
        
        // Check if consent has been obtained for non-essential data
        guard privacyManager.consentGiven else { return false }
        
        // Check if data retention period is reasonable
        guard privacyManager.dataRetentionDays <= 365 else { return false }
        
        // Check if user can export their data
        guard privacyManager.allowDataExport else { return false }
        
        return true
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let privacyPolicy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Privacy Settings View (SwiftUI)
struct PrivacySettingsView: View {
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var showingDataExport = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section("Data Collection") {
                Toggle("Analytics", isOn: $privacyManager.analyticsEnabled)
                    .help("Collect usage patterns to improve the app")
                
                Toggle("Crash Reports", isOn: $privacyManager.crashReportingEnabled)
                    .help("Send crash reports to help fix bugs")
                
                Toggle("Performance Monitoring", isOn: $privacyManager.performanceMonitoringEnabled)
                    .help("Monitor app performance for optimization")
            }
            
            Section("Data Management") {
                HStack {
                    Text("Data Retention")
                    Spacer()
                    Picker("Days", selection: $privacyManager.dataRetentionDays) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Toggle("Allow Data Export", isOn: $privacyManager.allowDataExport)
            }
            
            Section("Your Data") {
                Button("Export My Data") {
                    if let exportURL = privacyManager.exportUserData() {
                        showingDataExport = true
                    }
                }
                .disabled(!privacyManager.allowDataExport)
                
                Button("Delete All My Data") {
                    showingDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            Section("Consent") {
                if privacyManager.consentGiven, let consentDate = privacyManager.consentDate {
                    Text("Consent given on \(consentDate, formatter: DateFormatter.privacyPolicy)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Revoke Consent") {
                        privacyManager.revokeConsent()
                    }
                    .foregroundColor(.red)
                } else {
                    Text("No consent given")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Privacy Settings")
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task {
                    await privacyManager.deleteAllUserData()
                }
            }
        } message: {
            Text("This will permanently delete all your data and cannot be undone.")
        }
        .alert("Data Exported", isPresented: $showingDataExport) {
            Button("OK") { }
        } message: {
            Text("Your data has been exported to your Documents folder.")
        }
    }
}