import SwiftUI
import Combine

/// Example integration showing how to use the ForceQUIT performance optimization system
/// This demonstrates the ultra-lightweight, high-performance architecture in action

@main
struct ForceQUITApp: App {
    @StateObject private var performanceCoordinator = PerformanceCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(performanceCoordinator)
                .task {
                    // Initialize performance system on app launch
                    await performanceCoordinator.initialize()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var performanceCoordinator: PerformanceCoordinator
    @State private var showPerformanceMetrics = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Performance Status Header
                performanceStatusHeader
                
                // Main Process List
                processListView
                
                // Action Buttons
                actionButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle("ForceQUIT")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    performanceButton
                }
            }
            .sheet(isPresented: $showPerformanceMetrics) {
                PerformanceMetricsView()
                    .environmentObject(performanceCoordinator)
            }
        }
        .performanceOptimized(with: performanceCoordinator)
    }
    
    private var performanceStatusHeader: some View {
        HStack {
            systemHealthIndicator
            
            Spacer()
            
            performanceMetrics
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var systemHealthIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: performanceCoordinator.systemHealth.icon)
                .foregroundColor(performanceCoordinator.systemHealth.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("System Health")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(performanceCoordinator.systemHealth.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }
    
    private var performanceMetrics: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(Int(performanceCoordinator.memoryManager.currentUsage / 1024 / 1024))MB")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Memory")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var processListView: some View {
        List {
            ForEach(Array(performanceCoordinator.eventMonitor.activeProcesses.values), id: \.pid) { process in
                ProcessRowView(process: process)
                    .memoryOptimizedList(coordinator: performanceCoordinator)
            }
        }
        .performanceScrollView(coordinator: performanceCoordinator)
        .refreshable {
            // Refresh process list with optimized caching
            await refreshProcessList()
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            ActionButton(
                title: "Force Quit All",
                icon: "xmark.circle.fill",
                color: .red,
                action: forceQuitAll
            )
            
            ActionButton(
                title: "Safe Restart",
                icon: "arrow.clockwise.circle.fill",
                color: .blue,
                action: safeRestartAll
            )
            
            ActionButton(
                title: "Optimize",
                icon: "speedometer",
                color: .green,
                action: optimizeSystem
            )
        }
    }
    
    private var performanceButton: some View {
        Button {
            showPerformanceMetrics = true
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Actions
    
    private func refreshProcessList() async {
        // Use optimized event-driven monitoring - no polling needed!
        // The EventDrivenMonitor automatically updates activeProcesses
        
        // Register animation for smooth refresh
        let animationID = AnimationID(rawValue: "processListRefresh")
        performanceCoordinator.registerAnimation(id: animationID, duration: 0.3)
        
        // Animation will be automatically optimized based on system performance
        withAnimation(performanceCoordinator.getAnimationConfig(for: .smooth)) {
            // Process list updates automatically via EventDrivenMonitor
        }
        
        performanceCoordinator.unregisterAnimation(id: animationID)
    }
    
    private func forceQuitAll() {
        let animationID = AnimationID(rawValue: "forceQuitAnimation")
        performanceCoordinator.registerAnimation(id: animationID, duration: 0.5) {
            // Completion callback
            print("Force quit animation completed")
        }
        
        withAnimation(performanceCoordinator.getAnimationConfig(for: .snappy)) {
            // Force quit implementation would go here
            // Using cached process data for instant access
        }
    }
    
    private func safeRestartAll() {
        withAnimation(performanceCoordinator.getAnimationConfig(for: .fluid)) {
            // Safe restart implementation
        }
    }
    
    private func optimizeSystem() {
        Task {
            await performanceCoordinator.optimizeSystem()
        }
    }
}

struct ProcessRowView: View {
    let process: EventDrivenMonitor.ProcessInfo
    @EnvironmentObject var performanceCoordinator: PerformanceCoordinator
    
    var body: some View {
        HStack {
            // Process icon (cached for performance)
            processIcon
            
            VStack(alignment: .leading, spacing: 4) {
                Text(process.name)
                    .font(.headline)
                
                Text("PID: \(process.pid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(process.memoryUsage / 1024 / 1024)MB")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.1f", process.cpuUsage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var processIcon: some View {
        // Cached icon loading for performance
        Image(systemName: "app.circle.fill")
            .font(.title2)
            .foregroundColor(.blue)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct PerformanceMetricsView: View {
    @EnvironmentObject var performanceCoordinator: PerformanceCoordinator
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // System Status Card
                    systemStatusCard
                    
                    // Performance Metrics Cards
                    performanceMetricsCards
                    
                    // Performance Insights
                    performanceInsights
                    
                    // Optimization Suggestions
                    optimizationSuggestions
                }
                .padding()
            }
            .navigationTitle("Performance Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .performanceOptimized(with: performanceCoordinator)
    }
    
    private var systemStatusCard: some View {
        let status = performanceCoordinator.getSystemStatus()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("System Health")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: status.health.icon)
                        .foregroundColor(status.health.color)
                    
                    Text(status.health.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(status.health.color)
                }
            }
            
            if !status.constraintsViolated.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Constraint Violations:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    ForEach(status.constraintsViolated, id: \.self) { violation in
                        Text("• \(violation)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var performanceMetricsCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Memory",
                value: "\(performanceCoordinator.memoryManager.currentUsage / 1024 / 1024)MB",
                subtitle: "/ 10MB limit",
                color: performanceCoordinator.memoryManager.status == .optimal ? .green : .orange
            )
            
            MetricCard(
                title: "FPS",
                value: "\(Int(performanceCoordinator.animationOptimizer.currentFPS))",
                subtitle: "Target: 60-120",
                color: .blue
            )
            
            MetricCard(
                title: "Processes",
                value: "\(performanceCoordinator.eventMonitor.activeProcesses.count)",
                subtitle: "Monitored",
                color: .purple
            )
            
            MetricCard(
                title: "Cache Hit",
                value: "\(Int(performanceCoordinator.processCache.getStatistics().hitRate * 100))%",
                subtitle: "Efficiency",
                color: .mint
            )
        }
    }
    
    private var performanceInsights: some View {
        let insights = performanceCoordinator.getPerformanceInsights()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Performance Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            if insights.isEmpty {
                Text("All systems optimal! 🎯")
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            } else {
                ForEach(insights.indices, id: \.self) { index in
                    InsightCard(insight: insights[index])
                }
            }
        }
    }
    
    private var optimizationSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button {
                Task {
                    await performanceCoordinator.optimizeSystem()
                }
            } label: {
                HStack {
                    Image(systemName: "speedometer")
                    Text("Optimize System")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InsightCard: View {
    let insight: PerformanceMonitor.PerformanceInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(insight.estimatedImpact * 100))% impact")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text(insight.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(insight.severity.color.opacity(0.1))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}