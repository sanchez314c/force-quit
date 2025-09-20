#!/bin/bash
# Run ForceQUIT from Source on macOS (Development Mode)

cd "$(dirname "$0")"

# Check platform
if [ "$(uname)" != "Darwin" ]; then
    echo "This script is for macOS only"
    exit 1
fi

# Check for Swift
if ! command -v swift >/dev/null 2>&1; then
    echo "Swift is not installed. Install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

echo "🚀 Starting ForceQUIT from source..."

# Determine run method
if [ -f "Package.swift" ]; then
    echo "Running with Swift Package Manager..."
    swift run
elif ls *.xcodeproj >/dev/null 2>&1; then
    PROJECT_FILE=$(ls *.xcodeproj | head -1)
    APP_NAME=$(basename "$PROJECT_FILE" .xcodeproj)
    
    echo "Building and running with xcodebuild..."
    xcodebuild -project "$PROJECT_FILE" -scheme "$APP_NAME" -configuration Debug build
    
    if [ $? -eq 0 ]; then
        # Find and run the built executable
        BUILT_APP=$(find . -name "$APP_NAME.app" -type d | head -1)
        if [ -n "$BUILT_APP" ]; then
            echo "Launching: $BUILT_APP"
            open "$BUILT_APP"
        else
            echo "Could not find built application"
        fi
    else
        echo "Build failed"
        exit 1
    fi
else
    echo "No Package.swift or .xcodeproj found"
    exit 1
fi

echo "✅ ForceQUIT development session ended"