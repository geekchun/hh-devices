#!/bin/bash

#同步系统根文件系统脚本

SYSROOT_DIR="sysroot"
TARGET_IP="10.100.174.189" 
TARGET_USER="root"
TARGET_PATH="/"

mkdir -p $SYSROOT_DIR
mkdir -p $SYSROOT_DIR/usr

ssh-keygen -t rsa -b 4096
ssh-copy-id $TARGET_USER@$TARGET_IP


echo "Starting synchronization of system root filesystem from $TARGET_USER@$TARGET_IP:$TARGET_PATH to $SYSROOT_DIR"
rsync -avzL --delete $TARGET_USER@$TARGET_IP:$TARGET_PATH/lib $SYSROOT_DIR
rsync -avzL --delete $TARGET_USER@$TARGET_IP:$TARGET_PATH/usr/lib $SYSROOT_DIR/usr
rsync -avzL --delete $TARGET_USER@$TARGET_IP:$TARGET_PATH/usr/include $SYSROOT_DIR/usr

#修复绝对路径链接
find $SYSROOT_DIR -type l | while read -r link; do
    target=$(readlink "$link")
    if [[ "$target" == /* ]]; then
        new_target="$SYSROOT_DIR$target"
        ln -sf "$new_target" "$link"
    fi
done    

echo "System root filesystem synchronized to $SYSROOT_DIR"