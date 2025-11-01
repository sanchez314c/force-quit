# Complete Swift macOS CLI Build System with Agent-Driven Compilation

## AMENDMENTS - SWIFT MACOS CLI CONFIGURATION:

**Important**: This configuration is designed for AI agents to use CLI tools for Swift compilation, NOT GUI tools like Xcode.

**Key Features**:
- Agent-controlled compilation using `swift build`, `xcodebuild`, and CLI tools
- Multi-architecture support (Intel x64 + Apple Silicon ARM64)
- SwiftUI and AppKit compatibility
- Automated code signing and notarization via CLI
- Command-line distribution package creation
- App bundle generation without Xcode GUI
- Comprehensive temp file cleanup and optimization
- Agent-executable build commands only

This build system provides comprehensive CLI-based Swift compilation that AI agents can execute autonomously.

## Build System Requirements

1. **macOS 12.0+** (for latest Swift features)
2. **Xcode Command Line Tools** installed (`xcode-select --install`)
3. **Swift 5.8+** available via command line
4. **Optional**: Developer account for code signing
5. **NEW**: Agent-friendly CLI-only workflow

## Required Project Structure (CLI-FRIENDLY)

```
swift-macos-app/
├── Sources/                # Swift source code
│   └── main.swift         # Main application entry point
│   └── App/               # App modules
│       ├── AppDelegate.swift
│       ├── ContentView.swift
│       └── Models/
├── Resources/             # App resources
│   ├── Assets.xcassets    # Images, icons
│   ├── Info.plist         # App configuration
│   └── Localizable.strings
├── Package.swift          # Swift Package Manager configuration
├── build/                 # Build outputs (created by build)
├── dist/                  # Distribution packages
├── scripts/               # Build scripts
├── .build/                # SPM build cache
└── MyApp.xcodeproj/       # Optional: Generated project file
```

## Script 1: compile-build-dist-swift.sh (MAIN CLI BUILD SCRIPT)

```bash
#!/bin/bash

# Complete Swift macOS CLI Build Script
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

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

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

# NEW: Function to cleanup Swift build temp directories
cleanup_swift_temp() {
    print_status "🧹 Cleaning Swift build temp directories..."
    
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
    
    # Clean ModuleCache
    if [ -d "$HOME/Library/Developer/Xcode/UserData/ModuleCache" ]; then
        CACHE_SIZE=$(du -sh "$HOME/Library/Developer/Xcode/UserData/ModuleCache" 2>/dev/null | cut -f1)
        rm -rf "$HOME/Library/Developer/Xcode/UserData/ModuleCache" 2>/dev/null || true
        print_success "Cleaned ModuleCache: $CACHE_SIZE"
    fi
}

# NEW: Function to perform Swift project analysis
swift_project_analysis() {
    print_status "🔍 Analyzing Swift project structure..."
    
    # Check source files
    if [ -d "Sources" ]; then
        SWIFT_FILES=$(find Sources -name "*.swift" | wc -l)
        TOTAL_LINES=$(find Sources -name "*.swift" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        print_info "Swift source files: $SWIFT_FILES ($TOTAL_LINES lines total)"
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
    if grep -r "import SwiftUI" Sources/ >/dev/null 2>&1; then
        print_info "Framework: SwiftUI detected"
    fi
    
    # Check for AppKit
    if grep -r "import AppKit" Sources/ >/dev/null 2>&1; then
        print_info "Framework: AppKit detected"
    fi
}

# Function to display help
show_help() {
    echo "Complete Swift macOS CLI Build Script"
    echo ""
    echo "Usage: ./compile-build-dist-swift.sh [options]"
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
    echo "  ./compile-build-dist-swift.sh                    # Basic build for current arch"
    echo "  ./compile-build-dist-swift.sh --arch universal   # Universal binary"
    echo "  ./compile-build-dist-swift.sh --sign --notarize  # Signed and notarized"
    echo "  ./compile-build-dist-swift.sh --config release --dmg  # Release build with DMG"
}

# Parse command line arguments
NO_CLEAN=false
NO_TEMP_CLEAN=false
ARCH="native"
CONFIG="release"
SCHEME=""
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

# Check for optional tools
if [ "$CODE_SIGN" = true ] && ! command_exists codesign; then
    print_warning "codesign not available - signing will be skipped"
    CODE_SIGN=false
fi

if [ "$NOTARIZE" = true ] && ! command_exists xcrun; then
    print_warning "xcrun not available - notarization will be skipped"
    NOTARIZE=false
fi

if [ "$CREATE_DMG" = true ] && ! command_exists hdiutil; then
    print_warning "hdiutil not available - DMG creation will be skipped"
    CREATE_DMG=false
fi

print_success "All requirements met"

# NEW: Cleanup system temp directories first
if [ "$NO_TEMP_CLEAN" = false ]; then
    cleanup_swift_temp
fi

# NEW: Analyze project structure
swift_project_analysis

# Step 1: Clean everything if not skipped
if [ "$NO_CLEAN" = false ]; then
    print_status "🧹 Purging all existing builds..."
    rm -rf .build/
    rm -rf build/
    rm -rf dist/
    rm -rf DerivedData/
    print_success "All build artifacts purged"
fi

# Step 2: Create output directories
mkdir -p build
mkdir -p dist

# Step 3: Determine build method and parameters
print_status "🎯 Configuring build parameters..."

APP_NAME=""
BUILD_METHOD=""

# Determine app name
if [ -f "Package.swift" ]; then
    # Try to extract name from Package.swift
    APP_NAME=$(grep -E "^\s*name:" Package.swift | sed 's/.*name:\s*"\([^"]*\)".*/\1/' | head -1)
elif ls *.xcodeproj >/dev/null 2>&1; then
    # Extract from Xcode project
    PROJECT_FILE=$(ls *.xcodeproj | head -1)
    APP_NAME=$(basename "$PROJECT_FILE" .xcodeproj)
fi

if [ -z "$APP_NAME" ]; then
    APP_NAME="MyApp"
    print_warning "Could not determine app name, using: $APP_NAME"
else
    print_info "App name: $APP_NAME"
fi

# Determine build method
if [ -f "Package.swift" ]; then
    BUILD_METHOD="spm"
    print_info "Build method: Swift Package Manager"
elif ls *.xcodeproj >/dev/null 2>&1; then
    BUILD_METHOD="xcodebuild"
    PROJECT_FILE=$(ls *.xcodeproj | head -1)
    print_info "Build method: xcodebuild with $PROJECT_FILE"
    
    # Auto-detect scheme if not provided
    if [ -z "$SCHEME" ]; then
        SCHEME="$APP_NAME"
        print_info "Using scheme: $SCHEME"
    fi
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
print_status "🏗️ Building Swift application..."

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
        exit 1
    fi
    
    # Find the built app
    APP_PATH=$(find build -name "$APP_NAME.app" -type d | head -1)
    if [ -z "$APP_PATH" ]; then
        print_error "Could not find built app: $APP_NAME.app"
        exit 1
    fi
    
    print_success "Xcodebuild completed: $APP_PATH"
fi

# Step 5: Code signing (if requested)
if [ "$CODE_SIGN" = true ]; then
    print_status "🔐 Code signing application..."
    
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
        
        if [ "$BUILD_METHOD" = "xcodebuild" ] && [ -d "$APP_PATH" ]; then
            # Sign app bundle
            codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_PATH"
            if [ $? -eq 0 ]; then
                print_success "Code signing completed"
            else
                print_error "Code signing failed"
                NOTARIZE=false
            fi
        elif [ "$BUILD_METHOD" = "spm" ] && [ -f "build/$APP_NAME" ]; then
            # Sign executable
            codesign --force --sign "$SIGNING_IDENTITY" "build/$APP_NAME"
            if [ $? -eq 0 ]; then
                print_success "Code signing completed"
            else
                print_error "Code signing failed"
                NOTARIZE=false
            fi
        fi
    fi
fi

# Step 6: Create app bundle (for SPM builds)
if [ "$BUILD_METHOD" = "spm" ]; then
    print_status "📦 Creating app bundle for SPM build..."
    
    APP_BUNDLE_PATH="build/$APP_NAME.app"
    mkdir -p "$APP_BUNDLE_PATH/Contents/MacOS"
    mkdir -p "$APP_BUNDLE_PATH/Contents/Resources"
    
    # Copy executable
    cp "build/$APP_NAME" "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
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
    <string>com.example.$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF
    
    # Copy icon if available
    if [ -f "Resources/Assets.xcassets/AppIcon.appiconset" ]; then
        cp -r "Resources/Assets.xcassets" "$APP_BUNDLE_PATH/Contents/Resources/"
        print_info "Added app icon to bundle"
    fi
    
    APP_PATH="$APP_BUNDLE_PATH"
    print_success "App bundle created: $APP_PATH"
fi

# Step 7: Notarization (if requested)
if [ "$NOTARIZE" = true ] && [ "$CODE_SIGN" = true ]; then
    print_status "📋 Notarizing application..."
    print_warning "Note: Notarization requires Apple Developer account and may take several minutes"
    
    # Create temporary ZIP for notarization
    NOTARY_ZIP="build/$APP_NAME-notary.zip"
    (cd build && zip -r "../$NOTARY_ZIP" "$APP_NAME.app")
    
    # Submit for notarization
    print_status "Submitting to Apple notary service..."
    xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "AC_PASSWORD" --wait
    NOTARY_RESULT=$?
    
    if [ $NOTARY_RESULT -eq 0 ]; then
        # Staple the notarization
        xcrun stapler staple "$APP_PATH"
        print_success "Notarization completed and stapled"
    else
        print_warning "Notarization failed or is pending. Check Apple Developer portal."
    fi
    
    # Clean up notary ZIP
    rm -f "$NOTARY_ZIP"
fi

# Step 8: Create distribution packages
print_status "📦 Creating distribution packages..."

# Copy app to dist folder
if [ -d "$APP_PATH" ]; then
    cp -r "$APP_PATH" "dist/"
    print_success "App copied to dist/"
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

# Step 9: Display build results
print_status "📋 Build Results Summary:"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"

print_success "🎉 Swift build completed successfully!"
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
if [ "$NOTARIZE" = true ]; then
    echo "   Notarized: Yes"
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
print_success "🎉 Swift macOS build process finished!"
print_status "📁 All outputs are in: ./dist/"

# Usage instructions
echo ""
print_info "To run the application:"
print_info "  Command line: ./build/$APP_NAME"
print_info "  App bundle: open dist/$APP_NAME.app"

print_status ""
print_info "Agent CLI commands used:"
print_info "  • swift build -c $CONFIG"
if [ "$BUILD_METHOD" = "xcodebuild" ]; then
    print_info "  • xcodebuild -project $PROJECT_FILE -scheme $SCHEME"
fi
if [ "$CODE_SIGN" = true ]; then
    print_info "  • codesign --force --sign [identity]"
fi
if [ "$NOTARIZE" = true ]; then
    print_info "  • xcrun notarytool submit"
fi
if [ "$CREATE_DMG" = true ]; then
    print_info "  • hdiutil create -format UDZO"
fi
```

## Script 2: run-swift-source.sh (Development Mode)

```bash
#!/bin/bash

# Run Swift App from Source (Development Mode)
# Agent-controlled execution using CLI tools only

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✔${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status "🚀 Starting Swift application from source..."

# Check macOS
if [ "$(uname)" != "Darwin" ]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Check for Swift
if ! command_exists swift; then
    print_error "Swift is not installed. Install Xcode Command Line Tools:"
    print_error "  xcode-select --install"
    exit 1
fi

# Determine run method
if [ -f "Package.swift" ]; then
    print_status "Running with Swift Package Manager..."
    swift run
    
elif ls *.xcodeproj >/dev/null 2>&1; then
    PROJECT_FILE=$(ls *.xcodeproj | head -1)
    APP_NAME=$(basename "$PROJECT_FILE" .xcodeproj)
    
    print_status "Building and running with xcodebuild..."
    xcodebuild -project "$PROJECT_FILE" -scheme "$APP_NAME" -configuration Debug build
    
    if [ $? -eq 0 ]; then
        # Find and run the built executable
        BUILT_APP=$(find . -name "$APP_NAME.app" -type d | head -1)
        if [ -n "$BUILT_APP" ]; then
            print_status "Launching: $BUILT_APP"
            open "$BUILT_APP"
        else
            print_error "Could not find built application"
        fi
    else
        print_error "Build failed"
        exit 1
    fi
    
else
    # Try to find and run main.swift directly
    if [ -f "Sources/main.swift" ]; then
        print_status "Running main.swift directly..."
        swift Sources/main.swift
    elif [ -f "main.swift" ]; then
        print_status "Running main.swift directly..."
        swift main.swift
    else
        print_error "No Package.swift, .xcodeproj, or main.swift found"
        exit 1
    fi
fi

print_success "Application session ended"
```

## Script 3: swift-project-setup.sh (Agent CLI Project Creator)

```bash
#!/bin/bash

# Swift macOS Project Setup Script
# Agent-controlled project creation using CLI tools only

print_status() {
    echo -e "\033[0;34m[$(date +'%H:%M:%S')]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[$(date +'%H:%M:%S')] ✔\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[$(date +'%H:%M:%S')] ✗\033[0m $1"
}

# Function to create SwiftUI app template
create_swiftui_template() {
    local app_name="$1"
    
    print_status "Creating SwiftUI template for $app_name..."
    
    # Create Package.swift
    cat > Package.swift << EOF
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "$app_name",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // Add your dependencies here
    ],
    targets: [
        .executableTarget(
            name: "$app_name",
            dependencies: []
        )
    ]
)
EOF
    
    # Create main.swift
    mkdir -p Sources
    cat > Sources/main.swift << 'EOF'
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .font(.largeTitle)
                .padding()
            
            Button("Click Me") {
                print("Button clicked!")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 300, minHeight: 200)
        .padding()
    }
}
EOF
    
    # Create Resources directory structure
    mkdir -p Resources
    
    # Create Info.plist
    cat > Resources/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$app_name</string>
    <key>CFBundleDisplayName</key>
    <string>$app_name</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$app_name</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$app_name</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF
    
    print_success "SwiftUI template created"
}

# Function to create AppKit app template
create_appkit_template() {
    local app_name="$1"
    
    print_status "Creating AppKit template for $app_name..."
    
    # Create Package.swift
    cat > Package.swift << EOF
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "$app_name",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        // Add your dependencies here
    ],
    targets: [
        .executableTarget(
            name: "$app_name",
            dependencies: []
        )
    ]
)
EOF
    
    # Create main.swift
    mkdir -p Sources
    cat > Sources/main.swift << 'EOF'
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "My App"
        window.center()
        
        // Create content view
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        
        // Add a label
        let label = NSTextField(labelWithString: "Hello, AppKit!")
        label.frame = NSRect(x: 20, y: 160, width: 440, height: 30)
        label.font = NSFont.systemFont(ofSize: 24)
        label.alignment = .center
        contentView.addSubview(label)
        
        // Add a button
        let button = NSButton(frame: NSRect(x: 190, y: 120, width: 100, height: 30))
        button.title = "Click Me"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(buttonClicked)
        contentView.addSubview(button)
        
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func buttonClicked() {
        print("Button clicked!")
        let alert = NSAlert()
        alert.messageText = "Button Clicked!"
        alert.informativeText = "Hello from AppKit!"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func applicationShouldTerminateWhenLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
EOF
    
    print_success "AppKit template created"
}

# Main script
APP_NAME="MyApp"
TEMPLATE="swiftui"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            APP_NAME="$2"
            shift 2
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --help)
            echo "Swift Project Setup Script"
            echo "Usage: $0 [--name AppName] [--template swiftui|appkit]"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Setting up Swift project: $APP_NAME"
print_status "Template: $TEMPLATE"

# Create project directory
mkdir -p "$APP_NAME"
cd "$APP_NAME"

# Create template based on choice
case $TEMPLATE in
    swiftui)
        create_swiftui_template "$APP_NAME"
        ;;
    appkit)
        create_appkit_template "$APP_NAME"
        ;;
    *)
        print_error "Invalid template: $TEMPLATE"
        exit 1
        ;;
esac

# Create build directories
mkdir -p build
mkdir -p dist

# Create build script
cp ../compile-build-dist-swift.sh . 2>/dev/null || echo "# Copy the main build script here"

print_success "Project setup complete: $APP_NAME/"
print_status "Next steps:"
print_status "  cd $APP_NAME"
print_status "  ./compile-build-dist-swift.sh"
```

## Package.swift Template (SwiftUI with Dependencies)

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MySwiftApp",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // SwiftUI Navigation
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // JSON Parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "MySwiftApp",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
```

## Agent CLI Commands Reference

```bash
# Setup commands (agent-executable)
xcode-select --install                    # Install development tools
swift --version                           # Check Swift version
xcodebuild -version                      # Check Xcode version

# Project creation commands
swift package init --type executable     # Create SPM project
mkdir -p Sources Resources               # Create directories

# Build commands (agent-executable)
swift build                              # Debug build
swift build -c release                   # Release build
swift run                               # Build and run

# Xcode project commands
xcodebuild -project MyApp.xcodeproj -scheme MyApp -configuration Release
xcodebuild -showBuildSettings           # Show build settings
xcodebuild -list                        # List schemes and targets

# Code signing commands (agent-executable)
security find-identity -v -p codesigning           # List signing identities
codesign --force --sign "Developer ID" MyApp.app   # Sign application
codesign --verify --verbose=4 MyApp.app            # Verify signature

# Notarization commands (agent-executable)
xcrun notarytool submit MyApp.zip --keychain-profile "AC_PASSWORD"
xcrun stapler staple MyApp.app           # Staple notarization

# Distribution commands (agent-executable)
zip -r MyApp.zip MyApp.app               # Create ZIP
hdiutil create -srcfolder MyApp.app -format UDZO MyApp.dmg  # Create DMG

# Analysis commands
swift package show-dependencies          # Show package dependencies
xcrun size MyApp                        # Show binary size
otool -L MyApp                          # Show linked libraries
```

## Quick Start Guide for Agents

```bash
# 1. Create project
./swift-project-setup.sh --name "MyApp" --template "swiftui"
cd MyApp

# 2. Build application
./compile-build-dist-swift.sh --config release

# 3. Create signed distribution
./compile-build-dist-swift.sh --config release --sign --dmg

# 4. Universal binary
./compile-build-dist-swift.sh --arch universal --config release

# 5. Development testing
./run-swift-source.sh
```

This system provides complete CLI-driven Swift compilation that AI agents can execute without any GUI dependencies.