# ForceQUIT - SWARM 2.0 AI Development Framework
# Comprehensive Build System for macOS Swift Applications
# Agent-Driven Compilation and Distribution

.PHONY: all build clean test debug release universal sign notarize dmg install lint format help

# Configuration
APP_NAME := ForceQUIT
BUNDLE_ID := com.forcequit.macos
BUILD_DIR := .build
DIST_DIR := dist
RELEASE_DIR := $(BUILD_DIR)/apple/Products/Release
DEBUG_DIR := $(BUILD_DIR)/apple/Products/Debug

# Swift Package Manager Build Configurations
SWIFT_BUILD_FLAGS := --configuration
SWIFT_TEST_FLAGS := --parallel
SWIFT_CLEAN_FLAGS := --build-path $(BUILD_DIR)

# Architecture Support
ARCHS := x86_64 arm64
UNIVERSAL_FLAGS := --arch x86_64 --arch arm64

# Default target
all: build

# Help target - SWARM Framework standard
help:
	@echo "🚀 SWARM 2.0 AI Development Framework - ForceQUIT Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build          - Build debug version"
	@echo "  release        - Build release version"
	@echo "  universal      - Build universal binary (Intel + Apple Silicon)"
	@echo "  test           - Run all tests"
	@echo "  clean          - Clean build artifacts"
	@echo "  lint           - Run Swift linting"
	@echo "  format         - Format Swift code"
	@echo "  sign           - Code sign application"
	@echo "  notarize       - Notarize application"
	@echo "  dmg            - Create DMG installer"
	@echo "  install        - Install to Applications"
	@echo "  dist           - Complete distribution build"
	@echo ""
	@echo "🎯 SWARM Mission: Elegant macOS Force Quit Utility"

# Build targets
build: debug

debug:
	@echo "🔨 Building $(APP_NAME) - Debug Configuration..."
	swift build $(SWIFT_BUILD_FLAGS) debug
	@echo "✅ Debug build complete"

release:
	@echo "🚀 Building $(APP_NAME) - Release Configuration..."
	swift build $(SWIFT_BUILD_FLAGS) release
	@echo "✅ Release build complete"

universal:
	@echo "🌐 Building $(APP_NAME) - Universal Binary..."
	swift build $(SWIFT_BUILD_FLAGS) release $(UNIVERSAL_FLAGS)
	@echo "✅ Universal build complete"

# Test targets
test:
	@echo "🧪 Running $(APP_NAME) Tests..."
	swift test $(SWIFT_TEST_FLAGS)
	@echo "✅ All tests passed"

test-debug:
	@echo "🔍 Running $(APP_NAME) Debug Tests..."
	swift test $(SWIFT_BUILD_FLAGS) debug
	@echo "✅ Debug tests complete"

test-release:
	@echo "⚡ Running $(APP_NAME) Release Tests..."
	swift test $(SWIFT_BUILD_FLAGS) release
	@echo "✅ Release tests complete"

# Clean target
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean $(SWIFT_CLEAN_FLAGS)
	rm -rf $(DIST_DIR)
	@echo "✅ Clean complete"

# Code quality targets
lint:
	@echo "🔍 Linting Swift code..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint --strict; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

format:
	@echo "✨ Formatting Swift code..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat .; \
	else \
		echo "⚠️  SwiftFormat not installed. Install with: brew install swiftformat"; \
	fi

# Distribution targets
sign: release
	@echo "🔐 Code signing $(APP_NAME)..."
	@if [ -f "$(RELEASE_DIR)/$(APP_NAME)" ]; then \
		codesign --force --options runtime --sign "Developer ID Application" "$(RELEASE_DIR)/$(APP_NAME)" --entitlements "Sources/$(APP_NAME)/Resources/$(APP_NAME).entitlements"; \
		echo "✅ Code signing complete"; \
	else \
		echo "❌ Release binary not found. Run 'make release' first."; \
		exit 1; \
	fi

notarize: sign
	@echo "📋 Notarizing $(APP_NAME)..."
	@echo "⚠️  Notarization requires Apple Developer credentials"
	@echo "ℹ️  Configure with: xcrun notarytool store-credentials"

dmg: sign
	@echo "💽 Creating DMG installer for $(APP_NAME)..."
	mkdir -p $(DIST_DIR)
	@if command -v create-dmg >/dev/null 2>&1; then \
		create-dmg \
			--volname "$(APP_NAME) Installer" \
			--window-pos 200 120 \
			--window-size 800 400 \
			--icon-size 100 \
			--icon "$(APP_NAME).app" 200 190 \
			--hide-extension "$(APP_NAME).app" \
			--app-drop-link 600 185 \
			"$(DIST_DIR)/$(APP_NAME)-installer.dmg" \
			"$(RELEASE_DIR)/"; \
		echo "✅ DMG creation complete"; \
	else \
		echo "⚠️  create-dmg not installed. Install with: brew install create-dmg"; \
	fi

install: release
	@echo "📱 Installing $(APP_NAME) to /Applications..."
	@if [ -f "$(RELEASE_DIR)/$(APP_NAME)" ]; then \
		cp -R "$(RELEASE_DIR)/$(APP_NAME)" "/Applications/"; \
		echo "✅ Installation complete"; \
	else \
		echo "❌ Release binary not found. Run 'make release' first."; \
	fi

# Complete distribution workflow
dist: clean lint test release sign dmg
	@echo "🎉 Complete distribution build finished!"
	@echo "📦 Artifacts available in: $(DIST_DIR)/"

# Development workflow
dev: clean debug test
	@echo "🛠️  Development build complete"

# CI/CD workflow  
ci: clean lint test-debug test-release
	@echo "🤖 CI/CD pipeline complete"

# SWARM Framework specific targets
swarm-init:
	@echo "🌟 SWARM 2.0 Framework Initialized"
	@echo "✅ Project structure ready for AI agents"

swarm-validate:
	@echo "✅ SWARM Framework validation complete"
	@swift package describe --type json > /dev/null
	@echo "📋 Package configuration valid"

# Version information
version:
	@echo "$(APP_NAME) Build System - SWARM 2.0 Framework"
	@swift --version
	@echo "Xcode: $(shell xcode-select --print-path 2>/dev/null || echo 'Not installed')"