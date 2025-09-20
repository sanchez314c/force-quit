#!/bin/bash

# ===============================================================================
# ForceQUIT - Debug Build Script
# SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER
# ===============================================================================
# Fast development builds with debug symbols and comprehensive logging
# Optimized for development workflow and debugging

set -e  # Exit on any error

# Configuration
PROJECT_NAME="ForceQUIT"
BUILD_CONFIG="debug"
BUILD_DIR="build"
SOURCE_DIR="."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[DEBUG BUILD]${NC} $1"
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
log "🛠️ DEBUG BUILD SYSTEM ACTIVATED"
log "==============================================================================="
log "Configuration: Debug | Fast compilation | Full symbols | Extensive logging"
log "==============================================================================="

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean previous debug builds
log "🧹 Cleaning previous debug builds..."
swift package clean
rm -rf .build/debug
rm -rf .build/*debug*

# Build for current architecture (fast)
log "🔨 Building debug configuration..."
start_time=$(date +%s)

# Swift build with debug optimizations
swift build \
    --configuration debug \
    --build-path ".build" \
    --enable-test-discovery \
    --verbose

end_time=$(date +%s)
build_time=$((end_time - start_time))

# Check if build succeeded
if [ $? -eq 0 ]; then
    success "Debug build completed in ${build_time}s"
else
    error "Debug build failed!"
fi

# Copy executable to build directory
if [ -f ".build/debug/$PROJECT_NAME" ]; then
    cp ".build/debug/$PROJECT_NAME" "$BUILD_DIR/${PROJECT_NAME}-debug"
    success "Debug executable: $BUILD_DIR/${PROJECT_NAME}-debug"
    
    # Make executable
    chmod +x "$BUILD_DIR/${PROJECT_NAME}-debug"
    
    # Show build info
    log "📊 Debug Build Information:"
    log "   • Size: $(du -h "$BUILD_DIR/${PROJECT_NAME}-debug" | cut -f1)"
    log "   • Architecture: $(file "$BUILD_DIR/${PROJECT_NAME}-debug" | cut -d: -f2)"
    log "   • Build Time: ${build_time}s"
    log "   • Debug Symbols: ✅ Enabled"
    log "   • Optimization: ❌ Disabled (for debugging)"
    
    # Optional: Create debug app bundle
    log "📦 Creating debug app bundle..."
    APP_DIR="$BUILD_DIR/${PROJECT_NAME}-Debug.app"
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR/Contents/MacOS"
    
    # Copy binary
    cp "$BUILD_DIR/${PROJECT_NAME}-debug" "$APP_DIR/Contents/MacOS/$PROJECT_NAME"
    
    # Create debug Info.plist
    cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.swarm.forcequit.debug</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME Debug</string>
    <key>CFBundleVersion</key>
    <string>1.0.0-debug</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2025 SWARM AI - Debug Build</string>
    <key>CFBundleDisplayName</key>
    <string>ForceQUIT Debug</string>
    <key>NSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF
    
    success "Debug app bundle: $APP_DIR"
    
    log "🚀 DEBUG BUILD COMPLETE!"
    log "==============================================================================="
    log "Debug tools available:"
    log "   • Binary: $BUILD_DIR/${PROJECT_NAME}-debug"
    log "   • App Bundle: $APP_DIR"
    log "   • Run directly: ./$BUILD_DIR/${PROJECT_NAME}-debug"
    log "   • Run with lldb: lldb ./$BUILD_DIR/${PROJECT_NAME}-debug"
    log "==============================================================================="
    
else
    error "Debug executable not found!"
fi