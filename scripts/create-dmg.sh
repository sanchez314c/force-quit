#!/bin/bash

# SWARM 2.0 ForceQUIT DMG Creation Script
# Phase 8: Build-Compile-Dist
# Session: FLIPPED-POLES

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
PROJECT_NAME="ForceQUIT"
VERSION="1.0.0"
DIST_DIR="./dist"
DMG_DIR="./dmg"
NOTARIZED_DIR="./notarized"

# DMG Configuration
DMG_NAME="${PROJECT_NAME}-${VERSION}"
DMG_SIZE="100m"
DMG_FORMAT="UDZO"  # Compressed

echo -e "${CYAN}===============================================${NC}"
echo -e "${WHITE}    SWARM 2.0 DMG Builder${NC}"
echo -e "${WHITE}    Project: ForceQUIT v${VERSION}${NC}"
echo -e "${CYAN}===============================================${NC}"

# Validate input
validate_input() {
    echo -e "${BLUE}🔍 Validating build artifacts...${NC}"
    
    # Check for signed app (preferred) or unsigned app (fallback)
    if [ -d "$NOTARIZED_DIR/$PROJECT_NAME.app" ]; then
        SOURCE_APP="$NOTARIZED_DIR/$PROJECT_NAME.app"
        DMG_SUFFIX="Signed"
        echo -e "${GREEN}✅ Found signed application${NC}"
    elif [ -d "$DIST_DIR/$PROJECT_NAME.app" ]; then
        SOURCE_APP="$DIST_DIR/$PROJECT_NAME.app"
        DMG_SUFFIX="Unsigned"
        echo -e "${YELLOW}⚠️ Using unsigned application${NC}"
    else
        echo -e "${RED}❌ ERROR: No application found${NC}"
        echo -e "${RED}   Run build-universal.sh first${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Input validation complete${NC}"
}

# Create DMG staging area
create_staging_area() {
    echo -e "${PURPLE}📁 Creating DMG staging area...${NC}"
    
    # Clean and create directories
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR/staging"
    
    # Copy application
    cp -R "$SOURCE_APP" "$DMG_DIR/staging/"
    
    # Create Applications symlink for easy installation
    ln -s /Applications "$DMG_DIR/staging/Applications"
    
    echo -e "${GREEN}✅ Staging area created${NC}"
}

# Create background image for DMG
create_dmg_background() {
    echo -e "${PURPLE}🎨 Creating DMG background...${NC}"
    
    # Create simple background using built-in tools
    mkdir -p "$DMG_DIR/staging/.background"
    
    # Generate a simple gradient background using sips (if available)
    if command -v sips &> /dev/null; then
        # Create a simple colored background
        cat > "$DMG_DIR/temp_bg.py" << 'EOF'
import sys
from PIL import Image, ImageDraw, ImageFont
import os

# Create background image
width, height = 600, 400
image = Image.new('RGB', (width, height), '#1a1a1a')
draw = ImageDraw.Draw(image)

# Create gradient effect
for y in range(height):
    shade = int(26 + (y / height) * 30)  # Gradient from #1a1a1a to #2a2a2a
    color = f"#{shade:02x}{shade:02x}{shade:02x}"
    draw.line([(0, y), (width, y)], fill=color)

# Add ForceQUIT branding
try:
    # Try to use system font
    font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
except:
    # Fallback to default font
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Center text
text = "ForceQUIT"
text_bbox = draw.textbbox((0, 0), text, font=font_large)
text_width = text_bbox[2] - text_bbox[0]
text_x = (width - text_width) // 2

draw.text((text_x, 50), text, fill='#ffffff', font=font_large)

subtitle = "Elegant macOS Force Quit Utility"
subtitle_bbox = draw.textbbox((0, 0), subtitle, font=font_small)
subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
subtitle_x = (width - subtitle_width) // 2

draw.text((subtitle_x, 100), subtitle, fill='#cccccc', font=font_small)

# Save
image.save(sys.argv[1])
EOF
        
        # Try to create background with Python/PIL
        if python3 -c "import PIL" 2>/dev/null; then
            python3 "$DMG_DIR/temp_bg.py" "$DMG_DIR/staging/.background/background.png"
            rm "$DMG_DIR/temp_bg.py"
            echo -e "${GREEN}✅ Custom background created${NC}"
        else
            echo -e "${YELLOW}⚠️ PIL not available, using simple background${NC}"
            # Create simple colored rectangle as fallback
            cat > "$DMG_DIR/staging/.background/background.png" << 'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==
EOF
        fi
    else
        echo -e "${YELLOW}⚠️ sips not available, skipping background${NC}"
    fi
    
    echo -e "${GREEN}✅ DMG background prepared${NC}"
}

# Create DMG with custom layout
create_dmg() {
    echo -e "${PURPLE}💿 Creating DMG...${NC}"
    
    # Generate unique DMG name
    FINAL_DMG_NAME="${DMG_NAME}-${DMG_SUFFIX}"
    TEMP_DMG="$DMG_DIR/${FINAL_DMG_NAME}-temp.dmg"
    FINAL_DMG="$DMG_DIR/${FINAL_DMG_NAME}.dmg"
    
    # Remove existing DMGs
    rm -f "$TEMP_DMG" "$FINAL_DMG"
    
    # Create temporary DMG
    hdiutil create \
        -srcfolder "$DMG_DIR/staging" \
        -volname "$PROJECT_NAME" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDRW \
        -size "$DMG_SIZE" \
        "$TEMP_DMG"
    
    echo -e "${GREEN}✅ Temporary DMG created${NC}"
    
    # Mount and customize DMG
    echo -e "${BLUE}🔧 Customizing DMG layout...${NC}"
    
    MOUNT_POINT="/Volumes/$PROJECT_NAME"
    hdiutil attach -readwrite -noverify "$TEMP_DMG"
    
    # Wait for mount
    sleep 2
    
    # Customize Finder view
    if [ -d "$MOUNT_POINT" ]; then
        # Set custom icon positions
        osascript << EOF
tell application "Finder"
    tell disk "$PROJECT_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set arrangement of icon view options of container window to not arranged
        set icon size of icon view options of container window to 128
        delay 1
        set position of item "$PROJECT_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
        
        # Set background if available
        if [ -f "$MOUNT_POINT/.background/background.png" ]; then
            osascript << EOF
tell application "Finder"
    tell disk "$PROJECT_NAME"
        open
        set background picture of icon view options of container window to file ".background:background.png"
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
EOF
        fi
        
        echo -e "${GREEN}✅ DMG layout customized${NC}"
    else
        echo -e "${YELLOW}⚠️ DMG mount point not accessible, skipping customization${NC}"
    fi
    
    # Unmount
    hdiutil detach "$MOUNT_POINT"
    
    # Convert to final compressed DMG
    echo -e "${BLUE}🗜️ Compressing DMG...${NC}"
    
    hdiutil convert \
        "$TEMP_DMG" \
        -format "$DMG_FORMAT" \
        -imagekey zlib-level=9 \
        -o "$FINAL_DMG"
    
    # Clean up
    rm -f "$TEMP_DMG"
    
    echo -e "${GREEN}✅ Final DMG created: $FINAL_DMG${NC}"
    
    # Move to distribution directory
    mkdir -p "$DIST_DIR"
    mv "$FINAL_DMG" "$DIST_DIR/"
    
    echo -e "${GREEN}✅ DMG moved to distribution directory${NC}"
}

# Verify DMG
verify_dmg() {
    echo -e "${BLUE}🔍 Verifying DMG...${NC}"
    
    FINAL_DMG_PATH="$DIST_DIR/${DMG_NAME}-${DMG_SUFFIX}.dmg"
    
    # Check DMG integrity
    hdiutil verify "$FINAL_DMG_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ DMG verification successful${NC}"
    else
        echo -e "${RED}❌ DMG verification failed${NC}"
        exit 1
    fi
    
    # Display DMG info
    echo -e "${YELLOW}📋 DMG Information:${NC}"
    hdiutil imageinfo "$FINAL_DMG_PATH" | grep -E "(Format|Size|Checksum)"
    
    # Show file size
    DMG_SIZE_MB=$(du -m "$FINAL_DMG_PATH" | cut -f1)
    echo -e "${YELLOW}   File Size: ${DMG_SIZE_MB}MB${NC}"
}

# Main execution
main() {
    validate_input
    create_staging_area
    create_dmg_background
    create_dmg
    verify_dmg
    
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${WHITE}    DMG Creation Complete!${NC}"
    echo -e "${GREEN}===============================================${NC}"
    
    echo -e "${YELLOW}📋 Final Output:${NC}"
    echo -e "   ✅ DMG: $DIST_DIR/${DMG_NAME}-${DMG_SUFFIX}.dmg"
    
    echo -e "${CYAN}🚀 Ready for distribution!${NC}"
    echo -e "${CYAN}   Upload to GitHub Releases, website, or distribute directly${NC}"
}

main "$@"