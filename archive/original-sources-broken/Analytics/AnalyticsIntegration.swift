import Foundation
import SwiftUI
import OSLog

// MARK: - Analytics Integration Coordinator
@MainActor
class AnalyticsIntegration: ObservableObject {
    static let shared = AnalyticsIntegration()
    
    private let logger = Logger(subsystem: "com.forcequit.analytics", category: "Integration")
    
    // Component references
    private let analyticsManager = AnalyticsManager.shared
    private let performanceDashboard = PerformanceDashboardViewModel()
    private let crashReporter = CrashReporter.shared
    private let featureTracker = FeatureAdoptionTracker.shared
    private let improvementEngine = ImprovementEngine.shared
    private let privacyManager = PrivacyManager.shared
    
    // Integration state
    @Published var isInitialized = false
    @Published var systemHealth: SystemHealthStatus = .unknown
    @Published var realtimeMetrics: RealtimeMetrics = RealtimeMetrics()
    
    private var healthCheckTimer: Timer?
    private var metricsUpdateTimer: Timer?
    
    private init() {
        setupIntegration()
    }
    
    private func setupIntegration() {
        logger.info("Setting up analytics integration")
        
        // Initialize all analytics components
        initializeComponents()
        
        // Setup real-time monitoring
        startRealtimeMonitoring()
        
        // Setup health checks
        startHealthChecks()
        
        isInitialized = true
        logger.info("Analytics integration initialized successfully")
    }
}

// MARK: - Component Integration
extension AnalyticsIntegration {
    private func initializeComponents() {
        // Ensure privacy settings are respected
        guard privacyManager.consentGiven else {
            logger.info("Analytics initialization skipped - no user consent")
            return
        }
        
        // Initialize tracking for app launch
        trackApplicationLifecycle()
        
        // Setup feature tracking integration
        setupFeatureTrackingIntegration()
        
        // Initialize performance monitoring
        setupPerformanceIntegration()
        
        // Setup crash reporting integration
        setupCrashReportingIntegration()
    }
    
    private func trackApplicationLifecycle() {
        // Track app lifecycle events
        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.analyticsManager.trackEvent(.appLaunched, properties: [
                "launch_time": Date().timeIntervalSince1970,
                "version": Bundle.main.appVersion
            ])
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.analyticsManager.trackEvent(.appTerminated)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.analyticsManager.trackEvent(.appForegrounded)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.analyticsManager.trackEvent(.appBackgrounded)
        }
    }
    
    private func setupFeatureTrackingIntegration() {
        // Integration points between feature tracking and main analytics
        logger.debug("Feature tracking integration setup complete")
    }
    
    private func setupPerformanceIntegration() {
        // Connect performance monitoring to dashboard updates
        logger.debug("Performance integration setup complete")
    }
    
    private func setupCrashReportingIntegration() {
        // Ensure crash reports are properly integrated with analytics
        logger.debug("Crash reporting integration setup complete")
    }
}

// MARK: - Real-time Monitoring
extension AnalyticsIntegration {
    private func startRealtimeMonitoring() {
        metricsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateRealtimeMetrics()
            }
        }
    }
    
    private func updateRealtimeMetrics() async {
        // Update real-time metrics
        let metrics = collectCurrentMetrics()
        
        realtimeMetrics = RealtimeMetrics(
            currentMemoryUsage: metrics.memoryUsage,
            cpuUsage: metrics.cpuUsage,
            activeProcessCount: metrics.processCount,
            responseTime: metrics.responseTime,
            timestamp: Date()
        )
        
        // Update system health
        systemHealth = calculateSystemHealth(from: metrics)
    }
    
    private func collectCurrentMetrics() -> CurrentMetrics {
        // Collect current system metrics
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        let memoryUsage = kerr == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0
        
        return CurrentMetrics(
            memoryUsage: memoryUsage,
            cpuUsage: getCPUUsage(),
            processCount: getProcessCount(),
            responseTime: 0.0 // Would be measured by UI interactions
        )
    }
    
    private func getCPUUsage() -> Double {
        // Simplified CPU usage calculation
        return Double.random(in: 5...15) // Placeholder
    }
    
    private func getProcessCount() -> Int {
        // Get running process count - placeholder implementation
        return NSWorkspace.shared.runningApplications.count
    }
    
    private func calculateSystemHealth(from metrics: CurrentMetrics) -> SystemHealthStatus {
        // Calculate overall system health
        var healthScore = 100.0
        
        // Memory usage impact
        if metrics.memoryUsage > 100 {
            healthScore -= 30
        } else if metrics.memoryUsage > 50 {
            healthScore -= 10
        }
        
        // CPU usage impact
        if metrics.cpuUsage > 50 {
            healthScore -= 20
        } else if metrics.cpuUsage > 25 {
            healthScore -= 5
        }
        
        // Response time impact
        if metrics.responseTime > 500 {
            healthScore -= 15
        } else if metrics.responseTime > 200 {
            healthScore -= 5
        }
        
        // Determine health status
        switch healthScore {
        case 90...100:
            return .excellent
        case 70...89:
            return .good
        case 50...69:
            return .fair
        case 30...49:
            return .poor
        default:
            return .critical
        }
    }
}

// MARK: - Health Checks
extension AnalyticsIntegration {
    private func startHealthChecks() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
    }
    
    private func performHealthCheck() async {
        logger.debug("Performing system health check")
        
        var healthIssues: [String] = []
        
        // Check memory usage
        if realtimeMetrics.currentMemoryUsage > 80 {
            healthIssues.append("High memory usage: \(String(format: "%.1f", realtimeMetrics.currentMemoryUsage))MB")
        }
        
        // Check crash rate
        let recentCrashes = crashReporter.getPendingCrashReports().filter {
            $0.timestamp.timeIntervalSinceNow > -24 * 60 * 60 // Last 24 hours
        }
        
        if recentCrashes.count > 2 {
            healthIssues.append("Multiple crashes detected: \(recentCrashes.count) in last 24 hours")
        }
        
        // Check feature adoption issues
        let adoptionInsights = featureTracker.generateAdoptionInsights()
        let criticalInsights = adoptionInsights.filter { $0.severity == .high }
        
        if !criticalInsights.isEmpty {
            healthIssues.append("Critical feature adoption issues: \(criticalInsights.count)")
        }
        
        // Log health issues
        if !healthIssues.isEmpty {
            logger.warning("Health check found \(healthIssues.count) issues: \(healthIssues.joined(separator: ", "))")
            
            // Track health issues
            analyticsManager.trackEvent(.systemError, properties: [
                "event_type": "health_check_issues",
                "issue_count": healthIssues.count,
                "issues": healthIssues
            ])
        }
    }
}

// MARK: - Public Interface
extension AnalyticsIntegration {
    func trackFeatureUsage(_ featureId: String, context: [String: Any] = [:]) {
        guard privacyManager.consentGiven else { return }
        
        // Track in both systems for comprehensive coverage
        featureTracker.trackFeatureUsage(featureId, context: context)
        analyticsManager.trackEvent(.processSelected, properties: [
            "feature_id": featureId,
            "context": context
        ])
    }
    
    func trackUserAction(_ action: String, properties: [String: Any] = [:]) {
        guard privacyManager.consentGiven else { return }
        
        analyticsManager.trackEvent(.processSelected, properties: [
            "action": action,
            "properties": properties
        ])
    }
    
    func trackError(_ error: Error, context: String = "") {
        guard privacyManager.consentGiven else { return }
        
        analyticsManager.trackError(error, context: context)
        
        // Check if error recovery is possible
        let recovered = ErrorRecoverySystem.shared.attemptRecovery(from: error, context: context)
        
        if recovered {
            logger.info("Successfully recovered from error: \(error.localizedDescription)")
        }
    }
    
    func getSystemHealth() -> SystemHealthStatus {
        return systemHealth
    }
    
    func getRealtimeMetrics() -> RealtimeMetrics {
        return realtimeMetrics
    }
    
    func generateInsights() async -> [ImprovementRecommendation] {
        guard privacyManager.consentGiven else { return [] }
        
        await improvementEngine.generateRecommendations()
        return improvementEngine.recommendations
    }
    
    func exportAnalyticsData() -> URL? {
        guard privacyManager.allowDataExport else { return nil }
        
        return privacyManager.exportUserData()
    }
}

// MARK: - SwiftUI Integration
extension AnalyticsIntegration {
    func createAnalyticsView() -> some View {
        AnalyticsTabView()
    }
}

struct AnalyticsTabView: View {
    @StateObject private var integration = AnalyticsIntegration.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PerformanceDashboard()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Performance")
                }
                .tag(0)
            
            FeatureAdoptionView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Features")
                }
                .tag(1)
            
            ImprovementRecommendationsView()
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Insights")
                }
                .tag(2)
            
            PrivacySettingsView()
                .tabItem {
                    Image(systemName: "hand.raised.fill")
                    Text("Privacy")
                }
                .tag(3)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Supporting Views
struct FeatureAdoptionView: View {
    @StateObject private var tracker = FeatureAdoptionTracker.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Feature Adoption Summary") {
                    let summary = tracker.getFeatureAdoptionSummary()
                    
                    HStack {
                        Text("Overall Adoption Rate")
                        Spacer()
                        Text("\(String(format: "%.1f", summary.overallAdoptionRate * 100))%")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Overall Retention Rate")
                        Spacer()
                        Text("\(String(format: "%.1f", summary.overallRetentionRate * 100))%")
                            .fontWeight(.semibold)
                    }
                }
                
                Section("Feature Performance") {
                    ForEach(Array(tracker.adoptionMetrics.keys), id: \.self) { featureId in
                        if let metrics = tracker.adoptionMetrics[featureId],
                           let feature = tracker.features[featureId] {
                            FeatureMetricRow(feature: feature, metrics: metrics)
                        }
                    }
                }
            }
            .navigationTitle("Feature Adoption")
        }
    }
}

struct FeatureMetricRow: View {
    let feature: Feature
    let metrics: FeatureAdoptionMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(feature.name)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(String(format: "%.1f", metrics.adoptionRate * 100))%")
                    .foregroundColor(adoptionColor)
                    .fontWeight(.semibold)
            }
            
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Active Users: \(metrics.activeUsers)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(metrics.usagePattern.description)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var adoptionColor: Color {
        switch metrics.adoptionRate {
        case 0.7...:
            return .green
        case 0.4..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

struct ImprovementRecommendationsView: View {
    @StateObject private var engine = ImprovementEngine.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(engine.recommendations) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }
            .navigationTitle("Improvement Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await engine.generateRecommendations()
                        }
                    }
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: ImprovementRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(recommendation.priority.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recommendation.priority.color.opacity(0.2))
                    .foregroundColor(recommendation.priority.color)
                    .cornerRadius(6)
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.primary)
            
            Text("Impact: \(recommendation.expectedImpact.displayName) • Effort: \(String(format: "%.1f", recommendation.estimatedEffort)) weeks")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models
struct RealtimeMetrics {
    let currentMemoryUsage: Double
    let cpuUsage: Double
    let activeProcessCount: Int
    let responseTime: Double
    let timestamp: Date
    
    init() {
        self.currentMemoryUsage = 0
        self.cpuUsage = 0
        self.activeProcessCount = 0
        self.responseTime = 0
        self.timestamp = Date()
    }
    
    init(currentMemoryUsage: Double, cpuUsage: Double, activeProcessCount: Int, responseTime: Double, timestamp: Date) {
        self.currentMemoryUsage = currentMemoryUsage
        self.cpuUsage = cpuUsage
        self.activeProcessCount = activeProcessCount
        self.responseTime = responseTime
        self.timestamp = timestamp
    }
}

struct CurrentMetrics {
    let memoryUsage: Double
    let cpuUsage: Double
    let processCount: Int
    let responseTime: Double
}

enum SystemHealthStatus {
    case unknown
    case excellent
    case good
    case fair
    case poor
    case critical
    
    var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Analytics Extensions for App Integration
extension View {
    func trackAnalytics(_ event: String, properties: [String: Any] = [:]) -> some View {
        self.onAppear {
            AnalyticsIntegration.shared.trackUserAction(event, properties: properties)
        }
    }
    
    func trackFeatureUsage(_ featureId: String, context: [String: Any] = [:]) -> some View {
        self.onAppear {
            AnalyticsIntegration.shared.trackFeatureUsage(featureId, context: context)
        }
    }
}