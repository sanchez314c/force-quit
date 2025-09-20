#!/bin/bash

# ===============================================================================
# ForceQUIT - Release Build Script  
# SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER
# ===============================================================================
# Optimized production builds with full optimization, universal binary support
# and distribution-ready app bundles

set -e  # Exit on any error

# Configuration
PROJECT_NAME="ForceQUIT"
BUILD_CONFIG="release"
BUILD_DIR="build"
DIST_DIR="dist"
VERSION="1.0.0"
BUNDLE_ID="com.swarm.forcequit"

# Parse arguments
ARCH="$(uname -m)"  # Default to current architecture
UNIVERSAL=false
OPTIMIZE_SIZE=false
STRIP_SYMBOLS=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --universal)
            UNIVERSAL=true
            ARCH="universal"
            shift
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --optimize-size)
            OPTIMIZE_SIZE=true
            shift
            ;;
        --keep-symbols)
            STRIP_SYMBOLS=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--universal] [--arch <arch>] [--optimize-size] [--keep-symbols]"
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
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[RELEASE BUILD]${NC} $1"
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

# Header
log "🚀 RELEASE BUILD SYSTEM ACTIVATED"
log "==============================================================================="
log "Configuration: Release | Full optimization | Architecture: $ARCH"
log "Size optimization: $OPTIMIZE_SIZE | Strip symbols: $STRIP_SYMBOLS"
log "==============================================================================="

# Create directories
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Clean previous release builds
log "🧹 Cleaning previous release builds..."
swift package clean
rm -rf .build/release
rm -rf .build/*release*

start_time=$(date +%s)

if [[ "$UNIVERSAL" == true ]]; then
    log "🔨 Building universal binary (Intel + Apple Silicon)..."
    
    # Build for Apple Silicon (arm64)
    log "   • Building for Apple Silicon (arm64)..."
    swift build --configuration release --arch arm64
    ARM64_BINARY=".build/arm64-apple-macosx/release/$PROJECT_NAME"
    
    if [ ! -f "$ARM64_BINARY" ]; then
        error "ARM64 build failed - binary not found: $ARM64_BINARY"
    fi
    
    # Build for Intel (x86_64)  
    log "   • Building for Intel (x86_64)..."
    swift build --configuration release --arch x86_64
    X86_BINARY=".build/x86_64-apple-macosx/release/$PROJECT_NAME"
    
    if [ ! -f "$X86_BINARY" ]; then
        error "x86_64 build failed - binary not found: $X86_BINARY"
    fi
    
    # Create universal binary
    FINAL_BINARY="$BUILD_DIR/${PROJECT_NAME}-release"
    log "   • Creating universal binary..."
    lipo -create "$ARM64_BINARY" "$X86_BINARY" -output "$FINAL_BINARY"
    
    # Verify universal binary
    if lipo -info "$FINAL_BINARY" | grep -q "x86_64 arm64"; then
        success "Universal binary created successfully"
    else
        error "Universal binary creation failed"
    fi
    
else
    log "🔨 Building for architecture: $ARCH..."
    
    # Additional optimization flags
    EXTRA_FLAGS=""
    if [[ "$OPTIMIZE_SIZE" == true ]]; then
        EXTRA_FLAGS="-Xswiftc -Osize"
    fi
    
    swift build \
        --configuration release \
        --arch "$ARCH" \
        $EXTRA_FLAGS
    
    BINARY_PATH=".build/$ARCH-apple-macosx/release/$PROJECT_NAME"
    
    if [ ! -f "$BINARY_PATH" ]; then
        error "Build failed - binary not found: $BINARY_PATH"
    fi
    
    FINAL_BINARY="$BUILD_DIR/${PROJECT_NAME}-release"
    cp "$BINARY_PATH" "$FINAL_BINARY"
fi

end_time=$(date +%s)
build_time=$((end_time - start_time))

# Make executable
chmod +x "$FINAL_BINARY"

# Strip symbols if requested
if [[ "$STRIP_SYMBOLS" == true ]]; then
    log "🔧 Stripping debug symbols for size optimization..."
    strip "$FINAL_BINARY"
fi

# Show build information
success "Release build completed in ${build_time}s"
log "📊 Release Build Information:"
log "   • Size: $(du -h "$FINAL_BINARY" | cut -f1)"
log "   • Architecture: $(file "$FINAL_BINARY" | cut -d: -f2 | cut -d, -f1-2)"
log "   • Build Time: ${build_time}s"
log "   • Optimization: ✅ Maximum (-O)"
log "   • Debug Symbols: $([ "$STRIP_SYMBOLS" == true ] && echo "❌ Stripped" || echo "✅ Preserved")"

# Create production app bundle
log "📦 Creating production app bundle..."
APP_DIR="$BUILD_DIR/${PROJECT_NAME}.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$FINAL_BINARY" "$APP_DIR/Contents/MacOS/$PROJECT_NAME"

# Create production Info.plist
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
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>CFBundleDocumentTypes</key>
    <array/>
    <key>UTExportedTypeDeclarations</key>
    <array/>
</dict>
</plist>
EOF

# Create basic PkgInfo file
echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

success "Production app bundle: $APP_DIR"

# Create distribution archive
log "📦 Creating distribution archive..."
cd "$BUILD_DIR"
ZIP_NAME="${PROJECT_NAME}-${VERSION}-${ARCH}-release.zip"
zip -r "../$DIST_DIR/$ZIP_NAME" "${PROJECT_NAME}.app"
cd ..

success "Distribution archive: $DIST_DIR/$ZIP_NAME"

# Final summary
log "🎯 RELEASE BUILD COMPLETE!"
log "==============================================================================="
log "Production artifacts:"
log "   • Binary: $FINAL_BINARY"
log "   • App Bundle: $APP_DIR"
log "   • Distribution: $DIST_DIR/$ZIP_NAME"
log "   • Architecture: $ARCH"
log "   • Size: $(du -h "$APP_DIR" | tail -1 | cut -f1) (app bundle)"
log "==============================================================================="
log "🚀 Ready for distribution and deployment!"