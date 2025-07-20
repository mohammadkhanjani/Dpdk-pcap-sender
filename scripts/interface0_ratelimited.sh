#!/bin/bash

#Enhanced DPDK rate-limited packet sender script
TXQUEUES=4
NICIFACE=0
BASECPU=0
PCAP_FILE=""
RATE_LIMIT=""
BUILD_DIR="build"

# Function to display usage
show_usage() {
    echo "======================================================================"
    echo "Enhanced DPDK Rate-Limited Packet Sender"
    echo "======================================================================"
    echo "Usage: $0 <pcap_file> [num_queues] [rate_limit_mbps]"
    echo ""
    echo "Parameters:"
    echo "  pcap_file         : Path to PCAP file to transmit"
    echo "  num_queues        : Number of TX queues (default: ${TXQUEUES})"
    echo "  rate_limit_mbps   : Rate limit in Mbps (default: unlimited)"
    echo ""
    echo "Examples:"
    echo "  $0 test.pcap                    # Unlimited rate"
    echo "  $0 test.pcap 4                 # 4 queues, unlimited rate"
    echo "  $0 test.pcap 4 100             # 4 queues, 100 Mbps limit"
    echo "  $0 test.pcap 2 50              # 2 queues, 50 Mbps limit"
    echo "  $0 test.pcap 1 10              # 1 queue, 10 Mbps limit"
    echo ""
    echo "Rate Limiting Features:"
    echo "  - Precise bandwidth control (Mbps)"
    echo "  - Real-time rate monitoring"
    echo "  - Burst size adaptation"
    echo "  - Zero packet loss at specified rates"
    echo ""
    echo "Note: This implementation enforces strict rate limiting."
    echo "      Transmission will never exceed the specified rate."
    echo "======================================================================"
}

# Check for help request
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

PCAP_FILE="$1"

if [ $# -gt 1 ]; then
    TXQUEUES=$2
fi

if [ $# -gt 2 ]; then
    RATE_LIMIT="$3"
fi

# Validate PCAP file
if [ ! -f "$PCAP_FILE" ]; then
    echo "Error: PCAP file '$PCAP_FILE' does not exist!"
    echo "Run '$0 --help' for usage information."
    exit 1
fi

# Build TX parameters
TXPARAM="($NICIFACE,0,$BASECPU)"
if [ $TXQUEUES -gt 1 ]; then
    for i in $(seq 2 $TXQUEUES); do
        QUEUE=$(($i - 1))
        CCPU=$(($BASECPU + $QUEUE))
        TXPARAM="$TXPARAM,($NICIFACE,$QUEUE,$CCPU)"
    done
fi

# Prepare rate limiting parameters
BWL_PARAM=""
if [ ! -z "$RATE_LIMIT" ]; then
    # Validate rate limit is a number
    if ! [[ "$RATE_LIMIT" =~ ^[0-9]+$ ]]; then
        echo "Error: Rate limit must be a positive integer (Mbps)"
        exit 1
    fi
    
    BWL_PARAM="--bwl ${RATE_LIMIT}"
    echo "======================================================================"
    echo "CONFIGURATION SUMMARY"
    echo "======================================================================"
    echo "PCAP File       : $PCAP_FILE"
    echo "TX Queues       : $TXQUEUES"
    echo "Rate Limit      : ${RATE_LIMIT} Mbps (ENFORCED)"
    echo "TX Parameters   : $TXPARAM"
    echo "Rate Limiting   : ENABLED - Transmission will NOT exceed ${RATE_LIMIT} Mbps"
    echo "======================================================================"
else
    echo "======================================================================"
    echo "CONFIGURATION SUMMARY"
    echo "======================================================================"
    echo "PCAP File       : $PCAP_FILE"
    echo "TX Queues       : $TXQUEUES"
    echo "Rate Limit      : UNLIMITED (maximum possible rate)"
    echo "TX Parameters   : $TXPARAM"
    echo "Rate Limiting   : DISABLED"
    echo "======================================================================"
fi

# Set DPDK environment
if [ -z ${RTE_SDK+x} ]; then
    export RTE_SDK=$(pwd)/dpdk
fi

# Build and run
echo "Building application..."
CUR_PATH=$(pwd)
cd ..
rm -rf $BUILD_DIR
mkdir $BUILD_DIR && cd $BUILD_DIR && cmake .. && cmake --build .

if [ $? -ne 0 ]; then
    echo "Error: Build failed!"
    cd $CUR_PATH
    exit 1
fi

echo "Starting rate-limited packet transmission..."
echo "Press Ctrl+C to stop transmission"
echo "======================================================================"

src/./dpdk_pcap_sender -c FF -n 6 -- --rx "(0,0,0)" --tx "$TXPARAM" --rsz "1024, 1024" --bsz "144, 144" --pcap "${PCAP_FILE}" ${BWL_PARAM}

cd $CUR_PATH
echo "Transmission completed."