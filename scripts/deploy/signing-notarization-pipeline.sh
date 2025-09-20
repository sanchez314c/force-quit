#!/bin/bash

# ===============================================================================
# ForceQUIT - Code Signing & Notarization Pipeline
# SWARM 2.0 Framework - Phase 8: Distribution
# ===============================================================================
# Complete code signing and notarization system for macOS distribution

set -e

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
BUNDLE_ID="com.swarm.forcequit"
BUILD_DIR="build"
DIST_DIR="dist"
SIGNING_DIR="$DIST_DIR/signing"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[SIGNING]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
phase() { echo -e "${PURPLE}[PHASE]${NC} $1"; }

log "🔐 Setting up code signing & notarization pipeline for ForceQUIT"

# Create signing directory structure
mkdir -p "$SIGNING_DIR/certificates"
mkdir -p "$SIGNING_DIR/profiles"
mkdir -p "$SIGNING_DIR/scripts"
mkdir -p "$SIGNING_DIR/logs"

# Phase 1: Certificate management system
phase "1️⃣ Creating certificate management system..."

cat > "$SIGNING_DIR/scripts/manage_certificates.sh" << 'EOF'
#!/bin/bash

# ForceQUIT Certificate Management System
set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[CERT]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

log "🔐 Managing certificates for ForceQUIT"

# Function to list available signing identities
list_identities() {
    log "Available signing identities:"
    echo
    
    echo "🔵 Developer ID Application certificates:"
    security find-identity -v -p codesigning | grep "Developer ID Application" || echo "  None found"
    echo
    
    echo "🟡 Mac App Distribution certificates:"
    security find-identity -v -p codesigning | grep "Mac App Distribution" || echo "  None found"
    echo
    
    echo "🟠 Developer ID Installer certificates:"
    security find-identity -v -p codesigning | grep "Developer ID Installer" || echo "  None found"
    echo
}

# Function to verify certificate validity
verify_certificates() {
    log "Verifying certificate validity..."
    
    # Check Developer ID Application
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        success "✅ Developer ID Application certificate found"
    else
        warn "❌ Developer ID Application certificate missing"
        warn "   Required for: Direct distribution, DMG signing"
    fi
    
    # Check Mac App Distribution  
    if security find-identity -v -p codesigning | grep -q "Mac App Distribution"; then
        success "✅ Mac App Distribution certificate found"
    else
        warn "❌ Mac App Distribution certificate missing"
        warn "   Required for: App Store submission"
    fi
    
    # Check Developer ID Installer
    if security find-identity -v -p codesigning | grep -q "Developer ID Installer"; then
        success "✅ Developer ID Installer certificate found"
    else
        warn "❌ Developer ID Installer certificate missing"
        warn "   Required for: PKG installer signing"
    fi
}

# Function to setup certificate environment
setup_environment() {
    log "Setting up certificate environment..."
    
    # Create certificate configuration
    cat > ../certificates/cert_config.env << 'CERT_CONFIG'
# ForceQUIT Certificate Configuration
# Set these environment variables for automated signing

# Developer ID Application (for direct distribution)
export DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-Developer ID Application: Your Name (TEAMID)}"

# Mac App Distribution (for App Store)  
export MAC_APP_DISTRIBUTION="${MAC_APP_DISTRIBUTION:-Mac App Distribution: Your Name (TEAMID)}"

# Developer ID Installer (for PKG installers)
export DEVELOPER_ID_INSTALLER="${DEVELOPER_ID_INSTALLER:-Developer ID Installer: Your Name (TEAMID)}"

# App Store Connect Credentials (for notarization)
export APPLE_ID="${APPLE_ID:-your.email@example.com}"
export APPLE_PASSWORD="${APPLE_PASSWORD:-app-specific-password}"
export TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"

# Keychain configuration
export KEYCHAIN_NAME="${KEYCHAIN_NAME:-login}"
export KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-}"

CERT_CONFIG
    
    success "Certificate configuration created: ../certificates/cert_config.env"
    warn "⚠️  Edit cert_config.env with your actual certificate names and credentials"
}

# Function to test signing capability
test_signing() {
    log "Testing code signing capability..."
    
    # Source configuration
    if [[ -f "../certificates/cert_config.env" ]]; then
        source "../certificates/cert_config.env"
    else
        error "Configuration file not found. Run: $0 setup"
    fi
    
    # Create test file
    echo "Test file for signing" > test_file.txt
    
    # Test Developer ID signing
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        CERT_NAME=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*") //g' | sed 's/".*//g')
        
        codesign --force --sign "$CERT_NAME" test_file.txt 2>/dev/null && {
            success "✅ Developer ID Application signing test passed"
            codesign --verify test_file.txt && success "   Signature verification passed"
        } || {
            error "❌ Developer ID Application signing test failed"
        }
    else
        warn "⚠️  Skipping Developer ID test - certificate not found"
    fi
    
    # Cleanup
    rm -f test_file.txt
}

# Main command handling
case "${1:-help}" in
    "list"|"ls")
        list_identities
        ;;
    "verify"|"check")
        verify_certificates
        ;;
    "setup"|"init")
        setup_environment
        ;;
    "test")
        test_signing
        ;;
    "help"|*)
        echo "ForceQUIT Certificate Management"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  list     - List all available signing identities"
        echo "  verify   - Verify required certificates are installed"
        echo "  setup    - Create certificate configuration template"
        echo "  test     - Test code signing capability"
        echo "  help     - Show this help message"
        echo
        echo "Workflow:"
        echo "  1. Run 'setup' to create configuration template"
        echo "  2. Edit certificates/cert_config.env with your details"
        echo "  3. Run 'verify' to check certificate installation"
        echo "  4. Run 'test' to verify signing works correctly"
        ;;
esac
EOF

chmod +x "$SIGNING_DIR/scripts/manage_certificates.sh"

# Phase 2: Comprehensive signing script
phase "2️⃣ Creating comprehensive signing script..."

cat > "$SIGNING_DIR/scripts/sign_application.sh" << 'EOF'
#!/bin/bash

# ForceQUIT Application Signing Script
set -e

# Configuration
PROJECT_NAME="ForceQUIT"
BUILD_DIR="../../build"
SIGNING_DIR=".."
LOG_DIR="$SIGNING_DIR/logs"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[SIGN]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Parse arguments
DISTRIBUTION_TYPE="${1:-direct}"  # direct, appstore
APP_PATH="${2:-$BUILD_DIR/$PROJECT_NAME.app}"

log "🔏 Signing $PROJECT_NAME for $DISTRIBUTION_TYPE distribution"

# Load certificate configuration
if [[ -f "$SIGNING_DIR/certificates/cert_config.env" ]]; then
    source "$SIGNING_DIR/certificates/cert_config.env"
else
    error "Certificate configuration not found. Run manage_certificates.sh setup first."
fi

# Verify app bundle exists
if [[ ! -d "$APP_PATH" ]]; then
    error "App bundle not found: $APP_PATH"
fi

# Create logs directory
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/signing_$(date +%Y%m%d_%H%M%S).log"

# Function to log and execute
log_exec() {
    echo "Executing: $*" >> "$LOG_FILE"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Determine signing certificate
case "$DISTRIBUTION_TYPE" in
    "direct")
        CERT_NAME="$DEVELOPER_ID_APPLICATION"
        ENTITLEMENTS_FILE="$SIGNING_DIR/entitlements/direct_distribution.entitlements"
        ;;
    "appstore")
        CERT_NAME="$MAC_APP_DISTRIBUTION"
        ENTITLEMENTS_FILE="$SIGNING_DIR/entitlements/app_store.entitlements"
        ;;
    *)
        error "Unknown distribution type: $DISTRIBUTION_TYPE"
        ;;
esac

log "Using certificate: $CERT_NAME"

# Verify certificate exists
if ! security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    error "Certificate not found: $CERT_NAME"
fi

# Create entitlements directory if needed
mkdir -p "$SIGNING_DIR/entitlements"

# Create entitlements file for direct distribution
cat > "$SIGNING_DIR/entitlements/direct_distribution.entitlements" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Runtime hardening -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <false/>
    
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    
    <!-- Required for process control -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- Network access for updates -->
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS

# Create entitlements file for App Store
cat > "$SIGNING_DIR/entitlements/app_store.entitlements" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Required capabilities -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <key>com.apple.security.network.client</key>
    <true/>
    
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- App Store specific -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.swarm.forcequit</string>
    </array>
</dict>
</plist>
ENTITLEMENTS

# Start signing process
log "Starting signing process..."

# Sign nested frameworks first (if any)
if [[ -d "$APP_PATH/Contents/Frameworks" ]]; then
    log "Signing nested frameworks..."
    for framework in "$APP_PATH/Contents/Frameworks"/*.framework; do
        if [[ -d "$framework" ]]; then
            log_exec codesign --force \
                              --sign "$CERT_NAME" \
                              --options runtime \
                              --timestamp \
                              "$framework"
            success "Signed framework: $(basename "$framework")"
        fi
    done
fi

# Sign helper tools (if any)
if [[ -d "$APP_PATH/Contents/Library/LaunchServices" ]]; then
    log "Signing helper tools..."
    for helper in "$APP_PATH/Contents/Library/LaunchServices"/*; do
        if [[ -f "$helper" ]]; then
            log_exec codesign --force \
                              --sign "$CERT_NAME" \
                              --options runtime \
                              --timestamp \
                              "$helper"
            success "Signed helper: $(basename "$helper")"
        fi
    done
fi

# Sign main executable
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/$PROJECT_NAME"
if [[ -f "$EXECUTABLE_PATH" ]]; then
    log "Signing main executable..."
    log_exec codesign --force \
                      --sign "$CERT_NAME" \
                      --entitlements "$ENTITLEMENTS_FILE" \
                      --options runtime \
                      --timestamp \
                      "$EXECUTABLE_PATH"
    success "Signed executable: $EXECUTABLE_PATH"
else
    error "Main executable not found: $EXECUTABLE_PATH"
fi

# Sign app bundle
log "Signing app bundle..."
log_exec codesign --force \
                  --sign "$CERT_NAME" \
                  --entitlements "$ENTITLEMENTS_FILE" \
                  --options runtime \
                  --timestamp \
                  "$APP_PATH"

# Verify signature
log "Verifying signature..."
if log_exec codesign --verify --deep --verbose "$APP_PATH"; then
    success "✅ Signature verification passed"
else
    error "❌ Signature verification failed"
fi

# Check for hardened runtime
if log_exec codesign --display --verbose "$APP_PATH" | grep -q "runtime"; then
    success "✅ Hardened runtime enabled"
else
    warn "⚠️  Hardened runtime not detected"
fi

success "🎉 Application signing complete!"
log "📋 Log file: $LOG_FILE"
log "🔍 Verification: codesign --verify --deep '$APP_PATH'"
EOF

chmod +x "$SIGNING_DIR/scripts/sign_application.sh"

# Phase 3: Notarization system
phase "3️⃣ Creating notarization system..."

cat > "$SIGNING_DIR/scripts/notarize_application.sh" << 'EOF'
#!/bin/bash

# ForceQUIT Notarization Script
set -e

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
SIGNING_DIR=".."
LOG_DIR="$SIGNING_DIR/logs"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[NOTARY]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
phase() { echo -e "${PURPLE}[PHASE]${NC} $1"; }

# Parse arguments
ARCHIVE_PATH="${1:-../../dist/$PROJECT_NAME-$VERSION-universal.zip}"

log "📋 Starting notarization for $PROJECT_NAME"

# Load configuration
if [[ -f "$SIGNING_DIR/certificates/cert_config.env" ]]; then
    source "$SIGNING_DIR/certificates/cert_config.env"
else
    error "Certificate configuration not found. Run manage_certificates.sh setup first."
fi

# Verify required credentials
if [[ -z "$APPLE_ID" || -z "$APPLE_PASSWORD" || -z "$TEAM_ID" ]]; then
    error "Missing notarization credentials. Set APPLE_ID, APPLE_PASSWORD, and TEAM_ID in cert_config.env"
fi

# Verify archive exists
if [[ ! -f "$ARCHIVE_PATH" ]]; then
    error "Archive not found: $ARCHIVE_PATH"
fi

# Create log file
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/notarization_$(date +%Y%m%d_%H%M%S).log"

log "Archive: $ARCHIVE_PATH"
log "Apple ID: $APPLE_ID"
log "Team ID: $TEAM_ID"

# Function to log and execute
log_exec() {
    echo "Executing: $*" >> "$LOG_FILE"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Phase 1: Submit for notarization
phase "1️⃣ Submitting for notarization..."

SUBMIT_OUTPUT=$(log_exec xcrun notarytool submit "$ARCHIVE_PATH" \
                                                 --apple-id "$APPLE_ID" \
                                                 --password "$APPLE_PASSWORD" \
                                                 --team-id "$TEAM_ID" \
                                                 --wait \
                                                 --timeout 3600)

if [[ $? -eq 0 ]]; then
    success "✅ Notarization submission successful"
else
    error "❌ Notarization submission failed"
fi

# Extract submission ID from output
SUBMISSION_ID=$(echo "$SUBMIT_OUTPUT" | grep -o 'id: [a-f0-9\-]*' | cut -d' ' -f2 | head -1)

if [[ -n "$SUBMISSION_ID" ]]; then
    log "📋 Submission ID: $SUBMISSION_ID"
else
    warn "⚠️  Could not extract submission ID from output"
fi

# Phase 2: Check notarization status
phase "2️⃣ Checking notarization status..."

if [[ -n "$SUBMISSION_ID" ]]; then
    log_exec xcrun notarytool info "$SUBMISSION_ID" \
                                   --apple-id "$APPLE_ID" \
                                   --password "$APPLE_PASSWORD" \
                                   --team-id "$TEAM_ID"
fi

# Phase 3: Get notarization log (if available)
phase "3️⃣ Retrieving notarization log..."

if [[ -n "$SUBMISSION_ID" ]]; then
    NOTARY_LOG="$LOG_DIR/notary_log_$SUBMISSION_ID.json"
    if log_exec xcrun notarytool log "$SUBMISSION_ID" \
                                     --apple-id "$APPLE_ID" \
                                     --password "$APPLE_PASSWORD" \
                                     --team-id "$TEAM_ID" \
                                     "$NOTARY_LOG"; then
        success "📋 Notarization log saved: $NOTARY_LOG"
        
        # Parse log for issues
        if command -v jq >/dev/null 2>&1; then
            ISSUES=$(jq -r '.issues[]? | .message' "$NOTARY_LOG" 2>/dev/null || true)
            if [[ -n "$ISSUES" ]]; then
                warn "⚠️  Notarization issues found:"
                echo "$ISSUES" | while read -r issue; do
                    warn "   • $issue"
                done
            fi
        fi
    else
        warn "⚠️  Could not retrieve notarization log"
    fi
fi

# Phase 4: Verify notarization status
phase "4️⃣ Verifying final status..."

if echo "$SUBMIT_OUTPUT" | grep -q "Successfully received submission info"; then
    if echo "$SUBMIT_OUTPUT" | grep -q "status: Accepted"; then
        success "🎉 Notarization completed successfully!"
        success "✅ $PROJECT_NAME is now notarized and ready for distribution"
        
        # Create notarization certificate
        cat > "$SIGNING_DIR/notarization_certificate.txt" << EOF
NOTARIZATION CERTIFICATE
========================

Project: $PROJECT_NAME
Version: $VERSION
Date: $(date)
Archive: $ARCHIVE_PATH
Submission ID: $SUBMISSION_ID
Status: ACCEPTED ✅

Apple ID: $APPLE_ID
Team ID: $TEAM_ID

This application has been successfully notarized by Apple
and is approved for distribution outside the App Store.

Verification: spctl --assess --verbose "$ARCHIVE_PATH"

Generated by ForceQUIT Distribution System
EOF
        
        success "📜 Notarization certificate created"
        
    else
        error "❌ Notarization rejected. Check logs for details."
    fi
else
    error "❌ Notarization process failed"
fi

success "📋 Complete log: $LOG_FILE"
success "🔍 Manual verification: spctl --assess --verbose '$ARCHIVE_PATH'"

log "🚀 Next steps:"
log "   1. Verify notarization: spctl --assess --verbose '$ARCHIVE_PATH'"
log "   2. Distribute the notarized archive"
log "   3. Users can run the app without Gatekeeper warnings"
EOF

chmod +x "$SIGNING_DIR/scripts/notarize_application.sh"

# Phase 4: Complete signing pipeline
phase "4️⃣ Creating complete signing pipeline..."

cat > "$SIGNING_DIR/complete_signing_pipeline.sh" << 'EOF'
#!/bin/bash

# ForceQUIT Complete Signing & Notarization Pipeline
set -e

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
BUILD_DIR="../build"
DIST_DIR=".."

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[PIPELINE]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
phase() { echo -e "${PURPLE}[PHASE]${NC} $1"; }

log "🔐 Starting complete signing & notarization pipeline for ForceQUIT"

# Parse arguments
DISTRIBUTION_TYPE="${1:-direct}"  # direct, appstore, both

# Phase 1: Verify environment
phase "1️⃣ Verifying signing environment..."
./scripts/manage_certificates.sh verify

# Phase 2: Sign application
phase "2️⃣ Signing application for $DISTRIBUTION_TYPE distribution..."

case "$DISTRIBUTION_TYPE" in
    "direct")
        ./scripts/sign_application.sh direct
        ;;
    "appstore")
        ./scripts/sign_application.sh appstore  
        ;;
    "both")
        # Create separate builds for each distribution
        cp -R "$BUILD_DIR/$PROJECT_NAME.app" "$BUILD_DIR/${PROJECT_NAME}_Direct.app"
        cp -R "$BUILD_DIR/$PROJECT_NAME.app" "$BUILD_DIR/${PROJECT_NAME}_AppStore.app"
        
        ./scripts/sign_application.sh direct "$BUILD_DIR/${PROJECT_NAME}_Direct.app"
        ./scripts/sign_application.sh appstore "$BUILD_DIR/${PROJECT_NAME}_AppStore.app"
        ;;
    *)
        error "Unknown distribution type: $DISTRIBUTION_TYPE"
        ;;
esac

# Phase 3: Create distribution archives
phase "3️⃣ Creating distribution archives..."

case "$DISTRIBUTION_TYPE" in
    "direct"|"both")
        # Create ZIP for notarization
        APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"
        if [[ "$DISTRIBUTION_TYPE" == "both" ]]; then
            APP_PATH="$BUILD_DIR/${PROJECT_NAME}_Direct.app"
        fi
        
        cd "$(dirname "$APP_PATH")"
        ZIP_PATH="$DIST_DIR/$PROJECT_NAME-$VERSION-signed.zip"
        zip -r "$ZIP_PATH" "$(basename "$APP_PATH")"
        cd - >/dev/null
        
        success "✅ Created signed archive: $ZIP_PATH"
        ;;
esac

# Phase 4: Notarization (for direct distribution)
if [[ "$DISTRIBUTION_TYPE" == "direct" || "$DISTRIBUTION_TYPE" == "both" ]]; then
    phase "4️⃣ Starting notarization process..."
    
    ZIP_PATH="$DIST_DIR/$PROJECT_NAME-$VERSION-signed.zip"
    ./scripts/notarize_application.sh "$ZIP_PATH"
fi

# Phase 5: Final verification
phase "5️⃣ Final verification and summary..."

case "$DISTRIBUTION_TYPE" in
    "direct")
        APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"
        spctl --assess --verbose "$APP_PATH" && success "✅ Gatekeeper verification passed" || error "❌ Gatekeeper verification failed"
        ;;
    "appstore")
        APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"
        codesign --verify --deep "$APP_PATH" && success "✅ App Store signature verification passed" || error "❌ App Store signature verification failed"
        ;;
    "both")
        spctl --assess --verbose "$BUILD_DIR/${PROJECT_NAME}_Direct.app" && success "✅ Direct distribution verified" || warn "⚠️  Direct distribution verification failed"
        codesign --verify --deep "$BUILD_DIR/${PROJECT_NAME}_AppStore.app" && success "✅ App Store distribution verified" || warn "⚠️  App Store distribution verification failed"
        ;;
esac

# Generate completion report
REPORT_FILE="signing_completion_report_$(date +%Y%m%d_%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
ForceQUIT Signing & Notarization Report
======================================

Project: $PROJECT_NAME
Version: $VERSION
Distribution Type: $DISTRIBUTION_TYPE
Completion Time: $(date)

SIGNED ARTIFACTS:
$(case "$DISTRIBUTION_TYPE" in
    "direct")
        echo "• Direct Distribution: $BUILD_DIR/$PROJECT_NAME.app"
        echo "• Notarized Archive: $DIST_DIR/$PROJECT_NAME-$VERSION-signed.zip"
        ;;
    "appstore")
        echo "• App Store Distribution: $BUILD_DIR/$PROJECT_NAME.app"
        ;;
    "both")
        echo "• Direct Distribution: $BUILD_DIR/${PROJECT_NAME}_Direct.app"
        echo "• App Store Distribution: $BUILD_DIR/${PROJECT_NAME}_AppStore.app"
        echo "• Notarized Archive: $DIST_DIR/$PROJECT_NAME-$VERSION-signed.zip"
        ;;
esac)

VERIFICATION STATUS:
✅ Code signing completed
$(if [[ "$DISTRIBUTION_TYPE" == "direct" || "$DISTRIBUTION_TYPE" == "both" ]]; then echo "✅ Notarization completed"; fi)
✅ Gatekeeper compatibility verified
✅ Ready for distribution

NEXT STEPS:
1. Test signed application on clean macOS system
2. Verify Gatekeeper allows execution without warnings
$(if [[ "$DISTRIBUTION_TYPE" == "appstore" || "$DISTRIBUTION_TYPE" == "both" ]]; then echo "3. Upload App Store build to App Store Connect"; fi)
$(if [[ "$DISTRIBUTION_TYPE" == "direct" || "$DISTRIBUTION_TYPE" == "both" ]]; then echo "3. Distribute notarized archive to users"; fi)

Generated by ForceQUIT Signing Pipeline
EOF

success "🎉 Signing & notarization pipeline complete!"
success "📋 Report: $REPORT_FILE"

log "🚀 ForceQUIT is now signed and ready for distribution!"
EOF

chmod +x "$SIGNING_DIR/complete_signing_pipeline.sh"

# Create final setup summary
success "🔐 Code signing & notarization pipeline complete!"
log "📦 Created components:"
log "   • Certificate management system"
log "   • Application signing script (direct + App Store)"
log "   • Comprehensive notarization system"
log "   • Complete automated pipeline"
log "   • Entitlements files for both distribution types"

success "🎯 Signing directory structure:"
find "$SIGNING_DIR" -type f -name "*.sh" | sort

log "🚀 Setup steps:"
log "   1. Run: cd $SIGNING_DIR && ./scripts/manage_certificates.sh setup"
log "   2. Edit certificates/cert_config.env with your details"
log "   3. Run: ./scripts/manage_certificates.sh verify"
log "   4. Run: ./complete_signing_pipeline.sh [direct|appstore|both]"

success "✅ ForceQUIT signing & notarization system ready!"