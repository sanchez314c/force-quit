# ForceQUIT Technology Stack

## Primary Language
- **Swift** - Native macOS development

## UI Framework
- **SwiftUI** with potential AppKit integration
- **MVVM + Coordinator Pattern** for architecture

## Platform Requirements
- **macOS 12.0+** (SwiftUI 3.0+ features)
- **Universal binary** support (Intel x64 + Apple Silicon ARM64)
- **Metal-capable GPU** for advanced rendering

## Core Frameworks
```swift
import SwiftUI          // Primary UI framework
import AppKit           // macOS native integration
import Foundation       // Core system APIs
import Combine          // Reactive programming
import Metal            // GPU rendering
import MetalKit         // Metal utilities
import CoreAnimation    // Animation engine
import ServiceManagement // Privilege management
import Security         // Authorization services
```

## Build System
- **Swift Package Manager** + CLI tools
- Multi-architecture support
- CLI-based build system designed for AI agent control

## Performance Targets
- Memory Budget: < 10MB base, < 20MB peak
- CPU Impact: < 0.1% idle, < 2% active  
- Startup Time: < 200ms cold start
- UI: 120fps on Apple Silicon, 60fps on Intel