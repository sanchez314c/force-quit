# Complete Multi-Platform HTML/CSS/Web Build System with Optimization

## AMENDMENTS - HTML/CSS/WEB CONFIGURATION:

**Important**: This configuration has been adapted for modern HTML/CSS/JavaScript web applications with comprehensive optimization.

**Key Features**:
- Multi-platform web deployment (Static, CDN, Docker, PWA)
- Modern CSS preprocessing (Sass, Less, PostCSS, Tailwind)
- JavaScript bundling and optimization
- HTML templating and minification
- Image optimization and WebP conversion
- Progressive Web App (PWA) generation
- Critical CSS extraction
- Service Worker generation
- Comprehensive asset optimization
- CDN deployment automation
- Integrated performance auditing

This build system provides comprehensive support for building modern web applications with full optimization, PWA capabilities, and multi-platform deployment.

## Build System Requirements

1. **Node.js 18+** and **npm/yarn/pnpm**
2. **Modern browsers** as build targets
3. **Build tools**: PostCSS, Sass, Webpack/Vite/Parcel
4. **Optional**: Docker, Service Worker tools, CDN CLI tools
5. **NEW**: Automatic performance optimization and PWA generation

## Required Project Structure (MODERN WEB)

```
html-css-web-app/
├── src/                    # Source code
│   ├── index.html         # Main HTML template
│   ├── css/               # Stylesheets
│   │   ├── main.css       # Main stylesheet
│   │   ├── components/    # Component styles
│   │   └── utilities/     # Utility classes
│   ├── js/                # JavaScript
│   │   ├── main.js        # Main script
│   │   ├── components/    # Component scripts
│   │   └── utils/         # Utilities
│   ├── assets/            # Images, fonts, etc.
│   │   ├── images/
│   │   ├── fonts/
│   │   └── icons/
│   └── templates/         # HTML templates
├── public/                # Static public assets
│   ├── favicon.ico
│   ├── manifest.json      # PWA manifest
│   └── robots.txt
├── dist/                  # Build outputs
├── build/                 # Alternative build output
├── node_modules/          # Dependencies
├── tests/                 # Test files
├── docs/                  # Documentation
├── package.json           # Project configuration
├── postcss.config.js      # PostCSS configuration
├── tailwind.config.js     # Tailwind configuration (if used)
├── webpack.config.js      # Webpack configuration (if used)
├── vite.config.js         # Vite configuration (if used)
├── .env                   # Environment variables
├── .gitignore             # Git ignore rules
├── Dockerfile             # Docker configuration (optional)
└── sw.js                  # Service worker (for PWA)
```

## Script 1: compile-build-dist-web.sh (MAIN BUILD SCRIPT)

```bash
#!/bin/bash

# Complete Multi-Platform HTML/CSS/Web Build Script
# Supports modern web tools and deployment targets
# Includes automatic optimization and PWA generation

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

# Function to detect package manager
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

# NEW: Function to cleanup web build temp directories
cleanup_web_temp() {
    print_status "🧹 Cleaning web build temp directories..."
    
    # Clean npm/yarn/pnpm cache
    if command_exists npm; then
        npm cache clean --force 2>/dev/null || true
    fi
    if command_exists yarn; then
        yarn cache clean 2>/dev/null || true
    fi
    if command_exists pnpm; then
        pnpm store prune 2>/dev/null || true
    fi
    
    # Clean build tool caches
    rm -rf node_modules/.cache 2>/dev/null || true
    rm -rf .parcel-cache 2>/dev/null || true
    rm -rf .vite 2>/dev/null || true
    rm -rf .next 2>/dev/null || true
    rm -rf .nuxt 2>/dev/null || true
    
    # Clean CSS and PostCSS caches
    find . -name ".postcssrc*" -delete 2>/dev/null || true
    find . -name ".sass-cache" -exec rm -rf {} + 2>/dev/null || true
    
    print_success "Web build temp cleanup completed"
}

# NEW: Function to perform web asset analysis
web_asset_analysis() {
    print_status "🔍 Analyzing web assets..."
    
    # Check source files
    if [ -d "src" ]; then
        HTML_FILES=$(find src -name "*.html" | wc -l)
        CSS_FILES=$(find src -name "*.css" -o -name "*.scss" -o -name "*.sass" -o -name "*.less" | wc -l)
        JS_FILES=$(find src -name "*.js" -o -name "*.ts" | wc -l)
        
        print_info "HTML files: $HTML_FILES"
        print_info "CSS/Sass/Less files: $CSS_FILES"
        print_info "JavaScript/TypeScript files: $JS_FILES"
        
        # Check for large source files
        find src -name "*.css" -o -name "*.js" | while read -r file; do
            if [ -f "$file" ]; then
                SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
                SIZE_KB=$((SIZE_BYTES / 1024))
                if [ $SIZE_KB -gt 50 ]; then
                    print_warning "⚠️  Large source file: $(basename "$file") (${SIZE_KB}KB)"
                fi
            fi
        done
    fi
    
    # Check assets
    if [ -d "src/assets" ] || [ -d "public" ]; then
        ASSETS_DIR="src/assets"
        [ -d "public" ] && ASSETS_DIR="public"
        
        if [ -d "$ASSETS_DIR" ]; then
            IMAGES=$(find "$ASSETS_DIR" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" | wc -l)
            FONTS=$(find "$ASSETS_DIR" -name "*.woff" -o -name "*.woff2" -o -name "*.ttf" -o -name "*.otf" | wc -l)
            
            print_info "Image files: $IMAGES"
            print_info "Font files: $FONTS"
            
            # Check for large assets
            find "$ASSETS_DIR" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" | while read -r file; do
                if [ -f "$file" ]; then
                    SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
                    SIZE_KB=$((SIZE_BYTES / 1024))
                    if [ $SIZE_KB -gt 500 ]; then
                        print_warning "⚠️  Large image: $(basename "$file") (${SIZE_KB}KB)"
                    fi
                fi
            done
        fi
    fi
    
    # Check for CSS frameworks
    CSS_FRAMEWORKS=(bootstrap tailwindcss bulma foundation materialize-css)
    for framework in "${CSS_FRAMEWORKS[@]}"; do
        if grep -q "\"$framework\"" package.json 2>/dev/null; then
            print_info "CSS Framework: $framework detected"
        fi
    done
    
    # Check for JavaScript frameworks
    JS_FRAMEWORKS=(react vue angular svelte)
    for framework in "${JS_FRAMEWORKS[@]}"; do
        if grep -q "\"$framework\"" package.json 2>/dev/null; then
            print_info "JavaScript Framework: $framework detected"
        fi
    done
}

# Function to display help
show_help() {
    echo "Complete Multi-Platform HTML/CSS/Web Build Script"
    echo ""
    echo "Usage: ./compile-build-dist-web.sh [options]"
    echo ""
    echo "Options:"
    echo "  --no-clean         Skip cleaning build artifacts"
    echo "  --no-temp-clean    Skip system temp cleanup"
    echo "  --no-analysis      Skip asset analysis"
    echo "  --mode MODE        Build mode (development, production)"
    echo "  --target TARGET    Build target (static, pwa, spa, ssr)"
    echo "  --bundler BUNDLER  Bundler to use (webpack, vite, parcel, rollup)"
    echo "  --optimize         Enable aggressive optimization"
    echo "  --minify           Minify HTML, CSS, and JavaScript"
    echo "  --compress         Enable gzip/brotli compression"
    echo "  --critical-css     Extract critical CSS"
    echo "  --webp             Convert images to WebP format"
    echo "  --pwa              Generate PWA with service worker"
    echo "  --docker           Build Docker image"
    echo "  --audit            Run performance audit"
    echo "  --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./compile-build-dist-web.sh                    # Standard production build"
    echo "  ./compile-build-dist-web.sh --pwa --optimize   # PWA with optimizations"
    echo "  ./compile-build-dist-web.sh --target ssr       # Server-side rendering build"
    echo "  ./compile-build-dist-web.sh --docker --audit   # Docker build with audit"
}

# Parse command line arguments
NO_CLEAN=false
NO_TEMP_CLEAN=false
NO_ANALYSIS=false
MODE="production"
TARGET="static"
BUNDLER="auto"
OPTIMIZE=false
MINIFY=false
COMPRESS=false
CRITICAL_CSS=false
WEBP=false
PWA=false
DOCKER=false
AUDIT=false

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
            MINIFY=true
            COMPRESS=true
            shift
            ;;
        --minify)
            MINIFY=true
            shift
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        --critical-css)
            CRITICAL_CSS=true
            shift
            ;;
        --webp)
            WEBP=true
            shift
            ;;
        --pwa)
            PWA=true
            shift
            ;;
        --docker)
            DOCKER=true
            shift
            ;;
        --audit)
            AUDIT=true
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
print_status "Checking web build requirements..."

# Check if we have any HTML files to work with
if [ ! -d "src" ] && [ ! -f "index.html" ] && [ ! -f "src/index.html" ]; then
    print_error "No HTML source files found. Expected src/ directory or index.html"
    exit 1
fi

# Check for Node.js if package.json exists
if [ -f "package.json" ]; then
    if ! command_exists node; then
        print_error "Node.js is not installed but package.json found."
        print_info "  Install Node.js from: https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(get_node_version)
    PKG_MANAGER=$(detect_package_manager)
    print_info "Node.js version: $NODE_VERSION"
    print_info "Package manager: $PKG_MANAGER"
fi

print_success "Requirements check passed"

# NEW: Cleanup temp directories first
if [ "$NO_TEMP_CLEAN" = false ]; then
    cleanup_web_temp
fi

# NEW: Perform asset analysis before build
if [ "$NO_ANALYSIS" = false ]; then
    web_asset_analysis
fi

# Step 1: Clean everything if not skipped
if [ "$NO_CLEAN" = false ]; then
    print_status "🧹 Purging all existing builds..."
    rm -rf dist/
    rm -rf build/
    rm -rf public/build/
    rm -rf .parcel-cache/
    rm -rf .cache/
    print_success "All build artifacts purged"
fi

# Step 2: Install dependencies (if package.json exists)
if [ -f "package.json" ]; then
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
fi

# Step 3: Auto-detect bundler if not specified
if [ "$BUNDLER" = "auto" ]; then
    if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
        BUNDLER="vite"
    elif [ -f "webpack.config.js" ] || [ -f "webpack.config.ts" ]; then
        BUNDLER="webpack"
    elif [ -f "parcel.json" ] || grep -q "parcel" package.json 2>/dev/null; then
        BUNDLER="parcel"
    elif [ -f "rollup.config.js" ] || [ -f "rollup.config.ts" ]; then
        BUNDLER="rollup"
    elif [ -f "package.json" ]; then
        BUNDLER="simple"  # Simple build without bundler
    else
        BUNDLER="copy"  # Just copy files
    fi
fi

print_info "Using build method: $BUNDLER"

# Step 4: Create output directory
mkdir -p dist

# Step 5: Build based on method
print_status "🏗️ Building web application..."
print_status "Mode: $MODE, Target: $TARGET, Method: $BUNDLER"

case $BUNDLER in
    vite)
        if [ -f "package.json" ]; then
            BUILD_CMD="$PKG_MANAGER run build"
            if [ "$MODE" = "development" ]; then
                BUILD_CMD="$PKG_MANAGER run dev"
            fi
        else
            print_error "Vite requires package.json configuration"
            exit 1
        fi
        ;;
    webpack)
        if [ -f "package.json" ]; then
            BUILD_CMD="$PKG_MANAGER run build"
            if [ "$MODE" = "production" ]; then
                export NODE_ENV=production
            fi
        else
            print_error "Webpack requires package.json configuration"
            exit 1
        fi
        ;;
    parcel)
        if [ -f "src/index.html" ]; then
            BUILD_CMD="npx parcel build src/index.html --dist-dir dist"
        elif [ -f "index.html" ]; then
            BUILD_CMD="npx parcel build index.html --dist-dir dist"
        else
            print_error "Parcel requires an HTML entry point"
            exit 1
        fi
        ;;
    rollup)
        BUILD_CMD="npx rollup -c"
        ;;
    simple)
        # Simple build without bundler
        print_status "Building with simple file processing..."
        
        # Copy HTML files
        if [ -d "src" ]; then
            cp -r src/* dist/ 2>/dev/null || true
        elif [ -f "index.html" ]; then
            cp index.html dist/
        fi
        
        # Copy public assets
        if [ -d "public" ]; then
            cp -r public/* dist/ 2>/dev/null || true
        fi
        
        BUILD_CMD=""  # No command needed, files already copied
        ;;
    copy)
        # Just copy files
        print_status "Copying files to dist..."
        
        if [ -d "src" ]; then
            cp -r src/* dist/
        else
            cp *.html dist/ 2>/dev/null || true
            cp *.css dist/ 2>/dev/null || true
            cp *.js dist/ 2>/dev/null || true
        fi
        
        BUILD_CMD=""  # No command needed
        ;;
    *)
        print_error "Unsupported bundler: $BUNDLER"
        exit 1
        ;;
esac

# Execute build command
if [ -n "$BUILD_CMD" ]; then
    print_info "Build command: $BUILD_CMD"
    eval $BUILD_CMD
    BUILD_RESULT=$?
    
    if [ $BUILD_RESULT -ne 0 ]; then
        print_error "Build failed"
        exit 1
    fi
fi

print_success "Build completed successfully"

# Step 6: Post-build optimizations
if [ "$OPTIMIZE" = true ] || [ "$MINIFY" = true ]; then
    print_status "⚡ Applying optimizations..."
    
    # Minify HTML
    if command_exists html-minifier-terser && find dist -name "*.html" | head -1 | grep -q "."; then
        print_status "Minifying HTML files..."
        find dist -name "*.html" -exec html-minifier-terser --collapse-whitespace --remove-comments --remove-optional-tags --remove-redundant-attributes --use-short-doctype --remove-empty-attributes --input {} --output {} \; 2>/dev/null || true
        print_success "HTML minification completed"
    fi
    
    # Minify CSS
    if command_exists cleancss && find dist -name "*.css" | head -1 | grep -q "."; then
        print_status "Minifying CSS files..."
        find dist -name "*.css" -exec cleancss -o {} {} \; 2>/dev/null || true
        print_success "CSS minification completed"
    fi
    
    # Minify JavaScript
    if command_exists terser && find dist -name "*.js" | head -1 | grep -q "."; then
        print_status "Minifying JavaScript files..."
        find dist -name "*.js" ! -name "*.min.js" -exec sh -c 'terser "$1" -o "$1" -c -m' _ {} \; 2>/dev/null || true
        print_success "JavaScript minification completed"
    fi
fi

# Step 7: Image optimization
if [ "$WEBP" = true ]; then
    print_status "🖼️ Converting images to WebP..."
    
    if command_exists cwebp; then
        find dist -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | while read -r img; do
            if [ -f "$img" ]; then
                webp_file="${img%.*}.webp"
                cwebp -q 80 "$img" -o "$webp_file" 2>/dev/null || true
                print_info "Converted: $(basename "$img") → $(basename "$webp_file")"
            fi
        done
        print_success "WebP conversion completed"
    else
        print_warning "cwebp not found, skipping WebP conversion"
        print_info "Install with: brew install webp (macOS) or apt install webp (Linux)"
    fi
fi

# Step 8: Critical CSS extraction
if [ "$CRITICAL_CSS" = true ]; then
    print_status "🎯 Extracting critical CSS..."
    
    if command_exists critical; then
        find dist -name "*.html" | head -1 | while read -r html_file; do
            if [ -f "$html_file" ]; then
                critical "$html_file" --base dist --inline --extract 2>/dev/null || true
            fi
        done
        print_success "Critical CSS extraction completed"
    else
        print_warning "critical command not found"
        print_info "Install with: npm install -g critical"
    fi
fi

# Step 9: PWA generation
if [ "$PWA" = true ]; then
    print_status "📱 Generating PWA components..."
    
    # Create manifest.json if not exists
    if [ ! -f "dist/manifest.json" ]; then
        APP_NAME=$(basename "$(pwd)")
        cat > dist/manifest.json << EOF
{
  "name": "$APP_NAME",
  "short_name": "$APP_NAME",
  "description": "Progressive Web App built with modern tooling",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [
    {
      "src": "icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
EOF
        print_success "Created manifest.json"
    fi
    
    # Create service worker if not exists
    if [ ! -f "dist/sw.js" ]; then
        cat > dist/sw.js << 'EOF'
const CACHE_NAME = 'pwa-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/main.css',
  '/main.js'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});
EOF
        print_success "Created service worker"
    fi
    
    # Add PWA meta tags to HTML files
    find dist -name "*.html" | while read -r html_file; do
        if [ -f "$html_file" ] && ! grep -q "manifest.json" "$html_file"; then
            # Add manifest link and PWA meta tags
            sed -i '' '/<head>/a\
  <link rel="manifest" href="/manifest.json">\
  <meta name="theme-color" content="#000000">\
  <meta name="apple-mobile-web-app-capable" content="yes">\
  <meta name="apple-mobile-web-app-status-bar-style" content="default">\
' "$html_file" 2>/dev/null || true
            
            # Add service worker registration
            if ! grep -q "serviceWorker" "$html_file"; then
                cat >> "$html_file" << 'EOF'
<script>
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js')
    .then((registration) => console.log('SW registered'))
    .catch((error) => console.log('SW registration failed'));
}
</script>
EOF
            fi
        fi
    done
    
    print_success "PWA components generated"
fi

# Step 10: Compression
if [ "$COMPRESS" = true ]; then
    print_status "🗜️ Compressing assets..."
    
    # Gzip compression
    if command_exists gzip; then
        find dist -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.json" | while read -r file; do
            if [ -f "$file" ]; then
                gzip -k -9 "$file" 2>/dev/null || true
            fi
        done
        print_success "Gzip compression completed"
    fi
    
    # Brotli compression
    if command_exists brotli; then
        find dist -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.json" | while read -r file; do
            if [ -f "$file" ]; then
                brotli -k -9 "$file" 2>/dev/null || true
            fi
        done
        print_success "Brotli compression completed"
    fi
fi

# Step 11: Docker build (if requested)
if [ "$DOCKER" = true ]; then
    print_status "🐳 Building Docker image..."
    
    if [ ! -f "Dockerfile" ]; then
        print_status "Creating nginx Dockerfile..."
        cat > Dockerfile << EOF
FROM nginx:alpine
COPY dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
        
        # Create nginx configuration
        cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    sendfile        on;
    keepalive_timeout  65;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/x-javascript
        application/xml+rss
        application/javascript
        application/json;
    
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
    fi
    
    APP_NAME=$(basename "$(pwd)")
    docker build -t "$APP_NAME:latest" .
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built: $APP_NAME:latest"
    else
        print_error "Docker build failed"
    fi
fi

# Step 12: Performance audit (if requested)
if [ "$AUDIT" = true ]; then
    print_status "🔍 Running performance audit..."
    
    if command_exists lighthouse; then
        if [ -f "dist/index.html" ]; then
            # Start a simple HTTP server for auditing
            if command_exists python3; then
                (cd dist && python3 -m http.server 8080) &
                SERVER_PID=$!
                sleep 2
                
                # Run Lighthouse audit
                lighthouse http://localhost:8080 --output json --output html --output-path dist/lighthouse-report
                
                # Stop the server
                kill $SERVER_PID 2>/dev/null || true
                
                print_success "Lighthouse audit completed: dist/lighthouse-report.html"
            else
                print_warning "Python3 not found, cannot run local server for audit"
            fi
        fi
    else
        print_warning "Lighthouse not found"
        print_info "Install with: npm install -g lighthouse"
    fi
fi

# Step 13: Post-build analysis
print_status "🔍 Post-build analysis..."

if [ -d "dist" ]; then
    TOTAL_SIZE=$(du -sh dist/ 2>/dev/null | cut -f1)
    print_info "Total build output size: $TOTAL_SIZE"
    
    # Analyze file types and sizes
    find dist -type f | while read -r file; do
        if [ -f "$file" ]; then
            SIZE=$(ls -lah "$file" | awk '{print $5}')
            NAME=$(basename "$file")
            EXT="${NAME##*.}"
            
            case $EXT in
                html)
                    SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
                    SIZE_KB=$((SIZE_BYTES / 1024))
                    if [ $SIZE_KB -gt 100 ]; then
                        print_warning "  ⚠️  Large HTML: $NAME ($SIZE)"
                    else
                        print_success "  ✓ HTML: $NAME ($SIZE)"
                    fi
                    ;;
                css)
                    SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
                    SIZE_KB=$((SIZE_BYTES / 1024))
                    if [ $SIZE_KB -gt 100 ]; then
                        print_warning "  ⚠️  Large CSS: $NAME ($SIZE)"
                    else
                        print_info "  🎨 CSS: $NAME ($SIZE)"
                    fi
                    ;;
                js)
                    SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
                    SIZE_KB=$((SIZE_BYTES / 1024))
                    if [ $SIZE_KB -gt 250 ]; then
                        print_warning "  ⚠️  Large JS: $NAME ($SIZE)"
                    else
                        print_info "  📜 JS: $NAME ($SIZE)"
                    fi
                    ;;
                png|jpg|jpeg|gif|webp|svg)
                    SIZE_BYTES=$(ls -l "$file" | awk '{print $5}')
                    SIZE_KB=$((SIZE_BYTES / 1024))
                    if [ $SIZE_KB -gt 500 ]; then
                        print_warning "  ⚠️  Large image: $NAME ($SIZE)"
                    else
                        print_info "  🖼️  Image: $NAME ($SIZE)"
                    fi
                    ;;
            esac
        fi
    done | head -20
    
    # Count compressed files
    GZIP_COUNT=$(find dist -name "*.gz" | wc -l)
    BROTLI_COUNT=$(find dist -name "*.br" | wc -l)
    if [ $GZIP_COUNT -gt 0 ]; then
        print_info "Gzip files: $GZIP_COUNT"
    fi
    if [ $BROTLI_COUNT -gt 0 ]; then
        print_info "Brotli files: $BROTLI_COUNT"
    fi
fi

# Step 14: Display build results
print_status "📋 Build Results Summary:"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"

print_success "🎉 Web application build completed successfully!"
echo ""

# Display build information
print_info "📊 Build Information:"
echo "   Mode: $MODE"
echo "   Target: $TARGET"
echo "   Build Method: $BUNDLER"
if [ -f "package.json" ]; then
    echo "   Package Manager: $PKG_MANAGER"
    echo "   Node.js: $(get_node_version)"
fi

# Display optimizations applied
echo ""
print_info "⚡ Optimizations Applied:"
[ "$MINIFY" = true ] && echo "   ✓ HTML, CSS, JS minification"
[ "$COMPRESS" = true ] && echo "   ✓ Gzip/Brotli compression"
[ "$CRITICAL_CSS" = true ] && echo "   ✓ Critical CSS extraction"
[ "$WEBP" = true ] && echo "   ✓ WebP image conversion"
[ "$PWA" = true ] && echo "   ✓ PWA components (manifest, service worker)"
[ "$DOCKER" = true ] && echo "   ✓ Docker containerization"

echo ""

# Display output structure
if [ -d "dist" ]; then
    print_info "📁 Output structure:"
    ls -la dist/ | head -10 | while read -r line; do
        if [[ $line != total* ]] && [[ $line != .* ]]; then
            SIZE=$(echo $line | awk '{print $5}')
            NAME=$(echo $line | awk '{print $9}')
            TYPE=$(echo $line | awk '{print $1}' | cut -c1)
            if [ "$TYPE" = "d" ]; then
                echo "   📁 $NAME/"
            else
                echo "   📄 $NAME ($SIZE bytes)"
            fi
        fi
    done
else
    print_warning "No dist directory found"
fi

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"
print_success "🎉 Web build process finished!"
print_status "📁 All outputs are in: ./dist/"

# Deployment instructions
echo ""
print_info "🚀 Deployment options:"
print_info "  Static hosting: Upload dist/ to your web server"
print_info "  CDN deployment: Use with Netlify, Vercel, AWS S3, or Cloudflare Pages"
print_info "  Local preview: python3 -m http.server 8080 (from dist/)"

if [ "$PWA" = true ]; then
    print_info "  PWA: Ensure HTTPS for service worker functionality"
fi

if [ "$DOCKER" = true ]; then
    APP_NAME=$(basename "$(pwd)")
    print_info "  Docker: docker run -p 80:80 $APP_NAME:latest"
fi

# Performance recommendations
echo ""
print_info "⚡ Performance tips:"
print_info "  • Enable HTTP/2 on your server"
print_info "  • Use a CDN for global distribution"
print_info "  • Implement proper cache headers"
print_info "  • Monitor Core Web Vitals"
if [ "$AUDIT" = true ] && [ -f "dist/lighthouse-report.html" ]; then
    print_info "  • Review Lighthouse report: open dist/lighthouse-report.html"
fi
```

## Script 2: run-web-dev.sh (Development Server)

```bash
#!/bin/bash

# Run Web App Development Server
# Live reloading and development features

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

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"
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

print_status "🚀 Starting web development server..."

# Check if we have HTML files to serve
if [ ! -d "src" ] && [ ! -f "index.html" ] && [ ! -f "src/index.html" ]; then
    print_error "No HTML files found. Expected src/ directory or index.html"
    exit 1
fi

# Method 1: Use package.json scripts
if [ -f "package.json" ]; then
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
    fi
    
    # Determine dev command
    DEV_CMD=""
    if grep -q '"dev"' package.json; then
        DEV_CMD="$PKG_MANAGER run dev"
    elif grep -q '"start"' package.json; then
        DEV_CMD="$PKG_MANAGER run start"
    elif grep -q '"serve"' package.json; then
        DEV_CMD="$PKG_MANAGER run serve"
    elif [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
        DEV_CMD="$PKG_MANAGER exec vite"
    elif [ -f "webpack.config.js" ]; then
        DEV_CMD="$PKG_MANAGER exec webpack serve"
    fi
    
    if [ -n "$DEV_CMD" ]; then
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
        exit 0
    fi
fi

# Method 2: Use Vite directly (if detected)
if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
    if command_exists npx; then
        print_status "Starting Vite development server..."
        npx vite
        exit 0
    fi
fi

# Method 3: Use Parcel
if command_exists parcel; then
    ENTRY_FILE=""
    if [ -f "src/index.html" ]; then
        ENTRY_FILE="src/index.html"
    elif [ -f "index.html" ]; then
        ENTRY_FILE="index.html"
    fi
    
    if [ -n "$ENTRY_FILE" ]; then
        print_status "Starting Parcel development server..."
        parcel "$ENTRY_FILE" --port 3000
        exit 0
    fi
fi

# Method 4: Use live-server (if available)
if command_exists live-server; then
    print_status "Starting live-server..."
    if [ -d "src" ]; then
        live-server src --port=3000 --browser=default
    else
        live-server --port=3000 --browser=default
    fi
    exit 0
fi

# Method 5: Use browser-sync (if available)
if command_exists browser-sync; then
    print_status "Starting browser-sync server..."
    if [ -d "src" ]; then
        browser-sync start --server src --files "src/**/*" --port 3000
    else
        browser-sync start --server . --files "**/*" --port 3000
    fi
    exit 0
fi

# Method 6: Use Python HTTP server (fallback)
if command_exists python3; then
    print_status "Starting Python HTTP server on port 8000..."
    print_warning "This is a simple static server without live reloading"
    print_status "Open http://localhost:8000 in your browser"
    print_status "Press Ctrl+C to stop"
    
    if [ -d "src" ]; then
        cd src && python3 -m http.server 8000
    else
        python3 -m http.server 8000
    fi
    
elif command_exists python; then
    print_status "Starting Python HTTP server on port 8000..."
    print_warning "This is a simple static server without live reloading"
    print_status "Open http://localhost:8000 in your browser"
    print_status "Press Ctrl+C to stop"
    
    if [ -d "src" ]; then
        cd src && python -m SimpleHTTPServer 8000
    else
        python -m SimpleHTTPServer 8000
    fi
    
# Method 7: Use Node.js HTTP server (if Node available)
elif command_exists node; then
    print_status "Starting Node.js HTTP server on port 3000..."
    print_warning "This is a simple static server without live reloading"
    
    # Create temporary server script
    cat > temp_server.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const port = 3000;
const publicDir = fs.existsSync('src') ? 'src' : '.';

const mimeTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url);
    let pathname = parsedUrl.pathname;
    
    if (pathname === '/') {
        pathname = '/index.html';
    }
    
    const filePath = path.join(publicDir, pathname);
    
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('Not found');
            return;
        }
        
        const ext = path.extname(filePath);
        const mimeType = mimeTypes[ext] || 'application/octet-stream';
        
        res.writeHead(200, { 'Content-Type': mimeType });
        res.end(data);
    });
});

server.listen(port, () => {
    console.log(`Server running at http://localhost:${port}/`);
});
EOF
    
    node temp_server.js
    rm temp_server.js
    
else
    print_error "No suitable development server found"
    print_info "Install one of the following:"
    print_info "  • Node.js and npm (recommended)"
    print_info "  • Python 3 (for simple static server)"
    print_info "  • live-server: npm install -g live-server"
    print_info "  • browser-sync: npm install -g browser-sync"
    exit 1
fi

echo ""
print_success "Development server stopped"
```

## Configuration Templates

### package.json Template (Full-featured)

```json
{
  "name": "my-web-app",
  "version": "1.0.0",
  "description": "Modern web application with optimization",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:analyze": "vite build --analyze",
    "preview": "vite preview",
    "serve": "live-server dist --port=3000",
    "lint": "eslint src --ext .js,.ts,.html",
    "lint:fix": "eslint src --ext .js,.ts,.html --fix",
    "format": "prettier --write src/**/*.{html,css,js,ts}",
    "optimize": "imagemin src/assets/images/* --out-dir=dist/images",
    "audit": "lighthouse http://localhost:3000 --output html",
    "test": "vitest"
  },
  "devDependencies": {
    "@vitejs/plugin-legacy": "^4.1.1",
    "autoprefixer": "^10.4.16",
    "clean-css": "^5.3.2",
    "eslint": "^8.56.0",
    "html-minifier-terser": "^7.2.0",
    "imagemin": "^8.0.1",
    "imagemin-webp": "^7.0.0",
    "lighthouse": "^11.4.0",
    "live-server": "^1.2.2",
    "postcss": "^8.4.32",
    "prettier": "^3.1.1",
    "sass": "^1.69.5",
    "tailwindcss": "^3.4.0",
    "terser": "^5.26.0",
    "vite": "^5.0.10",
    "vite-plugin-pwa": "^0.17.4",
    "vitest": "^1.1.0"
  },
  "dependencies": {}
}
```

### vite.config.js Template (Optimized)

```javascript
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'
import legacy from '@vitejs/plugin-legacy'

export default defineConfig({
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    },
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['lodash', 'axios'],
          utils: ['./src/utils/helpers.js']
        }
      }
    },
    sourcemap: false,
    cssMinify: true
  },
  plugins: [
    legacy({
      targets: ['defaults', 'not IE 11']
    }),
    VitePWA({
      registerType: 'autoUpdate',
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg}']
      },
      manifest: {
        name: 'My Web App',
        short_name: 'WebApp',
        description: 'Modern web application',
        theme_color: '#ffffff',
        background_color: '#ffffff',
        display: 'standalone',
        icons: [
          {
            src: 'icon-192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: 'icon-512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      }
    })
  ],
  css: {
    postcss: {
      plugins: [
        require('autoprefixer'),
        require('cssnano')({
          preset: 'default'
        })
      ]
    }
  }
})
```

## Quick Start Commands

```bash
# Setup
chmod +x compile-build-dist-web.sh
chmod +x run-web-dev.sh

# Development
./run-web-dev.sh

# Production build
./compile-build-dist-web.sh

# Optimized build with PWA
./compile-build-dist-web.sh --optimize --pwa

# Full build with all features
./compile-build-dist-web.sh --optimize --pwa --docker --audit

# Static build (no Node.js required)
./compile-build-dist-web.sh --bundler copy

# Performance-focused build
./compile-build-dist-web.sh --minify --compress --critical-css --webp
```

This system provides comprehensive web build support with modern optimization, PWA capabilities, and multi-platform deployment options.