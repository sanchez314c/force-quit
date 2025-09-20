import SwiftUI
import Charts
import Foundation

// MARK: - Performance Dashboard Models
struct DashboardMetric {
    let name: String
    let value: Double
    let unit: String
    let timestamp: Date
    let threshold: Double?
    let status: MetricStatus
}

enum MetricStatus {
    case optimal
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}

struct UserBehaviorInsight {
    let title: String
    let description: String
    let impact: InsightImpact
    let recommendation: String
    let confidence: Double
}

enum InsightImpact {
    case high
    case medium
    case low
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Performance Dashboard View
struct PerformanceDashboard: View {
    @StateObject private var viewModel = PerformanceDashboardViewModel()
    @State private var selectedTimeRange = TimeRange.last24Hours
    @State private var showingInsights = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Controls
                    headerSection
                    
                    // Key Metrics Cards
                    metricsCardsSection
                    
                    // Performance Charts
                    chartsSection
                    
                    // User Behavior Analytics
                    behaviorSection
                    
                    // System Health Status
                    systemHealthSection
                }
                .padding()
            }
            .navigationTitle("Performance Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Insights") {
                        showingInsights = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .sheet(isPresented: $showingInsights) {
                InsightsView(insights: viewModel.insights)
            }
        }
        .onAppear {
            viewModel.loadData(for: selectedTimeRange)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("ForceQUIT Analytics Dashboard")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)
        }
        .onChange(of: selectedTimeRange) { _ in
            viewModel.loadData(for: selectedTimeRange)
        }
    }
    
    private var metricsCardsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
            ForEach(viewModel.keyMetrics, id: \.name) { metric in
                MetricCard(metric: metric)
            }
        }
    }
    
    private var chartsSection: some View {
        VStack(spacing: 20) {
            // Memory Usage Chart
            ChartCard(title: "Memory Usage Over Time") {
                Chart(viewModel.memoryData) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Memory (MB)", data.memoryUsage)
                    )
                    .foregroundStyle(.blue)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
            }
            
            // Performance Latency Chart
            ChartCard(title: "Operation Latency") {
                Chart(viewModel.latencyData) { data in
                    BarMark(
                        x: .value("Operation", data.operation),
                        y: .value("Latency (ms)", data.averageLatency)
                    )
                    .foregroundStyle(.orange)
                }
                .frame(height: 200)
            }
            
            // User Activity Heatmap
            ChartCard(title: "Daily User Activity") {
                Chart(viewModel.activityData) { data in
                    RectangleMark(
                        x: .value("Hour", data.hour),
                        y: .value("Day", data.dayOfWeek),
                        width: .fixed(20),
                        height: .fixed(20)
                    )
                    .foregroundStyle(Color.blue.opacity(data.intensity))
                }
                .frame(height: 150)
            }
        }
    }
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("User Behavior Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                // Feature Usage Chart
                ChartCard(title: "Feature Usage") {
                    Chart(viewModel.featureUsage) { feature in
                        SectorMark(
                            angle: .value("Usage", feature.usageCount),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(0.8)
                        )
                        .foregroundStyle(by: .value("Feature", feature.name))
                    }
                    .frame(height: 200)
                }
                
                // Session Duration Distribution
                ChartCard(title: "Session Durations") {
                    Chart(viewModel.sessionData) { session in
                        BarMark(
                            x: .value("Duration Range", session.durationRange),
                            y: .value("Count", session.sessionCount)
                        )
                        .foregroundStyle(.purple)
                    }
                    .frame(height: 200)
                }
            }
        }
    }
    
    private var systemHealthSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("System Health Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                HealthStatusCard(
                    title: "Overall Health",
                    status: viewModel.overallHealth,
                    icon: "checkmark.circle.fill"
                )
                
                HealthStatusCard(
                    title: "Performance",
                    status: viewModel.performanceHealth,
                    icon: "speedometer"
                )
                
                HealthStatusCard(
                    title: "Error Rate",
                    status: viewModel.errorRateHealth,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let metric: DashboardMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(metric.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Circle()
                    .fill(metric.status.color)
                    .frame(width: 8, height: 8)
            }
            
            Text("\(metric.value, specifier: "%.1f")")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(metric.unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct HealthStatusCard: View {
    let title: String
    let status: MetricStatus
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(status.color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            Text(status.displayName)
                .font(.caption)
                .foregroundColor(status.color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Insights View
struct InsightsView: View {
    let insights: [UserBehaviorInsight]
    
    var body: some View {
        NavigationView {
            List(insights, id: \.title) { insight in
                InsightRow(insight: insight)
            }
            .navigationTitle("Performance Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InsightRow: View {
    let insight: UserBehaviorInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
            
            Text(insight.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(insight.impact.color.opacity(0.2))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Dashboard Data Models
struct MemoryDataPoint {
    let timestamp: Date
    let memoryUsage: Double
}

struct LatencyDataPoint {
    let operation: String
    let averageLatency: Double
}

struct ActivityDataPoint {
    let hour: Int
    let dayOfWeek: String
    let intensity: Double
}

struct FeatureUsageData {
    let name: String
    let usageCount: Int
}

struct SessionDurationData {
    let durationRange: String
    let sessionCount: Int
}

// MARK: - Extensions
extension MetricStatus {
    var displayName: String {
        switch self {
        case .optimal: return "Optimal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

enum TimeRange: CaseIterable {
    case last1Hour
    case last24Hours
    case last7Days
    case last30Days
    
    var displayName: String {
        switch self {
        case .last1Hour: return "1 Hour"
        case .last24Hours: return "24 Hours"
        case .last7Days: return "7 Days"
        case .last30Days: return "30 Days"
        }
    }
}

// MARK: - View Model (Placeholder)
class PerformanceDashboardViewModel: ObservableObject {
    @Published var keyMetrics: [DashboardMetric] = []
    @Published var memoryData: [MemoryDataPoint] = []
    @Published var latencyData: [LatencyDataPoint] = []
    @Published var activityData: [ActivityDataPoint] = []
    @Published var featureUsage: [FeatureUsageData] = []
    @Published var sessionData: [SessionDurationData] = []
    @Published var insights: [UserBehaviorInsight] = []
    
    @Published var overallHealth: MetricStatus = .optimal
    @Published var performanceHealth: MetricStatus = .optimal
    @Published var errorRateHealth: MetricStatus = .warning
    
    func loadData(for timeRange: TimeRange) {
        // Load and process analytics data based on time range
        loadKeyMetrics()
        loadChartData()
        loadBehaviorData()
        generateInsights()
    }
    
    private func loadKeyMetrics() {
        keyMetrics = [
            DashboardMetric(name: "Avg Memory", value: 45.2, unit: "MB", timestamp: Date(), threshold: 100, status: .optimal),
            DashboardMetric(name: "Avg CPU", value: 12.5, unit: "%", timestamp: Date(), threshold: 50, status: .optimal),
            DashboardMetric(name: "Force Quit Time", value: 234, unit: "ms", timestamp: Date(), threshold: 500, status: .optimal),
            DashboardMetric(name: "Error Rate", value: 0.12, unit: "%", timestamp: Date(), threshold: 1.0, status: .optimal)
        ]
    }
    
    private func loadChartData() {
        // Generate sample data - in production, load from analytics storage
        memoryData = generateSampleMemoryData()
        latencyData = generateSampleLatencyData()
        activityData = generateSampleActivityData()
    }
    
    private func loadBehaviorData() {
        featureUsage = [
            FeatureUsageData(name: "Force Quit All", usageCount: 450),
            FeatureUsageData(name: "Selective Quit", usageCount: 320),
            FeatureUsageData(name: "Safe Restart", usageCount: 180),
            FeatureUsageData(name: "Settings", usageCount: 95)
        ]
        
        sessionData = [
            SessionDurationData(durationRange: "0-1 min", sessionCount: 120),
            SessionDurationData(durationRange: "1-5 min", sessionCount: 85),
            SessionDurationData(durationRange: "5-15 min", sessionCount: 45),
            SessionDurationData(durationRange: "15+ min", sessionCount: 20)
        ]
    }
    
    private func generateInsights() {
        insights = [
            UserBehaviorInsight(
                title: "Peak Usage Hours",
                description: "Users are most active between 9 AM and 11 AM, with 65% of force quit operations occurring during this window.",
                impact: .medium,
                recommendation: "Consider optimizing performance during peak hours and providing proactive system health notifications.",
                confidence: 0.87
            ),
            UserBehaviorInsight(
                title: "Feature Adoption",
                description: "Safe Restart feature has low adoption (18%) despite positive user feedback in surveys.",
                impact: .high,
                recommendation: "Implement contextual tooltips and onboarding flow to increase Safe Restart visibility and usage.",
                confidence: 0.92
            ),
            UserBehaviorInsight(
                title: "Performance Optimization",
                description: "Force quit operations taking longer than 500ms correlate with 34% increase in app abandonment.",
                impact: .high,
                recommendation: "Implement process prioritization and background optimization to reduce operation latency.",
                confidence: 0.76
            )
        ]
    }
    
    private func generateSampleMemoryData() -> [MemoryDataPoint] {
        let now = Date()
        return (0..<24).map { hour in
            MemoryDataPoint(
                timestamp: now.addingTimeInterval(-TimeInterval(hour * 3600)),
                memoryUsage: Double.random(in: 35...65)
            )
        }
    }
    
    private func generateSampleLatencyData() -> [LatencyDataPoint] {
        return [
            LatencyDataPoint(operation: "Process Scan", averageLatency: 125),
            LatencyDataPoint(operation: "Force Quit", averageLatency: 234),
            LatencyDataPoint(operation: "Safe Restart", averageLatency: 1450),
            LatencyDataPoint(operation: "UI Refresh", averageLatency: 67)
        ]
    }
    
    private func generateSampleActivityData() -> [ActivityDataPoint] {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var data: [ActivityDataPoint] = []
        
        for day in days {
            for hour in 0..<24 {
                data.append(ActivityDataPoint(
                    hour: hour,
                    dayOfWeek: day,
                    intensity: Double.random(in: 0...1)
                ))
            }
        }
        
        return data
    }
}