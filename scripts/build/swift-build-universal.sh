#!/bin/bash

# ===============================================================================
# ForceQUIT - Universal Binary Build Script (Swift Package Manager)
# SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER  
# ===============================================================================
# Builds universal binaries (Intel + Apple Silicon) using Swift Package Manager
# Supports: Optimization levels, size optimization, symbol stripping, testing

set -e  # Exit on any error

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
BUNDLE_ID="com.swarm.forcequit"
BUILD_DIR="build"
DIST_DIR="dist"
CONFIG="release"

# Parse arguments
OPTIMIZE_SIZE=false
STRIP_SYMBOLS=true
RUN_TESTS=false
PARALLEL_BUILD=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --optimize-size)
            OPTIMIZE_SIZE=true
            shift
            ;;
        --keep-symbols)
            STRIP_SYMBOLS=false
            shift
            ;;
        --test)
            RUN_TESTS=true
            shift
            ;;
        --sequential)
            PARALLEL_BUILD=false
            shift
            ;;
        --debug)
            CONFIG="debug"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--optimize-size] [--keep-symbols] [--test] [--sequential] [--debug]"
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
    echo -e "${BLUE}[UNIVERSAL BUILD]${NC} $1"
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
echo -e "${WHITE}                ForceQUIT Universal Binary Builder${NC}"
echo -e "${WHITE}                Swift Package Manager + Native Toolchain${NC}"
echo -e "${WHITE}                BUILD_SYSTEM_DEVELOPER - SWARM 2.0${NC}"
echo -e "${CYAN}===============================================================================${NC}"
info "Configuration: $CONFIG | Size optimization: $OPTIMIZE_SIZE | Strip symbols: $STRIP_SYMBOLS"
info "Run tests: $RUN_TESTS | Parallel build: $PARALLEL_BUILD"

# Validate environment
log "🔍 Validating build environment..."
if ! command -v swift &> /dev/null; then
    error "Swift toolchain not found. Please install Xcode Command Line Tools."
fi

if ! command -v lipo &> /dev/null; then
    error "lipo not found. Please install Xcode Command Line Tools."
fi

SWIFT_VERSION=$(swift --version | head -1)
success "Found: $SWIFT_VERSION"

# Check Package.swift
if [ ! -f "Package.swift" ]; then
    error "Package.swift not found. Run from the project root directory."
fi

# Create directories
mkdir -p "$BUILD_DIR" "$DIST_DIR"
log "📁 Build directories created: $BUILD_DIR, $DIST_DIR"

# Clean previous builds
log "🧹 Cleaning previous builds..."
swift package clean
rm -rf .build/arm64-apple-macosx
rm -rf .build/x86_64-apple-macosx

# Run tests if requested
if [[ "$RUN_TESTS" == true ]]; then
    log "🧪 Running test suite..."
    start_test_time=$(date +%s)
    
    if swift test; then
        end_test_time=$(date +%s)
        test_time=$((end_test_time - start_test_time))
        success "Tests passed in ${test_time}s"
    else
        error "Tests failed! Cannot proceed with universal build."
    fi
fi

# Build function for a specific architecture
build_for_arch() {
    local arch=$1
    local arch_name=$2
    
    log "🔨 Building for $arch_name ($arch)..."
    local arch_start_time=$(date +%s)
    
    # Build with architecture-specific flags
    local build_flags=("--configuration" "$CONFIG" "--arch" "$arch")
    
    if [[ "$OPTIMIZE_SIZE" == true && "$CONFIG" == "release" ]]; then
        build_flags+=("-Xswiftc" "-Osize")
    fi
    
    if swift build "${build_flags[@]}"; then
        local arch_end_time=$(date +%s)
        local arch_build_time=$((arch_end_time - arch_start_time))
        success "$arch_name build completed in ${arch_build_time}s"
        return 0
    else
        error "$arch_name build failed!"
    fi
}

start_time=$(date +%s)

if [[ "$PARALLEL_BUILD" == true ]]; then
    log "🚀 Starting parallel builds..."
    
    # Start builds in background
    build_for_arch "arm64" "Apple Silicon" &
    ARM64_PID=$!
    
    build_for_arch "x86_64" "Intel" &
    X86_64_PID=$!
    
    # Wait for both builds to complete
    log "⏳ Waiting for parallel builds to complete..."
    wait $ARM64_PID
    ARM64_RESULT=$?
    
    wait $X86_64_PID  
    X86_64_RESULT=$?
    
    if [[ $ARM64_RESULT -ne 0 ]]; then
        error "Apple Silicon build failed!"
    fi
    
    if [[ $X86_64_RESULT -ne 0 ]]; then
        error "Intel build failed!"
    fi
    
    success "Parallel builds completed successfully"
else
    log "📦 Starting sequential builds..."
    build_for_arch "arm64" "Apple Silicon"
    build_for_arch "x86_64" "Intel"
fi

# Locate built binaries
ARM64_BINARY=".build/arm64-apple-macosx/$CONFIG/$PROJECT_NAME"
X86_64_BINARY=".build/x86_64-apple-macosx/$CONFIG/$PROJECT_NAME"

# Verify binaries exist
if [ ! -f "$ARM64_BINARY" ]; then
    error "Apple Silicon binary not found: $ARM64_BINARY"
fi

if [ ! -f "$X86_64_BINARY" ]; then
    error "Intel binary not found: $X86_64_BINARY"
fi

# Create universal binary
log "🔗 Creating universal binary..."
UNIVERSAL_BINARY="$BUILD_DIR/${PROJECT_NAME}-universal"

lipo -create "$ARM64_BINARY" "$X86_64_BINARY" -output "$UNIVERSAL_BINARY"

# Verify universal binary
if lipo -info "$UNIVERSAL_BINARY" | grep -q "arm64 x86_64"; then
    success "Universal binary created successfully"
else
    error "Universal binary creation failed - architecture verification failed"
fi

# Strip symbols if requested
if [[ "$STRIP_SYMBOLS" == true && "$CONFIG" == "release" ]]; then
    log "🔧 Stripping debug symbols..."
    strip "$UNIVERSAL_BINARY"
    success "Debug symbols stripped"
fi

# Make executable
chmod +x "$UNIVERSAL_BINARY"

# Create comprehensive app bundle
log "📦 Creating universal app bundle..."
APP_DIR="$DIST_DIR/${PROJECT_NAME}.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy universal binary
cp "$UNIVERSAL_BINARY" "$APP_DIR/Contents/MacOS/$PROJECT_NAME"

# Create comprehensive Info.plist
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
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

# Copy any resources (if they exist)
if [ -d "Resources" ]; then
    cp -R Resources/* "$APP_DIR/Contents/Resources/" 2>/dev/null || true
fi

end_time=$(date +%s)
total_time=$((end_time - start_time))

# Build summary
log "📊 Universal Build Summary:"
info "   • Total build time: ${total_time}s"
info "   • Configuration: $CONFIG"
info "   • Architectures: Intel x64 + Apple Silicon ARM64"
info "   • Binary size: $(du -h "$UNIVERSAL_BINARY" | cut -f1)"
info "   • App bundle size: $(du -h "$APP_DIR" | tail -1 | cut -f1)"
info "   • Optimization: $([ "$OPTIMIZE_SIZE" == true ] && echo "Size (-Osize)" || echo "Speed (-O)")"
info "   • Debug symbols: $([ "$STRIP_SYMBOLS" == true ] && echo "Stripped" || echo "Preserved")"

# Verify architecture support
log "🔍 Architecture verification:"
lipo -info "$UNIVERSAL_BINARY"
file "$UNIVERSAL_BINARY"

# Create distribution archive
log "📦 Creating distribution archive..."
cd "$DIST_DIR"
ZIP_NAME="${PROJECT_NAME}-${VERSION}-Universal.zip"
zip -r "$ZIP_NAME" "${PROJECT_NAME}.app"
cd ..

success "Distribution archive: $DIST_DIR/$ZIP_NAME"

# Final summary
echo -e "${GREEN}===============================================================================${NC}"
echo -e "${WHITE}                Universal Binary Build Complete!${NC}"
echo -e "${GREEN}===============================================================================${NC}"
success "🎯 Build artifacts:"
info "   • Universal Binary: $UNIVERSAL_BINARY"
info "   • App Bundle: $APP_DIR"
info "   • Distribution ZIP: $DIST_DIR/$ZIP_NAME"
info "   • Total time: ${total_time}s"
echo -e "${CYAN}🚀 Ready for code signing and distribution!${NC}"