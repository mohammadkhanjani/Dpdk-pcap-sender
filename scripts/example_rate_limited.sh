#!/bin/bash

# Example script demonstrating rate-limited packet transmission with DPDK
# This script shows how to send packets at specific rates using interface0.sh

echo "DPDK Rate-Limited Packet Transmission Examples"
echo "=============================================="
echo ""

# Check if a pcap file was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <pcap_file>"
    echo ""
    echo "Examples:"
    echo "  $0 test.pcap                    # Send at maximum rate (no limit)"
    echo "  $0 test.pcap 1 100              # Send with 1 queue at 100 Mbps"
    echo "  $0 test.pcap 4 1000             # Send with 4 queues at 1000 Mbps"
    echo "  $0 test.pcap 2 500              # Send with 2 queues at 500 Mbps"
    exit 1
fi

PCAP_FILE="$1"
QUEUES="${2:-4}"        # Default to 4 queues
RATE="${3:-}"           # No rate limit by default

# Check if pcap file exists
if [ ! -f "$PCAP_FILE" ]; then
    echo "Error: PCAP file '$PCAP_FILE' not found!"
    exit 1
fi

echo "Configuration:"
echo "  PCAP file: $PCAP_FILE"
echo "  TX queues: $QUEUES"

if [ -z "$RATE" ]; then
    echo "  Rate limit: None (maximum speed)"
    echo ""
    echo "Starting packet transmission at maximum rate..."
    ./scripts/interface0.sh "$PCAP_FILE" "$QUEUES"
else
    echo "  Rate limit: ${RATE} Mbps"
    echo ""
    echo "Starting rate-limited packet transmission..."
    ./scripts/interface0.sh "$PCAP_FILE" "$QUEUES" "$RATE"
fi