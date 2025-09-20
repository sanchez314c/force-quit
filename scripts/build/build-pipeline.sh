#!/bin/bash

# SWARM 2.0 ForceQUIT Automated Build Pipeline
# Phase 8: Build-Compile-Dist
# Session: FLIPPED-POLES
# Complete automated build, sign, notarize, and distribute

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Build Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

# Pipeline Configuration
SKIP_TESTS="${SKIP_TESTS:-false}"
SKIP_SIGNING="${SKIP_SIGNING:-false}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-false}"
SKIP_DMG="${SKIP_DMG:-false}"
CLEAN_BUILD="${CLEAN_BUILD:-true}"
VERBOSE="${VERBOSE:-false}"

# Directories
BUILD_LOG_DIR="./logs"
PIPELINE_START_TIME=$(date +%s)

echo -e "${CYAN}===============================================${NC}"
echo -e "${WHITE}    SWARM 2.0 Automated Build Pipeline${NC}"
echo -e "${WHITE}    Project: ForceQUIT v${VERSION} (${BUILD_NUMBER})${NC}"
echo -e "${WHITE}    Session: FLIPPED-POLES${NC}"
echo -e "${CYAN}===============================================${NC}"

# Create logging infrastructure
setup_logging() {
    mkdir -p "$BUILD_LOG_DIR"
    PIPELINE_LOG="$BUILD_LOG_DIR/pipeline-$(date +%Y%m%d-%H%M%S).log"
    
    echo -e "${BLUE}📝 Build logs: $PIPELINE_LOG${NC}"
    
    # Redirect all output to log file while maintaining console output
    if [ "$VERBOSE" = "true" ]; then
        exec 1> >(tee -a "$PIPELINE_LOG")
        exec 2> >(tee -a "$PIPELINE_LOG" >&2)
    else
        exec 1> >(tee -a "$PIPELINE_LOG")
        exec 2> >(tee -a "$PIPELINE_LOG" >&2)
    fi
}

# Display environment information
display_environment() {
    echo -e "${BLUE}🔍 Build Environment:${NC}"
    echo "   • macOS Version: $(sw_vers -productVersion)"
    echo "   • Xcode Version: $(xcodebuild -version | head -1 | awk '{print $2}')"
    echo "   • Swift Version: $(swift --version | head -1 | cut -d' ' -f4)"
    echo "   • Architecture: $(uname -m)"
    echo "   • Build Host: $(hostname)"
    echo "   • Build Date: $(date)"
    echo "   • Git Commit: $(git rev-parse HEAD 2>/dev/null || echo 'Not a git repository')"
    echo ""
}

# Clean previous builds
clean_build_artifacts() {
    if [ "$CLEAN_BUILD" = "true" ]; then
        echo -e "${YELLOW}🧹 Cleaning previous build artifacts...${NC}"
        
        # Remove build directories
        rm -rf ./build ./dist ./dmg ./notarized ./archive
        rm -rf ./ForceQUIT.xcodeproj/project.xcworkspace/xcuserdata
        rm -rf ./ForceQUIT.xcodeproj/xcuserdata
        
        # Clean Xcode derived data
        rm -rf ~/Library/Developer/Xcode/DerivedData/ForceQUIT-*
        
        echo -e "${GREEN}✅ Build artifacts cleaned${NC}"
    else
        echo -e "${YELLOW}⚠️ Skipping build cleanup (CLEAN_BUILD=false)${NC}"
    fi
}

# Pre-flight checks
preflight_checks() {
    echo -e "${BLUE}🔍 Running pre-flight checks...${NC}"
    
    local errors=0
    
    # Check for required tools
    local required_tools=("xcodebuild" "swift" "codesign" "hdiutil" "plutil")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}❌ Required tool not found: $tool${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✅ $tool available${NC}"
        fi
    done
    
    # Check source files
    if [ ! -f "src/Sources/main.swift" ]; then
        echo -e "${RED}❌ Main source file not found: src/Sources/main.swift${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✅ Main source file found${NC}"
    fi
    
    # Check Package.swift
    if [ ! -f "src/Package.swift" ]; then
        echo -e "${RED}❌ Package.swift not found${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✅ Package.swift found${NC}"
    fi
    
    # Check Xcode project
    if [ ! -f "ForceQUIT.xcodeproj/project.pbxproj" ]; then
        echo -e "${RED}❌ Xcode project not found${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✅ Xcode project found${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "${RED}❌ Pre-flight checks failed with $errors errors${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Pre-flight checks passed${NC}"
}

# Run tests (if available)
run_tests() {
    if [ "$SKIP_TESTS" = "true" ]; then
        echo -e "${YELLOW}⚠️ Skipping tests (SKIP_TESTS=true)${NC}"
        return 0
    fi
    
    echo -e "${PURPLE}🧪 Running tests...${NC}"
    
    # Check if tests exist
    if [ -d "src/Tests" ]; then
        cd src
        swift test --configuration release
        local test_result=$?
        cd ..
        
        if [ $test_result -eq 0 ]; then
            echo -e "${GREEN}✅ Tests passed${NC}"
        else
            echo -e "${RED}❌ Tests failed${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️ No tests found, skipping${NC}"
    fi
}

# Execute build pipeline steps
execute_pipeline_step() {
    local step_name="$1"
    local script_name="$2"
    local skip_flag="$3"
    
    if [ "$skip_flag" = "true" ]; then
        echo -e "${YELLOW}⚠️ Skipping $step_name${NC}"
        return 0
    fi
    
    echo -e "${PURPLE}🚀 Executing: $step_name${NC}"
    
    local step_start_time=$(date +%s)
    
    if [ -x "./$script_name" ]; then
        if ./"$script_name"; then
            local step_end_time=$(date +%s)
            local step_duration=$((step_end_time - step_start_time))
            echo -e "${GREEN}✅ $step_name completed in ${step_duration}s${NC}"
        else
            echo -e "${RED}❌ $step_name failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Script not found or not executable: $script_name${NC}"
        exit 1
    fi
}

# Generate build report
generate_build_report() {
    local pipeline_end_time=$(date +%s)
    local total_duration=$((pipeline_end_time - pipeline_start_time))
    
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${WHITE}    Build Pipeline Complete!${NC}"
    echo -e "${WHITE}    Total Duration: ${total_duration}s${NC}"
    echo -e "${CYAN}===============================================${NC}"
    
    # Create build report
    local report_file="$BUILD_LOG_DIR/build-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$report_file" << EOF
{
    "project": "$PROJECT_NAME",
    "version": "$VERSION",
    "build_number": "$BUILD_NUMBER",
    "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "build_host": "$(hostname)",
    "macos_version": "$(sw_vers -productVersion)",
    "xcode_version": "$(xcodebuild -version | head -1 | awk '{print $2}')",
    "swift_version": "$(swift --version | head -1 | cut -d' ' -f4)",
    "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "build_duration_seconds": $total_duration,
    "pipeline_configuration": {
        "skip_tests": $SKIP_TESTS,
        "skip_signing": $SKIP_SIGNING,
        "skip_notarization": $SKIP_NOTARIZATION,
        "skip_dmg": $SKIP_DMG,
        "clean_build": $CLEAN_BUILD
    },
    "artifacts": {
        "unsigned_app": "$([ -f "dist/$PROJECT_NAME.app" ] && echo "true" || echo "false")",
        "signed_app": "$([ -f "notarized/$PROJECT_NAME.app" ] && echo "true" || echo "false")",
        "installer_pkg": "$([ -f "notarized/installer/$PROJECT_NAME-$VERSION.pkg" ] && echo "true" || echo "false")",
        "appstore_pkg": "$([ -f "notarized/appstore/$PROJECT_NAME-AppStore-$VERSION.pkg" ] && echo "true" || echo "false")",
        "distribution_dmg": "$([ -f "dist/$PROJECT_NAME-$VERSION"*.dmg ] && echo "true" || echo "false")"
    }
}
EOF
    
    echo -e "${BLUE}📊 Build report: $report_file${NC}"
    
    # Display artifacts summary
    echo -e "${YELLOW}📦 Build Artifacts:${NC}"
    
    if [ -f "dist/$PROJECT_NAME.app/Contents/MacOS/$PROJECT_NAME" ]; then
        echo -e "   ✅ Universal App Binary: dist/$PROJECT_NAME.app"
        file "dist/$PROJECT_NAME.app/Contents/MacOS/$PROJECT_NAME"
    fi
    
    if [ -f "notarized/$PROJECT_NAME.app/Contents/MacOS/$PROJECT_NAME" ]; then
        echo -e "   ✅ Signed & Notarized App: notarized/$PROJECT_NAME.app"
    fi
    
    if [ -f "notarized/installer/$PROJECT_NAME-$VERSION.pkg" ]; then
        echo -e "   ✅ Installer Package: notarized/installer/$PROJECT_NAME-$VERSION.pkg"
    fi
    
    if [ -f "notarized/appstore/$PROJECT_NAME-AppStore-$VERSION.pkg" ]; then
        echo -e "   ✅ App Store Package: notarized/appstore/$PROJECT_NAME-AppStore-$VERSION.pkg"
    fi
    
    for dmg_file in dist/$PROJECT_NAME-$VERSION*.dmg; do
        if [ -f "$dmg_file" ]; then
            echo -e "   ✅ Distribution DMG: $dmg_file"
        fi
    done
    
    echo -e "${CYAN}🎉 ForceQUIT is ready to ship!${NC}"
}

# Help function
show_help() {
    echo -e "${WHITE}SWARM 2.0 ForceQUIT Build Pipeline${NC}"
    echo -e ""
    echo -e "${YELLOW}Usage:${NC} ./build-pipeline.sh [OPTIONS]"
    echo -e ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  --skip-tests           Skip test execution"
    echo -e "  --skip-signing         Skip code signing"
    echo -e "  --skip-notarization    Skip notarization"
    echo -e "  --skip-dmg             Skip DMG creation"
    echo -e "  --no-clean             Don't clean previous builds"
    echo -e "  --verbose              Enable verbose logging"
    echo -e "  --help                 Show this help message"
    echo -e ""
    echo -e "${YELLOW}Environment Variables:${NC}"
    echo -e "  BUILD_NUMBER           Build number (default: 1)"
    echo -e "  DEVELOPER_ID_APPLICATION  Code signing identity"
    echo -e "  APPLE_ID               Apple ID for notarization"
    echo -e "  APPLE_ID_PASSWORD      App-specific password"
    echo -e "  TEAM_ID                Apple Developer Team ID"
    echo -e ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ./build-pipeline.sh                    # Full pipeline"
    echo -e "  ./build-pipeline.sh --skip-signing     # Build without signing"
    echo -e "  ./build-pipeline.sh --verbose          # Verbose output"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            --skip-signing)
                SKIP_SIGNING="true"
                shift
                ;;
            --skip-notarization)
                SKIP_NOTARIZATION="true"
                shift
                ;;
            --skip-dmg)
                SKIP_DMG="true"
                shift
                ;;
            --no-clean)
                CLEAN_BUILD="false"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main pipeline execution
main() {
    parse_arguments "$@"
    setup_logging
    display_environment
    clean_build_artifacts
    preflight_checks
    run_tests
    
    # Execute pipeline steps
    execute_pipeline_step "Universal Binary Build" "build-universal.sh" "false"
    execute_pipeline_step "Code Signing & Notarization" "code-sign-notarize.sh" "$SKIP_SIGNING"
    execute_pipeline_step "DMG Creation" "create-dmg.sh" "$SKIP_DMG"
    
    generate_build_report
}

# Trap to handle interrupts
trap 'echo -e "${RED}Build pipeline interrupted${NC}"; exit 130' INT TERM

main "$@"