#!/bin/bash

# This script is used to build the Linux kernel for Bypassd.

SCRIPT_DIR=$(dirname $(realpath $0))
BASE_DIR=$SCRIPT_DIR/..
LINUX_DIR=$BASE_DIR/kernel/linux-5.4

# Install dependencies
sudo apt-get update
sudo apt-get install build-dep libncurses-dev flex bison openssl libssl-dev dkms \
    libelf-dev libudev-dev libpci-dev libiberty-dev \
    autoconf fakeroot bc cpio flex libpci-dev

# Build the kernel
pushd $LINUX_DIR

# Configure the kernel
echo "Configuring the kernel..."
cp /boot/config-$(uname -r) .config
echo | make localmodconfig
sleep 1
# Enable the following config options:
# Refer to kernel/config_used_for_eval for more information
sed -i 's/# CONFIG_NVME_CORE is not set/CONFIG_NVME_CORE=y/g' .config
sed -i 's/# CONFIG_BLK_DEV_NVME is not set/CONFIG_BLK_DEV_NVME=y/g' .config
sed -i 's/# CONFIG_UIO is not set/CONFIG_UIO=y/g' .config
sed -i 's/# CONFIG_UIO_PCI_GENERIC is not set/CONFIG_UIO_PCI_GENERIC=y/g' .config
sed -i 's/# CONFIG_EXT4_FS is not set/CONFIG_EXT4_FS=y/g' .config

# Compile the kernel
sudo make -j
# If there is an error during build related to thunk_64.o, refer to these patches:
# https://github.com/torvalds/linux/commit/de979c83574abf6e78f3fa65b716515c91b2613d.patch
# https://github.com/torvalds/linux/commit/1d489151e9f9d1647110277ff77282fe4d96d09b.patch

# Build cpupower tools required for enabling/disabling frequency scaling
pushd tools/power/cpupower
sudo make install
popd

sudo make modules_install -j
# Install the kernel
sudo make install

popd

echo "Kernel for Bypassd has been built and installed."
echo "Use the below command to update grub to use the new kernel."
echo "   sudo grub-reboot \'Advanced options for Ubuntu>Ubuntu, with Linux-5.4.0'"
echo "   sudo reboot"
