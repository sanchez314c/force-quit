#!/bin/bash
# Simple Build and Run Script for Claude ForceQUIT

cd "$(dirname "$0")"

echo "🚀 Building Claude ForceQUIT..."

# Build the Swift app
swift build -c release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "🎯 Running Claude ForceQUIT..."
    
    # Run the app
    ./.build/release/ForceQUIT
else
    echo "❌ Build failed!"
    exit 1
fi