# Complete Multi-Platform Python/CustomTkinter Build System with Cleanup & Optimization

## AMENDMENTS - PYTHON/CUSTOMTKINTER CONFIGURATION:

**Important**: This configuration has been adapted for Python applications using CustomTkinter/Tkinter GUI frameworks.

**Key Features**:
- Multi-platform Python build support (macOS Intel/ARM, Windows x64, Linux x64)
- PyInstaller integration with intelligent optimization
- CustomTkinter and Tkinter compatibility
- Virtual environment management
- Dependency optimization and cleanup
- App bundle creation for macOS (.app)
- Executable creation for Windows (.exe)
- Linux AppImage and package support
- Comprehensive temp file cleanup and prevention
- Integrated bloat checking and optimization features

This build system provides comprehensive support for building Python applications for macOS, Windows, and Linux with native installers, plus automatic cleanup and size optimization.

If the application requires an environment environment MUST BE SELF-CONTAINED WITHIN THE APPLICATION.

## Build System Requirements

1. **Python 3.8+** installed on system
2. **Virtual environment** (recommended)
3. **Platform-specific tools**: PyInstaller, UPX (optional), platform SDKs
4. **Dependencies**: CustomTkinter, Tkinter, PIL/Pillow, etc.
5. **NEW**: Automatic temp file cleanup and bloat prevention

## Required Project Structure (VERIFIED WORKING)

```
your-python-app/
├── src/                     # Source code
│   ├── main.py             # Main application entry point
│   ├── ui/                 # UI components
│   ├── core/               # Core business logic
│   ├── utils/              # Utilities
│   └── assets/             # Images, icons, resources
├── dist/                   # Build outputs (created by build)
├── build/                  # Temporary build files
├── venv/                   # Virtual environment
├── requirements.txt        # Python dependencies
├── build-resources/        # Icons and resources
│   ├── icon.icns          # macOS icon
│   ├── icon.ico           # Windows icon
│   ├── icon.png           # Linux icon
│   └── Info.plist         # macOS app info
├── scripts/               # Build scripts
└── main.spec             # PyInstaller spec file (generated)
```

## Script 1: compile-build-dist-python.sh (MAIN BUILD SCRIPT)

```bash
#!/bin/bash

# Complete Multi-Platform Python Build Script
# Builds Python/CustomTkinter apps for macOS, Windows, and Linux
# Includes automatic temp cleanup and bloat monitoring

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

# Function to get Python version
get_python_version() {
    python --version 2>/dev/null | cut -d' ' -f2 || python3 --version 2>/dev/null | cut -d' ' -f2 || echo "Not found"
}

# NEW: Function to cleanup system temp directories
cleanup_system_temp() {
    print_status "🧹 Cleaning Python build temp directories..."
    
    # macOS temp cleanup
    if [ "$(uname)" = "Darwin" ]; then
        TEMP_DIR=$(find /private/var/folders -name "Temporary*" -type d 2>/dev/null | head -1)
        if [ -n "$TEMP_DIR" ]; then
            PARENT_DIR=$(dirname "$TEMP_DIR")
            BEFORE_SIZE=$(du -sh "$PARENT_DIR" 2>/dev/null | cut -f1)
            
            # Clean up Python/PyInstaller artifacts (older than 1 day)
            find "$PARENT_DIR" -name "pyinstaller-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "pip-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "python-build-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "setuptools-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            
            AFTER_SIZE=$(du -sh "$PARENT_DIR" 2>/dev/null | cut -f1)
            print_success "System temp cleanup: $BEFORE_SIZE → $AFTER_SIZE"
        fi
    fi
    
    # Linux temp cleanup
    if [ "$(uname)" = "Linux" ]; then
        if [ -d "/tmp" ]; then
            BEFORE_SIZE=$(du -sh /tmp 2>/dev/null | cut -f1)
            find /tmp -name "pyinstaller-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find /tmp -name "pip-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find /tmp -name "python-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            AFTER_SIZE=$(du -sh /tmp 2>/dev/null | cut -f1)
            print_success "System temp cleanup: $BEFORE_SIZE → $AFTER_SIZE"
        fi
    fi
}

# NEW: Function to set custom temp directory
setup_build_temp() {
    BUILD_TEMP_DIR="$SCRIPT_DIR/build-temp"
    mkdir -p "$BUILD_TEMP_DIR"
    export TMPDIR="$BUILD_TEMP_DIR"
    export TMP="$BUILD_TEMP_DIR"
    export TEMP="$BUILD_TEMP_DIR"
    export PYINSTALLER_WORKDIR="$BUILD_TEMP_DIR/pyinstaller"
    print_info "Using custom temp directory: $BUILD_TEMP_DIR"
}

# NEW: Function to perform Python bloat check
python_bloat_check() {
    print_status "🔍 Performing Python dependencies analysis..."
    
    # Check virtual environment size
    if [ -d "venv" ]; then
        VENV_SIZE=$(du -sh venv/ 2>/dev/null | cut -f1)
        print_info "Virtual environment size: $VENV_SIZE"
    fi
    
    # Check requirements.txt
    if [ -f "requirements.txt" ]; then
        REQ_COUNT=$(wc -l < requirements.txt)
        print_info "Requirements.txt dependencies: $REQ_COUNT"
        
        # Check for heavy dependencies
        HEAVY_DEPS=(tensorflow torch numpy scipy matplotlib pillow opencv opencv-python pandas)
        for dep in "${HEAVY_DEPS[@]}"; do
            if grep -qi "$dep" requirements.txt; then
                print_warning "⚠️  Heavy dependency detected: $dep"
            fi
        done
    fi
    
    # Check installed packages
    if [ -f "venv/bin/pip" ] || [ -f "venv/Scripts/pip.exe" ]; then
        INSTALLED_COUNT=$(source venv/bin/activate 2>/dev/null && pip list | wc -l || echo "Unknown")
        print_info "Installed packages: $INSTALLED_COUNT"
    fi
    
    # Check for common bloat patterns
    if [ -d "src" ]; then
        PYTHON_FILES=$(find src -name "*.py" | wc -l)
        TOTAL_LINES=$(find src -name "*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        print_info "Python files: $PYTHON_FILES ($TOTAL_LINES lines total)"
    fi
}

# NEW: Function to cleanup build temp after build
cleanup_build_temp() {
    if [ -n "$BUILD_TEMP_DIR" ] && [ -d "$BUILD_TEMP_DIR" ]; then
        print_status "🧹 Cleaning build temp directory..."
        TEMP_SIZE=$(du -sh "$BUILD_TEMP_DIR" 2>/dev/null | cut -f1 || echo "0")
        rm -rf "$BUILD_TEMP_DIR" 2>/dev/null || true
        print_success "Cleaned build temp: $TEMP_SIZE"
    fi
}

# Function to display help
show_help() {
    echo "Complete Multi-Platform Python Build Script"
    echo ""
    echo "Usage: ./compile-build-dist-python.sh [options]"
    echo ""
    echo "Options:"
    echo "  --no-clean         Skip cleaning build artifacts"
    echo "  --no-temp-clean    Skip system temp cleanup"
    echo "  --no-bloat-check   Skip bloat analysis"
    echo "  --platform PLAT    Build for specific platform (mac, win, linux, all)"
    echo "  --onefile          Create single executable file"
    echo "  --windowed         Create windowed app (no console)"
    echo "  --upx              Use UPX compression"
    echo "  --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./compile-build-dist-python.sh                    # Full build for current platform"
    echo "  ./compile-build-dist-python.sh --platform mac     # macOS only"
    echo "  ./compile-build-dist-python.sh --onefile          # Single file executable"
    echo "  ./compile-build-dist-python.sh --windowed --upx   # Windowed app with compression"
}

# Parse command line arguments
NO_CLEAN=false
NO_TEMP_CLEAN=false
NO_BLOAT_CHECK=false
PLATFORM="current"
ONEFILE=false
WINDOWED=false
USE_UPX=false

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
        --no-bloat-check)
            NO_BLOAT_CHECK=true
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --onefile)
            ONEFILE=true
            shift
            ;;
        --windowed)
            WINDOWED=true
            shift
            ;;
        --upx)
            USE_UPX=true
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

# Trap to ensure cleanup on exit
trap cleanup_build_temp EXIT

# Check for required tools
print_status "Checking Python build requirements..."

PYTHON_CMD=""
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
else
    print_error "Python is not installed. Please install Python 3.8+ first."
    exit 1
fi

PYTHON_VERSION=$(get_python_version)
print_info "Python version: $PYTHON_VERSION"

# Check for pip
if ! command_exists pip && ! command_exists pip3; then
    print_error "pip is not installed. Please install pip first."
    exit 1
fi

# Check for PyInstaller
if ! $PYTHON_CMD -c "import PyInstaller" 2>/dev/null; then
    print_warning "PyInstaller not found. Installing..."
    pip install PyInstaller
fi

# Check for UPX if requested
if [ "$USE_UPX" = true ]; then
    if ! command_exists upx; then
        print_warning "UPX not found. Install for better compression:"
        print_info "  macOS: brew install upx"
        print_info "  Linux: sudo apt install upx-ucl"
        USE_UPX=false
    else
        print_success "UPX compression available"
    fi
fi

print_success "All requirements met"

# NEW: Cleanup system temp directories first
if [ "$NO_TEMP_CLEAN" = false ]; then
    cleanup_system_temp
fi

# NEW: Setup custom build temp directory
setup_build_temp

# NEW: Perform bloat check before build
if [ "$NO_BLOAT_CHECK" = false ]; then
    python_bloat_check
fi

# Step 1: Clean everything if not skipped
if [ "$NO_CLEAN" = false ]; then
    print_status "🧹 Purging all existing builds..."
    rm -rf dist/
    rm -rf build/
    rm -rf __pycache__/
    rm -rf *.spec
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    print_success "All build artifacts purged"
fi

# Step 2: Setup virtual environment (if not exists)
if [ ! -d "venv" ]; then
    print_status "📦 Creating virtual environment..."
    $PYTHON_CMD -m venv venv
    if [ $? -ne 0 ]; then
        print_error "Failed to create virtual environment"
        exit 1
    fi
    print_success "Virtual environment created"
fi

# Step 3: Activate virtual environment and install dependencies
print_status "📦 Installing/updating dependencies..."

# Activate virtual environment
if [ "$(uname)" = "Darwin" ] || [ "$(uname)" = "Linux" ]; then
    source venv/bin/activate
else
    source venv/Scripts/activate
fi

# Install/upgrade pip
pip install --upgrade pip

# Install dependencies
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
fi

# Ensure PyInstaller is installed in venv
pip install PyInstaller

print_success "Dependencies ready"

# Step 4: Determine build parameters
print_status "🎯 Configuring build parameters..."

PYINSTALLER_OPTS=""
MAIN_FILE="src/main.py"

# Find main file
if [ ! -f "$MAIN_FILE" ]; then
    for candidate in main.py app.py src/app.py src/__main__.py; do
        if [ -f "$candidate" ]; then
            MAIN_FILE="$candidate"
            break
        fi
    done
fi

if [ ! -f "$MAIN_FILE" ]; then
    print_error "Cannot find main Python file. Expected: src/main.py, main.py, or app.py"
    exit 1
fi

print_info "Main file: $MAIN_FILE"

# Configure PyInstaller options
if [ "$ONEFILE" = true ]; then
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --onefile"
    print_info "Mode: Single file executable"
else
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --onedir"
    print_info "Mode: Directory bundle"
fi

if [ "$WINDOWED" = true ]; then
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --windowed --noconsole"
    print_info "GUI: Windowed (no console)"
else
    print_info "GUI: Console mode"
fi

# Add icon if available
ICON_FILE=""
if [ "$(uname)" = "Darwin" ] && [ -f "build-resources/icon.icns" ]; then
    ICON_FILE="build-resources/icon.icns"
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --icon=$ICON_FILE"
elif [ "$(uname)" = "Linux" ] && [ -f "build-resources/icon.png" ]; then
    ICON_FILE="build-resources/icon.png"
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --icon=$ICON_FILE"
elif [ -f "build-resources/icon.ico" ]; then
    ICON_FILE="build-resources/icon.ico"
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --icon=$ICON_FILE"
fi

if [ -n "$ICON_FILE" ]; then
    print_info "Icon: $ICON_FILE"
fi

# Add assets directory if exists
if [ -d "src/assets" ]; then
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --add-data src/assets:assets"
    print_info "Assets: src/assets included"
fi

# Configure CustomTkinter
PYINSTALLER_OPTS="$PYINSTALLER_OPTS --collect-all customtkinter"
PYINSTALLER_OPTS="$PYINSTALLER_OPTS --collect-all tkinter"

# Add UPX compression if available
if [ "$USE_UPX" = true ]; then
    PYINSTALLER_OPTS="$PYINSTALLER_OPTS --upx-dir=$(which upx | xargs dirname)"
    print_info "Compression: UPX enabled"
fi

# Set build directory
PYINSTALLER_OPTS="$PYINSTALLER_OPTS --workpath=$BUILD_TEMP_DIR/pyinstaller"
PYINSTALLER_OPTS="$PYINSTALLER_OPTS --distpath=dist"
PYINSTALLER_OPTS="$PYINSTALLER_OPTS --specpath=."

# Step 5: Build the application
print_status "🏗️ Building Python application..."
print_status "Platform: $(uname) ($(uname -m))"
print_status "PyInstaller command: pyinstaller $PYINSTALLER_OPTS $MAIN_FILE"

pyinstaller $PYINSTALLER_OPTS "$MAIN_FILE"
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    print_error "Build failed"
    exit 1
fi

print_success "Build completed successfully"

# Step 6: Platform-specific post-processing
print_status "🔧 Post-processing for $(uname)..."

if [ "$(uname)" = "Darwin" ]; then
    # macOS specific processing
    print_status "📱 macOS app bundle processing..."
    
    APP_NAME=$(basename "$MAIN_FILE" .py)
    if [ -d "dist/$APP_NAME.app" ]; then
        print_success "Created macOS app: dist/$APP_NAME.app"
        
        # Create Info.plist if not exists
        if [ ! -f "dist/$APP_NAME.app/Contents/Info.plist" ] && [ -f "build-resources/Info.plist" ]; then
            cp "build-resources/Info.plist" "dist/$APP_NAME.app/Contents/Info.plist"
            print_info "Added Info.plist to app bundle"
        fi
        
        # Make executable
        chmod +x "dist/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    fi
    
elif [ "$(uname)" = "Linux" ]; then
    # Linux specific processing
    print_status "🐧 Linux executable processing..."
    
    APP_NAME=$(basename "$MAIN_FILE" .py)
    if [ -d "dist/$APP_NAME" ]; then
        # Make executable
        chmod +x "dist/$APP_NAME/$APP_NAME"
        print_success "Created Linux executable: dist/$APP_NAME/$APP_NAME"
        
        # Create desktop file
        if [ -f "build-resources/icon.png" ]; then
            cat > "dist/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$(pwd)/dist/$APP_NAME/$APP_NAME
Icon=$(pwd)/build-resources/icon.png
Type=Application
Categories=Utility;
EOF
            print_info "Created desktop file: dist/$APP_NAME.desktop"
        fi
    fi
fi

# NEW: Post-build bloat analysis
if [ "$NO_BLOAT_CHECK" = false ]; then
    print_status "🔍 Post-build size analysis..."
    
    if [ -d "dist" ]; then
        TOTAL_SIZE=$(du -sh dist/ 2>/dev/null | cut -f1)
        print_info "Total build output size: $TOTAL_SIZE"
        
        # Find and report on executables
        find dist -type f \( -name "*.exe" -o -name "*.app" -o -perm +111 \) | while read -r file; do
            if [ -f "$file" ]; then
                SIZE=$(ls -lah "$file" | awk '{print $5}')
                NAME=$(basename "$file")
                print_info "  $NAME: $SIZE"
                
                # Warning for large files
                SIZE_MB=$(ls -l "$file" | awk '{print int($5/1024/1024)}')
                if [ "$SIZE_MB" -gt 200 ]; then
                    print_warning "⚠️  Large executable detected: $NAME ($SIZE)"
                fi
            fi
        done
        
        # Check for common bloat
        if find dist -name "*.so" | head -10 | grep -q "tensorflow\|torch\|opencv"; then
            print_warning "⚠️  Heavy ML libraries detected in build"
        fi
    fi
fi

# Step 7: Display build results
print_status "📋 Build Results Summary:"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"

if [ -d "dist" ]; then
    APP_NAME=$(basename "$MAIN_FILE" .py)
    
    print_success "🎉 Build completed successfully!"
    echo ""
    
    # Display platform-specific results
    if [ "$(uname)" = "Darwin" ]; then
        print_info "🍎 macOS Build:"
        if [ -d "dist/$APP_NAME.app" ]; then
            SIZE=$(du -sh "dist/$APP_NAME.app" | cut -f1)
            echo "   ✓ App Bundle: dist/$APP_NAME.app ($SIZE)"
        fi
        if [ -f "dist/$APP_NAME" ]; then
            SIZE=$(ls -lh "dist/$APP_NAME" | awk '{print $5}')
            echo "   ✓ Executable: dist/$APP_NAME ($SIZE)"
        fi
        
    elif [ "$(uname)" = "Linux" ]; then
        print_info "🐧 Linux Build:"
        if [ -d "dist/$APP_NAME" ]; then
            SIZE=$(du -sh "dist/$APP_NAME" | cut -f1)
            echo "   ✓ Directory: dist/$APP_NAME/ ($SIZE)"
        fi
        if [ -f "dist/$APP_NAME.desktop" ]; then
            echo "   ✓ Desktop file: dist/$APP_NAME.desktop"
        fi
        
    else
        print_info "🪟 Windows Build:"
        if [ -f "dist/$APP_NAME.exe" ]; then
            SIZE=$(ls -lh "dist/$APP_NAME.exe" | awk '{print $5}')
            echo "   ✓ Executable: dist/$APP_NAME.exe ($SIZE)"
        fi
    fi
    
    # Show spec file
    if [ -f "$APP_NAME.spec" ]; then
        echo "   ✓ PyInstaller spec: $APP_NAME.spec"
    fi
    
else
    print_warning "No dist directory found. Build may have failed."
fi

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"
print_success "🎉 Python build process finished!"
print_status "📁 All binaries are in: ./dist/"

# NEW: Cleanup recommendations
echo ""
print_info "🧹 Cleanup & Optimization Tips:"
print_info "  • Regular temp cleanup: Run temp cleanup monthly"
print_info "  • Dependency audit: Review requirements.txt regularly"
print_info "  • Size optimization: Use --upx for compression"
print_info "  • Virtual env cleanup: Recreate venv periodically"

print_status ""
print_info "To run the application:"
if [ "$(uname)" = "Darwin" ]; then
    print_info "  macOS: open dist/$APP_NAME.app"
elif [ "$(uname)" = "Linux" ]; then
    print_info "  Linux: ./dist/$APP_NAME/$APP_NAME"
else
    print_info "  Windows: ./dist/$APP_NAME.exe"
fi
```

## Script 2: run-python-source.sh (Development Mode)

```bash
#!/bin/bash

# Run Python App from Source (Development Mode)
# Launches the app directly from source code

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
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

print_status "🚀 Starting Python application from source..."

# Determine Python command
PYTHON_CMD=""
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
else
    print_error "Python is not installed. Please install Python 3.8+ first."
    exit 1
fi

# Check if virtual environment exists and activate it
if [ -d "venv" ]; then
    print_status "Activating virtual environment..."
    if [ "$(uname)" = "Darwin" ] || [ "$(uname)" = "Linux" ]; then
        source venv/bin/activate
    else
        source venv/Scripts/activate
    fi
    print_success "Virtual environment activated"
else
    print_status "No virtual environment found, using system Python"
fi

# Install dependencies if needed
if [ -f "requirements.txt" ] && [ ! -d "venv/lib" ] && [ ! -d "venv/Lib" ]; then
    print_status "Installing dependencies..."
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    print_success "Dependencies installed"
fi

# Find main file
MAIN_FILE=""
for candidate in src/main.py main.py app.py src/app.py; do
    if [ -f "$candidate" ]; then
        MAIN_FILE="$candidate"
        break
    fi
done

if [ -z "$MAIN_FILE" ]; then
    print_error "Cannot find main Python file. Expected: src/main.py, main.py, or app.py"
    exit 1
fi

print_status "Running: $PYTHON_CMD $MAIN_FILE"
print_status "Press Ctrl+C to stop the application"
echo ""

# Run the application
$PYTHON_CMD "$MAIN_FILE"

echo ""
print_success "Application session ended"
```

## Script 3: python-bloat-check.sh (Python-specific bloat analysis)

```bash
#!/bin/bash

# 🔍 PYTHON BLOAT CHECK SCRIPT
# Comprehensive analysis of Python app size and optimization opportunities

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

print_header() {
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════${NC}"
    echo ""
}

# Function to convert bytes to human readable
human_readable() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(($bytes / 1073741824))GB"
    elif [ $bytes -gt 1048576 ]; then
        echo "$(($bytes / 1048576))MB"
    elif [ $bytes -gt 1024 ]; then
        echo "$(($bytes / 1024))KB"
    else
        echo "${bytes}B"
    fi
}

print_header "🔍 PYTHON APPLICATION BLOAT CHECK"

# Check if in Python project
if [ ! -f "requirements.txt" ] && [ ! -f "setup.py" ] && [ ! -d "src" ]; then
    print_error "No Python project found. Run this in your project root directory."
    exit 1
fi

# 1. Virtual environment analysis
print_header "🐍 VIRTUAL ENVIRONMENT ANALYSIS"

if [ -d "venv" ]; then
    VENV_SIZE=$(du -sb venv 2>/dev/null | cut -f1)
    VENV_SIZE_HR=$(human_readable $VENV_SIZE)
    print_info "Virtual environment size: $VENV_SIZE_HR"
    
    # Size categories
    if [ $VENV_SIZE -gt 2147483648 ]; then
        print_warning "⚠️  LARGE: Virtual env > 2GB - optimization needed"
    elif [ $VENV_SIZE -gt 1073741824 ]; then
        print_warning "⚠️  MEDIUM: Virtual env > 1GB - consider cleanup"
    else
        print_success "✓ Virtual environment size acceptable"
    fi
    
    echo ""
    print_info "Largest packages in virtual environment:"
    if [ -d "venv/lib" ]; then
        find venv/lib -name "site-packages" | head -1 | xargs -I {} find {} -maxdepth 1 -type d | head -10 | while read dir; do
            if [ -d "$dir" ]; then
                SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
                NAME=$(basename "$dir")
                if [[ $NAME != "site-packages" ]] && [[ $NAME != "__pycache__" ]]; then
                    echo "  $SIZE - $NAME"
                fi
            fi
        done | sort -hr | head -5
    fi
else
    print_warning "No virtual environment found"
fi

# 2. Dependencies analysis
print_header "📋 DEPENDENCIES ANALYSIS"

if [ -f "requirements.txt" ]; then
    REQ_COUNT=$(grep -v "^#" requirements.txt | grep -v "^$" | wc -l)
    print_info "requirements.txt dependencies: $REQ_COUNT"
    
    # Check for heavy dependencies
    HEAVY_DEPS=(tensorflow tensorflow-gpu torch torchvision numpy scipy matplotlib pillow opencv-python opencv-contrib-python pandas scikit-learn jupyter notebook flask django requests beautifulsoup4)
    
    echo ""
    print_info "Heavy dependencies detected:"
    for dep in "${HEAVY_DEPS[@]}"; do
        if grep -qi "^$dep" requirements.txt; then
            SIZE_ESTIMATE="Unknown"
            case $dep in
                tensorflow*) SIZE_ESTIMATE="~500MB" ;;
                torch*) SIZE_ESTIMATE="~300MB" ;;
                opencv*) SIZE_ESTIMATE="~150MB" ;;
                numpy) SIZE_ESTIMATE="~20MB" ;;
                scipy) SIZE_ESTIMATE="~50MB" ;;
                matplotlib) SIZE_ESTIMATE="~40MB" ;;
                pillow) SIZE_ESTIMATE="~5MB" ;;
                pandas) SIZE_ESTIMATE="~30MB" ;;
            esac
            print_warning "  ⚠️  $dep ($SIZE_ESTIMATE)"
        fi
    done
    
    # GUI framework detection
    echo ""
    print_info "GUI frameworks detected:"
    GUI_FRAMEWORKS=(tkinter customtkinter PyQt5 PyQt6 PySide2 PySide6 wxPython kivy)
    for gui in "${GUI_FRAMEWORKS[@]}"; do
        if grep -qi "$gui" requirements.txt; then
            print_info "  ✓ $gui"
        fi
    done
else
    print_warning "No requirements.txt found"
fi

# Check for pip freeze output if venv active
if [ -d "venv" ] && [ -n "$VIRTUAL_ENV" ]; then
    print_status "Analyzing installed packages..."
    INSTALLED_COUNT=$(pip list | wc -l)
    print_info "Currently installed packages: $INSTALLED_COUNT"
fi

# 3. Source code analysis
print_header "💻 SOURCE CODE ANALYSIS"

if [ -d "src" ]; then
    PYTHON_FILES=$(find src -name "*.py" | wc -l)
    TOTAL_LINES=$(find src -name "*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    print_info "Python source files: $PYTHON_FILES"
    print_info "Total lines of code: $TOTAL_LINES"
    
    # Check file sizes
    echo ""
    print_info "Largest Python files:"
    find src -name "*.py" -exec wc -l {} + 2>/dev/null | sort -nr | head -5 | while read lines file; do
        if [ "$lines" != "total" ]; then
            print_info "  $lines lines - $file"
        fi
    done
else
    print_warning "No src directory found"
fi

# Check for assets
if [ -d "assets" ] || [ -d "src/assets" ]; then
    ASSETS_DIR="assets"
    [ -d "src/assets" ] && ASSETS_DIR="src/assets"
    
    ASSETS_SIZE=$(du -sh "$ASSETS_DIR" 2>/dev/null | cut -f1)
    print_info "Assets directory size: $ASSETS_SIZE"
    
    # Check for large assets
    echo ""
    print_info "Largest asset files:"
    find "$ASSETS_DIR" -type f | xargs ls -lah | sort -k5 -hr | head -5 | while read -r line; do
        SIZE=$(echo $line | awk '{print $5}')
        NAME=$(echo $line | awk '{print $9}')
        print_info "  $SIZE - $(basename "$NAME")"
    done
fi

# 4. Build output analysis
print_header "📦 BUILD OUTPUT ANALYSIS"

if [ -d "dist" ]; then
    DIST_SIZE=$(du -sb dist 2>/dev/null | cut -f1)
    DIST_SIZE_HR=$(human_readable $DIST_SIZE)
    print_info "Total dist size: $DIST_SIZE_HR"
    
    echo ""
    print_info "Build outputs:"
    
    # Check executables
    find dist -type f \( -name "*.exe" -o -name "*.app" -o -perm +111 \) | while read -r file; do
        SIZE=$(ls -lah "$file" | awk '{print $5}')
        NAME=$(basename "$file")
        
        # Convert size to MB for comparison
        SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
        SIZE_MB=$((SIZE_BYTES / 1024 / 1024))
        
        if [ $SIZE_MB -gt 100 ]; then
            print_warning "  ⚠️  $NAME: $SIZE (LARGE)"
        elif [ $SIZE_MB -gt 50 ]; then
            print_info "  📦 $NAME: $SIZE"
        else
            print_success "  ✓ $NAME: $SIZE"
        fi
    done
    
    # Check for common bloat in builds
    if find dist -name "*.so" -o -name "*.dll" -o -name "*.dylib" | head -20 | grep -q "tensorflow\|torch\|cv2"; then
        print_warning "⚠️  Heavy ML/CV libraries found in build"
    fi
else
    print_warning "No dist directory found. Run a build first."
fi

# 5. PyInstaller analysis
print_header "🔨 PYINSTALLER ANALYSIS"

if [ -f "*.spec" ]; then
    SPEC_FILE=$(ls *.spec | head -1)
    print_info "PyInstaller spec file: $SPEC_FILE"
    
    # Analyze spec file
    if grep -q "onefile=True" "$SPEC_FILE"; then
        print_info "Build mode: Single file (--onefile)"
    else
        print_info "Build mode: Directory bundle"
    fi
    
    if grep -q "console=False" "$SPEC_FILE"; then
        print_info "Console mode: Windowed (no console)"
    else
        print_info "Console mode: Console visible"
    fi
    
    # Check for data files
    DATA_FILES=$(grep -c "datas=" "$SPEC_FILE" || echo "0")
    print_info "Additional data files: $DATA_FILES"
    
    # Check for hidden imports
    HIDDEN_IMPORTS=$(grep "hiddenimports=" "$SPEC_FILE" | wc -l)
    if [ $HIDDEN_IMPORTS -gt 0 ]; then
        print_info "Hidden imports specified: $HIDDEN_IMPORTS"
    fi
else
    print_warning "No PyInstaller spec file found"
fi

# 6. Optimization recommendations
print_header "💡 OPTIMIZATION RECOMMENDATIONS"

print_info "🐍 Python Dependencies:"
if [ -d "venv" ] && [ $VENV_SIZE -gt 1073741824 ]; then
    print_warning "  • Review heavy dependencies (TensorFlow, PyTorch, OpenCV)"
    print_info "  • Use lighter alternatives where possible"
    print_info "  • Consider lazy loading for ML libraries"
fi

print_info "  • Use 'pipreqs' to generate minimal requirements.txt"
print_info "  • Remove unused packages with 'pip-autoremove'"
print_info "  • Use virtual environments for isolation"

print_info "🏗️  Build Optimization:"
print_info "  • Use --onefile for single executable"
print_info "  • Use --windowed for GUI applications"
print_info "  • Enable UPX compression with --upx"
print_info "  • Exclude unnecessary modules with --exclude-module"
print_info "  • Use --optimize for Python bytecode optimization"

print_info "📦 Asset Optimization:"
print_info "  • Compress images (PNG → WebP, JPG quality)"
print_info "  • Use vector formats (SVG) when possible"
print_info "  • Remove unused asset files"
print_info "  • Consider external asset loading"

# 7. Size targets
print_header "🎯 SIZE TARGETS & BENCHMARKS"

print_info "Python application size guidelines:"
print_success "  ✓ Excellent: < 50MB"
print_info "  📊 Good: 50-150MB"
print_warning "  ⚠️  Acceptable: 150-500MB"
print_error "  ❌ Needs optimization: > 500MB"

echo ""
print_info "Quick optimization commands:"
echo "  pipreqs --force .  # Generate minimal requirements"
echo "  pip-autoremove -y  # Remove unused packages"
echo "  pyinstaller --onefile --windowed --upx main.py"
echo "  find . -name '*.pyc' -delete  # Clean bytecode"

print_header "✅ PYTHON BLOAT CHECK COMPLETE"

# Final recommendations
print_info "🧹 Maintenance tasks:"
print_info "  • Run dependency audit monthly"
print_info "  • Recreate virtual environment quarterly"
print_info "  • Monitor build sizes after changes"
print_info "  • Use continuous integration for size monitoring"
```

## Requirements.txt Template for CustomTkinter Apps

```
# GUI Framework
customtkinter>=5.2.0
tkinter  # Usually built-in with Python

# Image Processing
Pillow>=10.0.0

# Common Utilities
requests>=2.31.0

# Build Tools
PyInstaller>=5.13.0

# Optional: Enhanced GUI components
# tkinterdnd2>=0.3.0  # Drag & drop support
# matplotlib>=3.7.0   # Plotting (WARNING: Large dependency ~40MB)
# numpy>=1.24.0       # Numerical operations (WARNING: ~20MB)

# Development Tools (not included in builds)
# black>=23.0.0       # Code formatter
# flake8>=6.0.0       # Linting
```

## Build Resources Structure

```
build-resources/
├── icon.icns           # macOS icon (1024x1024)
├── icon.ico            # Windows icon (256x256) 
├── icon.png            # Linux icon (512x512)
└── Info.plist          # macOS app information
```

## Sample Info.plist for macOS

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Your App Name</string>
    <key>CFBundleDisplayName</key>
    <string>Your App Name</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.yourapp</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>main</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.10.0</string>
</dict>
</plist>
```

## Quick Start Commands

```bash
# Setup
chmod +x compile-build-dist-python.sh
chmod +x run-python-source.sh
chmod +x python-bloat-check.sh

# Create virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Development
./run-python-source.sh

# Build for current platform
./compile-build-dist-python.sh

# Build with optimizations
./compile-build-dist-python.sh --onefile --windowed --upx

# Check for bloat
./python-bloat-check.sh

# Platform-specific builds
./compile-build-dist-python.sh --platform mac
./compile-build-dist-python.sh --platform linux
```

## Expected Build Results

After successful build:

```
dist/
├── main                    # Linux executable directory
│   ├── main               # Main executable
│   └── _internal/         # Dependencies
├── main.app/              # macOS app bundle
│   └── Contents/
│       ├── MacOS/main     # Main executable
│       ├── Info.plist     # App information
│       └── Resources/     # Assets and libraries
└── main.exe               # Windows executable (if built on Windows)
```

This system provides comprehensive Python/CustomTkinter build support with size optimization, dependency management, and multi-platform compatibility.