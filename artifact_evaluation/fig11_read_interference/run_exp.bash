#!/bin/bash

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH})
BYPASSD_DIR=$SCRIPT_DIR/../../
USERLIB_DIR=$BYPASSD_DIR/userLib
FIO_DIR=$BYPASSD_DIR/workloads/fio

# Need to check that kernel is installed

# Disable CPU frequency scaling
${BYPASSD_DIR}/utils/cpu_freq_scaling.sh disable

BACKGROUND_FILE=fio-bg-read.fio
WORKLOAD_FILE=fio-read.fio

# Create results directory
RESULTS_DIR=$SCRIPT_DIR/results
if [ ! -d ${RESULTS_DIR} ]; then
    mkdir $SCRIPT_DIR/results
fi

FIO_OPTIONS='--lat_percentiles=1 --clat_percentiles=0'

# Run baseline linux evaluations
for BG_PROCS in 1 2 4 8 12 16
do
    for i in $(seq 1 $BG_PROCS)
    do
        sudo $FIO_DIR/fio ${BACKGROUND_FILE} > /dev/null &
    done
    sudo $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/baseline_${BG_PROCS}.out
    wait # Wait for background processes to finish
done

# Run bypassd evaluations
bash ${BYPASSD_DIR}/utils/enable_bypassd.sh
bash ${BYPASSD_DIR}/utils/set_num_queues_userlib.sh 1

for BG_PROCS in 1 2 4 8 12 16
do
    for i in $(seq 1 $BG_PROCS)
    do
        sudo LD_PRELOAD=${USERLIB_DIR}/libshim.so $FIO_DIR/fio ${BACKGROUND_FILE} > /dev/null &
    done
    sudo LD_PRELOAD=${USERLIB_DIR}/libshim.so $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/bypassd_${BG_PROCS}.out
    wait
done
bash ${BYPASSD_DIR}/utils/disable_bypassd.sh

# Plot the graph
python3 ${SCRIPT_DIR}/plot.py $SCRIPT_DIR/results

# Enable CPU frequency scaling
${BYPASSD_DIR}/utils/cpu_freq_scaling.sh enable