#!/bin/bash

UBUNTU_VERSION="22.04.5"
UBUNTU_RELEASE="jammy"
UBUNTU_ARCH="armhf"
ROOTFS_DIR="ubuntu-rootfs"
ROOTFS_ARCHIVE="ubuntu-base-$UBUNTU_VERSION-base-${UBUNTU_ARCH}.tar.gz"


# chroot rootfs
echo "Setting up chroot environment..."
cp /etc/resolv.conf $ROOTFS_DIR/etc/resolv.conf
cp /usr/bin/qemu-arm-static $ROOTFS_DIR/usr/bin/qemu-arm-static
chmod   +x $ROOTFS_DIR/usr/bin/qemu-arm-static

mount -t proc /proc $ROOTFS_DIR/proc
mount --bind /sys $ROOTFS_DIR/sys
mount --bind /dev $ROOTFS_DIR/dev
mount --bind /dev/pts $ROOTFS_DIR/dev/pts



chroot $ROOTFS_DIR /bin/bash
echo "Exiting chroot environment..."
umount $ROOTFS_DIR/dev/pts
umount $ROOTFS_DIR/dev  
umount $ROOTFS_DIR/sys
umount $ROOTFS_DIR/proc
