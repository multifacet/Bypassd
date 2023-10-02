#!/bin/bash

##########################################################
# *IMPORTANT*: This script doesn't work for Intel pstate.
# Disable frequency scaling manually if CPU has pstate.
##########################################################

NUM_CORES=$(nproc --all)

# Silent pushd and popd
pushd () {
    command pushd "$@" > /dev/null
}
popd () {
    command popd "$@" > /dev/null
}

pushd /sys/devices/system/cpu

for i in $(seq 0 $(($NUM_CORES-1)))
do
    pushd "cpu${i}"/cpufreq

    MAX_FREQ=$(cat cpuinfo_max_freq)
    MIN_FREQ=$(cat cpuinfo_min_freq)

    if [ $1 == "enable" ]; then
        sudo bash -c "echo ${MIN_FREQ} > scaling_max_freq"
        sudo bash -c "echo 'ondemand' > scaling_governor"
    else
        sudo bash -c "echo ${MAX_FREQ} > scaling_max_freq"
        sudo bash -c "echo 'performance' > scaling_governor"
    fi

    popd
done

popd

if [ $1 == "enable" ]; then
    sudo cpupower idle-set --enable-all > /dev/null
else
    sudo cpupower idle-set --disable-by-latency 0 > /dev/null
fi
