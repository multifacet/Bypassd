#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))

# Ensure device name and mount point are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide device name and mount point."
    exit 1
fi

DEV_NAME=$1
MOUNT_POINT=$2

# Reset spdk config
sudo bash $SCRIPT_DIR/../spdk/scripts/setup.sh reset

# Mount device back to mount point
bash $SCRIPT_DIR/mount_dev.sh $DEV_NAME $MOUNT_POINT