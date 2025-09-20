#!/bin/bash

# SWARM 2.0 ForceQUIT Code Signing & Notarization Script
# Phase 8: Build-Compile-Dist
# Session: FLIPPED-POLES

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

# Configuration
PROJECT_NAME="ForceQUIT"
BUNDLE_ID="com.swarm.forcequit"
VERSION="1.0.0"
DIST_DIR="./dist"
NOTARIZED_DIR="./notarized"

# Code Signing Configuration
DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
DEVELOPER_ID_INSTALLER="${DEVELOPER_ID_INSTALLER:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_ID_PASSWORD="${APPLE_ID_PASSWORD:-}"
TEAM_ID="${TEAM_ID:-}"

echo -e "${CYAN}===============================================${NC}"
echo -e "${WHITE}    SWARM 2.0 Code Signing & Notarization${NC}"
echo -e "${WHITE}    Project: ForceQUIT v${VERSION}${NC}"
echo -e "${CYAN}===============================================${NC}"

# Validate environment
validate_environment() {
    echo -e "${BLUE}🔍 Validating signing environment...${NC}"
    
    if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
        echo -e "${YELLOW}⚠️ DEVELOPER_ID_APPLICATION not set${NC}"
        echo -e "${YELLOW}   Set with: export DEVELOPER_ID_APPLICATION=\"Developer ID Application: Your Name (TEAMID)\"${NC}"
        SIGNING_REQUIRED=false
    else
        echo -e "${GREEN}✅ Developer ID Application: $DEVELOPER_ID_APPLICATION${NC}"
        SIGNING_REQUIRED=true
    fi
    
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
        echo -e "${YELLOW}⚠️ Apple ID credentials not configured${NC}"
        echo -e "${YELLOW}   Set with: export APPLE_ID=\"your@apple.id\"${NC}"
        echo -e "${YELLOW}   Set with: export APPLE_ID_PASSWORD=\"app-specific-password\"${NC}"
        NOTARIZATION_REQUIRED=false
    else
        echo -e "${GREEN}✅ Apple ID configured for notarization${NC}"
        NOTARIZATION_REQUIRED=true
    fi
    
    # Check if app exists
    if [ ! -d "$DIST_DIR/$PROJECT_NAME.app" ]; then
        echo -e "${RED}❌ ERROR: $PROJECT_NAME.app not found in $DIST_DIR${NC}"
        echo -e "${RED}   Run build-universal.sh first${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Environment validation complete${NC}"
}

# Code signing function
sign_application() {
    if [ "$SIGNING_REQUIRED" = false ]; then
        echo -e "${YELLOW}⚠️ Skipping code signing (credentials not configured)${NC}"
        return 0
    fi
    
    echo -e "${PURPLE}🔒 Code signing application...${NC}"
    
    # Create signed directory
    mkdir -p "$NOTARIZED_DIR"
    cp -R "$DIST_DIR/$PROJECT_NAME.app" "$NOTARIZED_DIR/"
    
    # Sign all binaries and frameworks recursively
    find "$NOTARIZED_DIR/$PROJECT_NAME.app" -type f \( -name "*.dylib" -o -name "*.framework" -o -perm +111 \) -exec codesign \
        --force \
        --verify \
        --verbose \
        --timestamp \
        --options runtime \
        --entitlements "ForceQUIT/ForceQUIT.entitlements" \
        --sign "$DEVELOPER_ID_APPLICATION" \
        {} \;
    
    # Sign the main application
    codesign \
        --force \
        --verify \
        --verbose \
        --timestamp \
        --options runtime \
        --entitlements "ForceQUIT/ForceQUIT.entitlements" \
        --sign "$DEVELOPER_ID_APPLICATION" \
        "$NOTARIZED_DIR/$PROJECT_NAME.app"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Code signing successful${NC}"
    else
        echo -e "${RED}❌ Code signing failed${NC}"
        return 1
    fi
    
    # Verify code signature
    echo -e "${BLUE}🔍 Verifying code signature...${NC}"
    codesign --verify --verbose=4 "$NOTARIZED_DIR/$PROJECT_NAME.app"
    spctl --assess --verbose=4 --type execute "$NOTARIZED_DIR/$PROJECT_NAME.app"
    
    echo -e "${GREEN}✅ Code signature verification complete${NC}"
}

# Notarization function
notarize_application() {
    if [ "$NOTARIZATION_REQUIRED" = false ]; then
        echo -e "${YELLOW}⚠️ Skipping notarization (credentials not configured)${NC}"
        return 0
    fi
    
    echo -e "${PURPLE}📋 Preparing for notarization...${NC}"
    
    # Create ZIP for notarization
    NOTARIZATION_ZIP="$NOTARIZED_DIR/${PROJECT_NAME}-${VERSION}.zip"
    cd "$NOTARIZED_DIR"
    zip -r "${PROJECT_NAME}-${VERSION}.zip" "$PROJECT_NAME.app"
    cd ..
    
    echo -e "${PURPLE}☁️ Submitting for notarization...${NC}"
    
    # Submit for notarization
    NOTARIZATION_RESPONSE=$(xcrun notarytool submit "$NOTARIZATION_ZIP" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait \
        --output-format json)
    
    # Parse response
    SUBMISSION_ID=$(echo "$NOTARIZATION_RESPONSE" | jq -r '.id')
    STATUS=$(echo "$NOTARIZATION_RESPONSE" | jq -r '.status')
    
    if [ "$STATUS" = "Accepted" ]; then
        echo -e "${GREEN}✅ Notarization successful${NC}"
        echo -e "${GREEN}   Submission ID: $SUBMISSION_ID${NC}"
        
        # Staple notarization
        echo -e "${BLUE}📎 Stapling notarization...${NC}"
        xcrun stapler staple "$NOTARIZED_DIR/$PROJECT_NAME.app"
        
        # Verify stapling
        xcrun stapler validate "$NOTARIZED_DIR/$PROJECT_NAME.app"
        echo -e "${GREEN}✅ Notarization stapled successfully${NC}"
        
    else
        echo -e "${RED}❌ Notarization failed${NC}"
        echo -e "${RED}   Status: $STATUS${NC}"
        echo -e "${RED}   Submission ID: $SUBMISSION_ID${NC}"
        
        # Get detailed log
        xcrun notarytool log "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD" \
            --team-id "$TEAM_ID"
        
        return 1
    fi
}

# Create installer package
create_installer_package() {
    echo -e "${PURPLE}📦 Creating installer package...${NC}"
    
    INSTALLER_DIR="$NOTARIZED_DIR/installer"
    mkdir -p "$INSTALLER_DIR"
    
    # Create component package
    pkgbuild \
        --root "$NOTARIZED_DIR" \
        --identifier "$BUNDLE_ID" \
        --version "$VERSION" \
        --install-location "/Applications" \
        "$INSTALLER_DIR/${PROJECT_NAME}-${VERSION}.pkg"
    
    if [ "$SIGNING_REQUIRED" = true ] && [ -n "$DEVELOPER_ID_INSTALLER" ]; then
        echo -e "${PURPLE}🔒 Signing installer package...${NC}"
        
        productsign \
            --sign "$DEVELOPER_ID_INSTALLER" \
            "$INSTALLER_DIR/${PROJECT_NAME}-${VERSION}.pkg" \
            "$INSTALLER_DIR/${PROJECT_NAME}-${VERSION}-signed.pkg"
        
        mv "$INSTALLER_DIR/${PROJECT_NAME}-${VERSION}-signed.pkg" \
           "$INSTALLER_DIR/${PROJECT_NAME}-${VERSION}.pkg"
    fi
    
    echo -e "${GREEN}✅ Installer package created${NC}"
}

# App Store package preparation
prepare_app_store_package() {
    echo -e "${PURPLE}🍎 Preparing App Store package...${NC}"
    
    APPSTORE_DIR="$NOTARIZED_DIR/appstore"
    mkdir -p "$APPSTORE_DIR"
    
    # Copy app for App Store submission
    cp -R "$DIST_DIR/$PROJECT_NAME.app" "$APPSTORE_DIR/"
    
    # Update entitlements for App Store
    cat > "$APPSTORE_DIR/ForceQUIT-AppStore.entitlements" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.apple.systemevents</string>
        <string>com.apple.finder</string>
    </array>
</dict>
</plist>
EOF
    
    if [ "$SIGNING_REQUIRED" = true ]; then
        echo -e "${PURPLE}🔒 Code signing for App Store...${NC}"
        
        # Sign with different identity for App Store
        codesign \
            --force \
            --verify \
            --verbose \
            --timestamp \
            --entitlements "$APPSTORE_DIR/ForceQUIT-AppStore.entitlements" \
            --sign "3rd Party Mac Developer Application" \
            "$APPSTORE_DIR/$PROJECT_NAME.app"
        
        # Create App Store package
        productbuild \
            --component "$APPSTORE_DIR/$PROJECT_NAME.app" /Applications \
            --sign "3rd Party Mac Developer Installer" \
            "$APPSTORE_DIR/${PROJECT_NAME}-AppStore-${VERSION}.pkg"
    fi
    
    echo -e "${GREEN}✅ App Store package prepared${NC}"
}

# Main execution
main() {
    validate_environment
    sign_application
    notarize_application
    create_installer_package
    prepare_app_store_package
    
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${WHITE}    Code Signing & Notarization Complete!${NC}"
    echo -e "${GREEN}===============================================${NC}"
    
    echo -e "${YELLOW}📋 Output Summary:${NC}"
    if [ -d "$NOTARIZED_DIR/$PROJECT_NAME.app" ]; then
        echo -e "   ✅ Signed App: $NOTARIZED_DIR/$PROJECT_NAME.app"
    fi
    if [ -f "$NOTARIZED_DIR/installer/${PROJECT_NAME}-${VERSION}.pkg" ]; then
        echo -e "   ✅ Installer: $NOTARIZED_DIR/installer/${PROJECT_NAME}-${VERSION}.pkg"
    fi
    if [ -f "$NOTARIZED_DIR/appstore/${PROJECT_NAME}-AppStore-${VERSION}.pkg" ]; then
        echo -e "   ✅ App Store: $NOTARIZED_DIR/appstore/${PROJECT_NAME}-AppStore-${VERSION}.pkg"
    fi
    
    echo -e "${CYAN}🚀 Ready for distribution!${NC}"
}

main "$@"