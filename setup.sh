#!/bin/bash
# ForceQUIT Project Setup Script

echo "🚀 Setting up ForceQUIT development environment..."

# Create required directories (if not exists)
mkdir -p src tests docs config scripts assets/icons assets/images assets/screenshots
mkdir -p dev/PRDs dev/specs dev/notes dev/research dev/build-scripts
mkdir -p archive backup dist

# Make all shell scripts executable
chmod +x run-*.sh 2>/dev/null || true
chmod +x setup.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x scripts/build/*.sh 2>/dev/null || true
chmod +x scripts/deploy/*.sh 2>/dev/null || true
chmod +x scripts/utils/*.sh 2>/dev/null || true

echo "📦 Installing Swift dependencies..."

# Check for Swift
if command -v swift >/dev/null 2>&1; then
    echo "✅ Swift found: $(swift --version | head -1)"
    
    if [ -f "Package.swift" ]; then
        echo "📋 Resolving Swift Package Manager dependencies..."
        swift package resolve
        if [ $? -eq 0 ]; then
            echo "✅ Dependencies resolved successfully"
        else
            echo "⚠️ Warning: Some dependencies may have issues"
        fi
    fi
else
    echo "❌ Swift not found. Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
fi

# Check for Xcode
if command -v xcodebuild >/dev/null 2>&1; then
    echo "✅ Xcode tools found: $(xcodebuild -version | head -1)"
else
    echo "⚠️ Xcode build tools not found. Some features may not work."
fi

echo "✅ Setup complete!"
echo ""
echo "📋 Available commands:"
echo "  Development:"
echo "    ./run-source-macos.sh    - Run from source (development)"
echo ""
echo "  Production:"
echo "    ./scripts/compile-build-dist.sh - Build application"
echo "    ./run-macos.sh           - Run compiled app"
echo ""
echo "  Testing:"
echo "    swift test               - Run test suite"
echo ""
echo "🎯 Next steps:"
echo "1. Review the README.md for project overview"
echo "2. Check docs/ folder for technical documentation"
echo "3. Run './run-source-macos.sh' to test the development setup"
echo "4. Run './scripts/compile-build-dist.sh' to create a production build"