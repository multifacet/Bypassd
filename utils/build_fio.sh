#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))
BASE_DIR=$SCRIPT_DIR/../
FIO_DIR=$BASE_DIR/workloads/fio

pushd $FIO_DIR

# Build fio
./configure
make -j $(nproc)

popd
