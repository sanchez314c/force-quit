#!/bin/bash

# ForceQUIT Swift macOS Build Script
# Agent-controlled compilation using command-line tools only
# NO GUI DEPENDENCY - Pure CLI workflow

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✔${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] ℹ${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get Swift version
get_swift_version() {
    swift --version 2>/dev/null | head -1 || echo "Not found"
}

# Function to get Xcode version
get_xcode_version() {
    xcodebuild -version 2>/dev/null | head -1 || echo "Not found"
}

# Function to cleanup system temp directories
cleanup_system_temp() {
    print_status "🧹 Cleaning system temp directories..."
    
    # macOS temp cleanup
    if [ "$(uname)" = "Darwin" ]; then
        TEMP_DIR=$(find /private/var/folders -name "Temporary*" -type d 2>/dev/null | head -1)
        if [ -n "$TEMP_DIR" ]; then
            PARENT_DIR=$(dirname "$TEMP_DIR")
            # Clean up build artifacts (older than 1 day)
            find "$PARENT_DIR" -name "t-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "electron-download-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "pyinstaller-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "npm-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
        fi
    fi
    
    # Clean DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        BEFORE_SIZE=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | cut -f1)
        find "$HOME/Library/Developer/Xcode/DerivedData" -name "Build" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
        find "$HOME/Library/Developer/Xcode/DerivedData" -name "Index" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
        AFTER_SIZE=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | cut -f1)
        print_success "DerivedData cleanup: $BEFORE_SIZE → $AFTER_SIZE"
    fi
    
    # Clean Swift build cache
    if [ -d ".build" ]; then
        CACHE_SIZE=$(du -sh .build 2>/dev/null | cut -f1)
        rm -rf .build 2>/dev/null || true
        print_success "Cleaned Swift build cache: $CACHE_SIZE"
    fi
    
    # Project-specific cleanup
    rm -rf DerivedData/ 2>/dev/null || true
    rm -rf simple-build/ 2>/dev/null || true
    rm -rf build/ 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
}

# Function to setup build temp directory
setup_build_temp() {
    BUILD_TEMP_DIR="$(pwd)/build-temp"
    mkdir -p "$BUILD_TEMP_DIR"
    export TMPDIR="$BUILD_TEMP_DIR"
    export TMP="$BUILD_TEMP_DIR"
    export TEMP="$BUILD_TEMP_DIR"
    echo "Using custom temp directory: $BUILD_TEMP_DIR"
}

# Function to cleanup build temp
cleanup_build_temp() {
    if [ -n "$BUILD_TEMP_DIR" ] && [ -d "$BUILD_TEMP_DIR" ]; then
        echo "Cleaning build temp directory..."
        rm -rf "$BUILD_TEMP_DIR" 2>/dev/null || true
    fi
}

# Function to analyze ForceQUIT project
forcequit_project_analysis() {
    print_status "🔍 Analyzing ForceQUIT project structure..."
    
    # Check source files
    if [ -d "Sources" ]; then
        SWIFT_FILES=$(find Sources -name "*.swift" | wc -l)
        TOTAL_LINES=$(find Sources -name "*.swift" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        print_info "Swift source files: $SWIFT_FILES ($TOTAL_LINES lines total)"
    fi
    
    # Check main ForceQUIT directory
    if [ -d "ForceQUIT" ]; then
        MAIN_SWIFT_FILES=$(find ForceQUIT -name "*.swift" | wc -l)
        print_info "Main app Swift files: $MAIN_SWIFT_FILES"
    fi
    
    # Check Package.swift
    if [ -f "Package.swift" ]; then
        print_info "Swift Package Manager: Package.swift found"
        DEPENDENCIES=$(grep -c "\.package" Package.swift || echo "0")
        print_info "Package dependencies: $DEPENDENCIES"
    fi
    
    # Check for Xcode project
    if ls *.xcodeproj >/dev/null 2>&1; then
        PROJECT_FILE=$(ls *.xcodeproj | head -1)
        print_info "Xcode project: $PROJECT_FILE"
    fi
    
    # Check for SwiftUI
    if grep -r "import SwiftUI" Sources/ ForceQUIT/ >/dev/null 2>&1; then
        print_info "Framework: SwiftUI detected"
    fi
    
    # Check for AppKit
    if grep -r "import AppKit" Sources/ ForceQUIT/ >/dev/null 2>&1; then
        print_info "Framework: AppKit detected"
    fi
    
    # Check icons
    if [ -d "assets/icons" ]; then
        ICON_COUNT=$(ls assets/icons/*.{png,icns,ico} 2>/dev/null | wc -l)
        print_info "Application icons: $ICON_COUNT files in assets/icons/"
    fi
}

# Function to display help
show_help() {
    echo "ForceQUIT Swift macOS Build Script"
    echo ""
    echo "Usage: ./scripts/compile-build-dist.sh [options]"
    echo ""
    echo "Options:"
    echo "  --no-clean         Skip cleaning build artifacts"
    echo "  --no-temp-clean    Skip system temp cleanup"
    echo "  --arch ARCH        Build architecture (x86_64, arm64, universal)"
    echo "  --config CONFIG    Build configuration (debug, release)"
    echo "  --scheme SCHEME    Xcode scheme to build"
    echo "  --sign             Code sign the application"
    echo "  --notarize         Notarize the application (requires signing)"
    echo "  --dmg              Create DMG installer"
    echo "  --zip              Create ZIP archive"
    echo "  --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/compile-build-dist.sh                    # Basic release build"
    echo "  ./scripts/compile-build-dist.sh --arch universal   # Universal binary"
    echo "  ./scripts/compile-build-dist.sh --sign --dmg       # Signed build with DMG"
}

# Parse command line arguments
NO_CLEAN=false
NO_TEMP_CLEAN=false
ARCH="native"
CONFIG="release"
SCHEME="ForceQUIT"
CODE_SIGN=false
NOTARIZE=false
CREATE_DMG=false
CREATE_ZIP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-clean)
            NO_CLEAN=true
            shift
            ;;
        --no-temp-clean)
            NO_TEMP_CLEAN=true
            shift
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --config)
            CONFIG="$2"
            shift 2
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --sign)
            CODE_SIGN=true
            shift
            ;;
        --notarize)
            NOTARIZE=true
            CODE_SIGN=true  # Notarization requires signing
            shift
            ;;
        --dmg)
            CREATE_DMG=true
            shift
            ;;
        --zip)
            CREATE_ZIP=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check macOS
if [ "$(uname)" != "Darwin" ]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Check for required tools
print_status "Checking Swift build requirements..."

if ! command_exists swift; then
    print_error "Swift is not installed. Install Xcode Command Line Tools:"
    print_info "  xcode-select --install"
    exit 1
fi

if ! command_exists xcodebuild; then
    print_error "xcodebuild not found. Install Xcode Command Line Tools:"
    print_info "  xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(get_swift_version)
XCODE_VERSION=$(get_xcode_version)
print_info "Swift version: $SWIFT_VERSION"
print_info "Xcode version: $XCODE_VERSION"

print_success "All requirements met"

# Setup temp directory
setup_build_temp

# Cleanup system temp directories
if [ "$NO_TEMP_CLEAN" = false ]; then
    cleanup_system_temp
fi

# Analyze ForceQUIT project structure
forcequit_project_analysis

# Step 1: Clean everything if not skipped
if [ "$NO_CLEAN" = false ]; then
    print_status "🧹 Purging all existing builds..."
    rm -rf dist/*
    print_success "All build artifacts purged"
fi

# Step 2: Create output directories
mkdir -p build
mkdir -p dist

# Step 3: Determine build parameters
print_status "🎯 Configuring ForceQUIT build parameters..."

APP_NAME="ForceQUIT"
print_info "App name: $APP_NAME"

# Determine build method
BUILD_METHOD=""
if [ -f "Package.swift" ]; then
    BUILD_METHOD="spm"
    print_info "Build method: Swift Package Manager"
elif ls *.xcodeproj >/dev/null 2>&1; then
    BUILD_METHOD="xcodebuild"
    PROJECT_FILE=$(ls *.xcodeproj | head -1)
    print_info "Build method: xcodebuild with $PROJECT_FILE"
else
    print_error "No Package.swift or .xcodeproj found. Cannot determine build method."
    exit 1
fi

# Configure architecture
ARCH_FLAGS=""
case $ARCH in
    x86_64)
        ARCH_FLAGS="--arch x86_64"
        print_info "Architecture: Intel x64"
        ;;
    arm64)
        ARCH_FLAGS="--arch arm64"
        print_info "Architecture: Apple Silicon ARM64"
        ;;
    universal)
        ARCH_FLAGS="--arch x86_64 --arch arm64"
        print_info "Architecture: Universal (Intel + Apple Silicon)"
        ;;
    native)
        print_info "Architecture: Native ($(uname -m))"
        ;;
    *)
        print_error "Invalid architecture: $ARCH"
        exit 1
        ;;
esac

print_info "Configuration: $CONFIG"

# Step 4: Build the application
print_status "🏗️ Building ForceQUIT application..."

if [ "$BUILD_METHOD" = "spm" ]; then
    # Swift Package Manager build
    print_status "Building with Swift Package Manager..."
    
    BUILD_CMD="swift build"
    if [ "$CONFIG" = "release" ]; then
        BUILD_CMD="$BUILD_CMD -c release"
    fi
    
    print_info "Command: $BUILD_CMD"
    $BUILD_CMD
    BUILD_RESULT=$?
    
    if [ $BUILD_RESULT -ne 0 ]; then
        print_error "Swift build failed"
        cleanup_build_temp
        exit 1
    fi
    
    # Copy executable to build directory
    EXECUTABLE_PATH=""
    if [ "$CONFIG" = "release" ]; then
        EXECUTABLE_PATH=".build/release/$APP_NAME"
    else
        EXECUTABLE_PATH=".build/debug/$APP_NAME"
    fi
    
    if [ -f "$EXECUTABLE_PATH" ]; then
        cp "$EXECUTABLE_PATH" "build/$APP_NAME"
        chmod +x "build/$APP_NAME"
        print_success "SPM build completed: build/$APP_NAME"
    else
        print_error "Executable not found: $EXECUTABLE_PATH"
        cleanup_build_temp
        exit 1
    fi
    
elif [ "$BUILD_METHOD" = "xcodebuild" ]; then
    # Xcodebuild method
    print_status "Building with xcodebuild..."
    
    # Configure build settings
    XCODE_BUILD_DIR="build/Release"
    if [ "$CONFIG" = "debug" ]; then
        XCODE_BUILD_DIR="build/Debug"
    fi
    
    BUILD_CMD="xcodebuild -project $PROJECT_FILE"
    BUILD_CMD="$BUILD_CMD -scheme $SCHEME"
    BUILD_CMD="$BUILD_CMD -configuration $CONFIG"
    BUILD_CMD="$BUILD_CMD -derivedDataPath build/DerivedData"
    BUILD_CMD="$BUILD_CMD CONFIGURATION_BUILD_DIR=$XCODE_BUILD_DIR"
    
    # Add architecture if specified
    if [ "$ARCH" != "native" ]; then
        if [ "$ARCH" = "universal" ]; then
            BUILD_CMD="$BUILD_CMD ARCHS='x86_64 arm64'"
        else
            BUILD_CMD="$BUILD_CMD ARCHS='$ARCH'"
        fi
    fi
    
    print_info "Command: $BUILD_CMD"
    $BUILD_CMD
    BUILD_RESULT=$?
    
    if [ $BUILD_RESULT -ne 0 ]; then
        print_error "xcodebuild failed"
        cleanup_build_temp
        exit 1
    fi
    
    # Find the built app
    APP_PATH=$(find build -name "$APP_NAME.app" -type d | head -1)
    if [ -z "$APP_PATH" ]; then
        print_error "Could not find built app: $APP_NAME.app"
        cleanup_build_temp
        exit 1
    fi
    
    print_success "Xcodebuild completed: $APP_PATH"
fi

# Step 5: Create app bundle (for SPM builds)
if [ "$BUILD_METHOD" = "spm" ]; then
    print_status "📦 Creating ForceQUIT app bundle..."
    
    APP_BUNDLE_PATH="build/$APP_NAME.app"
    mkdir -p "$APP_BUNDLE_PATH/Contents/MacOS"
    mkdir -p "$APP_BUNDLE_PATH/Contents/Resources"
    
    # Find and copy SPM executable
    SPM_EXECUTABLE=$(find .build -name "$APP_NAME" -type f | grep -E "(debug|release)/$APP_NAME$" | head -1)
    if [ -z "$SPM_EXECUTABLE" ]; then
        print_error "Could not find Swift Package Manager executable: $APP_NAME"
        cleanup_build_temp
        exit 1
    fi
    
    print_info "Found executable: $SPM_EXECUTABLE"
    cp "$SPM_EXECUTABLE" "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
    
    # Create Info.plist
    cat > "$APP_BUNDLE_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.forcequit.app</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIconName</key>
    <string>icon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF
    
    # Copy icons if available
    if [ -f "assets/icons/icon.icns" ]; then
        cp "assets/icons/icon.icns" "$APP_BUNDLE_PATH/Contents/Resources/"
        print_info "Added app icon to bundle"
    fi
    
    # Copy entitlements if available
    if [ -f "assets/icons/ForceQUIT.entitlements" ]; then
        cp "assets/icons/ForceQUIT.entitlements" "$APP_BUNDLE_PATH/Contents/Resources/"
        print_info "Added entitlements to bundle"
    fi
    
    APP_PATH="$APP_BUNDLE_PATH"
    print_success "App bundle created: $APP_PATH"
fi

# Step 6: Code signing (if requested)
if [ "$CODE_SIGN" = true ]; then
    print_status "🔐 Code signing ForceQUIT..."
    
    # Find signing identity
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*") \(.*\)/\1/')
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        print_warning "No Developer ID found, trying Mac App Distribution..."
        SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Mac App Distribution" | head -1 | sed 's/.*") \(.*\)/\1/')
    fi
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        print_error "No valid code signing identity found"
        CODE_SIGN=false
        NOTARIZE=false
    else
        print_info "Signing identity: $SIGNING_IDENTITY"
        
        if [ -d "$APP_PATH" ]; then
            # Sign app bundle
            codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_PATH"
            if [ $? -eq 0 ]; then
                print_success "Code signing completed"
            else
                print_error "Code signing failed"
                NOTARIZE=false
            fi
        fi
    fi
fi

# Step 7: Create distribution packages
print_status "📦 Creating ForceQUIT distribution packages..."

# Copy app to dist folder
if [ -d "$APP_PATH" ]; then
    cp -r "$APP_PATH" "dist/"
    print_success "App copied to dist/"
    
    # Create symlink in project root for macOS convenience
    if [ -L "$APP_NAME.app" ]; then
        rm "$APP_NAME.app"
    fi
    ln -sf "dist/$APP_NAME.app" "$APP_NAME.app"
    print_success "Created symlink: $APP_NAME.app -> dist/$APP_NAME.app"
fi

# Create ZIP archive
if [ "$CREATE_ZIP" = true ] || [ "$BUILD_METHOD" = "spm" ]; then
    print_status "Creating ZIP archive..."
    ZIP_NAME="$APP_NAME-$(uname -m).zip"
    (cd dist && zip -r "$ZIP_NAME" "$APP_NAME.app")
    print_success "ZIP archive created: dist/$ZIP_NAME"
fi

# Create DMG installer
if [ "$CREATE_DMG" = true ]; then
    print_status "Creating DMG installer..."
    DMG_NAME="$APP_NAME-$(uname -m).dmg"
    
    # Create temporary DMG directory
    DMG_DIR="build/dmg"
    mkdir -p "$DMG_DIR"
    cp -r "dist/$APP_NAME.app" "$DMG_DIR/"
    
    # Create symbolic link to Applications
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Create DMG
    hdiutil create -size 100m -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "dist/$DMG_NAME"
    
    if [ $? -eq 0 ]; then
        print_success "DMG installer created: dist/$DMG_NAME"
    else
        print_error "DMG creation failed"
    fi
    
    # Clean up
    rm -rf "$DMG_DIR"
fi

# Cleanup temp directory
cleanup_build_temp

# Step 8: Display build results
print_status "📋 ForceQUIT Build Results Summary:"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"

print_success "🎉 ForceQUIT build completed successfully!"
echo ""

# Display build information
print_info "📊 Build Information:"
echo "   App name: $APP_NAME"
echo "   Build method: $BUILD_METHOD"
echo "   Configuration: $CONFIG"
echo "   Architecture: $ARCH"
if [ "$CODE_SIGN" = true ]; then
    echo "   Code signed: Yes"
fi

echo ""

# Display output files
if [ -d "dist" ]; then
    print_info "📁 Distribution files:"
    ls -lah dist/ | while read -r line; do
        if [[ $line == *".app"* ]] || [[ $line == *".zip"* ]] || [[ $line == *".dmg"* ]]; then
            SIZE=$(echo $line | awk '{print $5}')
            NAME=$(echo $line | awk '{print $9}')
            echo "   ✓ $NAME ($SIZE)"
        fi
    done
else
    print_warning "No dist directory found"
fi

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"
print_success "🎉 ForceQUIT build process finished!"
print_status "📁 All outputs are in: ./dist/"

# Usage instructions
echo ""
print_info "To run ForceQUIT:"
if [ "$BUILD_METHOD" = "spm" ]; then
    print_info "  Command line: ./build/$APP_NAME"
fi
print_info "  App bundle: open dist/$APP_NAME.app"
print_info "  Or double-click: $APP_NAME.app (symlink in project root)"

echo ""
print_success "ForceQUIT is ready for distribution! 🚀"