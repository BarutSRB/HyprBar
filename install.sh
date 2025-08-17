#!/bin/bash

# SketchyBar Configuration Installer
# This script sets up all dependencies and configures SketchyBar

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SKETCHYBAR_CONFIG_DIR="$HOME/.config/sketchybar"
SBARLUA_DIR="$HOME/.local/share/sketchybar_lua"

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is for macOS only"
        exit 1
    fi
    print_success "Running on macOS"
}

# Check and install Homebrew
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
    fi
}

# Install SketchyBar
install_sketchybar() {
    print_step "Installing SketchyBar..."
    
    if brew list --formula | grep -q "^sketchybar$"; then
        print_success "SketchyBar already installed"
        print_step "Updating SketchyBar..."
        brew upgrade sketchybar 2>/dev/null || true
    else
        brew install sketchybar
        print_success "SketchyBar installed"
    fi
    
    # Start SketchyBar service
    print_step "Starting SketchyBar service..."
    brew services start sketchybar
    print_success "SketchyBar service started"
}

# Install required fonts
install_fonts() {
    print_step "Installing required fonts..."
    
    # Install sketchybar-app-font
    if ! brew list --cask | grep -q "font-sketchybar-app-font"; then
        brew tap FelixKratz/formulae
        brew install --cask font-sketchybar-app-font
        print_success "sketchybar-app-font installed"
    else
        print_success "sketchybar-app-font already installed"
    fi
    
    # Check for SF fonts (they come with macOS)
    if fc-list | grep -q "SF Pro"; then
        print_success "SF Pro fonts found"
    else
        print_warning "SF Pro fonts not found. You may need to:"
        echo "  1. Download from https://developer.apple.com/fonts/"
        echo "  2. Or the config will fall back to JetBrains Mono"
    fi
    
    # Optional: Install JetBrains Mono as fallback
    read -p "Install JetBrains Mono Nerd Font as fallback? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew tap homebrew/cask-fonts
        brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || true
        print_success "JetBrains Mono Nerd Font installed"
    fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    print_step "Checking Xcode Command Line Tools..."
    
    if xcode-select -p &> /dev/null; then
        print_success "Xcode Command Line Tools already installed"
    else
        print_step "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        # Wait for installation
        echo "Please complete the Xcode Command Line Tools installation in the popup window."
        echo "Press any key to continue after installation is complete..."
        read -n 1 -s
        
        if xcode-select -p &> /dev/null; then
            print_success "Xcode Command Line Tools installed"
        else
            print_error "Failed to install Xcode Command Line Tools"
            exit 1
        fi
    fi
}

# Download and install SbarLua
install_sbarlua() {
    print_step "Installing SbarLua module..."
    
    # Create directory if it doesn't exist
    mkdir -p "$SBARLUA_DIR"
    
    # Detect architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        SBARLUA_ARCH="arm64"
    else
        SBARLUA_ARCH="x86_64"
    fi
    
    print_step "Detected architecture: $SBARLUA_ARCH"
    
    # Download the latest SbarLua release
    print_step "Downloading SbarLua..."
    
    # Get the latest release URL from GitHub
    SBARLUA_URL=$(curl -s https://api.github.com/repos/FelixKratz/SbarLua/releases/latest | \
        grep "browser_download_url.*${SBARLUA_ARCH}" | \
        cut -d '"' -f 4 | \
        head -n 1)
    
    if [[ -z "$SBARLUA_URL" ]]; then
        print_error "Could not find SbarLua release for architecture: $SBARLUA_ARCH"
        print_warning "You may need to build SbarLua from source"
        print_warning "Visit: https://github.com/FelixKratz/SbarLua"
    else
        # Download and extract
        TEMP_DIR=$(mktemp -d)
        curl -L "$SBARLUA_URL" -o "$TEMP_DIR/sbarlua.tar.gz"
        tar -xzf "$TEMP_DIR/sbarlua.tar.gz" -C "$TEMP_DIR"
        
        # Find and copy the .so file
        find "$TEMP_DIR" -name "*.so" -exec cp {} "$SBARLUA_DIR/" \;
        
        # Clean up
        rm -rf "$TEMP_DIR"
        
        if ls "$SBARLUA_DIR"/*.so 1> /dev/null 2>&1; then
            print_success "SbarLua module installed to $SBARLUA_DIR"
        else
            print_error "Failed to install SbarLua module"
            exit 1
        fi
    fi
}

# Compile C binaries
compile_binaries() {
    print_step "Compiling C event providers..."
    
    cd "$SKETCHYBAR_CONFIG_DIR/helpers"
    
    # Clean previous builds
    make clean 2>/dev/null || true
    
    # Compile
    if make; then
        print_success "C binaries compiled successfully"
        
        # Verify binaries exist
        BINARIES=("cpu_load" "ram_load" "network_load")
        for binary in "${BINARIES[@]}"; do
            if [[ -f "event_providers/$binary/bin/$binary" ]]; then
                print_success "  ✓ $binary"
            else
                print_warning "  ⚠ $binary not found"
            fi
        done
        
        # Check for menus binary
        if [[ -f "menus/bin/menus" ]]; then
            print_success "  ✓ menus"
        else
            print_warning "  ⚠ menus not found"
        fi
    else
        print_error "Failed to compile C binaries"
        print_warning "Some features may not work correctly"
    fi
    
    cd - > /dev/null
}

# Detect network interface
detect_network_interface() {
    print_step "Detecting network interface..."
    
    # Try to get the primary network interface
    INTERFACE=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
    
    if [[ -z "$INTERFACE" ]]; then
        # Fallback: look for active interfaces
        INTERFACE=$(ifconfig | grep -E "^en[0-9]" | head -1 | cut -d: -f1)
    fi
    
    if [[ -n "$INTERFACE" ]]; then
        print_success "Detected network interface: $INTERFACE"
    else
        INTERFACE="en0"
        print_warning "Could not detect network interface, using default: $INTERFACE"
    fi
}

# Detect device type
detect_device_type() {
    print_step "Detecting device type..."
    
    # Check if battery exists (indicates laptop)
    if pmset -g batt &>/dev/null; then
        DEVICE_TYPE="laptop"
        print_success "Detected device type: laptop"
    else
        DEVICE_TYPE="desktop"
        print_success "Detected device type: desktop"
    fi
}

# Configure settings
configure_settings() {
    print_step "Configuring settings..."
    
    # Update config.lua with detected settings
    CONFIG_FILE="$SKETCHYBAR_CONFIG_DIR/config.lua"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Backup existing config
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
        print_success "Backed up existing config to config.lua.backup"
    fi
    
    # Update network interface in config.lua
    if [[ -f "$CONFIG_FILE" ]]; then
        # Update network interface
        sed -i '' "s/M.network_interface = \".*\"/M.network_interface = \"$INTERFACE\"/" "$CONFIG_FILE"
        
        # Update device type
        sed -i '' "s/M.device_type = \".*\"/M.device_type = \"$DEVICE_TYPE\"/" "$CONFIG_FILE"
        
        print_success "Updated configuration with detected settings"
    fi
}

# Install optional dependencies
install_optional_deps() {
    print_step "Optional dependencies..."
    
    # AeroSpace window manager
    read -p "Install AeroSpace window manager? (recommended) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install --cask nikitabobko/tap/aerospace
        print_success "AeroSpace installed"
    fi
    
    # jq for JSON parsing
    if ! command -v jq &> /dev/null; then
        read -p "Install jq (for better JSON parsing)? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install jq
            print_success "jq installed"
        fi
    fi
}

# Reload SketchyBar
reload_sketchybar() {
    print_step "Reloading SketchyBar..."
    sketchybar --reload
    print_success "SketchyBar reloaded"
}

# Main installation flow
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     SketchyBar Configuration Installer       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "$SKETCHYBAR_CONFIG_DIR/sketchybarrc" ]]; then
        print_error "This script should be run from the SketchyBar config directory"
        print_error "Expected location: $SKETCHYBAR_CONFIG_DIR"
        exit 1
    fi
    
    check_macos
    install_homebrew
    install_sketchybar
    install_fonts
    install_xcode_tools
    install_sbarlua
    compile_binaries
    detect_network_interface
    detect_device_type
    configure_settings
    install_optional_deps
    reload_sketchybar
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Installation Complete! 🎉             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo
    print_success "SketchyBar is now configured and running!"
    echo
    echo "Next steps:"
    echo "  1. Check the bar at the top of your screen"
    echo "  2. Customize settings in: $SKETCHYBAR_CONFIG_DIR/config.lua"
    echo "  3. Reload after changes: sketchybar --reload"
    echo
    echo "For troubleshooting, check:"
    echo "  • Logs: tail -f /tmp/sketchybar_*.out"
    echo "  • Docs: $SKETCHYBAR_CONFIG_DIR/CLAUDE.md"
}

# Run main installation
main