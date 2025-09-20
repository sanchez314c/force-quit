# Claude Instructions for ForceQUIT

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ForceQUIT is an elegant macOS application designed to provide users with a sophisticated solution for quickly closing all open applications. The app serves as a master force quit utility with safe restart capabilities, featuring a dark mode, sleek, and avant-garde design with visual indicators, animations, and enhanced UX elements.

**Key Features:**
- 🚀 **Elegant Force Quit**: Sophisticated UI for terminating applications
- 🔄 **Safe Restart**: Restart applications that support it safely  
- 🎨 **Dark Mode Design**: Sleek, avant-garde interface with lights and indicators
- 🔒 **Security First**: SIP-compliant with proper sandboxing
- ⚡ **Multi-Modal Activation**: GUI, menu bar, hotkeys, and shake detection
- 📊 **Performance Monitoring**: Built-in analytics and system health tracking

## Technology Stack
- **Language**: Swift 5.9+
- **Framework**: SwiftUI with AppKit integration
- **Platform**: macOS 12.0+ (Monterey and later)  
- **Architecture**: Universal Binary (Intel x64 + Apple Silicon ARM64)
- **Build System**: Swift Package Manager + Xcode
- **Security**: SIP-compliant with helper tool architecture

**See [dev/tech-stack.md](dev/tech-stack.md) for complete technical details.**

## Key Conventions
- **File Naming**: Swift files use PascalCase (e.g., `ProcessManager.swift`)
- **Code Style**: Swift API guidelines with SwiftLint compliance
- **Architecture**: MVVM pattern with modular Swift packages
- **Testing**: Comprehensive XCTest suite with >90% coverage target

## Important Paths
- **Source Code**: `Sources/` (Swift packages) and root directory for main app files
- **Tests**: `tests/` with organized unit/integration/security tests  
- **Documentation**: `docs/` for technical documentation, `dev/` for development resources
- **Build Scripts**: `scripts/` with organized build/deploy/utils subdirectories
- **Assets**: `assets/` for icons, images, and resources
- **Development**: `dev/` for PRDs, specifications, research, and build templates

## Common Tasks

### Development
- **Run from source**: `./run-source-macos.sh`
- **Run compiled app**: `./run-macos.sh` 
- **Setup environment**: `./setup.sh`

### Building
- **Basic build**: `./scripts/compile-build-dist.sh`
- **Universal binary**: `./scripts/compile-build-dist.sh --arch universal`
- **Release with DMG**: `./scripts/compile-build-dist.sh --config release --dmg`
- **Signed build**: `./scripts/compile-build-dist.sh --sign --notarize`

### Testing
- **Run tests**: `swift test`
- **Full test suite**: `./scripts/build/test-automation.sh`

## SWARM 2.0 AI Development Framework

This project utilizes the SWARM 2.0 AI-driven development framework - a proven system that transforms ideas into production-ready applications using coordinated AI swarms. The framework has successfully built 3+ working apps in 24 hours and resurrected dead codebases in under 10 minutes.

### Framework Files Location
All SWARM framework documentation is located in the `/swarm/` directory:

- `master-swarm-prompt.md` - Complete system instructions and master coordinator prompt
- `swarm-workflow.md` - 10-step development sequence execution guide  
- `swarm-index.md` - Master index and navigation hub for all components
- `technical-overview-detailed.md` - Comprehensive technical documentation
- `proven-commands.md` - Library of tested command sequences
- `project-init-template.md` - Standardized project initialization template
- `build-compile-dist-swift-macos.md` - Swift macOS CLI build system with agent-driven compilation

### Development Commands (SWARM Framework)

**Critical Flags for Automation:**
```bash
--model sonnet --verbose --dangerously-skip-permissions -p
```

**Basic SWARM Pattern:**
```bash
echo "TASK_DESCRIPTION" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output.txt
```

**Parallel SWARM Execution:**
```bash
echo "AGENT_1_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent1.txt &
echo "AGENT_2_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent2.txt &
echo "AGENT_3_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent3.txt &
wait
```

## Build System for macOS Swift Apps

The project includes a comprehensive CLI-based Swift build system designed for AI agent control:

### Build Commands
```bash
# Basic Swift build (agent-executable)
swift build -c release

# Complete build with distribution (agent-controlled)
./compile-build-dist-swift.sh --config release

# Universal binary build
./compile-build-dist-swift.sh --arch universal --config release

# Signed and notarized build
./compile-build-dist-swift.sh --sign --notarize --dmg

# Development testing
./run-swift-source.sh
```

### Swift Project Structure
```
ForceQUIT/
├── Sources/                # Swift source code
│   └── main.swift         # Main application entry point
│   └── App/               # App modules
├── Resources/             # App resources
├── Package.swift          # Swift Package Manager configuration
├── build/                 # Build outputs
├── dist/                  # Distribution packages
└── swarm/                 # SWARM framework files
```

## 10-Step SWARM Development Process

When implementing features, follow this proven sequence:

1. **BrainSWARMING - App**: Concept definition and architecture decisions
2. **BrainSWARMING - UI/UX**: Interface design and user flow mapping  
3. **Techstack NanoSWARM Finalize**: Technology selection and dependencies
4. **PRD SWARM**: Comprehensive requirements documentation
5. **SWARM Build Phases**: Implementation in structured modules
6. **CodeFIX SWARM**: Automated issue detection and repair
7. **Q/C SWARM**: Quality control and optimization
8. **Build-Compile-Dist**: Platform-specific compilation
9. **Test**: Comprehensive testing and validation
10. **Feedback**: User testing and iteration planning

## Technology Stack

- **Primary Language**: Swift
- **UI Framework**: SwiftUI (with potential AppKit integration)
- **Platform**: macOS 12.0+
- **Build System**: Swift Package Manager + CLI tools
- **Architecture**: Multi-architecture support (Intel x64 + Apple Silicon ARM64)

## Code Architecture

### Core Concepts
- The app should provide elegant visual feedback during force quit operations
- Dark mode, sleek, avant-garde design philosophy
- Use of visual indicators like lights, switches, radio buttons for enhanced UX
- Safe restart capabilities for applications that support it

### Module Organization
The SWARM framework emphasizes breaking complex applications into 5-7 implementable modules with clear dependencies. For ForceQUIT, consider modules like:
- Process detection and management
- UI/UX components and visual feedback
- Safe restart logic
- User preferences and settings
- System integration and permissions

## Development Workflow

### Starting a New Feature
1. Reference `/swarm/master-swarm-prompt.md` for complete system instructions
2. Use `/swarm/project-init-template.md` for task structure
3. Follow `/swarm/swarm-workflow.md` for execution guidance
4. Deploy parallel SWARM agents using proven commands from `/swarm/proven-commands.md`

### Code Quality Assurance
- Use the CodeFIX SWARM for automated issue detection
- Deploy diagnostic swarms for comprehensive analysis
- Follow the two-phase approach: Generate → Fix
- Maintain context window efficiency (keep usage under 20%)

## Key Success Factors

1. **Follow the Sequence**: Each SWARM step builds on previous ones
2. **Use Mission Language**: "LAUNCH APPROVED" style commands improve output quality
3. **Trust Parallel Execution**: Terminal chaos during multiple swarms is normal
4. **Reference Specific Files**: Always point to relevant SWARM documentation
5. **Maintain Task Lists**: Essential for recovery and progress tracking
6. **Validate at Each Step**: Check outputs against acceptance criteria

## Critical Notes

- **Always use `--dangerously-skip-permissions`** for automation
- **Always use `&` for parallel execution** followed by `wait`
- **Use Sonnet for speed, Opus for synthesis**
- The framework operates on the principle that LLMs excel at finding and fixing problems rather than generating perfect code initially
- Context window usage should stay under 20% for optimal performance

## Recovery Procedures

If SWARM commands return "(No content)":
1. Verify you're using Claude CLI terminal (not GUI)
2. Check environment variables and API keys
3. Fall back to sequential execution if parallel fails
4. Create required directory structure: `mkdir -p {dev,docs,src,dist}`

## Success Metrics

The SWARM framework has proven metrics:
- Development time: 90-180 minutes for complete applications
- Dead codebase resurrection: 7-45 minutes  
- Context window usage: 8-10% (vs 80-90% traditional)
- Continuous development time: 8-10 hours without context issues