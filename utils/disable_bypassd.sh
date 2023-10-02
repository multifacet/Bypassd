#!/bin/bash

sudo rmmod bypassd.ko

# Deallocate hugepages for DMA buffers
sudo bash -c "echo 0 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"