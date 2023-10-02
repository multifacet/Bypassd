#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))
BASE_DIR=$SCRIPT_DIR/../
SPDK_DIR=$BASE_DIR/spdk

pushd $SPDK_DIR

# Install dependencies
sudo ./scripts/pkgdep.sh

# Configure and build
# Configure with fio
./configure --with-fio=$BASE_DIR/workloads/fio
make -j $(nproc)

popd