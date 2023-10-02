#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))

DEV_NAME=$1
MOUNT_POINT=$2

if [ -z "$DEV_NAME" ]; then
    echo "Cannot find device $DEV_NAME. Please change it in the script."
    exit 1
fi
echo "Using device $DEV_NAME"

if [ -z "$MOUNT_POINT" ]; then
    echo "Cannot find mount point $MOUNT_POINT. Please change it in the script."
    exit 1
fi

if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p $MOUNT_POINT
fi

# Remove / at the end mount point if it exists
MOUNT_POINT=${MOUNT_POINT%/}
if [ -z "$(cat /proc/mounts | grep -m 1 $DEV_NAME\\\s$MOUNT_POINT)" ]; then
    # Unmount device from other mount points
    bash $SCRIPT_DIR/unmount_dev.sh $DEV_NAME
    # Check if device has been formatted to ext4
    if [ -z "$(sudo file -sL $DEV_NAME | grep ext4)" ]; then
        echo "Formatting $DEV_NAME to ext4"
        sudo mkfs.ext4 $DEV_NAME
    fi
    # Check if another device is mounted at the mount point
    if [ ! -z "$(cat /proc/mounts | grep -m 1 $MOUNT_POINT)" ]; then
        echo "Another disk mounted at $MOUNT_POINT. Unmounting it."
        sudo umount $MOUNT_POINT
    fi
    echo "Mounting $DEV_NAME at $MOUNT_POINT"
    sudo mount -o defaults,noatime,nodiratime,nodelalloc $DEV_NAME $MOUNT_POINT
fi