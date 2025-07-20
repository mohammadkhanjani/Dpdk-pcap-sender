#!/bin/bash

# Test script to demonstrate rate limiting functionality
# This script shows how to use the modified interface0.sh with rate limiting

echo "DPDK Packet Sender Rate Limiting Test"
echo "======================================"
echo ""

# Check if a pcap file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <pcap_file> [rate_limit_mbps]"
    echo ""
    echo "Examples:"
    echo "  $0 sample.pcap              # No rate limiting (maximum speed)"
    echo "  $0 sample.pcap 1000         # Rate limit to 1000 Mbps (1 Gbps)"
    echo "  $0 sample.pcap 100          # Rate limit to 100 Mbps"
    echo "  $0 sample.pcap 10           # Rate limit to 10 Mbps"
    echo ""
    echo "Note: Rate limit is applied per port, divided equally among all TX queues"
    exit 1
fi

PCAP_FILE="$1"
RATE_LIMIT="$2"

# Check if pcap file exists
if [ ! -f "$PCAP_FILE" ]; then
    echo "Error: PCAP file '$PCAP_FILE' not found!"
    exit 1
fi

echo "PCAP file: $PCAP_FILE"
if [ ! -z "$RATE_LIMIT" ]; then
    echo "Rate limit: ${RATE_LIMIT} Mbps"
else
    echo "Rate limit: None (maximum speed)"
fi
echo ""

# Run the interface0.sh script with rate limiting
echo "Starting DPDK packet sender..."
echo "================================"

if [ ! -z "$RATE_LIMIT" ]; then
    ./scripts/interface0.sh "$PCAP_FILE" 4 "$RATE_LIMIT"
else
    ./scripts/interface0.sh "$PCAP_FILE" 4
fi