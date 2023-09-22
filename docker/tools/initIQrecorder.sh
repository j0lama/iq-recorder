#!/bin/bash

CONFIG=$(echo "$CONFIG64" | base64 -d)

# Parse configuration
USRP=$(jq -r ".usrp" <<< "$CONFIG")
EARFCN=$(jq -r ".earfcn" <<< "$CONFIG")
FREQ=$(python3 earfcn2freq.py $EARFCN)
GAIN=$(jq -r ".gain" <<< "$CONFIG")
DURATION=$(jq -r ".duration_sec" <<< "$CONFIG")
ISOL_CPUS=$(./getIsolatedCPUs.py)
CONSUMER_ISOL_CPU=$(echo $ISOL_CPUS | awk '{ print $1 }')
RECORDER_ISOL_CPU=$(echo $ISOL_CPUS | awk '{ print $NF }')
NUM_ISOL_CPU=$(echo $ISOL_CPUS | awk '{ print NF }')
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create 2G ramdisk for the pipe
mkdir /tmp/ramdisk
mount -t tmpfs -o size=2g tmpfs /tmp/ramdisk

# Init consumer
if [ "$NUM_ISOL_CPU" = 0 ]; then
    printf "${YELLOW}Warning${NC}: No isolated CPUs found, your performance might get affected. Two isolated CPUs are recommended"
    ./consumer logs/${FREQ}_output.iq &
    /usr/local/lib/uhd/examples/rx_samples_to_file --args "serial=$USRP" --file /tmp/ramdisk/pipe --freq $FREQ --rate 23.04e6 --gain $GAIN --duration $DURATION --stats
elif [ "$NUM_ISOL_CPU" = 1 ]; then
    printf "${YELLOW}Warning${NC}: One isolated CPUs found, your performance might get affected. Two isolated CPUs are recommended"
    ./consumer logs/${FREQ}_output.iq &
    taskset -c $RECORDER_ISOL_CPU /usr/local/lib/uhd/examples/rx_samples_to_file --args "serial=$USRP" --file /tmp/ramdisk/pipe --freq $FREQ --rate 23.04e6 --gain $GAIN --duration $DURATION --stats
else
    printf "Using isolated CPUS $CONSUMER_ISOL_CPU and $RECORDER_ISOL_CPU"
    taskset -c $CONSUMER_ISOL_CPU ./consumer logs/${FREQ}_output.iq &
    taskset -c $RECORDER_ISOL_CPU /usr/local/lib/uhd/examples/rx_samples_to_file --args "serial=$USRP" --file /tmp/ramdisk/pipe --freq $FREQ --rate 23.04e6 --gain $GAIN --duration $DURATION --stats
fi