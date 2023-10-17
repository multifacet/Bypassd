#!/bin/bash

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH})
BYPASSD_DIR=$SCRIPT_DIR/../../
USERLIB_DIR=$BYPASSD_DIR/userLib
FIO_DIR=$BYPASSD_DIR/workloads/fio

# Ensure that device name and mount point are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <device name> <mount point>"
    exit 1
fi

DEV_NAME=$1
MOUNT_POINT=$2

# Mount the device (if not already mounted)
bash $BYPASSD_DIR/utils/mount_dev.sh $DEV_NAME $MOUNT_POINT

# Disable CPU frequency scaling
bash ${BYPASSD_DIR}/utils/cpu_freq_scaling.sh disable

# Copy the workload config to tmp directory
if [ -d /tmp/bypassd ]; then
    rm -r /tmp/bypassd
fi
mkdir /tmp/bypassd
cp $SCRIPT_DIR/fio-rand-read.fio /tmp/bypassd
WORKLOAD_FILE=/tmp/bypassd/fio-rand-read.fio

# Update the filename in the workload file
sed -i "s|filename=.*|filename=${MOUNT_POINT}/fio-rand-read|g" ${WORKLOAD_FILE}

# Create results directory
RESULTS_DIR=$SCRIPT_DIR/results
if [ ! -d ${RESULTS_DIR} ]; then
    mkdir $SCRIPT_DIR/results
fi

# Enable bypassd
bash ${BYPASSD_DIR}/utils/enable_bypassd.sh $MOUNT_POINT

FIO_OPTIONS='--lat_percentiles=1 --clat_percentiles=0'

# Run baseline linux evaluations
sed -i 's/ioengine=.*/ioengine=psync/g' ${WORKLOAD_FILE}
for THREADS in 1 2 4 8 12 16 20
do
    sed -i 's/numjobs=.*/numjobs='${THREADS}'/g' ${WORKLOAD_FILE}
    sudo $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/baseline_${THREADS}.out
done

# Run libaio evaluations
sed -i 's/ioengine=.*/ioengine=libaio/g' ${WORKLOAD_FILE}
for THREADS in 1 2 4 8 12 16 20
do
    sed -i 's/numjobs=.*/numjobs='${THREADS}'/g' ${WORKLOAD_FILE}
    sudo $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/libaio_${THREADS}.out
done

# Run io_uring evaluations
sed -i 's/ioengine=.*/ioengine=io_uring/g' ${WORKLOAD_FILE}
echo "sqthread_poll=1" >> ${WORKLOAD_FILE} # Enable SQ polling
echo "fixedbufs=1" >> ${WORKLOAD_FILE}     # Enable fixed buffers
for THREADS in 1 2 4 8 12 16 20
do
    sed -i 's/numjobs=.*/numjobs='${THREADS}'/g' ${WORKLOAD_FILE}
    sudo $FIO_DIR/fio ${FIO_OPTIONS}  ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/iouring_${THREADS}.out
done

# Run bypassd evaluations
bash ${BYPASSD_DIR}/utils/set_num_queues_userlib.sh 20

sed -i 's/ioengine=.*/ioengine=psync/g' ${WORKLOAD_FILE}
sed -i '/sqthread_poll/d' ${WORKLOAD_FILE}
sed -i '/fixedbufs/d' ${WORKLOAD_FILE}
for THREADS in 1 2 4 8 12 16 20
do
    sed -i 's/numjobs=.*/numjobs='${THREADS}'/g' ${WORKLOAD_FILE}
    sudo LD_PRELOAD=${USERLIB_DIR}/libshim.so $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/bypassd_${THREADS}.out
done
bash ${BYPASSD_DIR}/utils/disable_bypassd.sh

# Run SPDK evaluations
# Need to figure out the device address for SPDK
DEV_ID=$(basename $DEV_NAME)
DEV_PCI_ADDR=$(cat /sys/block/$DEV_ID/device/address)
# Replace ':' with '.' in the PCI address
DEV_PCI_ADDR=$(echo $DEV_PCI_ADDR | sed 's/:/./g')

# Need to bind device to UIO driver so that SPDK can use it
bash ${BYPASSD_DIR}/utils/spdk_setup.sh $DEV_NAME
sed -i 's/ioengine=.*/ioengine=spdk/g' ${WORKLOAD_FILE}
sed -i "s/filename=.*/filename=trtype=PCIe traddr=${DEV_PCI_ADDR}/g" ${WORKLOAD_FILE}
for THREADS in 1 2 4 8 12 16 20
do
    sed -i 's/numjobs=.*/numjobs='${THREADS}'/g' ${WORKLOAD_FILE}
    sudo LD_PRELOAD=${BYPASSD_DIR}/spdk/build/fio/spdk_nvme $FIO_DIR/fio ${FIO_OPTIONS} ${WORKLOAD_FILE} 2>&1 | tee $SCRIPT_DIR/results/spdk_${THREADS}.out
done
# Rebind device to kernel driver
bash ${BYPASSD_DIR}/utils/spdk_reset.sh $DEV_NAME $MOUNT_POINT

# Plot the graph
python3 ${SCRIPT_DIR}/plot.py $SCRIPT_DIR/results

# Delete tmp files
rm -r /tmp/bypassd

# Enable CPU frequency scaling
bash ${BYPASSD_DIR}/utils/cpu_freq_scaling.sh enable
