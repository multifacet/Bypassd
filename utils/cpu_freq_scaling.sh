#!/bin/bash

NUM_CORES=$(nproc --all)

# Silent pushd and popd
pushd () {
    command pushd "$@" > /dev/null
}
popd () {
    command popd "$@" > /dev/null
}

pushd /sys/devices/system/cpu

# Check if the CPU has cpufreq
if [ ! -d cpu0/cpufreq ]; then
    echo "CPU frequency scaling not supported."
    popd
    exit 1
fi

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
