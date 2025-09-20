import Foundation
import SwiftUI
import AppKit
import Combine

// SWARM 2.0 ForceQUIT - Advanced Window Management System
// Handles overlays, animations, and window behaviors for Mission Control aesthetic

@MainActor
class WindowManager: ObservableObject {
    // MARK: - Published Properties
    @Published var mainWindow: NSWindow?
    @Published var overlayWindows: [String: NSWindow] = [:]
    @Published var isOverlayMode: Bool = false
    @Published var currentWindowStyle: WindowStyle = .standard
    @Published var windowOpacity: Double = 1.0
    
    // MARK: - Private Properties
    private var windowObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()
    private let windowStyleAnimator = WindowStyleAnimator()
    private let overlayController = OverlayController()
    
    // MARK: - Configuration
    private let config = WindowManagerConfig()
    
    init() {
        setupWindowObservers()
        setupKeyboardShortcuts()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Interface
    
    /// Configure the main application window with Mission Control aesthetics
    func configureMainWindow(_ window: NSWindow) {
        mainWindow = window
        applyMissionControlStyling(to: window)
        setupWindowBehaviors(for: window)
    }
    
    /// Show overlay window with specified type and configuration
    func showOverlay(_ type: OverlayType, configuration: OverlayConfiguration = .default) {
        let overlayWindow = createOverlayWindow(for: type, with: configuration)
        overlayWindows[type.identifier] = overlayWindow
        
        // Animate overlay appearance
        animateOverlayAppearance(overlayWindow, type: type)
        
        isOverlayMode = true
    }
    
    /// Hide specific overlay window
    func hideOverlay(_ type: OverlayType, animated: Bool = true) {
        guard let overlayWindow = overlayWindows[type.identifier] else { return }
        
        if animated {
            animateOverlayDisappearance(overlayWindow) { [weak self] in
                self?.finalizeOverlayHide(type)
            }
        } else {
            finalizeOverlayHide(type)
        }
    }
    
    /// Hide all overlay windows
    func hideAllOverlays(animated: Bool = true) {
        let overlayTypes = overlayWindows.keys.compactMap { OverlayType.from($0) }
        
        for type in overlayTypes {
            hideOverlay(type, animated: animated)
        }
        
        isOverlayMode = false
    }
    
    /// Change window style with smooth animation
    func setWindowStyle(_ style: WindowStyle, animated: Bool = true) {
        guard let window = mainWindow, currentWindowStyle != style else { return }
        
        if animated {
            windowStyleAnimator.animate(window: window, from: currentWindowStyle, to: style) { [weak self] in
                self?.currentWindowStyle = style
            }
        } else {
            applyWindowStyle(style, to: window)
            currentWindowStyle = style
        }
    }
    
    /// Toggle overlay mode (Mission Control style overlay)
    func toggleOverlayMode() {
        if isOverlayMode {
            hideAllOverlays()
        } else {
            showMissionControlOverlay()
        }
    }
    
    /// Set window opacity with animation
    func setWindowOpacity(_ opacity: Double, animated: Bool = true) {
        guard let window = mainWindow else { return }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                window.alphaValue = opacity
            } completionHandler: { [weak self] in
                self?.windowOpacity = opacity
            }
        } else {
            window.alphaValue = opacity
            windowOpacity = opacity
        }
    }
    
    /// Show process termination animation overlay
    func showTerminationAnimation(for processName: String, at position: CGPoint) {
        let config = OverlayConfiguration(
            position: position,
            size: CGSize(width: 200, height: 200),
            animationType: .termination,
            customData: ["processName": processName]
        )
        
        showOverlay(.terminationAnimation, configuration: config)
        
        // Auto-hide after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.hideOverlay(.terminationAnimation)
        }
    }
    
    /// Show system health overlay
    func showSystemHealthOverlay(metrics: SystemMetrics) {
        let config = OverlayConfiguration(
            position: CGPoint(x: 50, y: 50),
            size: CGSize(width: 300, height: 150),
            animationType: .fade,
            customData: ["metrics": metrics]
        )
        
        showOverlay(.systemHealth, configuration: config)
    }
    
    // MARK: - Private Implementation
    
    private func setupWindowObservers() {
        let notificationCenter = NotificationCenter.default
        
        // Window state change observers
        let windowDidBecomeMain = notificationCenter.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWindowBecameMain(notification)
        }
        
        let windowDidResignMain = notificationCenter.addObserver(
            forName: NSWindow.didResignMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWindowResignedMain(notification)
        }
        
        let windowDidMiniaturize = notificationCenter.addObserver(
            forName: NSWindow.didMiniaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWindowMiniaturized(notification)
        }
        
        windowObservers = [windowDidBecomeMain, windowDidResignMain, windowDidMiniaturize]
    }
    
    private func setupKeyboardShortcuts() {
        // Global keyboard shortcuts for window management
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyDown(event)
        }
    }
    
    private func applyMissionControlStyling(to window: NSWindow) {
        // Apply Mission Control aesthetic styling
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.clear
        
        // Apply dark, sleek appearance
        window.appearance = NSAppearance(named: .darkAqua)
        
        // Configure window behavior
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set minimum and maximum sizes for optimal UX
        window.minSize = CGSize(width: 800, height: 600)
        window.maxSize = CGSize(width: 1400, height: 1000)
    }
    
    private func setupWindowBehaviors(for window: NSWindow) {
        // Custom window behaviors for enhanced UX
        window.delegate = WindowManagerDelegate()
        
        // Enable smooth animations
        window.animationBehavior = .documentWindow
        
        // Configure for optimal performance
        window.displaysWhenScreenProfileChanges = true
        window.acceptsMouseMovedEvents = true
    }
    
    private func createOverlayWindow(for type: OverlayType, with config: OverlayConfiguration) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: config.position, size: config.size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure overlay window properties
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = config.hasShadow
        window.level = .floating
        window.ignoresMouseEvents = config.ignoresMouseEvents
        window.collectionBehavior = [.transient, .ignoresCycle]
        
        // Set content view based on overlay type
        window.contentView = createOverlayContentView(for: type, config: config)
        
        window.makeKeyAndOrderFront(nil)
        
        return window
    }
    
    private func createOverlayContentView(for type: OverlayType, config: OverlayConfiguration) -> NSView {
        let hostingView = NSHostingView(rootView: createOverlaySwiftUIView(for: type, config: config))
        return hostingView
    }
    
    @ViewBuilder
    private func createOverlaySwiftUIView(for type: OverlayType, config: OverlayConfiguration) -> some View {
        switch type {
        case .missionControl:
            MissionControlOverlayView(configuration: config)
        case .terminationAnimation:
            TerminationAnimationView(configuration: config)
        case .systemHealth:
            SystemHealthOverlayView(configuration: config)
        case .processDetails:
            ProcessDetailsOverlayView(configuration: config)
        }
    }
    
    private func showMissionControlOverlay() {
        guard let mainWindow = mainWindow else { return }
        
        let screenFrame = mainWindow.screen?.frame ?? NSScreen.main?.frame ?? .zero
        let config = OverlayConfiguration(
            position: screenFrame.origin,
            size: screenFrame.size,
            animationType: .missionControl,
            backgroundBlur: true
        )
        
        showOverlay(.missionControl, configuration: config)
    }
    
    private func animateOverlayAppearance(_ window: NSWindow, type: OverlayType) {
        // Initial state
        window.alphaValue = 0.0
        
        // Animate appearance
        NSAnimationContext.runAnimationGroup { context in
            context.duration = type.animationDuration
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            window.alphaValue = 1.0
            
            // Type-specific animations
            switch type {
            case .missionControl:
                window.setFrame(window.frame, display: true, animate: false)
            case .terminationAnimation:
                // Scale animation for termination
                if let contentView = window.contentView {
                    contentView.layer?.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
                }
            default:
                break
            }
        }
    }
    
    private func animateOverlayDisappearance(_ window: NSWindow, completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            window.alphaValue = 0.0
        } completionHandler: {
            completion()
        }
    }
    
    private func finalizeOverlayHide(_ type: OverlayType) {
        if let window = overlayWindows.removeValue(forKey: type.identifier) {
            window.close()
        }
        
        if overlayWindows.isEmpty {
            isOverlayMode = false
        }
    }
    
    private func applyWindowStyle(_ style: WindowStyle, to window: NSWindow) {
        switch style {
        case .standard:
            window.titlebarAppearsTransparent = false
            window.styleMask.insert(.titled)
        case .borderless:
            window.titlebarAppearsTransparent = true
            window.styleMask.remove(.titled)
        case .floating:
            window.level = .floating
            window.titlebarAppearsTransparent = true
        case .hudWindow:
            window.styleMask = [.hudWindow, .closable]
            window.titlebarAppearsTransparent = true
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleWindowBecameMain(_ notification: Notification) {
        // Window became active - update UI state
    }
    
    private func handleWindowResignedMain(_ notification: Notification) {
        // Window lost focus - may want to hide overlays
        if config.hideOverlaysOnFocusLoss {
            hideAllOverlays(animated: true)
        }
    }
    
    private func handleWindowMiniaturized(_ notification: Notification) {
        // Window was minimized - hide all overlays
        hideAllOverlays(animated: false)
    }
    
    private func handleGlobalKeyDown(_ event: NSEvent) {
        // Handle global keyboard shortcuts
        if event.modifierFlags.contains([.command, .option]) {
            switch event.keyCode {
            case 49: // Space key
                toggleOverlayMode()
            case 31: // O key
                setWindowOpacity(windowOpacity == 1.0 ? 0.8 : 1.0)
            default:
                break
            }
        }
    }
    
    private func cleanup() {
        windowObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        windowObservers.removeAll()
        cancellables.removeAll()
        
        // Close all overlay windows
        overlayWindows.values.forEach { $0.close() }
        overlayWindows.removeAll()
    }
}

// MARK: - Supporting Types

enum WindowStyle: String, CaseIterable {
    case standard = "Standard"
    case borderless = "Borderless"
    case floating = "Floating"
    case hudWindow = "HUD"
    
    var displayName: String { rawValue }
}

enum OverlayType: String, CaseIterable {
    case missionControl = "MissionControl"
    case terminationAnimation = "TerminationAnimation"
    case systemHealth = "SystemHealth"
    case processDetails = "ProcessDetails"
    
    var identifier: String { rawValue }
    
    var animationDuration: TimeInterval {
        switch self {
        case .missionControl: return 0.5
        case .terminationAnimation: return 2.0
        case .systemHealth: return 0.3
        case .processDetails: return 0.4
        }
    }
    
    static func from(_ identifier: String) -> OverlayType? {
        return OverlayType(rawValue: identifier)
    }
}

struct OverlayConfiguration {
    let position: CGPoint
    let size: CGSize
    let animationType: AnimationType
    let backgroundBlur: Bool
    let hasShadow: Bool
    let ignoresMouseEvents: Bool
    let customData: [String: Any]
    
    init(
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 400, height: 300),
        animationType: AnimationType = .fade,
        backgroundBlur: Bool = false,
        hasShadow: Bool = true,
        ignoresMouseEvents: Bool = false,
        customData: [String: Any] = [:]
    ) {
        self.position = position
        self.size = size
        self.animationType = animationType
        self.backgroundBlur = backgroundBlur
        self.hasShadow = hasShadow
        self.ignoresMouseEvents = ignoresMouseEvents
        self.customData = customData
    }
    
    static let `default` = OverlayConfiguration()
}

enum AnimationType {
    case fade
    case slide
    case scale
    case missionControl
    case termination
}

struct WindowManagerConfig {
    let hideOverlaysOnFocusLoss: Bool = true
    let enableKeyboardShortcuts: Bool = true
    let maxOverlayWindows: Int = 5
    let defaultAnimationDuration: TimeInterval = 0.3
}

// MARK: - Window Style Animator

private class WindowStyleAnimator {
    func animate(window: NSWindow, from fromStyle: WindowStyle, to toStyle: WindowStyle, completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // Apply new style
            applyWindowStyleChanges(window: window, style: toStyle)
            
        } completionHandler: {
            completion()
        }
    }
    
    private func applyWindowStyleChanges(window: NSWindow, style: WindowStyle) {
        switch style {
        case .standard:
            window.animator().alphaValue = 1.0
        case .borderless:
            window.animator().alphaValue = 0.95
        case .floating:
            window.animator().alphaValue = 0.9
        case .hudWindow:
            window.animator().alphaValue = 0.85
        }
    }
}

// MARK: - Overlay Controller

private class OverlayController {
    // Manages overlay-specific behaviors and animations
    func configureOverlay(_ window: NSWindow, for type: OverlayType) {
        switch type {
        case .missionControl:
            configureMissionControlOverlay(window)
        case .terminationAnimation:
            configureTerminationAnimationOverlay(window)
        case .systemHealth:
            configureSystemHealthOverlay(window)
        case .processDetails:
            configureProcessDetailsOverlay(window)
        }
    }
    
    private func configureMissionControlOverlay(_ window: NSWindow) {
        window.backgroundColor = NSColor.black.withAlphaComponent(0.7)
        window.isOpaque = false
        window.ignoresMouseEvents = false
    }
    
    private func configureTerminationAnimationOverlay(_ window: NSWindow) {
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
    }
    
    private func configureSystemHealthOverlay(_ window: NSWindow) {
        window.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        window.isOpaque = false
        window.ignoresMouseEvents = false
    }
    
    private func configureProcessDetailsOverlay(_ window: NSWindow) {
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9)
        window.isOpaque = false
        window.ignoresMouseEvents = false
    }
}

// MARK: - Window Manager Delegate

private class WindowManagerDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Custom close behavior
        return true
    }
    
    func windowDidResize(_ notification: Notification) {
        // Handle window resize events
    }
    
    func windowDidMove(_ notification: Notification) {
        // Handle window move events
    }
}

// MARK: - Overlay Views (SwiftUI)

private struct MissionControlOverlayView: View {
    let configuration: OverlayConfiguration
    
    var body: some View {
        ZStack {
            // Background blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack {
                Text("Mission Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Press Esc to close")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct TerminationAnimationView: View {
    let configuration: OverlayConfiguration
    @State private var animationPhase: Int = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.red.opacity(0.7))
                .frame(width: 100, height: 100)
                .scaleEffect(animationPhase == 0 ? 0.1 : 1.0)
                .opacity(animationPhase == 2 ? 0.0 : 1.0)
            
            Image(systemName: "xmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(animationPhase == 0 ? 0.1 : 1.0)
                .opacity(animationPhase == 2 ? 0.0 : 1.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 0.5)) {
                    animationPhase = 2
                }
            }
        }
    }
}

private struct SystemHealthOverlayView: View {
    let configuration: OverlayConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("System Health")
                    .font(.headline)
            }
            
            // Health metrics would be displayed here
            Text("Memory: 67% used")
            Text("CPU: 23% used")
            Text("Processes: 127 active")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ProcessDetailsOverlayView: View {
    let configuration: OverlayConfiguration
    
    var body: some View {
        VStack {
            Text("Process Details")
                .font(.headline)
            
            // Process details would be displayed here
            Text("Detailed process information")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}