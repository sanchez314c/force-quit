#!/bin/bash
# Quick Launch Script for Claude ForceQUIT (bypasses complex build system)

cd "$(dirname "$0")"

echo "🚀 Quick launching Claude ForceQUIT..."

# Use the simplified Package.swift
if [ -f "Package_Simple.swift" ]; then
    echo "📦 Using simplified package configuration..."
    cp Package.swift Package_Original.swift
    cp Package_Simple.swift Package.swift
fi

# Quick build and run
echo "🔨 Building simple version..."
swift run ForceQUIT

# Restore original Package.swift if we made changes
if [ -f "Package_Original.swift" ]; then
    mv Package_Original.swift Package.swift
fi