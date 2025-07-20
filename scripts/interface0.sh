#!/bin/bash

#Base parameters
TXQUEUES=4
NICIFACE=0
BASECPU=0
PCAP_FILE=""
BUILD_DIR="build"
RATE_LIMIT=""  # New parameter for precise rate limiting

if [ $# -le 0 ]
    then echo "Usage: $0 <pcap_file> [num_queues] [rate_limit_packets_per_second]"
    echo "  pcap_file: Path to the pcap file to send"
    echo "  num_queues: Number of TX queues (default: ${TXQUEUES})"
    echo "  rate_limit_packets_per_second: Precise rate limit in packets per second (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 file.pcap                    # Send at maximum rate"
    echo "  $0 file.pcap 4                  # Send with 4 queues at maximum rate"
    echo "  $0 file.pcap 4 1000            # Send with 4 queues at 1000 packets/second"
    exit 1
fi
PCAP_FILE="$1"

if [ $# -gt 1 ]
    then TXQUEUES=$2
fi

if [ $# -gt 2 ]
    then RATE_LIMIT="--rate $3"
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

# Use existing build if available
if [ -f "build/src/dpdk_pcap_sender" ]; then
    echo "Using existing build..."
    ./build/src/dpdk_pcap_sender -c 1 -n 1 --huge-dir=/mnt/huge --vdev=net_null0 -- --rx "(0,0,0)" --tx "$TXPARAM" --rsz "1024, 1024" --bsz "144, 144" --pcap "${PCAP_FILE}" $RATE_LIMIT
else
    echo "Building project..."
    rm -rf $BUILD_DIR
    mkdir $BUILD_DIR && cd $BUILD_DIR && cmake .. && cmake --build .
    src/./dpdk_pcap_sender -c 1 -n 1 -- --rx "(0,0,0)" --tx "$TXPARAM" --rsz "1024, 1024" --bsz "144, 144" --pcap "${PCAP_FILE}" $RATE_LIMIT
    cd ..
fi

