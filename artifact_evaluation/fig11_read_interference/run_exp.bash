#!/bin/bash

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH})
BYPASSD_DIR=$SCRIPT_DIR/../../
USERLIB_DIR=$BYPASSD_DIR/userLib
FIO_DIR=$BYPASSD_DIR/workloads/fio

# Need to check that kernel is installed

# Disable CPU frequency scaling
${BYPASSD_DIR}/utils/cpu_freq_scaling.sh disable

# Copy the workload config to tmp directory
if [ -d /tmp/bypassd ]; then
    rm -r /tmp/bypassd
fi
mkdir /tmp/bypassd
cp $SCRIPT_DIR/fio-rread.fio /tmp/bypassd
WORKLOAD_FILE=/tmp/bypassd/fio-rread.fio

# Create results directory
RESULTS_DIR=$SCRIPT_DIR/results
if [ ! -d ${RESULTS_DIR} ]; then
    mkdir $SCRIPT_DIR/results
fi

FIO_OPTIONS='--lat_percentiles=1 --clat_percentiles=0'

# Run baseline linux evaluations
for BG_PROCS in 1 2 4 8 12 16
do
    sed -i "0,/numjobs=/{s/numjobs=.*/numjobs=${BG_PROCS}/}" ${WORKLOAD_FILE}
    sudo $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/baseline_${BG_PROCS}.out
done

# Run bypassd evaluations
bash ${BYPASSD_DIR}/utils/enable_bypassd.sh
bash ${BYPASSD_DIR}/utils/set_num_queues_userlib.sh 20

for BG_PROCS in 1 2 4 8 12 16
do
    sed -i "0,/numjobs=/{s/numjobs=.*/numjobs=${BG_PROCS}/}" ${WORKLOAD_FILE}
    sudo LD_PRELOAD=${USERLIB_DIR}/libshim.so $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/bypassd_${BG_PROCS}.out
done
bash ${BYPASSD_DIR}/utils/disable_bypassd.sh

# Plot the graph
python3 ${SCRIPT_DIR}/plot.py $SCRIPT_DIR/results

# Delete tmp files
rm -r /tmp/bypassd

# Enable CPU frequency scaling
${BYPASSD_DIR}/utils/cpu_freq_scaling.sh enable