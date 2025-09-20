//
//  ActivationCoordinator.swift
//  ForceQUIT - Multi-Modal Activation System
//
//  Created by SWARM 2.0 AI Development Framework
//  Central coordinator for all input activation methods
//

import Foundation
import Combine
import SwiftUI

/// Central coordinator managing all multi-modal activation methods
/// Orchestrates shake detection, voice commands, hotkeys, and touch gestures
@MainActor
public final class ActivationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isActive = false
    @Published public private(set) var activeInputMethods: Set<InputMethod> = []
    @Published public private(set) var lastActivation: ActivationEvent?
    @Published public private(set) var systemStatus: SystemStatus = .idle
    
    // MARK: - Input Method Types
    public enum InputMethod: String, CaseIterable {
        case shake = "shake"
        case voice = "voice"
        case hotkey = "hotkey"
        case touchGesture = "touch_gesture"
        
        public var displayName: String {
            switch self {
            case .shake: return "Shake Detection"
            case .voice: return "Voice Commands"
            case .hotkey: return "Keyboard Shortcuts"
            case .touchGesture: return "Touch Gestures"
            }
        }
        
        public var icon: String {
            switch self {
            case .shake: return "gyroscope"
            case .voice: return "mic.fill"
            case .hotkey: return "keyboard.fill"
            case .touchGesture: return "hand.tap.fill"
            }
        }
    }
    
    // MARK: - System Status
    public enum SystemStatus {
        case idle
        case listening
        case processing
        case executing(ActionType)
        case error(Error)
        
        public var description: String {
            switch self {
            case .idle: return "Ready"
            case .listening: return "Listening..."
            case .processing: return "Processing..."
            case .executing(let action): return "Executing \(action.description)"
            case .error(let error): return "Error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Action Types
    public enum ActionType: String, CaseIterable {
        case showInterface = "show_interface"
        case hideInterface = "hide_interface"
        case toggleInterface = "toggle_interface"
        case forceQuitAll = "force_quit_all"
        case forceQuitCurrent = "force_quit_current"
        case quitAllGracefully = "quit_all_gracefully"
        case showSettings = "show_settings"
        case showHelp = "show_help"
        case restartSystem = "restart_system"
        case shutdownSystem = "shutdown_system"
        case cancel = "cancel"
        
        public var description: String {
            switch self {
            case .showInterface: return "Show Interface"
            case .hideInterface: return "Hide Interface"
            case .toggleInterface: return "Toggle Interface"
            case .forceQuitAll: return "Force Quit All"
            case .forceQuitCurrent: return "Force Quit Current"
            case .quitAllGracefully: return "Quit All Gracefully"
            case .showSettings: return "Show Settings"
            case .showHelp: return "Show Help"
            case .restartSystem: return "Restart System"
            case .shutdownSystem: return "Shutdown System"
            case .cancel: return "Cancel"
            }
        }
        
        public var requiresConfirmation: Bool {
            switch self {
            case .forceQuitAll, .restartSystem, .shutdownSystem:
                return true
            default:
                return false
            }
        }
        
        public var isDestructive: Bool {
            switch self {
            case .forceQuitAll, .forceQuitCurrent, .restartSystem, .shutdownSystem:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Activation Event
    public struct ActivationEvent {
        public let id = UUID()
        public let inputMethod: InputMethod
        public let action: ActionType
        public let timestamp: Date
        public let metadata: [String: Any]
        public let confidence: Double
        
        public init(
            inputMethod: InputMethod,
            action: ActionType,
            timestamp: Date = Date(),
            metadata: [String: Any] = [:],
            confidence: Double = 1.0
        ) {
            self.inputMethod = inputMethod
            self.action = action
            self.timestamp = timestamp
            self.metadata = metadata
            self.confidence = confidence
        }
    }
    
    // MARK: - Configuration
    public struct Configuration {
        public var enabledInputMethods: Set<InputMethod> = Set(InputMethod.allCases)
        public var priority: [InputMethod] = [.hotkey, .voice, .touchGesture, .shake]
        public var confirmationTimeout: TimeInterval = 5.0
        public var debounceInterval: TimeInterval = 0.5
        public var enableLogging: Bool = true
        public var enableHapticFeedback: Bool = true
        public var enableAudioFeedback: Bool = true
        public var maxConcurrentActions: Int = 1
        
        public init(
            enabledInputMethods: Set<InputMethod> = Set(InputMethod.allCases),
            priority: [InputMethod] = [.hotkey, .voice, .touchGesture, .shake],
            confirmationTimeout: TimeInterval = 5.0,
            debounceInterval: TimeInterval = 0.5,
            enableLogging: Bool = true,
            enableHapticFeedback: Bool = true,
            enableAudioFeedback: Bool = true,
            maxConcurrentActions: Int = 1
        ) {
            self.enabledInputMethods = enabledInputMethods
            self.priority = priority
            self.confirmationTimeout = confirmationTimeout
            self.debounceInterval = debounceInterval
            self.enableLogging = enableLogging
            self.enableHapticFeedback = enableHapticFeedback
            self.enableAudioFeedback = enableAudioFeedback
            self.maxConcurrentActions = maxConcurrentActions
        }
    }
    
    // MARK: - Component Properties
    public let shakeDetector: ShakeDetector
    public let voiceCommandHandler: VoiceCommandHandler
    public let globalHotkeyManager: GlobalHotkeyManager
    public let touchGestureRecognizer: TouchGestureRecognizer
    
    // MARK: - Private Properties
    private var configuration: Configuration
    private var cancellables = Set<AnyCancellable>()
    private var activationBuffer: [ActivationEvent] = []
    private var pendingConfirmations: [UUID: PendingConfirmation] = [:]
    private var executingActions: Set<UUID> = []
    private var lastActivationTime: Date?
    
    private struct PendingConfirmation {
        let event: ActivationEvent
        let expiryTime: Date
    }
    
    // MARK: - Publishers
    public let activationPublisher = PassthroughSubject<ActivationEvent, Never>()
    public let systemStatusPublisher = PassthroughSubject<SystemStatus, Never>()
    public let inputMethodStatusPublisher = PassthroughSubject<InputMethodStatus, Never>()
    
    public struct InputMethodStatus {
        public let method: InputMethod
        public let isActive: Bool
        public let status: String
    }
    
    // MARK: - Action Handler
    public var actionHandler: ((ActionType, [String: Any]) -> Void)?
    
    // MARK: - Initialization
    public init(
        configuration: Configuration = Configuration(),
        shakeConfiguration: ShakeDetector.Configuration = ShakeDetector.Configuration(),
        voiceConfiguration: VoiceCommandHandler.Configuration = VoiceCommandHandler.Configuration(),
        touchConfiguration: TouchGestureRecognizer.Configuration = TouchGestureRecognizer.Configuration()
    ) {
        self.configuration = configuration
        
        // Initialize components
        self.shakeDetector = ShakeDetector(configuration: shakeConfiguration)
        self.voiceCommandHandler = VoiceCommandHandler(configuration: voiceConfiguration)
        self.globalHotkeyManager = GlobalHotkeyManager()
        self.touchGestureRecognizer = TouchGestureRecognizer(configuration: touchConfiguration)
        
        setupInputMethodObservers()
        setupDefaultHotkeys()
    }
    
    deinit {
        stopAllInputMethods()
    }
    
    // MARK: - Public Methods
    
    /// Start all enabled input methods
    public func startAllInputMethods() async {
        guard !isActive else { return }
        
        isActive = true
        systemStatus = .listening
        
        // Start each enabled input method
        for method in configuration.enabledInputMethods {
            await startInputMethod(method)
        }
        
        systemStatusPublisher.send(systemStatus)
        
        print("🚀 ActivationCoordinator: Started all input methods")
    }
    
    /// Stop all input methods
    public func stopAllInputMethods() {
        guard isActive else { return }
        
        // Stop each input method
        shakeDetector.stopMonitoring()
        voiceCommandHandler.stopListening()
        globalHotkeyManager.stopMonitoring()
        touchGestureRecognizer.stopMonitoring()
        
        // Clear state
        activeInputMethods.removeAll()
        isActive = false
        systemStatus = .idle
        
        systemStatusPublisher.send(systemStatus)
        
        print("🔴 ActivationCoordinator: Stopped all input methods")
    }
    
    /// Start specific input method
    public func startInputMethod(_ method: InputMethod) async {
        guard configuration.enabledInputMethods.contains(method) else { return }
        guard !activeInputMethods.contains(method) else { return }
        
        switch method {
        case .shake:
            shakeDetector.startMonitoring()
        case .voice:
            do {
                try await voiceCommandHandler.startListening()
            } catch {
                print("❌ ActivationCoordinator: Failed to start voice commands: \(error)")
                return
            }
        case .hotkey:
            globalHotkeyManager.startMonitoring()
        case .touchGesture:
            touchGestureRecognizer.startMonitoring()
        }
        
        activeInputMethods.insert(method)
        
        inputMethodStatusPublisher.send(InputMethodStatus(
            method: method,
            isActive: true,
            status: getInputMethodStatus(method)
        ))
        
        print("✅ ActivationCoordinator: Started \(method.displayName)")
    }
    
    /// Stop specific input method
    public func stopInputMethod(_ method: InputMethod) {
        guard activeInputMethods.contains(method) else { return }
        
        switch method {
        case .shake:
            shakeDetector.stopMonitoring()
        case .voice:
            voiceCommandHandler.stopListening()
        case .hotkey:
            globalHotkeyManager.stopMonitoring()
        case .touchGesture:
            touchGestureRecognizer.stopMonitoring()
        }
        
        activeInputMethods.remove(method)
        
        inputMethodStatusPublisher.send(InputMethodStatus(
            method: method,
            isActive: false,
            status: "Stopped"
        ))
        
        print("❌ ActivationCoordinator: Stopped \(method.displayName)")
    }
    
    /// Execute action with confirmation if required
    public func executeAction(_ action: ActionType, metadata: [String: Any] = [:]) async {
        let event = ActivationEvent(
            inputMethod: .hotkey, // Default for manual execution
            action: action,
            metadata: metadata
        )
        
        await handleActivationEvent(event)
    }
    
    /// Update coordinator configuration
    public func updateConfiguration(_ newConfiguration: Configuration) {
        configuration = newConfiguration
        
        // Restart input methods if needed
        Task {
            stopAllInputMethods()
            await startAllInputMethods()
        }
        
        print("⚙️ ActivationCoordinator: Configuration updated")
    }
    
    /// Get system diagnostics
    public func getSystemDiagnostics() -> SystemDiagnostics {
        return SystemDiagnostics(
            isActive: isActive,
            activeInputMethods: activeInputMethods,
            shakeStatus: shakeDetector.status,
            voiceStatus: voiceCommandHandler.status,
            hotkeyStatus: globalHotkeyManager.status,
            touchStatus: touchGestureRecognizer.status,
            lastActivation: lastActivation,
            activationCount: activationBuffer.count
        )
    }
    
    // MARK: - Private Methods
    
    private func setupInputMethodObservers() {
        // Observe shake detection
        shakeDetector.shakeDetectedPublisher
            .sink { [weak self] pattern in
                let action = self?.mapShakePatternToAction(pattern) ?? .toggleInterface
                let event = ActivationEvent(
                    inputMethod: .shake,
                    action: action,
                    metadata: ["pattern": pattern]
                )
                Task { await self?.handleActivationEvent(event) }
            }
            .store(in: &cancellables)
        
        // Observe voice commands
        voiceCommandHandler.commandRecognizedPublisher
            .sink { [weak self] result in
                let action = self?.mapVoiceCommandToAction(result.command) ?? .showHelp
                let event = ActivationEvent(
                    inputMethod: .voice,
                    action: action,
                    metadata: [
                        "command": result.command.rawValue,
                        "confidence": result.confidence,
                        "originalText": result.originalText
                    ],
                    confidence: Double(result.confidence)
                )
                Task { await self?.handleActivationEvent(event) }
            }
            .store(in: &cancellables)
        
        // Observe hotkey triggers
        globalHotkeyManager.hotkeyTriggeredPublisher
            .sink { [weak self] hotkey in
                let action = self?.mapHotkeyToAction(hotkey.action) ?? .toggleInterface
                let event = ActivationEvent(
                    inputMethod: .hotkey,
                    action: action,
                    metadata: [
                        "hotkey": hotkey.name,
                        "displayString": hotkey.displayString
                    ]
                )
                Task { await self?.handleActivationEvent(event) }
            }
            .store(in: &cancellables)
        
        // Observe touch gestures
        touchGestureRecognizer.gestureDetectedPublisher
            .sink { [weak self] gesture in
                let action = self?.mapGestureToAction(gesture.type) ?? .toggleInterface
                let event = ActivationEvent(
                    inputMethod: .touchGesture,
                    action: action,
                    metadata: [
                        "gesture": gesture.type.rawValue,
                        "fingerCount": gesture.fingerCount,
                        "pressure": gesture.pressure
                    ],
                    confidence: gesture.confidence
                )
                Task { await self?.handleActivationEvent(event) }
            }
            .store(in: &cancellables)
    }
    
    private func setupDefaultHotkeys() {
        // Register default hotkeys
        globalHotkeyManager.registerDefaultHotkeys()
    }
    
    private func handleActivationEvent(_ event: ActivationEvent) async {
        // Check debounce interval
        if let lastTime = lastActivationTime,
           Date().timeIntervalSince(lastTime) < configuration.debounceInterval {
            return
        }
        
        lastActivationTime = Date()
        lastActivation = event
        
        // Add to activation buffer
        activationBuffer.append(event)
        cleanActivationBuffer()
        
        // Log activation
        if configuration.enableLogging {
            print("🎯 ActivationCoordinator: Activation - \(event.inputMethod.displayName) -> \(event.action.description)")
        }
        
        // Check if action requires confirmation
        if event.action.requiresConfirmation {
            await requestConfirmation(event)
        } else {
            await executeActionInternal(event)
        }
        
        // Publish activation
        activationPublisher.send(event)
    }
    
    private func requestConfirmation(_ event: ActivationEvent) async {
        let confirmationId = event.id
        let expiryTime = Date().addingTimeInterval(configuration.confirmationTimeout)
        
        pendingConfirmations[confirmationId] = PendingConfirmation(
            event: event,
            expiryTime: expiryTime
        )
        
        systemStatus = .processing
        systemStatusPublisher.send(systemStatus)
        
        print("❓ ActivationCoordinator: Requesting confirmation for \(event.action.description)")
        
        // Auto-cancel after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.confirmationTimeout) { [weak self] in
            self?.cancelConfirmation(confirmationId)
        }
    }
    
    public func confirmAction(_ eventId: UUID) async {
        guard let confirmation = pendingConfirmations.removeValue(forKey: eventId) else { return }
        
        await executeActionInternal(confirmation.event)
    }
    
    public func cancelConfirmation(_ eventId: UUID) {
        pendingConfirmations.removeValue(forKey: eventId)
        
        if pendingConfirmations.isEmpty {
            systemStatus = .listening
            systemStatusPublisher.send(systemStatus)
        }
        
        print("❌ ActivationCoordinator: Cancelled confirmation")
    }
    
    private func executeActionInternal(_ event: ActivationEvent) async {
        guard !executingActions.contains(event.id) else { return }
        guard executingActions.count < configuration.maxConcurrentActions else { return }
        
        executingActions.insert(event.id)
        systemStatus = .executing(event.action)
        systemStatusPublisher.send(systemStatus)
        
        // Provide feedback
        provideFeedback(for: event)
        
        // Execute action via handler
        actionHandler?(event.action, event.metadata)
        
        // Clean up
        executingActions.remove(event.id)
        
        if executingActions.isEmpty {
            systemStatus = .listening
            systemStatusPublisher.send(systemStatus)
        }
        
        print("✅ ActivationCoordinator: Executed \(event.action.description)")
    }
    
    private func provideFeedback(for event: ActivationEvent) {
        // Audio feedback
        if configuration.enableAudioFeedback {
            // Could implement audio feedback here
        }
        
        // Haptic feedback
        if configuration.enableHapticFeedback {
            // macOS has limited haptic feedback, but prepare for future support
        }
    }
    
    private func cleanActivationBuffer() {
        let cutoffTime = Date().timeIntervalSince1970 - 60 // Keep last minute of activations
        activationBuffer.removeAll { event in
            event.timestamp.timeIntervalSince1970 < cutoffTime
        }
    }
    
    private func getInputMethodStatus(_ method: InputMethod) -> String {
        switch method {
        case .shake:
            return shakeDetector.status
        case .voice:
            return voiceCommandHandler.status
        case .hotkey:
            return globalHotkeyManager.status
        case .touchGesture:
            return touchGestureRecognizer.status
        }
    }
    
    // MARK: - Action Mapping Methods
    
    private func mapShakePatternToAction(_ pattern: ShakeDetector.ShakePattern) -> ActionType {
        switch pattern {
        case .singleShake:
            return .toggleInterface
        case .doubleShake:
            return .forceQuitCurrent
        case .tripleShake:
            return .forceQuitAll
        case .continuousShake:
            return .showSettings
        }
    }
    
    private func mapVoiceCommandToAction(_ command: VoiceCommandHandler.VoiceCommand) -> ActionType {
        switch command {
        case .forceQuit:
            return .forceQuitCurrent
        case .forceQuitAll:
            return .forceQuitAll
        case .quitAll:
            return .quitAllGracefully
        case .closeAll:
            return .quitAllGracefully
        case .killAll:
            return .forceQuitAll
        case .shutdown:
            return .shutdownSystem
        case .restart:
            return .restartSystem
        case .cancel:
            return .cancel
        case .stop:
            return .hideInterface
        case .help:
            return .showHelp
        }
    }
    
    private func mapHotkeyToAction(_ hotkeyAction: GlobalHotkeyManager.HotkeyAction) -> ActionType {
        switch hotkeyAction {
        case .showInterface:
            return .showInterface
        case .hideInterface:
            return .hideInterface
        case .toggleInterface:
            return .toggleInterface
        case .forceQuitAll:
            return .forceQuitAll
        case .forceQuitCurrent:
            return .forceQuitCurrent
        case .quitAllApps:
            return .quitAllGracefully
        case .restartSystem:
            return .restartSystem
        case .shutdownSystem:
            return .shutdownSystem
        case .showHelp:
            return .showHelp
        case .showSettings:
            return .showSettings
        case .custom:
            return .toggleInterface
        }
    }
    
    private func mapGestureToAction(_ gestureType: TouchGestureRecognizer.GestureType) -> ActionType {
        switch gestureType.systemAction {
        case .showInterface:
            return .showInterface
        case .hideInterface:
            return .hideInterface
        case .toggleInterface:
            return .toggleInterface
        case .showSettings:
            return .showSettings
        case .showHelp:
            return .showHelp
        case .forceQuitAll:
            return .forceQuitAll
        case .forceQuitCurrent:
            return .forceQuitCurrent
        case .quitAllGracefully:
            return .quitAllGracefully
        case .custom:
            return .toggleInterface
        }
    }
}

// MARK: - System Diagnostics

public struct SystemDiagnostics {
    public let isActive: Bool
    public let activeInputMethods: Set<ActivationCoordinator.InputMethod>
    public let shakeStatus: String
    public let voiceStatus: String
    public let hotkeyStatus: String
    public let touchStatus: String
    public let lastActivation: ActivationCoordinator.ActivationEvent?
    public let activationCount: Int
    
    public var summary: String {
        let activeCount = activeInputMethods.count
        let totalCount = ActivationCoordinator.InputMethod.allCases.count
        return "System: \(isActive ? "Active" : "Inactive"), Input Methods: \(activeCount)/\(totalCount), Activations: \(activationCount)"
    }
}

// MARK: - ActivationCoordinator Extensions

extension ActivationCoordinator {
    
    /// Convenience method to handle specific actions
    public func onAction(_ action: ActionType, handler: @escaping (ActivationEvent) -> Void) {
        activationPublisher
            .filter { $0.action == action }
            .sink { event in
                handler(event)
            }
            .store(in: &cancellables)
    }
    
    /// Convenience method to handle input method activations
    public func onInputMethod(_ method: InputMethod, handler: @escaping (ActivationEvent) -> Void) {
        activationPublisher
            .filter { $0.inputMethod == method }
            .sink { event in
                handler(event)
            }
            .store(in: &cancellables)
    }
    
    /// Get overall system status description
    public var overallStatus: String {
        let activeInputs = activeInputMethods.count
        let totalInputs = InputMethod.allCases.count
        
        if !isActive {
            return "💤 Inactive"
        }
        
        return "🚀 Active (\(activeInputs)/\(totalInputs) methods) - \(systemStatus.description)"
    }
}