#!/bin/bash

#Base parameters
TXQUEUES=4
NICIFACE=0
BASECPU=0
PCAP_FILE=""
BUILD_DIR="build"
RATE_LIMIT=""

if [ $# -le 0 ]
    then echo "A pcap file should be provided to this script. Example: ./scripts/scriptname.sh file.pcap [num of queues, default=${TXQUEUES}] [rate limit in Mbps, optional]"
    exit 1
fi
PCAP_FILE="$1"

if [ $# -gt 1 ]
    then TXQUEUES=$2
fi

if [ $# -gt 2 ]
    then RATE_LIMIT=$3
fi

TXPARAM="($NICIFACE,0,$BASECPU)"
if [ $TXQUEUES -gt 1 ]; then
        for i in $(seq 2 $TXQUEUES); do
                QUEUE=$(($i - 1))
                CCPU=$(($BASECPU + $QUEUE))
                TXPARAM="$TXPARAM,($NICIFACE,$QUEUE,$CCPU)"
        done
fi

if [ -z ${RTE_SDK+x} ]; then
        export RTE_SDK=$(pwd)/dpdk
fi

CUR_PATH=$(pwd)
cd ..
rm -rf $BUILD_DIR
mkdir $BUILD_DIR && cd $BUILD_DIR && cmake .. && cmake --build .

# Build the command with optional rate limit
CMD="src/./dpdk_pcap_sender -c FF -n 6 -- --rx \"(0,0,0)\" --tx \"$TXPARAM\" --rsz \"1024, 1024\" --bsz \"144, 144\" --pcap \"${PCAP_FILE}\""

if [ ! -z "$RATE_LIMIT" ]; then
    CMD="$CMD --bwl \"$RATE_LIMIT\""
    echo "Rate limiting enabled: ${RATE_LIMIT} Mbps"
fi

echo "Executing: $CMD"
eval $CMD
cd $CUR_PATH

