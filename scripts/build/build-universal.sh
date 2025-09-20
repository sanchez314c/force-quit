#!/bin/bash

# SWARM 2.0 ForceQUIT Universal Binary Build Script
# Phase 8: Build-Compile-Dist
# Session: FLIPPED-POLES

set -euo pipefail

# ANSI Color Codes for Professional Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Build Configuration
PROJECT_NAME="ForceQUIT"
BUNDLE_ID="com.swarm.forcequit"
VERSION="1.0.0"
BUILD_NUMBER="1"

# Build Paths
BUILD_DIR="./build"
DIST_DIR="./dist"
ARCHIVE_DIR="./archive"

echo -e "${CYAN}===============================================${NC}"
echo -e "${WHITE}    SWARM 2.0 Universal Binary Builder${NC}"
echo -e "${WHITE}    Project: ForceQUIT v${VERSION}${NC}"
echo -e "${CYAN}===============================================${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR" "$DIST_DIR" "$ARCHIVE_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$ARCHIVE_DIR"

# Validate Xcode environment
echo -e "${BLUE}🔍 Validating Xcode environment...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ ERROR: xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
echo -e "${GREEN}✅ Xcode ${XCODE_VERSION} detected${NC}"

# Link source files to Xcode project structure
echo -e "${YELLOW}🔗 Setting up project structure...${NC}"
mkdir -p "ForceQUIT"

# Copy source files with proper structure
cp "src/Sources/main.swift" "ForceQUIT/"
cp "src/Sources/ForceQUITUI.swift" "ForceQUIT/"
cp "src/Sources/SystemStateManager.swift" "ForceQUIT/"
cp "src/Sources/AnimationController.swift" "ForceQUIT/"
cp "src/Sources/HealthRingsGrid.swift" "ForceQUIT/"
cp "src/Sources/PerformanceOptimizer.swift" "ForceQUIT/"

# Copy additional source directories
cp -r "src/Sources/Core" "ForceQUIT/" 2>/dev/null || true
cp -r "src/Sources/Models" "ForceQUIT/" 2>/dev/null || true
cp -r "src/Sources/Views" "ForceQUIT/" 2>/dev/null || true
cp -r "src/Sources/ViewModels" "ForceQUIT/" 2>/dev/null || true
cp -r "src/Sources/Security" "ForceQUIT/" 2>/dev/null || true

echo -e "${GREEN}✅ Project structure configured${NC}"

# Build for Apple Silicon (arm64)
echo -e "${PURPLE}🏗️ Building for Apple Silicon (arm64)...${NC}"
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${PROJECT_NAME}" \
    -configuration Release \
    -arch arm64 \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    ARCHS=arm64 \
    VALID_ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Apple Silicon build successful${NC}"
else
    echo -e "${RED}❌ Apple Silicon build failed${NC}"
    exit 1
fi

# Build for Intel (x86_64)
echo -e "${PURPLE}🏗️ Building for Intel (x86_64)...${NC}"
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${PROJECT_NAME}" \
    -configuration Release \
    -arch x86_64 \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    ARCHS=x86_64 \
    VALID_ARCHS=x86_64 \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Intel build successful${NC}"
else
    echo -e "${RED}❌ Intel build failed${NC}"
    exit 1
fi

# Create Universal Binary
echo -e "${CYAN}🔗 Creating Universal Binary...${NC}"

# Locate the built apps
ARM64_APP="${BUILD_DIR}/DerivedData/Build/Products/Release/${PROJECT_NAME}.app"
INTEL_APP="${BUILD_DIR}/DerivedData/Build/Products/Release/${PROJECT_NAME}.app"
UNIVERSAL_APP="${DIST_DIR}/${PROJECT_NAME}.app"

# Copy the app bundle (use arm64 as base)
cp -R "$ARM64_APP" "$UNIVERSAL_APP"

# Create universal binary using lipo
lipo -create \
    "${ARM64_APP}/Contents/MacOS/${PROJECT_NAME}" \
    "${INTEL_APP}/Contents/MacOS/${PROJECT_NAME}" \
    -output "${UNIVERSAL_APP}/Contents/MacOS/${PROJECT_NAME}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Universal binary created successfully${NC}"
else
    echo -e "${RED}❌ Universal binary creation failed${NC}"
    exit 1
fi

# Verify universal binary
echo -e "${BLUE}🔍 Verifying universal binary...${NC}"
file "${UNIVERSAL_APP}/Contents/MacOS/${PROJECT_NAME}"
lipo -info "${UNIVERSAL_APP}/Contents/MacOS/${PROJECT_NAME}"

# Update Info.plist with version info
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "${UNIVERSAL_APP}/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "${UNIVERSAL_APP}/Contents/Info.plist"

echo -e "${GREEN}===============================================${NC}"
echo -e "${WHITE}    Universal Binary Build Complete!${NC}"
echo -e "${WHITE}    Output: ${DIST_DIR}/${PROJECT_NAME}.app${NC}"
echo -e "${GREEN}===============================================${NC}"

# Display build summary
echo -e "${YELLOW}📋 Build Summary:${NC}"
echo -e "   Project: ${PROJECT_NAME}"
echo -e "   Version: ${VERSION} (${BUILD_NUMBER})"
echo -e "   Bundle ID: ${BUNDLE_ID}"
echo -e "   Architectures: arm64, x86_64 (Universal)"
echo -e "   Output Path: ${DIST_DIR}/${PROJECT_NAME}.app"

echo -e "${CYAN}🚀 Ready for code signing and notarization!${NC}"