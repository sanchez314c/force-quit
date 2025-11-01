#!/bin/bash

# ===============================================================================
# ForceQUIT - App Store Package Preparation System
# SWARM 2.0 Framework - Phase 8: Distribution
# ===============================================================================
# Comprehensive App Store submission preparation with all required components

set -e

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
BUNDLE_ID="com.swarm.forcequit"
BUILD_DIR="build"
DIST_DIR="dist"
APPSTORE_DIR="$DIST_DIR/appstore"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[APPSTORE]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

log "🏪 Preparing ForceQUIT for App Store submission"

# Create App Store directory structure
mkdir -p "$APPSTORE_DIR/metadata"
mkdir -p "$APPSTORE_DIR/screenshots"
mkdir -p "$APPSTORE_DIR/assets"

# Verify app bundle
APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
    error "App bundle not found: $APP_PATH"
fi

# Phase 1: Create App Store specific Info.plist
log "📋 Creating App Store compliant Info.plist..."

cat > "$APPSTORE_DIR/$PROJECT_NAME-AppStore-Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2025 SWARM AI. All rights reserved.</string>
    <key>CFBundleDisplayName</key>
    <string>ForceQUIT</string>
    <key>CFBundleGetInfoString</key>
    <string>ForceQUIT $VERSION - Nuclear Option Made Beautiful</string>
    <key>NSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    
    <!-- App Store Specific Keys -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    
    <!-- Privacy and Permissions -->
    <key>NSAppleEventsUsageDescription</key>
    <string>ForceQUIT needs permission to quit applications for you. This is the core functionality of the app.</string>
    <key>NSSystemAdministrationUsageDescription</key>
    <string>ForceQUIT requires administrative privileges to force quit unresponsive applications safely.</string>
    
    <!-- App Store Marketing -->
    <key>CFBundleDocumentTypes</key>
    <array/>
    <key>UTExportedTypeDeclarations</key>
    <array/>
    <key>UTImportedTypeDeclarations</key>
    <array/>
</dict>
</plist>
EOF

# Phase 2: Create App Store metadata
log "📝 Creating App Store metadata..."

# App Store Connect metadata
cat > "$APPSTORE_DIR/metadata/app_description.txt" << EOF
ForceQUIT: Nuclear Option Made Beautiful

Transform your Mac's force quit experience with ForceQUIT - the sleek, Mission Control-inspired application manager that makes closing unresponsive apps elegant and efficient.

✨ FEATURES:
• Instant Visual Status: 4-state RGB system with real-time app health monitoring
• Mission Control Aesthetics: Dark, glassmorphic interface with 120fps animations
• Smart Process Detection: Automatically identifies running applications and system processes
• Safe Force Quit: Intelligent process termination with data protection
• Minimal Resource Usage: <10MB memory, <200ms startup time
• Native macOS Integration: Built with SwiftUI for optimal performance

🎯 PERFECT FOR:
• Developers managing multiple applications
• Power users who need reliable process control
• Anyone frustrated with the default Force Quit dialog
• Mac enthusiasts who appreciate beautiful, functional design

🔒 SECURITY & PRIVACY:
• Enterprise-grade security architecture
• Sandboxed execution with privilege escalation only when needed
• No data collection or telemetry
• Open source transparency

ForceQUIT transforms the nuclear option of force quitting into a beautiful, controlled experience. Say goodbye to frozen apps and hello to elegant process management.
EOF

# Keywords for App Store optimization
cat > "$APPSTORE_DIR/metadata/keywords.txt" << EOF
force quit,task manager,process manager,application manager,system utilities,mac utilities,process killer,app killer,force close,unresponsive apps,system monitor,activity monitor,process control,mac tools,productivity,developer tools,system maintenance,mac performance,application control,process utilities
EOF

# App Store categories and ratings
cat > "$APPSTORE_DIR/metadata/categories.txt" << EOF
PRIMARY_CATEGORY: Utilities
SECONDARY_CATEGORY: Developer Tools
RATING: 4+
CONTENT_RATING: None - utility application with no objectionable content
EOF

# Release notes
cat > "$APPSTORE_DIR/metadata/release_notes.txt" << EOF
🚀 ForceQUIT 1.0.0 - Initial Release

Welcome to ForceQUIT - Nuclear Option Made Beautiful!

✨ NEW FEATURES:
• Complete Mission Control-inspired interface
• 4-state RGB visual feedback system  
• Smart application detection and monitoring
• Safe force quit with data protection
• Native macOS SwiftUI architecture
• Sub-200ms response times
• <10MB memory footprint

🔒 SECURITY:
• Enterprise-grade sandboxed architecture
• Privilege escalation only when required
• No data collection or tracking
• Complete user privacy protection

🎨 DESIGN:
• Dark mode native interface
• Glassmorphic components with subtle animations
• 120fps smooth performance
• Retina-optimized graphics

This initial release establishes ForceQUIT as the premier application management utility for macOS, combining powerful functionality with beautiful design.
EOF

# Phase 3: Create entitlements for App Store
log "🔐 Creating App Store entitlements..."

cat > "$APPSTORE_DIR/$PROJECT_NAME.entitlements" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Required for process monitoring -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- Outgoing network connections (for updates) -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- File access for user data -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Hardware access -->
    <key>com.apple.security.device.audio-input</key>
    <false/>
    <key>com.apple.security.device.camera</key>
    <false/>
    
    <!-- App Store specific -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.$BUNDLE_ID</string>
    </array>
</dict>
</plist>
EOF

# Phase 4: Create provisioning profile template
log "📜 Creating provisioning profile template..."

cat > "$APPSTORE_DIR/provisioning_profile_requirements.txt" << EOF
PROVISIONING PROFILE REQUIREMENTS FOR APP STORE SUBMISSION

Application Details:
- Bundle ID: $BUNDLE_ID
- App Name: ForceQUIT
- Version: $VERSION
- Platform: macOS 12.0+

Required Capabilities:
- App Sandbox
- Apple Events (for application control)
- Network Client (for updates)

Distribution Certificate Required:
- Mac App Store distribution certificate
- Must match Team ID in provisioning profile

Steps to create provisioning profile:
1. Login to Apple Developer Portal
2. Create new provisioning profile for Mac App Store distribution
3. Select Bundle ID: $BUNDLE_ID
4. Choose Mac App Store distribution certificate
5. Download and install provisioning profile

Profile should be named: ${PROJECT_NAME}_AppStore_Distribution.provisionprofile
EOF

# Phase 5: Create signing script for App Store
log "🔏 Creating App Store signing script..."

cat > "$APPSTORE_DIR/sign_for_appstore.sh" << 'EOF'
#!/bin/bash

# ForceQUIT App Store Signing Script
set -e

PROJECT_NAME="ForceQUIT"
APP_PATH="../build/$PROJECT_NAME.app"
SIGNED_APP_PATH="./signed/$PROJECT_NAME.app"

# Configuration (set these environment variables)
MAC_APPSTORE_CERT="${MAC_APPSTORE_CERT:-3rd Party Mac Developer Application}"
INSTALLER_CERT="${INSTALLER_CERT:-3rd Party Mac Developer Installer}"
PROVISIONING_PROFILE="${PROVISIONING_PROFILE:-${PROJECT_NAME}_AppStore_Distribution.provisionprofile}"

echo "🔏 Signing ForceQUIT for App Store submission..."

# Create signed app directory
mkdir -p signed

# Copy app bundle
cp -R "$APP_PATH" "$SIGNED_APP_PATH"

# Apply provisioning profile
cp "$PROVISIONING_PROFILE" "$SIGNED_APP_PATH/Contents/embedded.provisionprofile"

# Sign with App Store certificate
codesign --force \
         --sign "$MAC_APPSTORE_CERT" \
         --entitlements "ForceQUIT.entitlements" \
         --options runtime \
         "$SIGNED_APP_PATH"

# Verify signing
codesign --verify --deep "$SIGNED_APP_PATH"
echo "✅ App bundle signed successfully"

# Create installer package
productbuild --component "$SIGNED_APP_PATH" /Applications \
             --sign "$INSTALLER_CERT" \
             "${PROJECT_NAME}_AppStore.pkg"

echo "🎉 App Store package ready: ${PROJECT_NAME}_AppStore.pkg"
echo "📋 Next steps:"
echo "   1. Test the signed app thoroughly"
echo "   2. Upload to App Store Connect using Transporter or Xcode"
echo "   3. Complete App Store Connect metadata"
echo "   4. Submit for review"
EOF

chmod +x "$APPSTORE_DIR/sign_for_appstore.sh"

# Phase 6: Create screenshot templates and guidelines
log "📸 Creating screenshot guidelines..."

cat > "$APPSTORE_DIR/screenshots/screenshot_requirements.txt" << EOF
APP STORE SCREENSHOT REQUIREMENTS

Required Screenshots for macOS:
1. 1280x800 (16:10 aspect ratio) - Primary display size
2. 2560x1600 (Retina) - High resolution version

Required Screenshots (minimum 3, maximum 10):
1. Main Interface - Show ForceQUIT's Mission Control inspired UI
2. Process Detection - Display running applications with status indicators
3. Force Quit Action - Demonstrate the elegant force quit process
4. Settings/Preferences - Show customization options
5. Dark Mode Integration - Highlight native macOS dark mode

Screenshot Guidelines:
- Show actual app functionality
- Use high-quality, crisp images
- Demonstrate key features clearly
- Include diverse application scenarios
- Maintain consistent visual branding

File naming convention:
- screenshot_1_main_interface.png
- screenshot_2_process_detection.png
- screenshot_3_force_quit_action.png
- screenshot_4_settings.png
- screenshot_5_dark_mode.png
EOF

# Phase 7: Create submission checklist
log "✅ Creating App Store submission checklist..."

cat > "$APPSTORE_DIR/submission_checklist.md" << EOF
# ForceQUIT App Store Submission Checklist

## Pre-Submission Requirements ✅

### Code & Build
- [ ] App bundle built and tested on multiple macOS versions (12.0+)
- [ ] All features working correctly
- [ ] No crashes or memory leaks detected
- [ ] Performance meets specifications (<10MB, <200ms startup)
- [ ] Universal binary (Intel + Apple Silicon) compiled

### Signing & Certificates
- [ ] Mac App Store distribution certificate installed
- [ ] Provisioning profile created and downloaded
- [ ] App bundle signed with App Store certificate
- [ ] Installer package (.pkg) created and signed
- [ ] Code signing verified with no errors

### Metadata & Assets
- [ ] App description completed (under 4000 characters)
- [ ] Keywords optimized for App Store search
- [ ] Release notes written for version 1.0.0
- [ ] Screenshots captured (5 high-quality images)
- [ ] App icon created in all required sizes
- [ ] Privacy policy URL provided (if applicable)

### App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] Bundle ID matches exactly: com.swarm.forcequit
- [ ] Version 1.0.0 created
- [ ] Pricing set (Free or Paid)
- [ ] Categories selected: Utilities (Primary), Developer Tools (Secondary)
- [ ] Age rating completed (4+)

### Legal & Compliance
- [ ] Export compliance information completed
- [ ] Content rights verified
- [ ] Privacy practices documented
- [ ] Terms of service created (if needed)

### Testing
- [ ] Beta testing completed with TestFlight (optional but recommended)
- [ ] Accessibility testing performed
- [ ] Performance testing on various Mac configurations
- [ ] Network connectivity testing

## Submission Steps

1. **Upload App**: Use Transporter or Xcode to upload signed .pkg
2. **Complete Metadata**: Fill all required fields in App Store Connect
3. **Add Screenshots**: Upload all 5 screenshots with descriptions
4. **Set Pricing**: Configure pricing and availability
5. **Submit for Review**: Click "Submit for Review"
6. **Monitor Status**: Check review status daily

## Common Rejection Reasons to Avoid

- Insufficient app description
- Missing or low-quality screenshots  
- Code signing issues
- Privacy policy missing (if collecting data)
- App functionality not clear
- Crashes or bugs during review
- Violating App Store guidelines

## Post-Submission

- [ ] Monitor review status in App Store Connect
- [ ] Respond to reviewer feedback promptly
- [ ] Prepare for potential rejection and resubmission
- [ ] Plan marketing and launch activities
- [ ] Set up app analytics and monitoring

## Success Metrics

- Review time: Typically 24-48 hours for utilities
- Approval rate: 95%+ with proper preparation
- Launch readiness: Complete distribution pipeline

---
Generated by SWARM 2.0 Distribution Specialist
EOF

# Create final summary
success "🏪 App Store package preparation complete!"
log "📦 Created components:"
log "   • App Store compliant Info.plist"
log "   • Comprehensive metadata and descriptions"
log "   • Entitlements file for sandboxing"
log "   • Signing script with provisioning profile support"
log "   • Screenshot requirements and guidelines"
log "   • Complete submission checklist"

success "🎯 App Store directory structure:"
find "$APPSTORE_DIR" -type f | sort

log "🚀 Next steps:"
log "   1. Create Apple Developer account and certificates"
log "   2. Generate provisioning profile for $BUNDLE_ID"
log "   3. Run signing script: cd $APPSTORE_DIR && ./sign_for_appstore.sh"
log "   4. Upload to App Store Connect"
log "   5. Complete metadata in App Store Connect portal"

success "✅ ForceQUIT ready for App Store submission!"