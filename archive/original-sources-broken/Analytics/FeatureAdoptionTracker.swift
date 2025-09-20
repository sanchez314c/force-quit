import Foundation
import OSLog
import SwiftUI

// MARK: - Feature Definition
struct Feature {
    let id: String
    let name: String
    let description: String
    let category: FeatureCategory
    let releaseVersion: String
    let isEnabled: Bool
    let prerequisites: [String]
    let metrics: [String]
}

enum FeatureCategory {
    case core
    case ui
    case performance
    case automation
    case settings
    case accessibility
    
    var displayName: String {
        switch self {
        case .core: return "Core Functionality"
        case .ui: return "User Interface"
        case .performance: return "Performance"
        case .automation: return "Automation"
        case .settings: return "Settings"
        case .accessibility: return "Accessibility"
        }
    }
}

// MARK: - Adoption Metrics
struct FeatureAdoptionMetrics {
    let featureId: String
    let totalUsers: Int
    let activeUsers: Int
    let adoptionRate: Double
    let retentionRate: Double
    let averageUsageFrequency: Double
    let timeToFirstUse: TimeInterval?
    let lastUsed: Date?
    let usagePattern: UsagePattern
    let userSegments: [UserSegmentAdoption]
}

struct UserSegmentAdoption {
    let segment: String
    let adoptionRate: Double
    let usageFrequency: Double
    let satisfaction: Double?
}

enum UsagePattern {
    case frequent    // Daily usage
    case regular     // Weekly usage
    case occasional  // Monthly usage
    case trial       // Used once or twice
    case abandoned   // Not used in 30+ days
    
    var description: String {
        switch self {
        case .frequent: return "Daily Active Users"
        case .regular: return "Weekly Active Users"
        case .occasional: return "Monthly Active Users"
        case .trial: return "Trial Users"
        case .abandoned: return "Abandoned Feature"
        }
    }
}

// MARK: - Feature Adoption Tracker
@MainActor
class FeatureAdoptionTracker: ObservableObject {
    static let shared = FeatureAdoptionTracker()
    
    private let logger = Logger(subsystem: "com.forcequit.adoption", category: "FeatureAdoption")
    
    @Published var features: [String: Feature] = [:]
    @Published var adoptionMetrics: [String: FeatureAdoptionMetrics] = [:]
    @Published var userJourney: [FeatureInteraction] = []
    
    private var featureUsageData: [String: [FeatureUsageEvent]] = [:]
    private let maxJourneyLength = 100
    
    private init() {
        setupDefaultFeatures()
        loadAdoptionData()
    }
    
    private func setupDefaultFeatures() {
        features = [
            "force_quit_all": Feature(
                id: "force_quit_all",
                name: "Force Quit All",
                description: "Quit all running applications at once",
                category: .core,
                releaseVersion: "1.0.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["usage_count", "success_rate", "time_to_complete"]
            ),
            "selective_quit": Feature(
                id: "selective_quit",
                name: "Selective Force Quit",
                description: "Choose specific applications to force quit",
                category: .core,
                releaseVersion: "1.0.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["usage_count", "selection_accuracy", "time_to_complete"]
            ),
            "safe_restart": Feature(
                id: "safe_restart",
                name: "Safe Restart",
                description: "Safely restart applications that support it",
                category: .core,
                releaseVersion: "1.1.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["usage_count", "success_rate", "user_preference"]
            ),
            "hotkey_control": Feature(
                id: "hotkey_control",
                name: "Hotkey Control",
                description: "Global hotkeys for quick access",
                category: .automation,
                releaseVersion: "1.0.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["setup_rate", "usage_frequency", "customization_rate"]
            ),
            "dark_mode": Feature(
                id: "dark_mode",
                name: "Dark Mode",
                description: "Dark theme for better visual experience",
                category: .ui,
                releaseVersion: "1.0.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["adoption_rate", "preference_stickiness"]
            ),
            "process_filtering": Feature(
                id: "process_filtering",
                name: "Process Filtering",
                description: "Filter and search through running processes",
                category: .ui,
                releaseVersion: "1.2.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["usage_count", "search_accuracy", "time_saved"]
            ),
            "startup_launch": Feature(
                id: "startup_launch",
                name: "Launch at Startup",
                description: "Automatically launch ForceQUIT at system startup",
                category: .settings,
                releaseVersion: "1.0.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["adoption_rate", "retention_after_enable"]
            ),
            "accessibility_mode": Feature(
                id: "accessibility_mode",
                name: "Accessibility Mode",
                description: "Enhanced accessibility features and navigation",
                category: .accessibility,
                releaseVersion: "1.3.0",
                isEnabled: true,
                prerequisites: [],
                metrics: ["adoption_rate", "user_satisfaction", "usage_duration"]
            )
        ]
    }
}

// MARK: - Feature Usage Tracking
extension FeatureAdoptionTracker {
    func trackFeatureUsage(_ featureId: String, context: [String: Any] = [:]) {
        guard let feature = features[featureId] else {
            logger.warning("Attempted to track usage for unknown feature: \(featureId)")
            return
        }
        
        let usageEvent = FeatureUsageEvent(
            featureId: featureId,
            timestamp: Date(),
            userId: AnalyticsManager.shared.userId,
            sessionId: AnalyticsManager.shared.sessionId,
            context: context
        )
        
        // Add to feature usage data
        if featureUsageData[featureId] == nil {
            featureUsageData[featureId] = []
        }
        featureUsageData[featureId]?.append(usageEvent)
        
        // Add to user journey
        let interaction = FeatureInteraction(
            featureId: featureId,
            featureName: feature.name,
            timestamp: Date(),
            interactionType: .used,
            context: context
        )
        
        userJourney.append(interaction)
        
        // Keep journey length manageable
        if userJourney.count > maxJourneyLength {
            userJourney.removeFirst(maxJourneyLength / 2)
        }
        
        // Track analytics event
        AnalyticsManager.shared.trackEvent(.processSelected, properties: [
            "feature_id": featureId,
            "feature_name": feature.name,
            "feature_category": feature.category.displayName,
            "context": context
        ])
        
        // Update adoption metrics
        updateAdoptionMetrics(for: featureId)
        
        logger.debug("Tracked usage for feature: \(featureId)")
    }
    
    func trackFeatureDiscovery(_ featureId: String, discoveryMethod: DiscoveryMethod, context: [String: Any] = [:]) {
        guard let feature = features[featureId] else { return }
        
        let interaction = FeatureInteraction(
            featureId: featureId,
            featureName: feature.name,
            timestamp: Date(),
            interactionType: .discovered,
            context: context
        )
        
        userJourney.append(interaction)
        
        var trackingContext = context
        trackingContext["discovery_method"] = discoveryMethod.rawValue
        
        AnalyticsManager.shared.trackEvent(.windowOpened, properties: [
            "feature_id": featureId,
            "feature_name": feature.name,
            "discovery_method": discoveryMethod.rawValue,
            "context": trackingContext
        ])
        
        logger.info("Feature discovered: \(featureId) via \(discoveryMethod.rawValue)")
    }
    
    func trackFeatureOnboarding(_ featureId: String, step: OnboardingStep, completed: Bool) {
        guard let feature = features[featureId] else { return }
        
        let interaction = FeatureInteraction(
            featureId: featureId,
            featureName: feature.name,
            timestamp: Date(),
            interactionType: completed ? .onboardingCompleted : .onboardingStarted,
            context: ["step": step.rawValue, "completed": completed]
        )
        
        userJourney.append(interaction)
        
        AnalyticsManager.shared.trackEvent(.settingsOpened, properties: [
            "feature_id": featureId,
            "onboarding_step": step.rawValue,
            "completed": completed
        ])
    }
}

// MARK: - Adoption Metrics Calculation
extension FeatureAdoptionTracker {
    private func updateAdoptionMetrics(for featureId: String) {
        guard let usageEvents = featureUsageData[featureId] else { return }
        
        let uniqueUsers = Set(usageEvents.map { $0.userId }).count
        let totalUsers = getTotalUserCount()
        let adoptionRate = totalUsers > 0 ? Double(uniqueUsers) / Double(totalUsers) : 0.0
        
        let now = Date()
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let recentEvents = usageEvents.filter { $0.timestamp >= thirtyDaysAgo }
        let recentActiveUsers = Set(recentEvents.map { $0.userId }).count
        
        let retentionRate = uniqueUsers > 0 ? Double(recentActiveUsers) / Double(uniqueUsers) : 0.0
        
        // Calculate usage frequency
        let averageUsageFrequency = uniqueUsers > 0 ? Double(usageEvents.count) / Double(uniqueUsers) : 0.0
        
        // Determine usage pattern
        let usagePattern = determineUsagePattern(for: featureId, events: usageEvents)
        
        // Calculate time to first use
        let firstUseTime = calculateTimeToFirstUse(for: featureId)
        
        // Get user segment adoption
        let userSegments = calculateUserSegmentAdoption(for: featureId, events: usageEvents)
        
        let metrics = FeatureAdoptionMetrics(
            featureId: featureId,
            totalUsers: totalUsers,
            activeUsers: uniqueUsers,
            adoptionRate: adoptionRate,
            retentionRate: retentionRate,
            averageUsageFrequency: averageUsageFrequency,
            timeToFirstUse: firstUseTime,
            lastUsed: usageEvents.last?.timestamp,
            usagePattern: usagePattern,
            userSegments: userSegments
        )
        
        adoptionMetrics[featureId] = metrics
    }
    
    private func determineUsagePattern(for featureId: String, events: [FeatureUsageEvent]) -> UsagePattern {
        guard !events.isEmpty else { return .trial }
        
        let now = Date()
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        
        let recentEvents = events.filter { $0.timestamp >= sevenDaysAgo }
        let monthlyEvents = events.filter { $0.timestamp >= thirtyDaysAgo }
        
        if events.last?.timestamp.timeIntervalSince(now) ?? 0 < -30 * 24 * 60 * 60 {
            return .abandoned
        }
        
        if recentEvents.count >= 7 {
            return .frequent
        } else if recentEvents.count >= 2 {
            return .regular
        } else if monthlyEvents.count >= 2 {
            return .occasional
        } else {
            return .trial
        }
    }
    
    private func calculateTimeToFirstUse(for featureId: String) -> TimeInterval? {
        // This would require tracking when features are first exposed to users
        // For now, return nil - implement based on specific requirements
        return nil
    }
    
    private func calculateUserSegmentAdoption(for featureId: String, events: [FeatureUsageEvent]) -> [UserSegmentAdoption] {
        // Simplified implementation - in production, integrate with user segmentation system
        return [
            UserSegmentAdoption(segment: "New Users", adoptionRate: 0.65, usageFrequency: 2.3, satisfaction: 4.2),
            UserSegmentAdoption(segment: "Power Users", adoptionRate: 0.89, usageFrequency: 8.7, satisfaction: 4.6),
            UserSegmentAdoption(segment: "Casual Users", adoptionRate: 0.34, usageFrequency: 1.1, satisfaction: 3.8)
        ]
    }
    
    private func getTotalUserCount() -> Int {
        // In production, this would query your user analytics system
        return 1000 // Placeholder
    }
}

// MARK: - Analytics and Insights
extension FeatureAdoptionTracker {
    func generateAdoptionInsights() -> [FeatureAdoptionInsight] {
        var insights: [FeatureAdoptionInsight] = []
        
        for (featureId, metrics) in adoptionMetrics {
            guard let feature = features[featureId] else { continue }
            
            // Low adoption insight
            if metrics.adoptionRate < 0.3 {
                insights.append(FeatureAdoptionInsight(
                    featureId: featureId,
                    featureName: feature.name,
                    type: .lowAdoption,
                    severity: .high,
                    description: "Feature has low adoption rate of \(String(format: "%.1f", metrics.adoptionRate * 100))%",
                    recommendation: "Consider improving feature discoverability, adding onboarding, or simplifying the user experience",
                    confidence: 0.85
                ))
            }
            
            // High abandonment insight
            if metrics.usagePattern == .abandoned && metrics.adoptionRate > 0.1 {
                insights.append(FeatureAdoptionInsight(
                    featureId: featureId,
                    featureName: feature.name,
                    type: .highAbandonment,
                    severity: .medium,
                    description: "Feature shows signs of user abandonment despite initial adoption",
                    recommendation: "Investigate user feedback and usage barriers. Consider feature improvements or better integration",
                    confidence: 0.78
                ))
            }
            
            // Success story insight
            if metrics.adoptionRate > 0.7 && metrics.retentionRate > 0.8 {
                insights.append(FeatureAdoptionInsight(
                    featureId: featureId,
                    featureName: feature.name,
                    type: .successStory,
                    severity: .low,
                    description: "Feature shows excellent adoption (\(String(format: "%.1f", metrics.adoptionRate * 100))%) and retention (\(String(format: "%.1f", metrics.retentionRate * 100))%)",
                    recommendation: "Use this feature's success patterns as a template for other features",
                    confidence: 0.92
                ))
            }
            
            // Onboarding opportunity
            if metrics.timeToFirstUse != nil && metrics.timeToFirstUse! > 7 * 24 * 60 * 60 {
                insights.append(FeatureAdoptionInsight(
                    featureId: featureId,
                    featureName: feature.name,
                    type: .onboardingOpportunity,
                    severity: .medium,
                    description: "Users take an average of \(Int(metrics.timeToFirstUse! / (24 * 60 * 60))) days to first use this feature",
                    recommendation: "Implement guided onboarding or contextual hints to reduce time to first value",
                    confidence: 0.71
                ))
            }
        }
        
        return insights.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    func getFeatureAdoptionSummary() -> FeatureAdoptionSummary {
        let totalFeatures = features.count
        let featuresWithMetrics = adoptionMetrics.count
        
        let overallAdoptionRate = adoptionMetrics.values.map { $0.adoptionRate }.reduce(0, +) / Double(max(featuresWithMetrics, 1))
        let overallRetentionRate = adoptionMetrics.values.map { $0.retentionRate }.reduce(0, +) / Double(max(featuresWithMetrics, 1))
        
        let topFeatures = adoptionMetrics.values
            .sorted { $0.adoptionRate > $1.adoptionRate }
            .prefix(5)
            .compactMap { metrics in
                features[metrics.featureId]?.name
            }
        
        let underperformingFeatures = adoptionMetrics.values
            .filter { $0.adoptionRate < 0.3 }
            .sorted { $0.adoptionRate < $1.adoptionRate }
            .compactMap { metrics in
                features[metrics.featureId]?.name
            }
        
        return FeatureAdoptionSummary(
            totalFeatures: totalFeatures,
            trackedFeatures: featuresWithMetrics,
            overallAdoptionRate: overallAdoptionRate,
            overallRetentionRate: overallRetentionRate,
            topPerformingFeatures: Array(topFeatures),
            underperformingFeatures: underperformingFeatures
        )
    }
}

// MARK: - Supporting Models
struct FeatureUsageEvent {
    let featureId: String
    let timestamp: Date
    let userId: String
    let sessionId: String
    let context: [String: Any]
}

struct FeatureInteraction {
    let featureId: String
    let featureName: String
    let timestamp: Date
    let interactionType: InteractionType
    let context: [String: Any]
}

enum InteractionType {
    case discovered
    case used
    case onboardingStarted
    case onboardingCompleted
    case abandoned
}

enum DiscoveryMethod: String, CaseIterable {
    case menu = "menu"
    case hotkey = "hotkey"
    case tutorial = "tutorial"
    case tooltip = "tooltip"
    case search = "search"
    case recommendation = "recommendation"
    case exploration = "exploration"
}

enum OnboardingStep: String, CaseIterable {
    case introduction = "introduction"
    case demonstration = "demonstration"
    case hands_on = "hands_on"
    case completion = "completion"
}

struct FeatureAdoptionInsight {
    let featureId: String
    let featureName: String
    let type: InsightType
    let severity: InsightSeverity
    let description: String
    let recommendation: String
    let confidence: Double
}

enum InsightType {
    case lowAdoption
    case highAbandonment
    case successStory
    case onboardingOpportunity
    case usagePattern
}

enum InsightSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct FeatureAdoptionSummary {
    let totalFeatures: Int
    let trackedFeatures: Int
    let overallAdoptionRate: Double
    let overallRetentionRate: Double
    let topPerformingFeatures: [String]
    let underperformingFeatures: [String]
}