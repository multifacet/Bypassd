#!/bin/bash
####################################################################
# This script sets the number of queues per process for the userLib.
# Usage: bash set_num_queues_userlib.sh <num_queues>
####################################################################

SCRIPT_PATH=$(realpath $0)
USERLIB_DIR=$(dirname ${SCRIPT_PATH})/../userLib

# Make sure that we have the correct number of arguments
if [ $# -ne 1 ]; then
    echo "Usage: bash set_num_queues_userlib.sh <num_queues>"
    exit 1
fi

NUM_QUEUES=$1

pushd ${USERLIB_DIR}

# Change the number of queues in userlib.h
sed -i "s/#define BYPASSD_NUM_QUEUES .*/#define BYPASSD_NUM_QUEUES ${NUM_QUEUES}/g" userlib.h

# Build the library
make clean; make

popd
