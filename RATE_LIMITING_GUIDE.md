# DPDK Packet Sender - Rate Limiting Guide

This guide explains how to use the rate limiting functionality in the DPDK packet sender project.

## Overview

The DPDK packet sender now supports transmission rate limiting through the `--bwl` (bandwidth limit) parameter. This feature allows you to specify a maximum transmission rate in Mbps, ensuring that the packet sender does not exceed the specified rate.

## Usage

### Basic Syntax

```bash
./scripts/interface0.sh <pcap_file> [num_queues] [rate_limit_mbps]
```

### Parameters

- `pcap_file`: Path to the PCAP file containing packets to transmit (required)
- `num_queues`: Number of TX queues to use (optional, default: 4)
- `rate_limit_mbps`: Maximum transmission rate in Mbps (optional, no limit if not specified)

### Examples

#### 1. Send packets at maximum rate (no rate limiting)
```bash
./scripts/interface0.sh test.pcap
./scripts/interface0.sh test.pcap 4
```

#### 2. Send packets with rate limiting
```bash
# Send at 100 Mbps with 1 queue
./scripts/interface0.sh test.pcap 1 100

# Send at 1000 Mbps (1 Gbps) with 4 queues
./scripts/interface0.sh test.pcap 4 1000

# Send at 500 Mbps with 2 queues
./scripts/interface0.sh test.pcap 2 500

# Send at 10 Gbps with 8 queues
./scripts/interface0.sh test.pcap 8 10000
```

#### 3. For CAIDA format files
```bash
# Send CAIDA format at 100 Mbps
./scripts/interface0.caida.sh caida_trace.pcap 4 100
```

### Using the Example Script

A convenient example script is provided that demonstrates various usage patterns:

```bash
# Show usage examples
./scripts/example_rate_limited.sh

# Send at maximum rate
./scripts/example_rate_limited.sh test.pcap

# Send at 100 Mbps with 1 queue
./scripts/example_rate_limited.sh test.pcap 1 100

# Send at 1 Gbps with 4 queues
./scripts/example_rate_limited.sh test.pcap 4 1000
```

## How Rate Limiting Works

The rate limiting feature uses DPDK's hardware-based rate limiting functionality:

1. **Hardware-level control**: The rate limiting is implemented at the NIC hardware level using `rte_eth_set_queue_rate_limit()`
2. **Per-queue distribution**: The specified rate is evenly distributed across all TX queues
3. **Precise control**: The rate limiting ensures packets are not sent faster than the specified rate

### Rate Distribution Across Queues

When you specify a rate limit, it gets distributed evenly across all TX queues:

- 1 queue with 1000 Mbps limit = 1000 Mbps per queue
- 4 queues with 1000 Mbps limit = 250 Mbps per queue
- 8 queues with 1000 Mbps limit = 125 Mbps per queue

## Implementation Details

### Modified Scripts

1. **interface0.sh**: Enhanced to accept rate limit parameter
2. **interface0.caida.sh**: Enhanced to accept rate limit parameter for CAIDA format files
3. **example_rate_limited.sh**: New demonstration script

### Key Changes

- Added `RATE_LIMIT` variable to store the rate parameter
- Modified command line argument parsing to accept the third parameter
- Enhanced the DPDK command construction to include `--bwl` parameter when rate limiting is enabled
- Added informative output when rate limiting is active

### DPDK Application Parameters

The rate limiting uses the existing `--bwl` parameter in the DPDK application:

```bash
src/./dpdk_pcap_sender -c FF -n 6 -- \
    --rx "(0,0,0)" \
    --tx "$TXPARAM" \
    --rsz "1024, 1024" \
    --bsz "144, 144" \
    --pcap "${PCAP_FILE}" \
    --bwl "${RATE_LIMIT}"
```

## Benefits

1. **Controlled transmission**: Prevents overwhelming the network or receiver
2. **Testing scenarios**: Allows simulation of different network conditions
3. **Quality of Service**: Enables testing with specific bandwidth constraints
4. **Hardware efficiency**: Uses NIC hardware capabilities for precise rate control

## Notes

- Rate limiting is optional - if not specified, the sender operates at maximum speed
- The rate limit is specified in Mbps (Megabits per second)
- Rate limiting works with both regular PCAP files and CAIDA format files
- The feature leverages DPDK's native hardware rate limiting capabilities
- All existing functionality remains unchanged when rate limiting is not used

## Troubleshooting

If you encounter issues with rate limiting:

1. Ensure your NIC supports hardware rate limiting
2. Verify the rate limit value is reasonable for your hardware
3. Check that DPDK is properly initialized
4. Monitor the application output for rate limiting confirmation messages