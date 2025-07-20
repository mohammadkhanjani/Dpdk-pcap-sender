#!/bin/bash

#Base parameters
TXQUEUES=4
NICIFACE=0
BASECPU=0
PCAP_FILE=""
MAX_BW=""       # Optional bandwidth limit in Mbps
BUILD_DIR="build"

if [ $# -le 0 ]
    then echo "A pcap file should be provided to this script. Example: ./scripts/scriptname.sh file.pcap [num of queues, default=${TXQUEUES}]"
    exit 1
fi
PCAP_FILE="$1"

if [ $# -gt 1 ]; then
    TXQUEUES=$2
fi

# Optional third argument: bandwidth limit in Mbps
if [ $# -gt 2 ]; then
    MAX_BW=$3
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

DPDK_ARGS="--rx \"(0,0,0)\" --tx \"$TXPARAM\" --rsz \"1024, 1024\" --bsz \"144, 144\" --caida --pcap \"${PCAP_FILE}\""

# Append bandwidth limit argument if provided
if [ -n "$MAX_BW" ]; then
    DPDK_ARGS="$DPDK_ARGS --bwl \"$MAX_BW\""
fi

src/./dpdk_pcap_sender -c FF -n 6 -- $DPDK_ARGS
cd $CUR_PATH
