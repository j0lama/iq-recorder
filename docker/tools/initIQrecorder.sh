#!/bin/bash

CONFIG=$(echo "$CONFIG64" | base64 -d)

# Parse configuration
USRP=$(jq -r ".usrp" <<< "$CONFIG")
EARFCN=$(jq -r ".earfcn" <<< "$CONFIG")
FREQ=$(python3 earfcn2freq.py $EARFCN)
GAIN=$(jq -r ".gain" <<< "$CONFIG")
DURATION=$(jq -r ".duration_sec" <<< "$CONFIG")
ISOLCPUS=$(cat /sys/devices/system/cpu/isolated)

if [ -z "$ISOLCPUS" ]; then
    ./rx_samples_to_file --args "serial=$USRP" --file logs/${FREQ}_output.iq --freq $FREQ --rate 23.04e6 --gain $GAIN --duration $DURATION --stats
else
    taskset -c $ISOLCPUS ./rx_samples_to_file --args "serial=$USRP" --file logs/$FREQ_output.iq --freq $FREQ --rate 23.04e6 --gain $GAIN --duration $DURATION --stats
fi
