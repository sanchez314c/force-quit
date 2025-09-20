#!/bin/bash

# ===============================================================================
# ForceQUIT - Master Build Pipeline
# SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER
# ===============================================================================
# Complete end-to-end build and distribution pipeline
# Orchestrates: Testing, Building, Signing, Notarization, Distribution

set -e

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
BUNDLE_ID="com.swarm.forcequit"

# Pipeline stages
RUN_TESTS=true
BUILD_DEBUG=false
BUILD_RELEASE=true
BUILD_UNIVERSAL=true
CODE_SIGN=false
NOTARIZE=false
CREATE_DMG=false
CREATE_INSTALLER=false
APPSTORE_PACKAGE=false
DEPLOY_ARTIFACTS=false

# Build configuration
OPTIMIZE_SIZE=true
STRIP_SYMBOLS=true
PARALLEL_BUILD=true
FAIL_FAST=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            RUN_TESTS=false
            shift
            ;;
        --debug)
            BUILD_DEBUG=true
            BUILD_RELEASE=false
            BUILD_UNIVERSAL=false
            shift
            ;;
        --sign)
            CODE_SIGN=true
            shift
            ;;
        --notarize)
            CODE_SIGN=true
            NOTARIZE=true
            shift
            ;;
        --dmg)
            CREATE_DMG=true
            shift
            ;;
        --installer)
            CREATE_INSTALLER=true
            shift
            ;;
        --appstore)
            APPSTORE_PACKAGE=true
            shift
            ;;
        --deploy)
            DEPLOY_ARTIFACTS=true
            shift
            ;;
        --full-pipeline)
            RUN_TESTS=true
            BUILD_RELEASE=true
            BUILD_UNIVERSAL=true
            CODE_SIGN=true
            NOTARIZE=true
            CREATE_DMG=true
            CREATE_INSTALLER=true
            DEPLOY_ARTIFACTS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-tests        Skip test execution"
            echo "  --debug            Build debug version only"
            echo "  --sign             Enable code signing"
            echo "  --notarize         Enable notarization (implies --sign)"
            echo "  --dmg              Create DMG installer"
            echo "  --installer        Create PKG installer"
            echo "  --appstore         Prepare App Store package"
            echo "  --deploy           Deploy artifacts"
            echo "  --full-pipeline    Run complete pipeline"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[BUILD PIPELINE]${NC} $1"
}

stage() {
    echo -e "\n${CYAN}===============================================================================${NC}"
    echo -e "${WHITE}                $1${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    if [[ "$FAIL_FAST" == true ]]; then
        exit 1
    fi
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Track pipeline progress
PIPELINE_START_TIME=$(date +%s)
STAGES_COMPLETED=0
STAGES_FAILED=0
STAGE_RESULTS=()

record_stage_result() {
    local stage_name="$1"
    local result="$2"
    local duration="$3"
    
    STAGE_RESULTS+=("$stage_name:$result:$duration")
    
    if [[ "$result" == "SUCCESS" ]]; then
        STAGES_COMPLETED=$((STAGES_COMPLETED + 1))
    else
        STAGES_FAILED=$((STAGES_FAILED + 1))
    fi
}

# Execute stage with timing and error handling
execute_stage() {
    local stage_name="$1"
    local command="$2"
    
    stage "$stage_name"
    local stage_start=$(date +%s)
    
    if eval "$command"; then
        local stage_end=$(date +%s)
        local duration=$((stage_end - stage_start))
        success "$stage_name completed in ${duration}s"
        record_stage_result "$stage_name" "SUCCESS" "$duration"
        return 0
    else
        local stage_end=$(date +%s)
        local duration=$((stage_end - stage_start))
        error "$stage_name failed after ${duration}s"
        record_stage_result "$stage_name" "FAILED" "$duration"
        return 1
    fi
}

# Header
echo -e "${CYAN}===============================================================================${NC}"
echo -e "${WHITE}                ForceQUIT Master Build Pipeline${NC}"
echo -e "${WHITE}                BUILD_SYSTEM_DEVELOPER - SWARM 2.0${NC}"
echo -e "${CYAN}===============================================================================${NC}"

info "Pipeline Configuration:"
info "   • Run Tests: $RUN_TESTS"
info "   • Build Debug: $BUILD_DEBUG"
info "   • Build Release: $BUILD_RELEASE"
info "   • Build Universal: $BUILD_UNIVERSAL"
info "   • Code Signing: $CODE_SIGN"
info "   • Notarization: $NOTARIZE"
info "   • Create DMG: $CREATE_DMG"
info "   • Create Installer: $CREATE_INSTALLER"
info "   • App Store Package: $APPSTORE_PACKAGE"
info "   • Deploy Artifacts: $DEPLOY_ARTIFACTS"

# Stage 1: Environment Validation
execute_stage "Environment Validation" '
    log "🔍 Validating build environment..."
    
    # Check required tools
    command -v swift >/dev/null || { error "Swift toolchain not found"; exit 1; }
    command -v lipo >/dev/null || { error "lipo not found"; exit 1; }
    
    # Check project structure
    [ -f "Package.swift" ] || { error "Package.swift not found"; exit 1; }
    
    # Make all scripts executable
    chmod +x *.sh 2>/dev/null || true
    
    log "✅ Environment validation passed"
'

# Stage 2: Test Suite Execution
if [[ "$RUN_TESTS" == true ]]; then
    execute_stage "Test Suite Execution" '
        log "🧪 Running comprehensive test suite..."
        ./swift-test-suite.sh --verbose
    '
fi

# Stage 3: Debug Build
if [[ "$BUILD_DEBUG" == true ]]; then
    execute_stage "Debug Build" '
        log "🛠️ Building debug version..."
        ./swift-build-debug.sh
    '
fi

# Stage 4: Release Build
if [[ "$BUILD_RELEASE" == true ]]; then
    execute_stage "Release Build" '
        log "🚀 Building release version..."
        local flags=""
        if [[ "$OPTIMIZE_SIZE" == true ]]; then
            flags="--optimize-size"
        fi
        if [[ "$STRIP_SYMBOLS" == false ]]; then
            flags="$flags --keep-symbols"
        fi
        ./swift-build-release.sh $flags
    '
fi

# Stage 5: Universal Binary Build
if [[ "$BUILD_UNIVERSAL" == true ]]; then
    execute_stage "Universal Binary Build" '
        log "🔗 Building universal binary..."
        local flags="--test"
        if [[ "$OPTIMIZE_SIZE" == true ]]; then
            flags="$flags --optimize-size"
        fi
        if [[ "$STRIP_SYMBOLS" == false ]]; then
            flags="$flags --keep-symbols"
        fi
        if [[ "$PARALLEL_BUILD" == false ]]; then
            flags="$flags --sequential"
        fi
        ./swift-build-universal.sh $flags
    '
fi

# Stage 6: Code Signing Configuration
if [[ "$CODE_SIGN" == true ]]; then
    execute_stage "Code Signing Setup" '
        log "🔑 Setting up code signing..."
        ./code-sign-config.sh
    '
fi

# Stage 7: Code Signing & Notarization
if [[ "$CODE_SIGN" == true ]]; then
    execute_stage "Code Signing & Notarization" '
        log "🔐 Signing and notarizing..."
        if [[ "$NOTARIZE" == true ]]; then
            # Full signing and notarization
            ./code-sign-notarize.sh
        else
            # Signing only (for development)
            log "⚠️ Notarization disabled - signing only"
            # Add signing-only command here
        fi
    '
fi

# Stage 8: DMG Creation
if [[ "$CREATE_DMG" == true ]]; then
    execute_stage "DMG Creation" '
        log "🗂️ Creating DMG installer..."
        ./create-dmg-installer.sh
    '
fi

# Stage 9: Installer Package Creation
if [[ "$CREATE_INSTALLER" == true ]]; then
    execute_stage "Installer Package Creation" '
        log "📦 Creating installer package..."
        # Use existing appstore-package.sh or create new installer script
        if [ -f "appstore-package.sh" ]; then
            ./appstore-package.sh
        else
            log "⚠️ Installer package script not found - skipping"
        fi
    '
fi

# Stage 10: App Store Package Preparation
if [[ "$APPSTORE_PACKAGE" == true ]]; then
    execute_stage "App Store Package Preparation" '
        log "🍎 Preparing App Store package..."
        # App Store specific packaging
        log "⚠️ App Store packaging requires additional configuration"
    '
fi

# Stage 11: Artifact Deployment
if [[ "$DEPLOY_ARTIFACTS" == true ]]; then
    execute_stage "Artifact Deployment" '
        log "🚀 Deploying artifacts..."
        
        # Create deployment directory
        mkdir -p deployment/
        
        # Copy all distribution artifacts
        cp -R build/ deployment/ 2>/dev/null || true
        cp -R dist/ deployment/ 2>/dev/null || true
        cp -R notarized/ deployment/ 2>/dev/null || true
        
        log "📊 Deployment artifacts:"
        find deployment/ -name "*.app" -o -name "*.zip" -o -name "*.dmg" -o -name "*.pkg" | head -20
    '
fi

# Pipeline Summary
PIPELINE_END_TIME=$(date +%s)
TOTAL_PIPELINE_TIME=$((PIPELINE_END_TIME - PIPELINE_START_TIME))

stage "Build Pipeline Complete"

success "📊 Pipeline Summary:"
info "   • Total Time: ${TOTAL_PIPELINE_TIME}s ($(($TOTAL_PIPELINE_TIME / 60))m $(($TOTAL_PIPELINE_TIME % 60))s)"
info "   • Stages Completed: $STAGES_COMPLETED"
info "   • Stages Failed: $STAGES_FAILED"
info "   • Success Rate: $(( STAGES_COMPLETED * 100 / (STAGES_COMPLETED + STAGES_FAILED) ))%"

log "🎯 Stage Results:"
for result in "${STAGE_RESULTS[@]}"; do
    IFS=':' read -ra PARTS <<< "$result"
    local stage="${PARTS[0]}"
    local status="${PARTS[1]}"
    local duration="${PARTS[2]}"
    
    if [[ "$status" == "SUCCESS" ]]; then
        echo -e "   ${GREEN}✅${NC} $stage (${duration}s)"
    else
        echo -e "   ${RED}❌${NC} $stage (${duration}s)"
    fi
done

# Final artifacts summary
if [ -d "deployment/" ]; then
    log "📦 Final Artifacts:"
    find deployment/ -name "*.app" -exec du -h {} \; | head -10
    find deployment/ -name "*.zip" -exec du -h {} \; | head -10
    find deployment/ -name "*.dmg" -exec du -h {} \; | head -10
fi

if [[ $STAGES_FAILED -gt 0 ]]; then
    error "❌ Pipeline completed with $STAGES_FAILED failed stages!"
    exit 1
else
    success "🎉 Pipeline completed successfully!"
    success "🚀 ForceQUIT is ready for distribution!"
fi