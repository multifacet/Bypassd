#!/bin/bash

DEV_NAME=$1

# Check if device is mounted. If so, unmount it.
if [ ! -z "$(cat /proc/mounts | grep -m 1 $DEV_NAME)" ]; then
    # Find where the device is mounted
    MOUNT_POINT=$(cat /proc/mounts | grep -m 1 $DEV_NAME | cut -d ' ' -f 2)
    echo "Unmounting $DEV_NAME from $MOUNT_POINT"
    sudo umount $DEV_NAME
fi