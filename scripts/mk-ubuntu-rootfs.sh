#!/bin/bash

# ============================================================================
# Ubuntu ARM Root Filesystem Setup Script
# 
# Purpose: Create a minimal Ubuntu 22.04.5 ARM root filesystem with 
#          USTC mirror sources and essential packages
# ============================================================================

# Configuration
UBUNTU_VERSION="22.04.5"
UBUNTU_RELEASE="jammy"
UBUNTU_ARCH="armhf"
UBUNTU_ROOTFS_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/$UBUNTU_VERSION/release/ubuntu-base-$UBUNTU_VERSION-base-${UBUNTU_ARCH}.tar.gz"
ROOTFS_DIR="ubuntu-rootfs"
ROOTFS_ARCHIVE="ubuntu-base-$UBUNTU_VERSION-base-${UBUNTU_ARCH}.tar.gz"
HOSTNAME="JujubePi"

# User Account Configuration
ROOT_PASSWORD="geekchun"          # Root user password
USER_NAME="geekchun"               # Non-root user name
USER_PASSWORD="geekchun"           # Non-root user password

# USTC Mirror Configuration
USTC_MIRROR="mirrors.ustc.edu.cn"
SECURITY_MIRROR="security.ubuntu.com"

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
# Step 1: Download Ubuntu Rootfs
# ============================================================================

log_info "Downloading Ubuntu $UBUNTU_VERSION root filesystem..."
wget $UBUNTU_ROOTFS_URL -O $ROOTFS_ARCHIVE || {
    log_error "Failed to download rootfs"
    exit 1
}

# ============================================================================
# Step 2: Extract Rootfs
# ============================================================================

mkdir -p $ROOTFS_DIR
log_info "Extracting root filesystem..."
sudo tar -xzf $ROOTFS_ARCHIVE -C $ROOTFS_DIR || {
    log_error "Failed to extract rootfs"
    exit 1
}

# ============================================================================
# Step 3: Setup QEMU for ARM Emulation
# ============================================================================

log_info "Setting up QEMU for ARM emulation..."
if [ ! -f /usr/bin/qemu-arm-static ]; then
    log_warn "QEMU static binary not found. Installing qemu-user-static..."
    sudo apt-get update
    sudo apt-get install -y qemu-user-static || {
        log_error "Failed to install qemu-user-static"
        exit 1
    }
fi

log_info "Copying QEMU binary into root filesystem..."
sudo cp /usr/bin/qemu-arm-static $ROOTFS_DIR/usr/bin/
sudo chmod +x $ROOTFS_DIR/usr/bin/qemu-arm-static

# ============================================================================
# Step 4: Configure DNS
# ============================================================================

log_info "Setting up DNS configuration..."
sudo bash -c 'echo "nameserver 8.8.8.8" > '$ROOTFS_DIR'/etc/resolv.conf'
sudo bash -c 'echo "nameserver 114.114.114.114" >> '$ROOTFS_DIR'/etc/resolv.conf'

# ============================================================================
# Step 5: Configure APT Sources (USTC Mirror)
# ============================================================================

log_info "Replacing APT sources with USTC (中科大) mirror..."
sudo tee $ROOTFS_DIR/etc/apt/sources.list > /dev/null << 'EOF'
# Ubuntu Ports Archive Mirror - USTC
deb http://mirrors.ustc.edu.cn/ubuntu-ports jammy main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu-ports jammy-updates main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu-ports jammy-backports main restricted universe multiverse

# Security Updates
deb http://security.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
EOF

# ============================================================================
# Step 6: Mount Filesystems for Chroot
# ============================================================================

log_info "Mounting filesystems and preparing chroot environment..."
sudo mount --bind /dev $ROOTFS_DIR/dev
sudo mount --bind /dev/pts $ROOTFS_DIR/dev/pts
sudo mount -t proc /proc $ROOTFS_DIR/proc
sudo mount -t sysfs /sys $ROOTFS_DIR/sys

# ============================================================================
# Step 7: Install Packages via Chroot
# ============================================================================

log_info "Entering chroot environment and installing packages..."
sudo chroot $ROOTFS_DIR /bin/bash << CHROOT_EOF
# Update package list
apt-get update

# ============================================================================
# Configure System Settings
# ============================================================================

# Configure hostname
echo "$HOSTNAME" > /etc/hostname

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create non-root user
useradd -m -s /bin/bash "$USER_NAME"
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# Grant sudo privileges to non-root user
usermod -aG sudo "$USER_NAME"

echo "${GREEN}[✓]${NC} System configuration completed"
echo "  - Hostname: $HOSTNAME"
echo "  - Root user password: configured"
echo "  - User '$USER_NAME' created with sudo privileges"
echo ""

# ============================================================================
# Install Packages
# ============================================================================

# Install essential packages
echo "${GREEN}[INFO]${NC} Installing development tools..."
apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    git

echo "${GREEN}[INFO]${NC} Installing utilities..."
apt-get install -y \
    nano \
    vim \
    wget \
    curl \
    neofetch \
    screenfetch 

echo "${GREEN}[INFO]${NC} Installing network tools..."
apt-get install -y \
    net-tools \
    iputils-ping \
    openssh-client \
    openssh-server

echo "${GREEN}[INFO]${NC} Installing hardware tools..."
apt-get install -y \
    i2c-tools

echo "${GREEN}[✓]${NC} Package installation completed successfully"
CHROOT_EOF

# ============================================================================
# Step 8: Unmount Filesystems
# ============================================================================

log_info "Unmounting filesystems..."
sudo umount -l $ROOTFS_DIR/sys
sudo umount -l $ROOTFS_DIR/proc
sudo umount -l $ROOTFS_DIR/dev/pts
sudo umount -l $ROOTFS_DIR/dev

# ============================================================================
# Step 9: Cleanup
# ============================================================================

log_info "Cleaning up temporary files..."
rm -f $ROOTFS_DIR/usr/bin/qemu-arm-static
rm -f $ROOTFS_ARCHIVE

# ============================================================================
# Completion
# ============================================================================

log_success "Ubuntu root filesystem setup completed successfully!"
log_info "Root filesystem location: $(pwd)/$ROOTFS_DIR"
echo ""
echo -e "${BLUE}=== Setup Complete ===${NC}"
log_info "Next steps:"
log_info "  1. To enter chroot for manual modifications: ./$(basename $0) chroot"
log_info "  2. Compress the rootfs: tar -czf rootfs.tar.gz $ROOTFS_DIR"
log_info "  3. Deploy to your ARM device"
log_info "  4. Boot and verify the system"
echo "" 