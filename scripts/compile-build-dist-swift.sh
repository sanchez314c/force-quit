#!/bin/bash

# ===============================================================================
# ForceQUIT - Comprehensive Swift Build & Distribution System
# SWARM 2.0 Framework - Phase 8: Build-Compile-Dist
# ===============================================================================
# Agent-driven compilation system for macOS Swift applications
# Supports: Universal binaries, code signing, notarization, multi-format distribution

set -e  # Exit on any error

# Configuration
PROJECT_NAME="ForceQUIT"
SOURCE_DIR="src"
BUILD_DIR="build"
DIST_DIR="dist"
VERSION="1.0.0"
BUNDLE_ID="com.swarm.forcequit"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[DISTRIBUTION]${NC} $1"
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

# Parse command line arguments
ARCH="x86_64"
CONFIG="release"
SIGN=false
NOTARIZE=false
DMG=false
APPSTORE=false
AUTO_UPDATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --config)
            CONFIG="$2"
            shift 2
            ;;
        --sign)
            SIGN=true
            shift
            ;;
        --notarize)
            NOTARIZE=true
            SIGN=true  # Notarization requires signing
            shift
            ;;
        --dmg)
            DMG=true
            shift
            ;;
        --appstore)
            APPSTORE=true
            shift
            ;;
        --auto-update)
            AUTO_UPDATE=true
            shift
            ;;
        --universal)
            ARCH="universal"
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

log "🚀 DISTRIBUTION_SPECIALIST - ForceQUIT Build System"
log "Configuration: $CONFIG | Architecture: $ARCH"
log "Features: Sign=$SIGN | Notarize=$NOTARIZE | DMG=$DMG | AppStore=$APPSTORE"

# Create directories
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Phase 1: Clean build
log "🧹 Cleaning previous builds..."
cd "$SOURCE_DIR"
swift package clean
rm -rf .build

# Phase 2: Swift build
log "🔨 Building Swift application ($CONFIG mode)..."
if [[ "$ARCH" == "universal" ]]; then
    log "Building universal binary..."
    
    # Build for Apple Silicon
    swift build -c "$CONFIG" --arch arm64
    ARM64_BINARY=".build/arm64-apple-macosx/$CONFIG/$PROJECT_NAME"
    
    # Build for Intel
    swift build -c "$CONFIG" --arch x86_64
    X86_BINARY=".build/x86_64-apple-macosx/$CONFIG/$PROJECT_NAME"
    
    # Create universal binary
    UNIVERSAL_BINARY="../$BUILD_DIR/$PROJECT_NAME"
    lipo -create "$ARM64_BINARY" "$X86_BINARY" -output "$UNIVERSAL_BINARY"
    success "Universal binary created: $UNIVERSAL_BINARY"
else
    swift build -c "$CONFIG" --arch "$ARCH"
    BINARY_PATH=".build/$ARCH-apple-macosx/$CONFIG/$PROJECT_NAME"
    cp "$BINARY_PATH" "../$BUILD_DIR/$PROJECT_NAME"
    success "Binary built for $ARCH: $BINARY_PATH"
fi

cd ..

# Phase 3: Create App Bundle
log "📦 Creating macOS App Bundle..."
APP_DIR="$BUILD_DIR/$PROJECT_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$PROJECT_NAME" "$APP_DIR/Contents/MacOS/$PROJECT_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$PROJECT_NAME"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
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
</dict>
</plist>
EOF

success "App bundle created: $APP_DIR"

# Phase 4: Code Signing (if requested)
if [[ "$SIGN" == true ]]; then
    log "🔐 Code signing application..."
    
    # Check for signing identity
    SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"
    
    if security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
        codesign --force --sign "$SIGNING_IDENTITY" --options runtime "$APP_DIR"
        success "Application signed with: $SIGNING_IDENTITY"
    else
        warn "Signing identity not found: $SIGNING_IDENTITY"
        warn "Skipping code signing. Set SIGNING_IDENTITY environment variable."
    fi
fi

# Phase 5: Create distribution packages
log "📦 Creating distribution packages..."

# Direct distribution (ZIP)
log "Creating ZIP package..."
cd "$BUILD_DIR"
zip -r "../$DIST_DIR/$PROJECT_NAME-$VERSION-$ARCH.zip" "$PROJECT_NAME.app"
cd ..
success "ZIP package: $DIST_DIR/$PROJECT_NAME-$VERSION-$ARCH.zip"

# DMG creation (if requested)
if [[ "$DMG" == true ]]; then
    log "🗂️ Creating DMG installer..."
    DMG_PATH="$DIST_DIR/$PROJECT_NAME-$VERSION-$ARCH.dmg"
    
    # Create temporary DMG directory
    DMG_DIR="$BUILD_DIR/dmg_temp"
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"
    
    # Copy app bundle
    cp -R "$APP_DIR" "$DMG_DIR/"
    
    # Create Applications link
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Create DMG
    hdiutil create -volname "$PROJECT_NAME" \
                   -srcfolder "$DMG_DIR" \
                   -ov -format UDZO \
                   "$DMG_PATH"
    
    success "DMG created: $DMG_PATH"
fi

# Phase 6: App Store package (if requested)
if [[ "$APPSTORE" == true ]]; then
    log "🏪 Preparing App Store package..."
    PKG_PATH="$DIST_DIR/$PROJECT_NAME-AppStore-$VERSION.pkg"
    
    # Create installer package
    pkgbuild --root "$BUILD_DIR" \
             --identifier "$BUNDLE_ID" \
             --version "$VERSION" \
             --install-location "/Applications" \
             "$PKG_PATH"
    
    success "App Store package: $PKG_PATH"
fi

# Phase 7: Notarization (if requested)
if [[ "$NOTARIZE" == true ]]; then
    log "📋 Submitting for notarization..."
    
    if [[ -n "$APPLE_ID" && -n "$APPLE_PASSWORD" ]]; then
        # Submit for notarization
        xcrun notarytool submit "$DIST_DIR/$PROJECT_NAME-$VERSION-$ARCH.zip" \
                               --apple-id "$APPLE_ID" \
                               --password "$APPLE_PASSWORD" \
                               --team-id "$TEAM_ID" \
                               --wait
        
        success "Notarization submitted and processed"
    else
        warn "Notarization credentials not set (APPLE_ID, APPLE_PASSWORD, TEAM_ID)"
    fi
fi

# Phase 8: Auto-updater integration (if requested)
if [[ "$AUTO_UPDATE" == true ]]; then
    log "🔄 Setting up auto-updater..."
    
    # Create appcast file
    cat > "$DIST_DIR/appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>ForceQUIT Updates</title>
        <description>Most recent updates to ForceQUIT</description>
        <language>en</language>
        <item>
            <title>ForceQUIT $VERSION</title>
            <description>Nuclear Option Made Beautiful - Latest release</description>
            <pubDate>$(date -R)</pubDate>
            <enclosure url="https://releases.forcequit.app/$PROJECT_NAME-$VERSION-$ARCH.zip"
                       sparkle:version="$VERSION"
                       length="$(stat -f%z "$DIST_DIR/$PROJECT_NAME-$VERSION-$ARCH.zip")"
                       type="application/octet-stream" />
        </item>
    </channel>
</rss>
EOF
    
    success "Auto-updater appcast created"
fi

# Final summary
log "✅ BUILD-COMPILE-DIST COMPLETE!"
echo
success "🎯 Distribution packages created:"
ls -la "$DIST_DIR/"
echo
log "🚀 Ready for multi-channel deployment!"
log "📊 Build summary:"
log "   • Architecture: $ARCH"
log "   • Configuration: $CONFIG" 
log "   • App Bundle: $APP_DIR"
log "   • Distribution: $DIST_DIR"

success "🎉 ForceQUIT distribution system ready for launch!"