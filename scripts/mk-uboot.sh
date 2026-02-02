#!/bin/bash

# ============================================================================
# U-Boot Build Script for Embedded Devices
#
# Purpose: Clone and build U-Boot bootloader for ARM devices
# ============================================================================

# Configuration
DEVICE_NAME="teclast-a10t"
UBOOT_VERSION="v2020.10"
UBOOT_REPO="https://github.com/geekchun/u-boot.git"
CROSS_COMPILE="arm-linux-gnueabihf-"
BUILD_JOBS=$(nproc)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# ============================================================================
# Step 1: Install Dependencies
# ============================================================================

log_info "Checking and installing build dependencies..."

# Check for required tools
required_tools=("swig" "git" "arm-linux-gnueabihf-gcc")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

# Install missing tools if any
if [ ${#missing_tools[@]} -gt 0 ]; then
    log_warn "Missing tools: ${missing_tools[*]}"
    log_info "Installing required packages..."
    
    sudo apt-get update -qq
    sudo apt-get install -y \
        git \
        build-essential \
        gcc-arm-linux-gnueabihf \
        make \
        bison \
        flex \
        libssl-dev \
        python3-distutils \
        swig \
        python3-dev || {
        log_error "Failed to install dependencies"
        exit 1
    }
    
    log_success "Dependencies installed"
else
    log_success "All dependencies are available"
fi

# ============================================================================
# Step 2: Clone U-Boot Repository
# ============================================================================

echo ""
log_info "Cloning U-Boot repository for $DEVICE_NAME..."
log_info "Version: $UBOOT_VERSION"

git clone --depth=1 --branch "$DEVICE_NAME-$UBOOT_VERSION" "$UBOOT_REPO" 

log_success "Repository cloned"

# ============================================================================
# Step 3: Configure and Build U-Boot
# ============================================================================

echo ""
log_info "Entering u-boot directory..."
cd u-boot || { log_error "Failed to enter u-boot directory"; exit 1; }

echo ""
log_info "Configuring U-Boot..."
make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" "${DEVICE_NAME//-/_}_defconfig" > /dev/null 2>&1 || {
    log_error "Failed to configure U-Boot"
    exit 1
}
log_success "Configuration complete"

echo ""
log_info "Building U-Boot (using $BUILD_JOBS jobs)..."
make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" -j"$BUILD_JOBS" || {
    log_error "Failed to build U-Boot"
    exit 1
}

# ============================================================================
# Step 4: Verify Build Output
# ============================================================================

echo ""
log_info "Verifying build output..."

if [ -f "u-boot" ] || [ -f "u-boot.bin" ]; then
    log_success "U-Boot build completed successfully!"
    echo ""
    echo -e "${BLUE}=== Build Summary ===${NC}"
    echo "Device:      $DEVICE_NAME"
    echo "Version:     $UBOOT_VERSION"
    echo "Location:    $(pwd)"
    echo ""
    echo "Generated binaries:"
    ls -lh u-boot* 2>/dev/null | grep -v ".o" | awk '{printf "  %-30s %8s\n", $9, $5}'
    echo ""
else
    log_error "Build verification failed: No binary files found"
    exit 1
fi
