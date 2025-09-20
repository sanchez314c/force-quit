# ForceQUIT Code Style and Conventions

## Swift Style Guidelines

### Naming Conventions
- **Classes**: PascalCase (e.g., `ProcessMonitor`, `ForceQuitApp`)
- **Functions/Variables**: camelCase (e.g., `scanForProcesses`, `isHealthy`)
- **Constants**: camelCase with descriptive names (e.g., `maxMemoryLimit`)
- **Enums**: PascalCase with descriptive cases (e.g., `ProcessState.healthy`)

### Architecture Patterns
- **MVVM + Coordinator Pattern** for SwiftUI apps
- **Actor-based concurrency** for thread safety
- **Combine framework** for reactive programming
- **Protocol-oriented programming** for testability

### Performance Guidelines
- Use `@StateObject` and `@ObservedObject` appropriately
- Implement `Equatable` for SwiftUI view optimization
- Use Swift actors for concurrent operations
- Memory-conscious data structures (weak references, ring buffers)

### Security Practices
- Input validation and sanitization
- Minimal privilege principle
- Secure XPC communication patterns
- Protection of critical system processes

### Documentation Standards
- Document public APIs with /// comments
- Use // MARK: for code organization
- Include performance considerations in comments
- Security implications noted where relevant

## Dark Mode & Avant-garde Design
- Glassmorphic UI components with proper blur effects
- RGB accent lighting system (Blue/Orange/Red/Green modes)
- Metal particle systems for visual feedback
- 120fps target for animations on Apple Silicon