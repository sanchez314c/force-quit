#!/bin/bash
# Run Compiled ForceQUIT Binary on macOS

cd "$(dirname "$0")"

# Check platform
if [ "$(uname)" != "Darwin" ]; then
    echo "This script is for macOS only"
    exit 1
fi

echo "🚀 Starting ForceQUIT compiled application..."

# Check for symlink to .app
if [ -L "ForceQUIT.app" ]; then
    echo "Opening ForceQUIT.app via symlink..."
    open "ForceQUIT.app"
elif [ -d "dist/ForceQUIT.app" ]; then
    echo "Opening ForceQUIT.app from dist..."
    open "dist/ForceQUIT.app"
elif [ -d "build/ForceQUIT.app" ]; then
    echo "Opening ForceQUIT.app from build..."
    open "build/ForceQUIT.app"
else
    echo "❌ No compiled ForceQUIT application found."
    echo "Run: ./scripts/compile-build-dist.sh"
    exit 1
fi

echo "✅ ForceQUIT launched successfully"