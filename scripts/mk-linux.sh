#!/bin/bash

#!/bin/bash

# ============================================================================
# U-Boot Build Script for Embedded Devices
#
# Purpose: Clone and build U-Boot bootloader for ARM devices
# ============================================================================

# Configuration
DEVICE_NAME="teclast-a10t"
LINUX_VERSION="v6.0"
LINUX_REPO="https://github.com/geekchun/linux.git"
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

git clone --depth=1 --branch "$DEVICE_NAME-$LINUX_VERSION" "$LINUX_REPO"

cd linux

log_info "Configuring kernel for $DEVICE_NAME..."
make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" "${DEVICE_NAME//-/_}_defconfig"

make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" -j"$BUILD_JOBS"

make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" headers_install INSTALL_HDR_PATH=../ubuntu-rootfs/usr