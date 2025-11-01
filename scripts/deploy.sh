#!/bin/bash

# ForceQUIT Deployment Script
# Handles deployment to various distribution channels

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ForceQUIT"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
BUILD_DIR="$PROJECT_ROOT/build"

# Deployment options
DEPLOY_GITHUB=false
DEPLOY_HOMEWREW=false
DEPLOY_DIRECT=false
CREATE_RELEASE=false

# GitHub configuration
GITHUB_TOKEN=""
GITHUB_REPO=""
RELEASE_TAG=""
RELEASE_NAME=""

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
ForceQUIT Deployment Script

Usage: $0 [OPTIONS]

OPTIONS:
    --github              Deploy to GitHub Releases
    --homebrew            Create Homebrew formula
    --direct              Create direct download package
    --release             Create GitHub release
    --token TOKEN         GitHub API token
    --repo REPO           GitHub repository (owner/repo)
    --tag TAG             Release tag
    --name NAME           Release name
    --help                Show this help message

REQUIREMENTS:
    - Build must be completed before deployment
    - For GitHub deployment: --token and --repo are required
    - GitHub CLI (gh) or curl for GitHub operations

EXAMPLES:
    $0 --github --release --token \$TOKEN --repo user/repo --tag v1.0.0
    $0 --homebrew --direct
    $0 --github --homebrew --token \$TOKEN --repo user/repo

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --github)
                DEPLOY_GITHUB=true
                shift
                ;;
            --homebrew)
                DEPLOY_HOMEWREW=true
                shift
                ;;
            --direct)
                DEPLOY_DIRECT=true
                shift
                ;;
            --release)
                CREATE_RELEASE=true
                shift
                ;;
            --token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --repo)
                GITHUB_REPO="$2"
                shift 2
                ;;
            --tag)
                RELEASE_TAG="$2"
                shift 2
                ;;
            --name)
                RELEASE_NAME="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check dependencies
check_dependencies() {
    log "Checking deployment dependencies..."

    # Check for required files
    local app_bundle="$DIST_DIR/$PROJECT_NAME.app"
    local dmg_file="$DIST_DIR/$PROJECT_NAME.dmg"

    if [[ ! -d "$app_bundle" ]]; then
        log_error "App bundle not found: $app_bundle"
        log_error "Please run the build script first"
        exit 1
    fi

    # Check for GitHub CLI or curl
    if [[ "$DEPLOY_GITHUB" == true ]]; then
        if ! command -v gh &> /dev/null && ! command -v curl &> /dev/null; then
            log_error "GitHub CLI (gh) or curl is required for GitHub deployment"
            exit 1
        fi

        if [[ -z "$GITHUB_TOKEN" || -z "$GITHUB_REPO" ]]; then
            log_error "GitHub token and repository are required for GitHub deployment"
            exit 1
        fi
    fi

    log_success "Deployment dependencies check passed"
}

# Create checksum for file
create_checksum() {
    local file="$1"
    local algorithm="${2:-sha256}"

    if command -v shasum &> /dev/null; then
        shasum -a "$algorithm" "$file" | awk '{print $1}'
    elif command -v sha256sum &> /dev/null; then
        sha256sum "$file" | awk '{print $1}'
    else
        log_error "No checksum tool available"
        return 1
    fi
}

# Deploy to GitHub
deploy_github() {
    if [[ "$DEPLOY_GITHUB" == true ]]; then
        log "Deploying to GitHub..."

        local dmg_file="$DIST_DIR/$PROJECT_NAME.dmg"

        if [[ ! -f "$dmg_file" ]]; then
            log_error "DMG file not found: $dmg_file"
            log_error "Please rebuild with --dmg option"
            exit 1
        fi

        # Create checksum
        local checksum=$(create_checksum "$dmg_file")
        echo "$checksum  $PROJECT_NAME.dmg" > "$DIST_DIR/$PROJECT_NAME.dmg.sha256"

        # Use GitHub CLI if available
        if command -v gh &> /dev/null; then
            deploy_github_cli "$dmg_file" "$checksum"
        else
            deploy_github_curl "$dmg_file" "$checksum"
        fi

        log_success "GitHub deployment completed"
    fi
}

# Deploy using GitHub CLI
deploy_github_cli() {
    local dmg_file="$1"
    local checksum="$2"

    log "Using GitHub CLI for deployment..."

    # Set token for gh CLI
    export GH_TOKEN="$GITHUB_TOKEN"

    # Create release if requested
    if [[ "$CREATE_RELEASE" == true ]]; then
        if [[ -z "$RELEASE_TAG" ]]; then
            RELEASE_TAG="v$(date +%Y.%m.%d)"
        fi

        if [[ -z "$RELEASE_NAME" ]]; then
            RELEASE_NAME="$PROJECT_NAME $RELEASE_TAG"
        fi

        log "Creating GitHub release: $RELEASE_TAG"

        # Create release
        gh release create "$RELEASE_TAG" \
            --title "$RELEASE_NAME" \
            --notes "Release $RELEASE_TAG of $PROJECT_NAME" \
            --repo "$GITHUB_REPO" \
            "$dmg_file" \
            "$DIST_DIR/$PROJECT_NAME.dmg.sha256"

        log_success "GitHub release created"
    else
        # Upload to existing release
        log "Uploading files to existing release..."

        # For now, we'll create a draft release
        gh release create "draft-$(date +%s)" \
            --title "Draft Release" \
            --draft \
            --repo "$GITHUB_REPO" \
            "$dmg_file" \
            "$DIST_DIR/$PROJECT_NAME.dmg.sha256"
    fi
}

# Deploy using curl
deploy_github_curl() {
    local dmg_file="$1"
    local checksum="$2"

    log "Using curl for GitHub deployment..."

    if [[ -z "$RELEASE_TAG" ]]; then
        RELEASE_TAG="v$(date +%Y.%m.%d)"
    fi

    if [[ -z "$RELEASE_NAME" ]]; then
        RELEASE_NAME="$PROJECT_NAME $RELEASE_TAG"
    fi

    # Create release
    local release_data=$(cat << EOF
{
    "tag_name": "$RELEASE_TAG",
    "target_commitish": "main",
    "name": "$RELEASE_NAME",
    "body": "Release $RELEASE_TAG of $PROJECT_NAME",
    "draft": false,
    "prerelease": false
}
EOF
)

    local release_response=$(curl -s \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPO/releases" \
        -d "$release_data")

    local upload_url=$(echo "$release_response" | grep -o '"upload_url": "[^"]*' | cut -d'"' -f4 | cut -d'{' -f1)

    if [[ -z "$upload_url" ]]; then
        log_error "Failed to create GitHub release"
        log_error "Response: $release_response"
        exit 1
    fi

    # Upload DMG
    log "Uploading DMG file..."
    curl -s \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        "$upload_url?name=$PROJECT_NAME.dmg" \
        --data-binary @"$dmg_file"

    # Upload checksum
    log "Uploading checksum file..."
    curl -s \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: text/plain" \
        "$upload_url?name=$PROJECT_NAME.dmg.sha256" \
        --data-binary @"$DIST_DIR/$PROJECT_NAME.dmg.sha256"

    log_success "Files uploaded to GitHub"
}

# Create Homebrew formula
create_homebrew_formula() {
    if [[ "$DEPLOY_HOMEWREW" == true ]]; then
        log "Creating Homebrew formula..."

        local dmg_file="$DIST_DIR/$PROJECT_NAME.dmg"
        local checksum=$(create_checksum "$dmg_file")

        if [[ -z "$GITHUB_REPO" ]]; then
            log_error "GitHub repository is required for Homebrew formula"
            exit 1
        fi

        local formula_content=$(cat << EOF
class Forcequit < Formula
  desc "Elegant macOS Force Quit Utility"
  homepage "https://github.com/$GITHUB_REPO"
  url "https://github.com/$GITHUB_REPO/releases/latest/download/$PROJECT_NAME.dmg"
  sha256 "$checksum"
  license :unknown

  app "$PROJECT_NAME.app"

  zap trash: [
    "~/Library/Application Support/ForceQUIT",
    "~/Library/Preferences/com.forcequit.app.plist"
  ]
end
EOF
)

        local formula_file="$DIST_DIR/forcequit.rb"
        echo "$formula_content" > "$formula_file"

        log_success "Homebrew formula created: $formula_file"
        log "To install with Homebrew:"
        log "  brew install --cask $formula_file"
    fi
}

# Create direct download package
create_direct_package() {
    if [[ "$DEPLOY_DIRECT" == true ]]; then
        log "Creating direct download package..."

        local app_bundle="$DIST_DIR/$PROJECT_NAME.app"
        local package_dir="$DIST_DIR/direct-download"

        # Create package directory
        mkdir -p "$package_dir"

        # Copy app bundle
        cp -R "$app_bundle" "$package_dir/"

        # Create installation script
        cat > "$package_dir/install.sh" << 'EOF'
#!/bin/bash

# ForceQUIT Installation Script

set -euo pipefail

APP_NAME="ForceQUIT.app"
INSTALL_DIR="/Applications"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This installer is for macOS only"
    exit 1
fi

# Check if app already exists
if [[ -d "$INSTALL_DIR/$APP_NAME" ]]; then
    echo "ForceQUIT is already installed in $INSTALL_DIR"
    echo "Removing existing version..."
    sudo rm -rf "$INSTALL_DIR/$APP_NAME"
fi

# Install app
echo "Installing ForceQUIT to $INSTALL_DIR..."
sudo cp -R "$APP_NAME" "$INSTALL_DIR/"

# Set permissions
sudo chown -R root:wheel "$INSTALL_DIR/$APP_NAME"

echo "Installation completed successfully!"
echo "You can now launch ForceQUIT from your Applications folder."
EOF

        chmod +x "$package_dir/install.sh"

        # Create README for direct download
        cat > "$package_dir/README.txt" << EOF
ForceQUIT - Elegant macOS Force Quit Utility

Installation:
1. Double-click on install.sh
2. Follow the prompts to install to /Applications
3. Launch ForceQUIT from your Applications folder

Manual Installation:
1. Copy ForceQUIT.app to /Applications
2. Launch from Applications folder

System Requirements:
- macOS 12.0 (Monterey) or later
- Intel Mac or Apple Silicon

For more information, visit: https://github.com/$GITHUB_REPO
EOF

        # Create zip archive
        local zip_file="$DIST_DIR/$PROJECT_NAME-direct.zip"
        cd "$DIST_DIR"
        zip -r "$zip_file" direct-download/
        rm -rf direct-download/

        log_success "Direct download package created: $zip_file"
    fi
}

# Display deployment summary
display_summary() {
    log "Deployment Summary:"
    log "  GitHub Deployment: $DEPLOY_GITHUB"
    log "  Homebrew Formula: $DEPLOY_HOMEWREW"
    log "  Direct Download: $DEPLOY_DIRECT"
    log "  GitHub Release: $CREATE_RELEASE"

    if [[ "$DEPLOY_GITHUB" == true ]]; then
        log "  Repository: $GITHUB_REPO"
        log "  Release Tag: $RELEASE_TAG"
    fi

    echo
    log "Files created in $DIST_DIR:"
    ls -la "$DIST_DIR/"

    log_success "Deployment completed!"
}

# Main deployment function
main() {
    parse_args "$@"

    log "Starting $PROJECT_NAME deployment..."

    check_dependencies
    deploy_github
    create_homebrew_formula
    create_direct_package
    display_summary
}

# Run main function with all arguments
main "$@"