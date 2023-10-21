#!/bin/bash

SCRIPT_PATH=$(realpath $0)
BYPASSD_DIR=$(dirname ${SCRIPT_PATH})/../

# Check that mount point is passed to this script
if [ $# -ne 2 ]; then
    echo "Usage: $0 <device_name> <mount point>"
    exit 1
fi
DEV_NAME=$1
MOUNT_POINT=$2

# Check if the Bypassd module is installed
if lsmod | grep -wq 'bypassd'; then
    echo "Bypassd module is already installed"
else
    pushd ${BYPASSD_DIR}/kernel/module
    make
    sudo insmod bypassd.ko
    popd
fi

# Build userLib
pushd ${BYPASSD_DIR}/userLib

sed -i "/char DEVICE_DIR/c\const char DEVICE_DIR[32] = \"${MOUNT_POINT}\";" shim.c
# Check if syscall intercept has been built
if [ ! -f syscall_intercept/build/libsyscall_intercept.so ]; then
    bash build_shim.sh
fi
make clean; make
popd

# Enable bypassd parameters
# Extract just the 'nvme' part from device name
# TODO: need to check if these files exist
DEV_ID=$(basename $DEV_NAME)
sudo bash -c "echo 1 > /proc/fs/ext4/${DEV_ID}/swiftcore_dram_pt"
sudo bash -c "echo 4 > /proc/fs/swiftcore/swiftcore_filesize_limit"

# Allocate hugepages for DMA buffers
sudo bash -c "echo 128 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"