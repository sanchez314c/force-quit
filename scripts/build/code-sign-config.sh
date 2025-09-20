#!/bin/bash

# ===============================================================================
# ForceQUIT - Code Signing Configuration System
# SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER
# ===============================================================================
# Comprehensive code signing setup, validation, and configuration management
# Supports: Developer ID, App Store, Ad-hoc signing, Entitlements management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ForceQUIT"
BUNDLE_ID="com.swarm.forcequit"
VERSION="1.0.0"

# Logging functions
log() {
    echo -e "${BLUE}[CODE SIGNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
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

# Header
echo -e "${CYAN}===============================================================================${NC}"
echo -e "${WHITE}                ForceQUIT Code Signing Configuration${NC}"
echo -e "${WHITE}                SWARM 2.0 BUILD_SYSTEM_DEVELOPER${NC}"
echo -e "${CYAN}===============================================================================${NC}"

# Check available signing identities
check_signing_identities() {
    log "🔍 Scanning for available signing identities..."
    
    # Developer ID Application
    DEV_ID_APP=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 || echo "")
    if [ -n "$DEV_ID_APP" ]; then
        success "Found Developer ID Application identity"
        echo -e "   ${DEV_ID_APP}"
        DEVELOPER_ID_APPLICATION=$(echo "$DEV_ID_APP" | sed 's/.*"\(.*\)".*/\1/')
    else
        warn "No Developer ID Application identity found"
        DEVELOPER_ID_APPLICATION=""
    fi
    
    # Developer ID Installer
    DEV_ID_INSTALLER=$(security find-identity -v -p codesigning | grep "Developer ID Installer" | head -1 || echo "")
    if [ -n "$DEV_ID_INSTALLER" ]; then
        success "Found Developer ID Installer identity"
        echo -e "   ${DEV_ID_INSTALLER}"
        DEVELOPER_ID_INSTALLER=$(echo "$DEV_ID_INSTALLER" | sed 's/.*"\(.*\)".*/\1/')
    else
        warn "No Developer ID Installer identity found"
        DEVELOPER_ID_INSTALLER=""
    fi
    
    # Mac App Store identities
    MAC_APP_STORE_APP=$(security find-identity -v -p codesigning | grep "3rd Party Mac Developer Application" | head -1 || echo "")
    if [ -n "$MAC_APP_STORE_APP" ]; then
        success "Found Mac App Store Application identity"
        echo -e "   ${MAC_APP_STORE_APP}"
        MAC_APP_STORE_APPLICATION=$(echo "$MAC_APP_STORE_APP" | sed 's/.*"\(.*\)".*/\1/')
    else
        warn "No Mac App Store Application identity found"
        MAC_APP_STORE_APPLICATION=""
    fi
    
    MAC_APP_STORE_INSTALLER=$(security find-identity -v -p codesigning | grep "3rd Party Mac Developer Installer" | head -1 || echo "")
    if [ -n "$MAC_APP_STORE_INSTALLER" ]; then
        success "Found Mac App Store Installer identity"
        echo -e "   ${MAC_APP_STORE_INSTALLER}"
        MAC_APP_STORE_INSTALLER_ID=$(echo "$MAC_APP_STORE_INSTALLER" | sed 's/.*"\(.*\)".*/\1/')
    else
        warn "No Mac App Store Installer identity found" 
        MAC_APP_STORE_INSTALLER_ID=""
    fi
}

# Create entitlements files
create_entitlements() {
    log "📄 Creating entitlements files..."
    
    # Production entitlements (Developer ID)
    cat > "ForceQUIT.entitlements" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Security Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.disable-executable-page-protection</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    
    <!-- System Access -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.apple.systemevents</string>
        <string>com.apple.finder</string>
        <string>com.apple.dock</string>
    </array>
    
    <!-- Process Management -->
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>com.apple.system.notification_center</string>
    </array>
    
    <!-- Network (if needed for analytics) -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- User Data Protection -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
EOF

    # App Store entitlements (Sandboxed)
    cat > "ForceQUIT-AppStore.entitlements" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- System Access (Limited for App Store) -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.apple.systemevents</string>
    </array>
    
    <!-- User Selected Files -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Network Access -->
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
EOF

    # Debug entitlements (Development)
    cat > "ForceQUIT-Debug.entitlements" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Development Settings -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.get-task-allow</key>
    <true/>
    
    <!-- Full System Access for Development -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>*</string>
    </array>
    
    <!-- Process Management -->
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>*</string>
    </array>
    
    <!-- Network Access -->
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    
    <!-- File System Access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
EOF

    success "Entitlements files created:"
    info "   • ForceQUIT.entitlements (Production/Developer ID)"
    info "   • ForceQUIT-AppStore.entitlements (Mac App Store)" 
    info "   • ForceQUIT-Debug.entitlements (Development)"
}

# Generate signing configuration script
create_signing_config() {
    log "⚙️ Creating signing configuration script..."
    
    cat > "set-signing-environment.sh" << EOF
#!/bin/bash
# ForceQUIT Code Signing Environment Configuration
# Generated by BUILD_SYSTEM_DEVELOPER

# Code Signing Identities
export DEVELOPER_ID_APPLICATION="$DEVELOPER_ID_APPLICATION"
export DEVELOPER_ID_INSTALLER="$DEVELOPER_ID_INSTALLER" 
export MAC_APP_STORE_APPLICATION="$MAC_APP_STORE_APPLICATION"
export MAC_APP_STORE_INSTALLER="$MAC_APP_STORE_INSTALLER_ID"

# Project Configuration
export PROJECT_NAME="$PROJECT_NAME"
export BUNDLE_ID="$BUNDLE_ID"
export VERSION="$VERSION"

# Notarization (set these manually)
# export APPLE_ID="your.apple.id@example.com"
# export APPLE_ID_PASSWORD="app-specific-password"
# export TEAM_ID="YOUR_TEAM_ID"

# Entitlements
export ENTITLEMENTS_PRODUCTION="ForceQUIT.entitlements"
export ENTITLEMENTS_APPSTORE="ForceQUIT-AppStore.entitlements"
export ENTITLEMENTS_DEBUG="ForceQUIT-Debug.entitlements"

echo "ForceQUIT Code Signing Environment Loaded"
echo "Developer ID Application: \$DEVELOPER_ID_APPLICATION"
echo "Developer ID Installer: \$DEVELOPER_ID_INSTALLER"
echo "Mac App Store Application: \$MAC_APP_STORE_APPLICATION"
echo "Mac App Store Installer: \$MAC_APP_STORE_INSTALLER"
EOF

    chmod +x "set-signing-environment.sh"
    success "Signing configuration script created: set-signing-environment.sh"
}

# Validate signing setup
validate_signing_setup() {
    log "✅ Validating code signing setup..."
    
    local validation_passed=true
    
    # Check if we have at least one signing identity
    if [ -z "$DEVELOPER_ID_APPLICATION" ] && [ -z "$MAC_APP_STORE_APPLICATION" ]; then
        warn "No application signing identities found"
        warn "You'll need to either:"
        warn "   • Install Developer ID certificates for distribution outside App Store"
        warn "   • Install Mac App Store certificates for App Store distribution"
        validation_passed=false
    fi
    
    # Check entitlements files
    for entitlements in "ForceQUIT.entitlements" "ForceQUIT-AppStore.entitlements" "ForceQUIT-Debug.entitlements"; do
        if [ -f "$entitlements" ]; then
            success "Found: $entitlements"
        else
            error "Missing: $entitlements"
            validation_passed=false
        fi
    done
    
    if [ "$validation_passed" == true ]; then
        success "Code signing setup validation passed!"
    else
        warn "Code signing setup validation failed - some issues need attention"
    fi
}

# Create signing test script
create_signing_test() {
    log "🧪 Creating code signing test script..."
    
    cat > "test-code-signing.sh" << 'EOF'
#!/bin/bash
# ForceQUIT Code Signing Test Script
# Tests code signing functionality with a simple test binary

set -e

echo "🧪 Testing ForceQUIT Code Signing Setup"
echo "======================================"

# Source environment
source ./set-signing-environment.sh

# Create test binary
echo "Creating test binary..."
cat > test_binary.c << 'EOFC'
#include <stdio.h>
int main() {
    printf("ForceQUIT Code Signing Test\n");
    return 0;
}
EOFC

gcc -o test_binary test_binary.c

# Test signing with different identities
if [ -n "$DEVELOPER_ID_APPLICATION" ]; then
    echo "Testing Developer ID signing..."
    codesign --sign "$DEVELOPER_ID_APPLICATION" \
             --entitlements ForceQUIT-Debug.entitlements \
             --force \
             test_binary
    
    echo "Verifying Developer ID signature..."
    codesign --verify --verbose test_binary
    echo "✅ Developer ID signing test passed"
else
    echo "⚠️ Skipping Developer ID test (no identity available)"
fi

if [ -n "$MAC_APP_STORE_APPLICATION" ]; then
    echo "Testing Mac App Store signing..."
    codesign --sign "$MAC_APP_STORE_APPLICATION" \
             --entitlements ForceQUIT-AppStore.entitlements \
             --force \
             test_binary
    
    echo "Verifying Mac App Store signature..."
    codesign --verify --verbose test_binary
    echo "✅ Mac App Store signing test passed"
else
    echo "⚠️ Skipping Mac App Store test (no identity available)"
fi

# Clean up
rm -f test_binary test_binary.c

echo "🎉 Code signing tests completed!"
EOF

    chmod +x "test-code-signing.sh"
    success "Code signing test script created: test-code-signing.sh"
}

# Main execution
main() {
    check_signing_identities
    create_entitlements
    create_signing_config
    validate_signing_setup
    create_signing_test
    
    echo -e "${GREEN}===============================================================================${NC}"
    echo -e "${WHITE}                Code Signing Configuration Complete!${NC}"
    echo -e "${GREEN}===============================================================================${NC}"
    
    echo -e "${CYAN}📋 Next Steps:${NC}"
    info "1. Review and customize entitlements files if needed"
    info "2. Set your Apple ID credentials in set-signing-environment.sh"
    info "3. Run: source ./set-signing-environment.sh"
    info "4. Test signing: ./test-code-signing.sh"
    info "5. Build and sign: ./swift-build-release.sh --universal && ./code-sign-notarize.sh"
    
    echo -e "${GREEN}🚀 Code signing system ready!${NC}"
}

main "$@"