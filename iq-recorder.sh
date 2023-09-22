#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "USE: $0 <Operator Config File (JSON)> <Output Folder>"
	echo "Example: .$0 config.json logs/"
    exit 1
fi

LOGS=$(realpath $2)

docker run -ti --privileged --rm -v /dev:/dev -v /proc:/proc -e CONFIG64="$(base64 $1)" -v $LOGS:/uhd/host/build/examples/logs/ princetonpaws/iq-recorder:latest ./initIQrecorder.sh
