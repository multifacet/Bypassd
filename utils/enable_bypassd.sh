#!/bin/bash

SCRIPT_PATH=$(realpath $0)
BYPASSD_DIR=$(dirname ${SCRIPT_PATH})/../

# Check if the Bypassd module is installed
if lsmod | grep -wq 'bypassd'; then
    echo "Bypassd module is already installed"
else
    pushd ${BYPASSD_DIR}/kernel/module
    make
    sudo insmod bypassd.ko
    popd
fi

# Check if the userLib is built
if [ ! -f ${BYPASSD_DIR}/userLib/libshim.so ]; then
    pushd ${BYPASSD_DIR}/userLib
    make
    popd
fi

# Enable bypassd parameters
sudo bash -c "echo 1 > /proc/fs/ext4/nvme0n1/swiftcore_dram_pt"
sudo bash -c "echo 4 > /proc/fs/swiftcore/swiftcore_filesize_limit"

# Allocate hugepages for DMA buffers
sudo bash -c "echo 128 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"