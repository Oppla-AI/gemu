#!/bin/bash
# Gemu Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/Oppla-AI/gemu/main/install-gemu.sh | bash

set -e

# Configuration
REPO="Oppla-AI/gemu"
BINARY_NAME="gemu"
INSTALL_DIR="/usr/local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Detect OS
detect_os() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        linux) echo "linux" ;;
        darwin) echo "darwin" ;;
        mingw*|msys*|cygwin*) echo "windows" ;;
        *)
            print_error "Unsupported operating system: $os"
            exit 1
            ;;
    esac
}

# Detect architecture
detect_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)
            print_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Check if running with necessary permissions
check_permissions() {
    if [ "$INSTALL_DIR" = "/usr/local/bin" ] && [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        print_info "This script requires sudo access to install to $INSTALL_DIR"
        print_info "You may be prompted for your password."
    fi
}

# Download and install Gemu
install_gemu() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    local platform="${os}-${arch}"

    print_info "Detected platform: $platform"

    # Get latest release URL
    local latest_release_url="https://api.github.com/repos/${REPO}/releases/latest"

    print_info "Fetching latest release information..."

    # Try to get latest release, fallback to direct download if API fails
    local download_url
    if command -v curl >/dev/null 2>&1; then
        download_url=$(curl -sL "$latest_release_url" | grep "browser_download_url.*gemu-${platform}.zip" | cut -d '"' -f 4)
    fi

    # If we couldn't get the URL from API, construct it directly
    if [ -z "$download_url" ]; then
        print_info "Using direct download URL..."
        download_url="https://github.com/${REPO}/releases/latest/download/gemu-${platform}.zip"
    fi

    print_info "Downloading Gemu for $platform..."

    # Create temp directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Download the binary
    if command -v curl >/dev/null 2>&1; then
        curl -L "$download_url" -o "$temp_dir/gemu.zip" || {
            print_error "Failed to download Gemu"
            exit 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget "$download_url" -O "$temp_dir/gemu.zip" || {
            print_error "Failed to download Gemu"
            exit 1
        }
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    # Extract the binary
    print_info "Extracting Gemu..."
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$temp_dir/gemu.zip" -d "$temp_dir"
    else
        print_error "unzip not found. Please install unzip."
        exit 1
    fi

    # Find the binary (it might be gemu or gemu.exe)
    local binary_name="gemu"
    if [ "$os" = "windows" ]; then
        binary_name="gemu.exe"
    fi

    if [ ! -f "$temp_dir/$binary_name" ]; then
        print_error "Binary not found in archive"
        exit 1
    fi

    # Install the binary
    print_info "Installing Gemu to $INSTALL_DIR..."
    if [ "$INSTALL_DIR" = "/usr/local/bin" ]; then
        sudo mv "$temp_dir/$binary_name" "$INSTALL_DIR/gemu"
        sudo chmod +x "$INSTALL_DIR/gemu"
    else
        mv "$temp_dir/$binary_name" "$INSTALL_DIR/gemu"
        chmod +x "$INSTALL_DIR/gemu"
    fi

    # Verify installation
    if command -v gemu >/dev/null 2>&1; then
        local version=$(gemu --version 2>/dev/null || echo "unknown")
        print_success "✓ Gemu installed successfully!"
        print_info "Version: $version"
        print_info "Location: $(which gemu)"
    else
        print_error "Installation completed but gemu is not in PATH"
        print_info "Add $INSTALL_DIR to your PATH or run: $INSTALL_DIR/gemu"
    fi
}

# Main execution
main() {
    print_info "=== Gemu Installer ==="

    check_permissions
    install_gemu

    print_info ""
    print_info "To get started, run: gemu --help"
    print_info "To authenticate, run: gemu auth gemu"
}

# Run main function
main "$@"