# Complete Multi-Platform TypeScript/JavaScript Build System with Optimization

## AMENDMENTS - TYPESCRIPT/JAVASCRIPT CONFIGURATION:

**Important**: This configuration has been adapted for TypeScript/JavaScript applications with modern build tooling.

**Key Features**:
- Multi-platform Node.js application builds (macOS, Windows, Linux)
- TypeScript compilation with optimization
- Modern bundling (Webpack, Vite, Rollup, esbuild)
- Electron app packaging (optional)
- PWA (Progressive Web App) support
- Docker containerization
- Comprehensive dependency management
- Tree-shaking and code splitting
- Source map generation and optimization
- Comprehensive temp file cleanup and prevention
- Integrated bloat checking and bundle analysis

This build system provides comprehensive support for building TypeScript/JavaScript applications with modern tooling, optimization, and multi-platform distribution.

## Build System Requirements

1. **Node.js 18+** and **npm/yarn/pnpm**
2. **TypeScript 5.0+** (if using TypeScript)
3. **Build tools**: Webpack, Vite, or preferred bundler
4. **Optional**: Docker, Electron, PWA tools
5. **NEW**: Automatic bundle analysis and optimization

## Required Project Structure (MODERN TOOLING)

```
typescript-js-app/
├── src/                    # Source code
│   ├── main.ts            # Main entry point
│   ├── components/        # Components/modules
│   ├── utils/             # Utilities
│   ├── types/             # TypeScript types
│   └── assets/            # Static assets
├── public/                # Public assets (for web apps)
├── dist/                  # Build outputs (created by build)
├── build/                 # Alternative build output
├── node_modules/          # Dependencies
├── tests/                 # Test files
├── docs/                  # Documentation
├── package.json           # Project configuration
├── tsconfig.json          # TypeScript configuration
├── webpack.config.js      # Webpack configuration (if used)
├── vite.config.ts         # Vite configuration (if used)
├── .env                   # Environment variables
├── .gitignore             # Git ignore rules
├── Dockerfile             # Docker configuration (optional)
└── electron.js            # Electron main process (if Electron app)
```

## Script 1: compile-build-dist-ts.sh (MAIN BUILD SCRIPT)

```bash
#!/bin/bash

# Complete Multi-Platform TypeScript/JavaScript Build Script
# Supports modern bundlers and deployment targets
# Includes automatic bundle analysis and optimization

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

# Function to get Node.js version
get_node_version() {
    node --version 2>/dev/null || echo "Not found"
}

# Function to get package manager
detect_package_manager() {
    if [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    elif [ -f "package-lock.json" ]; then
        echo "npm"
    else
        echo "npm"  # default
    fi
}

# NEW: Function to cleanup Node.js build temp directories
cleanup_node_temp() {
    print_status "🧹 Cleaning Node.js build temp directories..."
    
    # Clean npm cache
    if command_exists npm; then
        npm cache clean --force 2>/dev/null || true
        print_success "NPM cache cleaned"
    fi
    
    # Clean yarn cache
    if command_exists yarn; then
        yarn cache clean 2>/dev/null || true
        print_success "Yarn cache cleaned"
    fi
    
    # Clean pnpm cache
    if command_exists pnpm; then
        pnpm store prune 2>/dev/null || true
        print_success "PNPM cache cleaned"
    fi
    
    # Clean node_modules/.cache
    if [ -d "node_modules/.cache" ]; then
        CACHE_SIZE=$(du -sh node_modules/.cache 2>/dev/null | cut -f1)
        rm -rf node_modules/.cache 2>/dev/null || true
        print_success "Cleaned node_modules cache: $CACHE_SIZE"
    fi
    
    # Clean webpack cache
    if [ -d "node_modules/.cache/webpack" ]; then
        rm -rf node_modules/.cache/webpack 2>/dev/null || true
        print_success "Cleaned webpack cache"
    fi
    
    # Clean TypeScript cache
    if [ -f "tsconfig.tsbuildinfo" ]; then
        rm -f tsconfig.tsbuildinfo
        print_success "Cleaned TypeScript build info"
    fi
}

# NEW: Function to perform bundle analysis
bundle_analysis() {
    print_status "🔍 Performing bundle analysis..."
    
    # Check node_modules size
    if [ -d "node_modules" ]; then
        NODE_SIZE=$(du -sh node_modules/ 2>/dev/null | cut -f1)
        print_info "Node modules size: $NODE_SIZE"
        
        # Find largest dependencies
        print_info "Top 5 largest dependencies:"
        du -sh node_modules/* 2>/dev/null | sort -hr | head -5 | while read size dir; do
            print_info "  $size - $(basename "$dir")"
        done
    fi
    
    # Check package.json dependencies
    if [ -f "package.json" ]; then
        PROD_DEPS=$(grep -c '".*":' package.json | head -1)
        DEV_DEPS=$(jq '.devDependencies | length' package.json 2>/dev/null || echo "0")
        print_info "Dependencies: $DEV_DEPS dev, ~$PROD_DEPS total"
        
        # Check for heavy dependencies
        HEAVY_DEPS=(lodash moment axios react vue angular @angular typescript webpack)
        for dep in "${HEAVY_DEPS[@]}"; do
            if grep -q "\"$dep\"" package.json; then
                print_warning "⚠️  Heavy dependency detected: $dep"
            fi
        done
    fi
    
    # Check for bundler
    BUNDLER="none"
    if [ -f "webpack.config.js" ] || [ -f "webpack.config.ts" ]; then
        BUNDLER="webpack"
    elif [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
        BUNDLER="vite"
    elif [ -f "rollup.config.js" ] || [ -f "rollup.config.ts" ]; then
        BUNDLER="rollup"
    elif grep -q "esbuild" package.json; then
        BUNDLER="esbuild"
    fi
    print_info "Detected bundler: $BUNDLER"
}

# Function to display help
show_help() {
    echo "Complete Multi-Platform TypeScript/JavaScript Build Script"
    echo ""
    echo "Usage: ./compile-build-dist-ts.sh [options]"
    echo ""
    echo "Options:"
    echo "  --no-clean         Skip cleaning build artifacts"
    echo "  --no-temp-clean    Skip system temp cleanup"
    echo "  --no-analysis      Skip bundle analysis"
    echo "  --mode MODE        Build mode (development, production)"
    echo "  --target TARGET    Build target (web, node, electron, pwa)"
    echo "  --bundler BUNDLER  Bundler to use (webpack, vite, rollup, esbuild)"
    echo "  --optimize         Enable aggressive optimization"
    echo "  --analyze          Generate bundle analysis report"
    echo "  --docker           Build Docker image"
    echo "  --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./compile-build-dist-ts.sh                    # Standard production build"
    echo "  ./compile-build-dist-ts.sh --target electron  # Electron app build"
    echo "  ./compile-build-dist-ts.sh --optimize --analyze  # Optimized build with analysis"
    echo "  ./compile-build-dist-ts.sh --docker           # Docker containerized build"
}

# Parse command line arguments
NO_CLEAN=false
NO_TEMP_CLEAN=false
NO_ANALYSIS=false
MODE="production"
TARGET="web"
BUNDLER="auto"
OPTIMIZE=false
ANALYZE=false
DOCKER=false

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
        --no-analysis)
            NO_ANALYSIS=true
            shift
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --bundler)
            BUNDLER="$2"
            shift 2
            ;;
        --optimize)
            OPTIMIZE=true
            shift
            ;;
        --analyze)
            ANALYZE=true
            shift
            ;;
        --docker)
            DOCKER=true
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

# Check for required tools
print_status "Checking Node.js build requirements..."

if ! command_exists node; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    print_info "  Download from: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(get_node_version)
print_info "Node.js version: $NODE_VERSION"

# Detect package manager
PKG_MANAGER=$(detect_package_manager)
print_info "Package manager: $PKG_MANAGER"

if ! command_exists "$PKG_MANAGER"; then
    print_error "$PKG_MANAGER is not installed."
    exit 1
fi

# Check for TypeScript if tsconfig.json exists
if [ -f "tsconfig.json" ] && ! command_exists tsc; then
    print_warning "TypeScript not found globally, will use local installation"
fi

print_success "All requirements met"

# NEW: Cleanup temp directories first
if [ "$NO_TEMP_CLEAN" = false ]; then
    cleanup_node_temp
fi

# NEW: Perform bundle analysis before build
if [ "$NO_ANALYSIS" = false ]; then
    bundle_analysis
fi

# Step 1: Clean everything if not skipped
if [ "$NO_CLEAN" = false ]; then
    print_status "🧹 Purging all existing builds..."
    rm -rf dist/
    rm -rf build/
    rm -rf out/
    rm -rf .next/
    rm -rf .nuxt/
    rm -rf .output/
    rm -rf coverage/
    rm -f tsconfig.tsbuildinfo
    find . -name "*.tsbuildinfo" -delete 2>/dev/null || true
    print_success "All build artifacts purged"
fi

# Step 2: Install/update dependencies
print_status "📦 Installing/updating dependencies..."

case $PKG_MANAGER in
    npm)
        npm ci || npm install
        ;;
    yarn)
        yarn install --frozen-lockfile || yarn install
        ;;
    pnpm)
        pnpm install --frozen-lockfile || pnpm install
        ;;
esac

if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies"
    exit 1
fi

print_success "Dependencies ready"

# Step 3: Auto-detect bundler if not specified
if [ "$BUNDLER" = "auto" ]; then
    if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
        BUNDLER="vite"
    elif [ -f "webpack.config.js" ] || [ -f "webpack.config.ts" ]; then
        BUNDLER="webpack"
    elif [ -f "rollup.config.js" ] || [ -f "rollup.config.ts" ]; then
        BUNDLER="rollup"
    elif grep -q "esbuild" package.json; then
        BUNDLER="esbuild"
    elif [ -f "next.config.js" ]; then
        BUNDLER="nextjs"
    elif [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.js" ]; then
        BUNDLER="nuxt"
    else
        BUNDLER="tsc"  # Fallback to TypeScript compiler
    fi
fi

print_info "Using bundler: $BUNDLER"

# Step 4: Configure build based on target and bundler
print_status "🎯 Configuring build for target: $TARGET"

BUILD_CMD=""
case $BUNDLER in
    vite)
        BUILD_CMD="$PKG_MANAGER run build"
        if [ "$ANALYZE" = true ]; then
            BUILD_CMD="$BUILD_CMD --analyze"
        fi
        ;;
    webpack)
        BUILD_CMD="$PKG_MANAGER run build"
        if [ "$MODE" = "production" ]; then
            BUILD_CMD="$BUILD_CMD --mode production"
        fi
        if [ "$ANALYZE" = true ]; then
            BUILD_CMD="webpack-bundle-analyzer dist/static/js/*.js"
        fi
        ;;
    rollup)
        BUILD_CMD="$PKG_MANAGER run build"
        ;;
    esbuild)
        BUILD_CMD="$PKG_MANAGER run build"
        ;;
    nextjs)
        BUILD_CMD="$PKG_MANAGER run build"
        if [ "$TARGET" = "node" ]; then
            BUILD_CMD="$BUILD_CMD && $PKG_MANAGER run start"
        fi
        ;;
    nuxt)
        BUILD_CMD="$PKG_MANAGER run build"
        ;;
    tsc)
        BUILD_CMD="tsc"
        if [ "$OPTIMIZE" = true ]; then
            BUILD_CMD="$BUILD_CMD --build --force"
        fi
        ;;
    *)
        print_error "Unsupported bundler: $BUNDLER"
        exit 1
        ;;
esac

# Step 5: Build the application
print_status "🏗️ Building TypeScript/JavaScript application..."
print_status "Mode: $MODE, Target: $TARGET, Bundler: $BUNDLER"

# Set environment variables
export NODE_ENV="$MODE"
if [ "$OPTIMIZE" = true ]; then
    export NODE_OPTIONS="--max-old-space-size=8192"
fi

# Execute build
print_info "Build command: $BUILD_CMD"
eval $BUILD_CMD
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    print_error "Build failed"
    exit 1
fi

print_success "Build completed successfully"

# Step 6: Target-specific post-processing
case $TARGET in
    electron)
        print_status "🔌 Building Electron application..."
        if command_exists electron-builder; then
            electron-builder --publish=never
        elif command_exists electron-packager; then
            electron-packager . --platform=darwin --arch=x64 --out=dist/
        else
            print_warning "No Electron packaging tool found"
        fi
        ;;
    pwa)
        print_status "📱 Generating PWA manifest and service worker..."
        if [ -f "src/sw.js" ] || [ -f "public/sw.js" ]; then
            print_success "Service worker found"
        else
            print_warning "No service worker found for PWA"
        fi
        ;;
    node)
        print_status "🐧 Preparing Node.js deployment..."
        if [ -f "dist/main.js" ] || [ -f "build/main.js" ]; then
            chmod +x dist/main.js 2>/dev/null || chmod +x build/main.js 2>/dev/null || true
            print_success "Node.js executable prepared"
        fi
        ;;
esac

# Step 7: Docker build (if requested)
if [ "$DOCKER" = true ]; then
    print_status "🐳 Building Docker image..."
    
    if [ ! -f "Dockerfile" ]; then
        print_status "Creating basic Dockerfile..."
        cat > Dockerfile << EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 3000
CMD ["node", "dist/main.js"]
EOF
    fi
    
    APP_NAME=$(jq -r '.name' package.json 2>/dev/null || echo "my-app")
    docker build -t "$APP_NAME:latest" .
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built: $APP_NAME:latest"
    else
        print_error "Docker build failed"
    fi
fi

# Step 8: Bundle analysis (if requested)
if [ "$ANALYZE" = true ]; then
    print_status "📊 Generating bundle analysis..."
    
    case $BUNDLER in
        webpack)
            if command_exists webpack-bundle-analyzer; then
                webpack-bundle-analyzer dist/static/js/*.js --mode static --open false --report dist/bundle-report.html
            fi
            ;;
        vite)
            if [ -f "dist/stats.json" ]; then
                npx vite-bundle-analyzer dist/stats.json
            fi
            ;;
        *)
            if command_exists bundlesize; then
                bundlesize
            fi
            ;;
    esac
fi

# NEW: Post-build bundle size analysis
print_status "🔍 Post-build size analysis..."

if [ -d "dist" ]; then
    TOTAL_SIZE=$(du -sh dist/ 2>/dev/null | cut -f1)
    print_info "Total build output size: $TOTAL_SIZE"
    
    # Find and report on main bundle files
    find dist -name "*.js" -o -name "*.css" -o -name "*.html" | head -10 | while read -r file; do
        if [ -f "$file" ]; then
            SIZE=$(ls -lah "$file" | awk '{print $5}')
            NAME=$(basename "$file")
            
            # Check file size
            SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
            SIZE_KB=$((SIZE_BYTES / 1024))
            
            if [ $SIZE_KB -gt 1000 ]; then
                print_warning "  ⚠️  $NAME: $SIZE (LARGE)"
            elif [ $SIZE_KB -gt 250 ]; then
                print_info "  📦 $NAME: $SIZE"
            else
                print_success "  ✓ $NAME: $SIZE"
            fi
        fi
    done
    
    # Check for source maps
    SOURCEMAP_COUNT=$(find dist -name "*.map" | wc -l)
    if [ $SOURCEMAP_COUNT -gt 0 ]; then
        SOURCEMAP_SIZE=$(find dist -name "*.map" -exec du -sh {} + | awk '{sum+=$1} END {print sum "K"}')
        print_info "Source maps: $SOURCEMAP_COUNT files ($SOURCEMAP_SIZE)"
    fi
fi

# Step 9: Display build results
print_status "📋 Build Results Summary:"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"

print_success "🎉 TypeScript/JavaScript build completed successfully!"
echo ""

# Display build information
print_info "📊 Build Information:"
echo "   Mode: $MODE"
echo "   Target: $TARGET"
echo "   Bundler: $BUNDLER"
echo "   Package Manager: $PKG_MANAGER"
echo "   Node.js: $NODE_VERSION"

if [ "$DOCKER" = true ]; then
    APP_NAME=$(jq -r '.name' package.json 2>/dev/null || echo "my-app")
    echo "   Docker Image: $APP_NAME:latest"
fi

echo ""

# Display output files
if [ -d "dist" ]; then
    print_info "📁 Output files:"
    ls -lah dist/ | head -10 | while read -r line; do
        if [[ $line == *".js"* ]] || [[ $line == *".css"* ]] || [[ $line == *".html"* ]]; then
            SIZE=$(echo $line | awk '{print $5}')
            NAME=$(echo $line | awk '{print $9}')
            echo "   ✓ $NAME ($SIZE)"
        fi
    done
elif [ -d "build" ]; then
    print_info "📁 Output files in build/:"
    ls -lah build/ | head -5 | tail -n +2 | while read -r line; do
        SIZE=$(echo $line | awk '{print $5}')
        NAME=$(echo $line | awk '{print $9}')
        echo "   ✓ $NAME ($SIZE)"
    done
else
    print_warning "No dist/ or build/ directory found"
fi

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"
print_success "🎉 TypeScript/JavaScript build process finished!"

OUTPUT_DIR="dist"
[ -d "build" ] && OUTPUT_DIR="build"
print_status "📁 All outputs are in: ./$OUTPUT_DIR/"

# Deployment instructions
echo ""
print_info "🚀 Deployment options:"
case $TARGET in
    web)
        print_info "  Static hosting: Upload $OUTPUT_DIR/ to your web server"
        print_info "  CDN deployment: Use with Netlify, Vercel, or AWS S3"
        ;;
    node)
        print_info "  Node.js server: node $OUTPUT_DIR/main.js"
        print_info "  PM2 process: pm2 start $OUTPUT_DIR/main.js --name myapp"
        ;;
    electron)
        print_info "  Desktop app: Check dist/ for platform-specific packages"
        ;;
    pwa)
        print_info "  PWA hosting: Upload to HTTPS server with service worker"
        ;;
esac

if [ "$DOCKER" = true ]; then
    APP_NAME=$(jq -r '.name' package.json 2>/dev/null || echo "my-app")
    print_info "  Docker: docker run -p 3000:3000 $APP_NAME:latest"
fi

# Performance recommendations
echo ""
print_info "⚡ Performance recommendations:"
print_info "  • Enable gzip/brotli compression on server"
print_info "  • Use CDN for static assets"
print_info "  • Implement proper caching headers"
print_info "  • Monitor bundle size with CI/CD"
if [ "$ANALYZE" = true ] && [ -f "dist/bundle-report.html" ]; then
    print_info "  • Review bundle analysis: open dist/bundle-report.html"
fi
```

## Script 2: run-ts-dev.sh (Development Mode)

```bash
#!/bin/bash

# Run TypeScript/JavaScript App in Development Mode
# Hot reloading and development server

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

# Detect package manager
detect_package_manager() {
    if [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    else
        echo "npm"
    fi
}

print_status "🚀 Starting TypeScript/JavaScript development server..."

# Check for Node.js
if ! command_exists node; then
    print_error "Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check for package.json
if [ ! -f "package.json" ]; then
    print_error "No package.json found. Make sure you're in the project root."
    exit 1
fi

PKG_MANAGER=$(detect_package_manager)
print_status "Using package manager: $PKG_MANAGER"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    print_status "Installing dependencies..."
    case $PKG_MANAGER in
        npm) npm install ;;
        yarn) yarn install ;;
        pnpm) pnpm install ;;
    esac
    
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    print_success "Dependencies installed"
fi

# Determine dev command
DEV_CMD=""
if grep -q '"dev"' package.json; then
    DEV_CMD="$PKG_MANAGER run dev"
elif grep -q '"start"' package.json; then
    DEV_CMD="$PKG_MANAGER run start"
elif grep -q '"serve"' package.json; then
    DEV_CMD="$PKG_MANAGER run serve"
elif [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
    DEV_CMD="$PKG_MANAGER exec vite"
elif [ -f "webpack.config.js" ]; then
    DEV_CMD="$PKG_MANAGER exec webpack serve"
else
    # Fallback to TypeScript watch mode
    if [ -f "tsconfig.json" ]; then
        DEV_CMD="$PKG_MANAGER exec tsc --watch"
    else
        print_error "Cannot determine development command"
        exit 1
    fi
fi

print_status "Development command: $DEV_CMD"
print_status "Starting development server..."
print_status "Press Ctrl+C to stop"
echo ""

# Set development environment
export NODE_ENV=development

# Run development server
eval $DEV_CMD

echo ""
print_success "Development server stopped"
```

## Script 3: ts-bundle-analyzer.sh (Bundle Analysis Tool)

```bash
#!/bin/bash

# 🔍 TYPESCRIPT/JAVASCRIPT BUNDLE ANALYZER
# Comprehensive analysis of bundle size and optimization opportunities

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

print_header "🔍 TYPESCRIPT/JAVASCRIPT BUNDLE ANALYSIS"

# Check if in Node.js project
if [ ! -f "package.json" ]; then
    print_error "No package.json found. Run this in your project root directory."
    exit 1
fi

PROJECT_NAME=$(jq -r '.name' package.json 2>/dev/null || echo "Unknown")
print_status "Analyzing project: $PROJECT_NAME"

# 1. Dependencies analysis
print_header "📦 DEPENDENCIES ANALYSIS"

if [ -f "package.json" ]; then
    PROD_DEPS=$(jq '.dependencies | length' package.json 2>/dev/null || echo "0")
    DEV_DEPS=$(jq '.devDependencies | length' package.json 2>/dev/null || echo "0")
    
    print_info "Production dependencies: $PROD_DEPS"
    print_info "Development dependencies: $DEV_DEPS"
    
    # Check for heavy dependencies
    HEAVY_DEPS=(lodash moment.js axios react react-dom vue angular @angular/core typescript webpack babel d3 three.js chart.js)
    
    echo ""
    print_info "Heavy dependencies detected:"
    for dep in "${HEAVY_DEPS[@]}"; do
        if jq -e ".dependencies[\"$dep\"] or .devDependencies[\"$dep\"]" package.json >/dev/null 2>&1; then
            VERSION=$(jq -r ".dependencies[\"$dep\"] // .devDependencies[\"$dep\"]" package.json)
            SIZE_ESTIMATE="Unknown"
            case $dep in
                lodash) SIZE_ESTIMATE="~70KB" ;;
                "moment.js") SIZE_ESTIMATE="~230KB" ;;
                axios) SIZE_ESTIMATE="~13KB" ;;
                react) SIZE_ESTIMATE="~40KB" ;;
                "react-dom") SIZE_ESTIMATE="~130KB" ;;
                vue) SIZE_ESTIMATE="~35KB" ;;
                "@angular/core") SIZE_ESTIMATE="~130KB" ;;
                typescript) SIZE_ESTIMATE="~40MB (dev)" ;;
                webpack) SIZE_ESTIMATE="~20MB (dev)" ;;
                d3) SIZE_ESTIMATE="~250KB" ;;
            esac
            print_warning "  ⚠️  $dep@$VERSION ($SIZE_ESTIMATE)"
        fi
    done
    
    # Alternative recommendations
    echo ""
    print_info "💡 Lighter alternatives:"
    if jq -e '.dependencies["lodash"]' package.json >/dev/null 2>&1; then
        print_info "  lodash → lodash-es (tree-shakable) or native JS"
    fi
    if jq -e '.dependencies["moment"]' package.json >/dev/null 2>&1; then
        print_info "  moment.js → date-fns or dayjs (~2-9KB)"
    fi
    if jq -e '.dependencies["axios"]' package.json >/dev/null 2>&1; then
        print_info "  axios → native fetch API (built-in)"
    fi
fi

# 2. Node modules analysis
print_header "📁 NODE_MODULES ANALYSIS"

if [ -d "node_modules" ]; then
    NODE_SIZE=$(du -sb node_modules 2>/dev/null | cut -f1)
    NODE_SIZE_HR=$(human_readable $NODE_SIZE)
    print_info "Total node_modules size: $NODE_SIZE_HR"
    
    # Size categories
    if [ $NODE_SIZE -gt 2147483648 ]; then
        print_warning "⚠️  HUGE: node_modules > 2GB - major optimization needed"
    elif [ $NODE_SIZE -gt 1073741824 ]; then
        print_warning "⚠️  LARGE: node_modules > 1GB - optimization recommended"
    elif [ $NODE_SIZE -gt 536870912 ]; then
        print_warning "⚠️  MEDIUM: node_modules > 500MB - consider cleanup"
    else
        print_success "✓ node_modules size acceptable"
    fi
    
    echo ""
    print_info "Top 10 largest packages:"
    du -sh node_modules/* 2>/dev/null | sort -hr | head -10 | while read size dir; do
        basename_dir=$(basename "$dir")
        # Convert size to numeric for comparison
        size_num=$(echo $size | sed 's/[^0-9]*//g')
        if [[ $size == *"G"* ]] || [[ $size == *"M"* && $size_num -gt 50 ]]; then
            print_warning "  ⚠️  $size - $basename_dir"
        else
            print_info "  📦 $size - $basename_dir"
        fi
    done
else
    print_warning "No node_modules directory found"
fi

# 3. Build output analysis
print_header "🏗️  BUILD OUTPUT ANALYSIS"

BUILD_DIRS=("dist" "build" "out" ".next/static" ".nuxt/dist")
BUILD_DIR=""

for dir in "${BUILD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        BUILD_DIR="$dir"
        break
    fi
done

if [ -n "$BUILD_DIR" ]; then
    BUILD_SIZE=$(du -sb "$BUILD_DIR" 2>/dev/null | cut -f1)
    BUILD_SIZE_HR=$(human_readable $BUILD_SIZE)
    print_info "Build output size ($BUILD_DIR): $BUILD_SIZE_HR"
    
    echo ""
    print_info "Bundle file analysis:"
    
    # JavaScript bundles
    find "$BUILD_DIR" -name "*.js" -not -path "*/node_modules/*" | while read -r jsfile; do
        if [ -f "$jsfile" ]; then
            SIZE=$(ls -lah "$jsfile" | awk '{print $5}')
            NAME=$(basename "$jsfile")
            SIZE_BYTES=$(ls -l "$jsfile" | awk '{print $5}')
            SIZE_KB=$((SIZE_BYTES / 1024))
            
            if [ $SIZE_KB -gt 1000 ]; then
                print_warning "  ⚠️  $NAME: $SIZE (LARGE JS)"
            elif [ $SIZE_KB -gt 250 ]; then
                print_info "  📦 $NAME: $SIZE"
            else
                print_success "  ✓ $NAME: $SIZE"
            fi
        fi
    done
    
    # CSS bundles
    find "$BUILD_DIR" -name "*.css" -not -path "*/node_modules/*" | while read -r cssfile; do
        if [ -f "$cssfile" ]; then
            SIZE=$(ls -lah "$cssfile" | awk '{print $5}')
            NAME=$(basename "$cssfile")
            SIZE_BYTES=$(ls -l "$cssfile" | awk '{print $5}')
            SIZE_KB=$((SIZE_BYTES / 1024))
            
            if [ $SIZE_KB -gt 100 ]; then
                print_warning "  ⚠️  $NAME: $SIZE (LARGE CSS)"
            else
                print_info "  🎨 $NAME: $SIZE"
            fi
        fi
    done
    
    # Source maps
    SOURCEMAP_COUNT=$(find "$BUILD_DIR" -name "*.map" | wc -l)
    if [ $SOURCEMAP_COUNT -gt 0 ]; then
        SOURCEMAP_SIZE=$(find "$BUILD_DIR" -name "*.map" -exec du -sb {} + | awk '{sum+=$1} END {print sum}')
        SOURCEMAP_SIZE_HR=$(human_readable $SOURCEMAP_SIZE)
        print_info "Source maps: $SOURCEMAP_COUNT files ($SOURCEMAP_SIZE_HR)"
        print_warning "  ⚠️  Consider removing source maps in production"
    fi
    
    # Assets
    ASSET_SIZE=$(find "$BUILD_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.svg" -o -name "*.gif" | xargs du -sb 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    if [ $ASSET_SIZE -gt 0 ]; then
        ASSET_SIZE_HR=$(human_readable $ASSET_SIZE)
        print_info "Static assets: $ASSET_SIZE_HR"
        
        # Find large assets
        find "$BUILD_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.svg" -o -name "*.gif" | while read -r asset; do
            if [ -f "$asset" ]; then
                SIZE_BYTES=$(ls -l "$asset" | awk '{print $5}')
                if [ $SIZE_BYTES -gt 102400 ]; then  # > 100KB
                    SIZE=$(ls -lah "$asset" | awk '{print $5}')
                    NAME=$(basename "$asset")
                    print_warning "  ⚠️  Large asset: $NAME ($SIZE)"
                fi
            fi
        done
    fi
else
    print_warning "No build directory found. Run a build first."
fi

# 4. TypeScript analysis
print_header "📘 TYPESCRIPT ANALYSIS"

if [ -f "tsconfig.json" ]; then
    print_info "TypeScript configuration: tsconfig.json found"
    
    # Check strict mode
    if jq -e '.compilerOptions.strict' tsconfig.json >/dev/null 2>&1; then
        STRICT_MODE=$(jq -r '.compilerOptions.strict' tsconfig.json)
        if [ "$STRICT_MODE" = "true" ]; then
            print_success "✓ Strict mode enabled"
        else
            print_warning "⚠️  Strict mode disabled"
        fi
    fi
    
    # Check target
    TARGET=$(jq -r '.compilerOptions.target' tsconfig.json 2>/dev/null || echo "not set")
    print_info "Compilation target: $TARGET"
    
    # Check module system
    MODULE=$(jq -r '.compilerOptions.module' tsconfig.json 2>/dev/null || echo "not set")
    print_info "Module system: $MODULE"
    
    # Source files
    if [ -d "src" ]; then
        TS_FILES=$(find src -name "*.ts" -o -name "*.tsx" | wc -l)
        JS_FILES=$(find src -name "*.js" -o -name "*.jsx" | wc -l)
        TOTAL_LINES=$(find src \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        
        print_info "TypeScript files: $TS_FILES"
        print_info "JavaScript files: $JS_FILES"
        print_info "Total lines of code: $TOTAL_LINES"
    fi
else
    print_warning "No tsconfig.json found"
fi

# 5. Build tool analysis
print_header "🔧 BUILD TOOLS ANALYSIS"

# Detect build tools
BUILD_TOOLS=()
if [ -f "webpack.config.js" ] || [ -f "webpack.config.ts" ]; then
    BUILD_TOOLS+=("Webpack")
fi
if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
    BUILD_TOOLS+=("Vite")
fi
if [ -f "rollup.config.js" ] || [ -f "rollup.config.ts" ]; then
    BUILD_TOOLS+=("Rollup")
fi
if jq -e '.devDependencies.esbuild' package.json >/dev/null 2>&1; then
    BUILD_TOOLS+=("esbuild")
fi
if [ -f "next.config.js" ]; then
    BUILD_TOOLS+=("Next.js")
fi
if [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.js" ]; then
    BUILD_TOOLS+=("Nuxt.js")
fi

if [ ${#BUILD_TOOLS[@]} -eq 0 ]; then
    print_warning "No build tools detected"
else
    print_info "Build tools detected: ${BUILD_TOOLS[*]}"
fi

# Check for optimization features
echo ""
print_info "Optimization features:"
if jq -e '.devDependencies["terser-webpack-plugin"] or .devDependencies.terser' package.json >/dev/null 2>&1; then
    print_success "✓ JavaScript minification (Terser)"
fi
if jq -e '.devDependencies["css-minimizer-webpack-plugin"] or .devDependencies["mini-css-extract-plugin"]' package.json >/dev/null 2>&1; then
    print_success "✓ CSS optimization"
fi
if jq -e '.devDependencies["html-webpack-plugin"]' package.json >/dev/null 2>&1; then
    print_success "✓ HTML optimization"
fi
if jq -e '.devDependencies["compression-webpack-plugin"]' package.json >/dev/null 2>&1; then
    print_success "✓ Gzip compression"
fi

# 6. Performance recommendations
print_header "⚡ OPTIMIZATION RECOMMENDATIONS"

print_info "📦 Bundle optimization:"
print_info "  • Enable tree shaking in your bundler"
print_info "  • Use dynamic imports for code splitting"
print_info "  • Implement lazy loading for components"
print_info "  • Remove unused dependencies"
print_info "  • Use bundle analysis tools regularly"

print_info "🎯 Dependency optimization:"
print_info "  • Replace heavy libraries with lighter alternatives"
print_info "  • Use ES modules versions (lodash-es vs lodash)"
print_info "  • Consider native browser APIs over polyfills"
print_info "  • Audit dependencies with 'npm audit' or 'yarn audit'"

print_info "🏗️  Build optimization:"
print_info "  • Enable minification and compression"
print_info "  • Generate source maps only for development"
print_info "  • Optimize images (WebP, proper sizing)"
print_info "  • Use CDN for static assets"

print_info "📊 Monitoring:"
print_info "  • Set up bundle size budgets in CI/CD"
print_info "  • Use Lighthouse for performance audits"
print_info "  • Monitor real user metrics (RUM)"
print_info "  • Regular dependency updates"

# 7. Size targets
print_header "🎯 SIZE TARGETS & BENCHMARKS"

print_info "Web application size guidelines:"
print_success "  ✓ Excellent: Initial JS < 100KB gzipped"
print_info "  📊 Good: Initial JS < 250KB gzipped"
print_warning "  ⚠️  Acceptable: Initial JS < 500KB gzipped"
print_error "  ❌ Needs optimization: Initial JS > 500KB gzipped"

echo ""
print_info "Quick optimization commands:"
echo "  npm audit fix              # Fix security issues"
echo "  npx depcheck               # Find unused dependencies"
echo "  npx webpack-bundle-analyzer dist/static/js/*.js"
echo "  npx bundlesize             # Check bundle size limits"

print_header "✅ BUNDLE ANALYSIS COMPLETE"

print_info "📈 Regular maintenance tasks:"
print_info "  • Run bundle analysis after major changes"
print_info "  • Update dependencies monthly"
print_info "  • Monitor performance metrics"
print_info "  • Review and remove unused code"
```

## TypeScript Configuration Templates

### tsconfig.json (Optimized for Production)

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "moduleResolution": "node",
    "allowImportingTsExtensions": false,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### package.json Template

```json
{
  "name": "my-typescript-app",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "build:analyze": "vite build --analyze",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "type-check": "tsc --noEmit",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "bundle-size": "bundlesize"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.22",
    "@typescript-eslint/eslint-plugin": "^7.2.0",
    "@typescript-eslint/parser": "^7.2.0",
    "@vitejs/plugin-react": "^4.2.1",
    "bundlesize": "^0.18.1",
    "eslint": "^8.57.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.6",
    "typescript": "^5.2.2",
    "vite": "^5.2.0",
    "vitest": "^1.4.0"
  },
  "bundlesize": [
    {
      "path": "dist/assets/*.js",
      "maxSize": "250KB"
    },
    {
      "path": "dist/assets/*.css",
      "maxSize": "50KB"
    }
  ]
}
```

Now let me create the HTML/CSS/Web build system documentation: