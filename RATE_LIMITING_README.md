# DPDK Packet Sender Rate Limiting

This document describes the rate limiting functionality added to the DPDK packet sender.

## Overview

The DPDK packet sender now supports rate limiting to control the maximum transmission rate. This is useful for:
- Testing network equipment at specific rates
- Simulating different network conditions
- Controlling bandwidth usage
- Performance testing with predictable traffic rates

## How It Works

The rate limiting is implemented using DPDK's `rte_eth_set_queue_rate_limit()` function, which sets a rate limit on each TX queue. The specified rate is divided equally among all TX queues for the port.

## Usage

### Using the Scripts

#### Basic Usage
```bash
# No rate limiting (maximum speed)
./scripts/interface0.sh file.pcap

# With rate limiting (1000 Mbps = 1 Gbps)
./scripts/interface0.sh file.pcap 4 1000

# With rate limiting (100 Mbps)
./scripts/interface0.sh file.pcap 4 100
```

#### CAIDA Trace Support
```bash
# For CAIDA traces with rate limiting
./scripts/interface0.caida.sh file.pcap 4 1000
```

### Using the Test Script

A test script is provided for easy testing:

```bash
# Show usage
./test_rate_limit.sh

# Examples
./test_rate_limit.sh sample.pcap          # No rate limiting
./test_rate_limit.sh sample.pcap 1000     # 1 Gbps rate limit
./test_rate_limit.sh sample.pcap 100      # 100 Mbps rate limit
./test_rate_limit.sh sample.pcap 10       # 10 Mbps rate limit
```

### Direct DPDK Command

You can also use the DPDK command directly:

```bash
# Build the application
mkdir build && cd build && cmake .. && make

# Run with rate limiting
./src/dpdk_pcap_sender -c FF -n 6 -- --rx "(0,0,0)" --tx "(0,0,0),(0,1,1),(0,2,2),(0,3,3)" --rsz "1024, 1024" --bsz "144, 144" --pcap "file.pcap" --bwl "1000"
```

## Parameters

- **PCAP file**: The packet capture file to replay
- **Number of queues**: Number of TX queues (default: 4)
- **Rate limit**: Bandwidth limit in Mbps (optional)

## Rate Limiting Details

### How Rate Limits Are Applied

1. The specified rate limit is applied per port
2. The rate is divided equally among all TX queues for that port
3. Each queue gets `rate_limit / num_queues` Mbps

### Example

If you specify a rate limit of 1000 Mbps with 4 TX queues:
- Each queue gets 250 Mbps (1000 / 4)
- Total transmission rate will not exceed 1000 Mbps

### Supported Rates

- Minimum: 1 Mbps
- Maximum: Depends on your NIC capabilities
- Common values: 10, 100, 1000, 10000 Mbps

## Implementation Details

### Code Changes

1. **Scripts Modified**:
   - `scripts/interface0.sh`: Added rate limit parameter support
   - `scripts/interface0.caida.sh`: Added rate limit parameter support

2. **Core Application**:
   - `src/config.c`: Added `--bwl` parameter parsing
   - `src/init.c`: Fixed queue counting and rate limit application

### Key Functions

- `rte_eth_set_queue_rate_limit()`: DPDK function to set queue rate limits
- Rate limit is applied after port initialization but before starting transmission

## Monitoring

The application provides feedback about rate limiting:

```
***** Setting rate limit for port 0: 1000 Mbps total, 250 Mbps per queue (4 queues) ****
***** Setting rate limit 0/0 to: 250 Mbps ****
***** Setting rate limit 0/1 to: 250 Mbps ****
***** Setting rate limit 0/2 to: 250 Mbps ****
***** Setting rate limit 0/3 to: 250 Mbps ****
```

## Troubleshooting

### Common Issues

1. **Rate limit not applied**: Check that the `--bwl` parameter is correctly passed
2. **Unexpected rates**: Verify the number of TX queues matches your configuration
3. **Performance issues**: Ensure your NIC supports the specified rate limits

### Verification

To verify rate limiting is working:
1. Monitor network statistics during transmission
2. Use tools like `iperf` to measure actual throughput
3. Check DPDK statistics using `rte_eth_stats_get()`

## Notes

- Rate limiting is hardware-dependent and may not be supported on all NICs
- The actual achieved rate may vary slightly from the specified rate
- Rate limiting adds some overhead to packet transmission
- For best performance, ensure your system has sufficient CPU resources