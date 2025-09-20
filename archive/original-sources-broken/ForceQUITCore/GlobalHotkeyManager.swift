//
//  GlobalHotkeyManager.swift
//  ForceQUIT - Multi-Modal Activation System
//
//  Created by SWARM 2.0 AI Development Framework
//  Advanced global keyboard shortcut management
//

import Foundation
import Carbon
import Combine
import AppKit

/// Advanced global keyboard shortcut management system
/// Provides system-wide hotkey registration and handling with conflict detection
@MainActor
public final class GlobalHotkeyManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var registeredHotkeys: [HotkeyBinding] = []
    @Published public private(set) var isMonitoring = false
    @Published public private(set) var lastTriggeredHotkey: HotkeyBinding?
    
    // MARK: - Hotkey Structure
    public struct HotkeyBinding: Identifiable, Hashable {
        public let id = UUID()
        public let name: String
        public let keyCode: UInt32
        public let modifiers: NSEvent.ModifierFlags
        public let description: String
        public let action: HotkeyAction
        public let isEnabled: Bool
        
        public init(
            name: String,
            keyCode: UInt32,
            modifiers: NSEvent.ModifierFlags,
            description: String,
            action: HotkeyAction,
            isEnabled: Bool = true
        ) {
            self.name = name
            self.keyCode = keyCode
            self.modifiers = modifiers
            self.description = description
            self.action = action
            self.isEnabled = isEnabled
        }
        
        public var displayString: String {
            var components: [String] = []
            
            if modifiers.contains(.command) { components.append("⌘") }
            if modifiers.contains(.option) { components.append("⌥") }
            if modifiers.contains(.control) { components.append("⌃") }
            if modifiers.contains(.shift) { components.append("⇧") }
            
            if let keyName = KeyCodeMapper.shared.keyName(for: keyCode) {
                components.append(keyName)
            } else {
                components.append("Key(\(keyCode))")
            }
            
            return components.joined()
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(keyCode)
            hasher.combine(modifiers.rawValue)
        }
        
        public static func == (lhs: HotkeyBinding, rhs: HotkeyBinding) -> Bool {
            return lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
        }
    }
    
    // MARK: - Hotkey Actions
    public enum HotkeyAction: Hashable {
        case forceQuitAll
        case forceQuitCurrent
        case showInterface
        case hideInterface
        case toggleInterface
        case quitAllApps
        case restartSystem
        case shutdownSystem
        case showHelp
        case showSettings
        case custom(String)
        
        public var description: String {
            switch self {
            case .forceQuitAll:
                return "Force quit all applications"
            case .forceQuitCurrent:
                return "Force quit current application"
            case .showInterface:
                return "Show ForceQUIT interface"
            case .hideInterface:
                return "Hide ForceQUIT interface"
            case .toggleInterface:
                return "Toggle ForceQUIT interface"
            case .quitAllApps:
                return "Quit all applications gracefully"
            case .restartSystem:
                return "Restart system"
            case .shutdownSystem:
                return "Shutdown system"
            case .showHelp:
                return "Show help"
            case .showSettings:
                return "Show settings"
            case .custom(let name):
                return "Custom action: \(name)"
            }
        }
    }
    
    // MARK: - Default Hotkeys
    public static let defaultHotkeys: [HotkeyBinding] = [
        HotkeyBinding(
            name: "Main Interface",
            keyCode: 3, // F key
            modifiers: [.command, .option],
            description: "Toggle ForceQUIT main interface",
            action: .toggleInterface
        ),
        HotkeyBinding(
            name: "Force Quit All",
            keyCode: 3, // F key
            modifiers: [.command, .option, .shift],
            description: "Force quit all running applications",
            action: .forceQuitAll
        ),
        HotkeyBinding(
            name: "Quit All Gracefully",
            keyCode: 12, // Q key
            modifiers: [.command, .option],
            description: "Quit all applications gracefully",
            action: .quitAllApps
        ),
        HotkeyBinding(
            name: "Force Quit Current",
            keyCode: 12, // Q key
            modifiers: [.command, .option, .shift],
            description: "Force quit the current application",
            action: .forceQuitCurrent
        ),
        HotkeyBinding(
            name: "Show Help",
            keyCode: 4, // H key
            modifiers: [.command, .option],
            description: "Show ForceQUIT help",
            action: .showHelp
        )
    ]
    
    // MARK: - Private Properties
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotkeyEventHandlers: [UInt32: () -> Void] = [:]
    private var hotkeyEventHandlerMapping: [HotkeyBinding: UInt32] = [:]
    private var nextHotkeyId: UInt32 = 1000
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers
    public let hotkeyTriggeredPublisher = PassthroughSubject<HotkeyBinding, Never>()
    public let hotkeyRegistrationPublisher = PassthroughSubject<HotkeyRegistrationEvent, Never>()
    
    public enum HotkeyRegistrationEvent {
        case registered(HotkeyBinding)
        case unregistered(HotkeyBinding)
        case failed(HotkeyBinding, Error)
    }
    
    // MARK: - Initialization
    public init() {
        setupKeyCodeMapper()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring for global hotkeys
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Request accessibility permissions if needed
        if !hasAccessibilityPermissions() {
            requestAccessibilityPermissions()
            return
        }
        
        setupEventTap()
        isMonitoring = true
        
        print("⌨️ GlobalHotkeyManager: Started monitoring")
    }
    
    /// Stop monitoring global hotkeys
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        // Disable event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        
        // Remove from run loop
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        // Clear handlers
        hotkeyEventHandlers.removeAll()
        hotkeyEventHandlerMapping.removeAll()
        
        isMonitoring = false
        
        print("🔴 GlobalHotkeyManager: Stopped monitoring")
    }
    
    /// Register a hotkey binding
    public func registerHotkey(_ hotkey: HotkeyBinding) throws {
        guard !registeredHotkeys.contains(hotkey) else {
            throw HotkeyError.alreadyRegistered
        }
        
        // Check for conflicts
        if let conflicting = findConflictingHotkey(hotkey) {
            throw HotkeyError.conflictWithExisting(conflicting)
        }
        
        // Register the hotkey
        let hotkeyId = nextHotkeyId
        nextHotkeyId += 1
        
        // Create handler
        hotkeyEventHandlers[hotkeyId] = { [weak self] in
            self?.handleHotkeyTriggered(hotkey)
        }
        
        // Store mapping
        hotkeyEventHandlerMapping[hotkey] = hotkeyId
        
        // Add to registered hotkeys
        registeredHotkeys.append(hotkey)
        
        // Publish registration event
        hotkeyRegistrationPublisher.send(.registered(hotkey))
        
        print("✅ GlobalHotkeyManager: Registered hotkey '\(hotkey.name)' (\(hotkey.displayString))")
    }
    
    /// Unregister a hotkey binding
    public func unregisterHotkey(_ hotkey: HotkeyBinding) {
        guard let index = registeredHotkeys.firstIndex(of: hotkey),
              let hotkeyId = hotkeyEventHandlerMapping[hotkey] else {
            return
        }
        
        // Remove from collections
        registeredHotkeys.remove(at: index)
        hotkeyEventHandlers.removeValue(forKey: hotkeyId)
        hotkeyEventHandlerMapping.removeValue(forKey: hotkey)
        
        // Publish unregistration event
        hotkeyRegistrationPublisher.send(.unregistered(hotkey))
        
        print("❌ GlobalHotkeyManager: Unregistered hotkey '\(hotkey.name)'")
    }
    
    /// Register default hotkeys
    public func registerDefaultHotkeys() {
        for hotkey in Self.defaultHotkeys {
            do {
                try registerHotkey(hotkey)
            } catch {
                print("⚠️ GlobalHotkeyManager: Failed to register default hotkey '\(hotkey.name)': \(error)")
                hotkeyRegistrationPublisher.send(.failed(hotkey, error))
            }
        }
    }
    
    /// Clear all registered hotkeys
    public func clearAllHotkeys() {
        let hotkeys = registeredHotkeys
        for hotkey in hotkeys {
            unregisterHotkey(hotkey)
        }
    }
    
    /// Check if accessibility permissions are granted
    public func hasAccessibilityPermissions() -> Bool {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [trusted: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Request accessibility permissions
    public func requestAccessibilityPermissions() {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [trusted: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        print("🔒 GlobalHotkeyManager: Requesting accessibility permissions")
    }
    
    // MARK: - Private Methods
    
    private func setupKeyCodeMapper() {
        // KeyCodeMapper setup is handled internally
        _ = KeyCodeMapper.shared
    }
    
    private func setupEventTap() {
        // Create event tap for key events
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { proxy, type, event, refcon in
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleEventTap(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            print("❌ GlobalHotkeyManager: Failed to create event tap")
            return
        }
        
        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
        
        // Check if any registered hotkey matches
        for hotkey in registeredHotkeys where hotkey.isEnabled {
            if hotkey.keyCode == keyCode && hotkey.modifiers.intersection([.command, .option, .control, .shift]) == modifiers.intersection([.command, .option, .control, .shift]) {
                
                // Trigger hotkey on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.handleHotkeyTriggered(hotkey)
                }
                
                // Consume the event (prevent further processing)
                return nil
            }
        }
        
        // Pass through unhandled events
        return Unmanaged.passRetained(event)
    }
    
    private func handleHotkeyTriggered(_ hotkey: HotkeyBinding) {
        lastTriggeredHotkey = hotkey
        
        // Publish hotkey event
        hotkeyTriggeredPublisher.send(hotkey)
        
        // Log trigger
        print("🎯 GlobalHotkeyManager: Triggered hotkey '\(hotkey.name)' (\(hotkey.displayString))")
        
        // Execute action (will be handled by ActivationCoordinator)
    }
    
    private func findConflictingHotkey(_ hotkey: HotkeyBinding) -> HotkeyBinding? {
        return registeredHotkeys.first { existing in
            existing.keyCode == hotkey.keyCode && existing.modifiers == hotkey.modifiers
        }
    }
}

// MARK: - Key Code Mapper

private final class KeyCodeMapper {
    static let shared = KeyCodeMapper()
    
    private let keyCodeToName: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3",
        21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
        31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'", 40: "K",
        41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "Delete", 53: "Escape", 55: "Command", 56: "Shift", 57: "CapsLock",
        58: "Option", 59: "Control", 60: "RightShift", 61: "RightOption", 62: "RightControl",
        63: "Function", 65: "KeypadDecimal", 67: "KeypadMultiply", 69: "KeypadPlus",
        71: "KeypadClear", 75: "KeypadDivide", 76: "KeypadEnter", 78: "KeypadMinus",
        81: "KeypadEquals", 82: "Keypad0", 83: "Keypad1", 84: "Keypad2", 85: "Keypad3",
        86: "Keypad4", 87: "Keypad5", 88: "Keypad6", 89: "Keypad7", 91: "Keypad8", 92: "Keypad9",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11",
        109: "F10", 111: "F12", 113: "F13", 114: "Help", 115: "Home", 116: "PageUp",
        117: "ForwardDelete", 118: "F4", 119: "End", 120: "F2", 121: "PageDown", 122: "F1",
        123: "LeftArrow", 124: "RightArrow", 125: "DownArrow", 126: "UpArrow"
    ]
    
    func keyName(for keyCode: UInt32) -> String? {
        return keyCodeToName[keyCode]
    }
}

// MARK: - Hotkey Errors

public enum HotkeyError: LocalizedError {
    case alreadyRegistered
    case conflictWithExisting(HotkeyBinding)
    case accessibilityPermissionsDenied
    case systemHotkeyConflict
    case invalidKeyCode
    
    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered:
            return "Hotkey is already registered"
        case .conflictWithExisting(let hotkey):
            return "Hotkey conflicts with existing binding: \(hotkey.name)"
        case .accessibilityPermissionsDenied:
            return "Accessibility permissions required for global hotkeys"
        case .systemHotkeyConflict:
            return "Hotkey conflicts with system shortcut"
        case .invalidKeyCode:
            return "Invalid key code"
        }
    }
}

// MARK: - GlobalHotkeyManager Extensions

extension GlobalHotkeyManager {
    
    /// Convenience method to handle specific actions
    public func onHotkeyAction(_ action: HotkeyAction, handler: @escaping (HotkeyBinding) -> Void) {
        hotkeyTriggeredPublisher
            .filter { $0.action == action }
            .sink { hotkey in
                handler(hotkey)
            }
            .store(in: &cancellables)
    }
    
    /// Convenience method to handle any hotkey
    public func onAnyHotkey(_ handler: @escaping (HotkeyBinding) -> Void) {
        hotkeyTriggeredPublisher
            .sink { hotkey in
                handler(hotkey)
            }
            .store(in: &cancellables)
    }
    
    /// Get current hotkey manager status
    public var status: String {
        if !hasAccessibilityPermissions() {
            return "🔒 Permissions needed"
        }
        
        if isMonitoring {
            return "⌨️ Monitoring (\(registeredHotkeys.count) hotkeys)"
        } else {
            return "💤 Inactive"
        }
    }
    
    /// Get hotkey statistics
    public var statistics: String {
        let enabled = registeredHotkeys.filter(\.isEnabled).count
        let total = registeredHotkeys.count
        return "Hotkeys: \(enabled)/\(total) enabled"
    }
}