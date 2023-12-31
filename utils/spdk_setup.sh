#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))

# Make sure device name is provided
if [ -z "$1" ]; then
    echo "Please provide device name."
    exit 1
fi

DEV_NAME=$1

# Unmount device from mount point
bash $SCRIPT_DIR/unmount_dev.sh $DEV_NAME

DEV_ID=$(basename $DEV_NAME)
DEV_PCI_ADDR=$(cat /sys/block/$DEV_ID/device/address)

sleep 1
# Run spdk setup
sudo PCI_ALLOWED=${DEV_PCI_ADDR} bash $SCRIPT_DIR/../spdk/scripts/setup.sh config
