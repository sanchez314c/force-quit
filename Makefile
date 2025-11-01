# ForceQUIT Makefile
# Comprehensive build, test, and quality assurance system

.PHONY: help build test clean lint security deploy install dev-setup ci-check release

# Default target
.DEFAULT_GOAL := help

# Configuration
PROJECT_NAME := ForceQUIT
SCHEME := ForceQUIT
CONFIGURATION := Release
PLATFORM := macOS
SWIFT_VERSION := 5.9

# Directories
BUILD_DIR := build
DIST_DIR := dist
SOURCES_DIR := Sources
TESTS_DIR := tests
DOCS_DIR := docs
SCRIPTS_DIR := scripts

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Help target
help: ## Show this help message
	@echo "$(BLUE)ForceQUIT Build System$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development setup
dev-setup: ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@echo "$(YELLOW)Checking Swift version...$(NC)"
	@swift --version
	@echo "$(YELLOW)Installing SwiftLint...$(NC)"
	@if ! command -v swiftlint &> /dev/null; then \
		echo "$(RED)SwiftLint not found. Please install it:$(NC)"; \
		echo "  brew install swiftlint"; \
	else \
		echo "$(GREEN)SwiftLint is installed$(NC)"; \
	fi
	@echo "$(YELLOW)Checking Xcode tools...$(NC)"
	@xcode-select --install || true
	@echo "$(GREEN)Development environment setup complete$(NC)"

# Build targets
build: ## Build the application
	@echo "$(BLUE)Building $(PROJECT_NAME)...$(NC)"
	@swift build -c $(CONFIGURATION)
	@echo "$(GREEN)Build completed$(NC)"

build-debug: ## Build debug version
	@echo "$(BLUE)Building debug version...$(NC)"
	@swift build -c debug
	@echo "$(GREEN)Debug build completed$(NC)"

build-release: ## Build release version
	@echo "$(BLUE)Building release version...$(NC)"
	@swift build -c release
	@echo "$(GREEN)Release build completed$(NC)"

build-universal: ## Build universal binary (Intel + Apple Silicon)
	@echo "$(BLUE)Building universal binary...$(NC)"
	@./scripts/build.sh --universal
	@echo "$(GREEN)Universal binary completed$(NC)"

# Test targets
test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@./scripts/test.sh --unit
	@echo "$(GREEN)Tests completed$(NC)"

test-all: ## Run all test suites with coverage
	@echo "$(BLUE)Running all tests with coverage...$(NC)"
	@./scripts/test.sh --unit --integration --coverage
	@echo "$(GREEN)All tests completed$(NC)"

test-integration: ## Run integration tests
	@echo "$(BLUE)Running integration tests...$(NC)"
	@./scripts/test.sh --integration
	@echo "$(GREEN)Integration tests completed$(NC)"

test-ui: ## Run UI tests
	@echo "$(BLUE)Running UI tests...$(NC)"
	@./scripts/test.sh --ui
	@echo "$(GREEN)UI tests completed$(NC)"

# Quality assurance targets
lint: ## Run code linting
	@echo "$(BLUE)Running SwiftLint...$(NC)"
	@if command -v swiftlint &> /dev/null; then \
		swiftlint lint --strict; \
		echo "$(GREEN)Linting completed$(NC)"; \
	else \
		echo "$(RED)SwiftLint not found. Run 'make dev-setup' first.$(NC)"; \
		exit 1; \
	fi

lint-fix: ## Fix linting issues automatically
	@echo "$(BLUE)Fixing linting issues...$(NC)"
	@if command -v swiftlint &> /dev/null; then \
		swiftlint --fix; \
		echo "$(GREEN)Linting fixes applied$(NC)"; \
	else \
		echo "$(RED)SwiftLint not found. Run 'make dev-setup' first.$(NC)"; \
	fi

security-check: ## Run security analysis
	@echo "$(BLUE)Running security analysis...$(NC)"
	@echo "$(YELLOW)Checking for hardcoded secrets...$(NC)"
	@if grep -r -i -E "(password|secret|key|token)\s*=\s*\"[^\"]+\"" $(SOURCES_DIR)/ --include="*.swift" 2>/dev/null; then \
		echo "$(RED)Potential hardcoded secrets found$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)No hardcoded secrets found$(NC)"; \
	fi
	@echo "$(YELLOW)Checking for insecure functions...$(NC)"
	@./scripts/test.sh --security || true
	@echo "$(GREEN)Security analysis completed$(NC)"

format: ## Format code using SwiftFormat (if available)
	@echo "$(BLUE)Formatting code...$(NC)"
	@if command -v swiftformat &> /dev/null; then \
		swiftformat .; \
		echo "$(GREEN)Code formatted$(NC)"; \
	else \
		echo "$(YELLOW)SwiftFormat not found. Install with: brew install swiftformat$(NC)"; \
	fi

# Documentation targets
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@if command -v jazzy &> /dev/null; then \
		jazzy --clean --output docs/api --theme apple; \
		echo "$(GREEN)Documentation generated in docs/api$(NC)"; \
	else \
		echo "$(YELLOW)Jazzy not found. Install with: gem install jazzy$(NC)"; \
	fi

docs-serve: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation...$(NC)"
	@if [ -d "docs/api" ]; then \
		cd docs/api && python3 -m http.server 8080; \
	else \
		echo "$(RED)Documentation not found. Run 'make docs' first.$(NC)"; \
	fi

# Quality checks
quality-check: lint security-check test ## Run all quality checks
	@echo "$(GREEN)All quality checks completed$(NC)"

ci-check: ## Run CI checks (used in CI/CD)
	@echo "$(BLUE)Running CI checks...$(NC)"
	@make lint
	@make security-check
	@make test-all
	@make build-release
	@echo "$(GREEN)CI checks passed$(NC)"

# Clean targets
clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@swift package clean
	@echo "$(GREEN)Clean completed$(NC)"

clean-all: clean ## Clean everything including derived data
	@echo "$(BLUE)Cleaning all artifacts...$(NC)"
	@rm -rf DerivedData
	@rm -rf .build
	@rm -rf .swiftpm
	@echo "$(GREEN)Deep clean completed$(NC)"

# Build targets with scripts
build-signed: ## Build and sign the application
	@echo "$(BLUE)Building signed application...$(NC)"
	@./scripts/build.sh --sign
	@echo "$(GREEN)Signed build completed$(NC)"

build-notarized: ## Build, sign, and notarize the application
	@echo "$(BLUE)Building notarized application...$(NC)"
	@./scripts/build.sh --sign --notarize
	@echo "$(GREEN)Notarized build completed$(NC)"

build-dmg: ## Build and create DMG installer
	@echo "$(BLUE)Building DMG installer...$(NC)"
	@./scripts/build.sh --dmg
	@echo "$(GREEN)DMG build completed$(NC)"

build-release-complete: ## Complete release build (universal, signed, notarized, DMG)
	@echo "$(BLUE)Building complete release package...$(NC)"
	@./scripts/build.sh --clean --universal --sign --notarize --dmg
	@echo "$(GREEN)Release package completed$(NC)"

# Deployment targets
deploy-github: ## Deploy to GitHub releases
	@echo "$(BLUE)Deploying to GitHub...$(NC)"
	@./scripts/deploy.sh --github --release
	@echo "$(GREEN)GitHub deployment completed$(NC)"

deploy-homebrew: ## Create Homebrew formula
	@echo "$(BLUE)Creating Homebrew formula...$(NC)"
	@./scripts/deploy.sh --homebrew
	@echo "$(GREEN)Homebrew formula created$(NC)"

deploy-direct: ## Create direct download package
	@echo "$(BLUE)Creating direct download package...$(NC)"
	@./scripts/deploy.sh --direct
	@echo "$(GREEN)Direct download package created$(NC)"

deploy-all: ## Deploy to all channels
	@echo "$(BLUE)Deploying to all channels...$(NC)"
	@./scripts/deploy.sh --github --homebrew --direct --release
	@echo "$(GREEN)Full deployment completed$(NC)"

# Release targets
release-check: ## Run release checks
	@echo "$(BLUE)Running release checks...$(NC)"
	@make ci-check
	@make build-release-complete
	@echo "$(GREEN)Release checks passed$(NC)"

release: ## Create a new release
	@echo "$(BLUE)Creating new release...$(NC)"
	@make release-check
	@make deploy-all
	@echo "$(GREEN)Release completed$(NC)"

# Installation targets
install-local: ## Install locally from build
	@echo "$(BLUE)Installing locally...$(NC)"
	@make build-release
	@mkdir -p ~/Applications
	@cp -R $(BUILD_DIR)/release/$(PROJECT_NAME).app ~/Applications/
	@echo "$(GREEN)Installation completed$(NC)"

install: ## Install using setup script
	@echo "$(BLUE)Installing $(PROJECT_NAME)...$(NC)"
	@./setup.sh
	@echo "$(GREEN)Installation completed$(NC)"

# Development targets
run: ## Run the application from source
	@echo "$(BLUE)Running $(PROJECT_NAME) from source...$(NC)"
	@./run-source-macos.sh

run-built: ## Run the built application
	@echo "$(BLUE)Running built $(PROJECT_NAME)...$(NC)"
	@./run-macos.sh

# Performance targets
benchmark: ## Run performance benchmarks
	@echo "$(BLUE)Running performance benchmarks...$(NC)"
	@./scripts/test.sh --performance
	@echo "$(GREEN)Benchmarks completed$(NC)"

profile: ## Build with profiling instruments
	@echo "$(BLUE)Building with profiling...$(NC)"
	@swift build -c release -Xswiftc -profile-generate
	@echo "$(GREEN)Profiling build completed$(NC)"

# Utility targets
version: ## Show version information
	@echo "$(BLUE)$(PROJECT_NAME) Version Information:$(NC)"
	@echo "$(YELLOW)Swift Version:$(NC) $(shell swift --version | head -1)"
	@echo "$(YELLOW)Build Configuration:$(NC) $(CONFIGURATION)"
	@echo "$(YELLOW)Platform:$(NC) $(PLATFORM)"
	@if [ -f Package.resolved ]; then \
		echo "$(YELLOW)Dependencies:$(NC)"; \
		cat Package.resolved | jq -r '.pins[].state.version // .pins[].state.branch' 2>/dev/null || echo "No dependencies"; \
	fi

update-deps: ## Update dependencies
	@echo "$(BLUE)Updating dependencies...$(NC)"
	@swift package update
	@echo "$(GREEN)Dependencies updated$(NC)"

resolve-deps: ## Resolve dependencies
	@echo "$(BLUE)Resolving dependencies...$(NC)"
	@swift package resolve
	@echo "$(GREEN)Dependencies resolved$(NC)"

# Check if required tools are installed
check-tools:
	@echo "$(BLUE)Checking required tools...$(NC)"
	@command -v swift > /dev/null || (echo "$(RED)Swift not found$(NC)" && exit 1)
	@command -v git > /dev/null || (echo "$(RED)Git not found$(NC)" && exit 1)
	@command -v xcodebuild > /dev/null || (echo "$(RED)Xcode tools not found$(NC)" && exit 1)
	@echo "$(GREEN)All required tools are available$(NC)"

# Quick development workflow
dev: build test lint ## Quick development build (build, test, lint)
	@echo "$(GREEN)Development workflow completed$(NC)"

# Full quality workflow
qa: quality-check benchmark docs ## Full quality assurance workflow
	@echo "$(GREEN)Quality assurance workflow completed$(NC)"

# Default development setup
init: dev-setup check-tools resolve-deps ## Initial project setup
	@echo "$(GREEN)Project initialization completed$(NC)"