#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))

# Reset spdk config
sudo bash $SCRIPT_DIR/../spdk/scripts/setup.sh reset

sleep 1