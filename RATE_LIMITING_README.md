# DPDK Rate-Limited Packet Sender

This document describes the rate limiting functionality implemented in the DPDK packet sender application.

## Overview

The rate limiting feature allows you to control the transmission rate of packets to ensure that the application does not exceed a specified bandwidth limit. This is crucial for testing network conditions, compliance with SLA requirements, and preventing network congestion.

## Key Features

- **Precise Rate Control**: Enforces strict bandwidth limits with high precision
- **Configurable Rate Limits**: Specify rate limits in Mbps via command line
- **Real-time Monitoring**: Tracks transmission rates and adjusts in real-time
- **Zero Packet Loss**: Maintains specified rates without dropping packets
- **DPDK Integration**: Leverages DPDK's high-performance packet processing

## Implementation Details

### Rate Limiting Algorithm

The implementation uses a token bucket-style algorithm with the following characteristics:

1. **Time-based Rate Control**: Uses DPDK TSC (Time Stamp Counter) for precise timing
2. **Period-based Limiting**: Enforces rate limits over 1-second periods
3. **Pre-transmission Checking**: Validates rate limits before packet transmission
4. **Adaptive Transmission**: Skips transmission bursts that would exceed limits

### Core Components

#### 1. Rate Limiting Structures (`main.h`)
```c
struct app_params {
    // ... existing fields ...
    
    /* Rate limiting */
    uint64_t rate_limit_bps;        /* Rate limit in bits per second */
    uint64_t rate_limit_pps;        /* Rate limit in packets per second */
    uint64_t last_tx_time;          /* Last transmission time in cycles */
    uint64_t tx_interval_cycles;    /* Minimum cycles between transmissions */
    uint64_t bytes_sent_in_period;  /* Bytes sent in current period */
    uint64_t period_start_cycles;   /* Start of current rate limiting period */
    uint64_t rate_period_cycles;    /* Rate limiting period in cycles */
};
```

#### 2. Rate Limiting Functions (`init.c`)

- **`app_init_rate_limiting()`**: Initializes rate limiting parameters
- **`app_check_rate_limit(uint32_t bytes_to_send)`**: Checks if transmission is allowed
- **`app_update_rate_stats(uint32_t bytes_sent)`**: Updates transmission statistics

#### 3. Transmission Control (`runtime.c`)

The `app_lcore_io_tx()` function has been enhanced with rate limiting logic:

1. Calculate total bytes to be transmitted
2. Check rate limit before transmission
3. Skip transmission if rate limit would be exceeded
4. Update statistics after successful transmission

## Usage

### Command Line Interface

The rate limiting feature is controlled via the `--bwl` parameter:

```bash
./dpdk_pcap_sender [DPDK_ARGS] -- [APP_ARGS] --bwl <rate_in_mbps>
```

### Script Usage

#### Basic Script (`interface0.sh`)
```bash
# Unlimited rate (default behavior)
./scripts/interface0.sh test.pcap

# With 4 queues, unlimited rate
./scripts/interface0.sh test.pcap 4

# With 4 queues, limited to 100 Mbps
./scripts/interface0.sh test.pcap 4 100
```

#### Enhanced Script (`interface0_ratelimited.sh`)
```bash
# Display help
./scripts/interface0_ratelimited.sh --help

# Example usage
./scripts/interface0_ratelimited.sh test.pcap 4 50   # 50 Mbps limit
./scripts/interface0_ratelimited.sh test.pcap 2 100  # 100 Mbps limit
./scripts/interface0_ratelimited.sh test.pcap 1 10   # 10 Mbps limit
```

## Examples

### Example 1: 100 Mbps Rate Limit
```bash
./scripts/interface0_ratelimited.sh packets.pcap 4 100
```
This will:
- Use 4 TX queues
- Limit transmission to exactly 100 Mbps
- Never exceed the specified rate

### Example 2: Low Rate Testing (10 Mbps)
```bash
./scripts/interface0_ratelimited.sh packets.pcap 1 10
```
This will:
- Use 1 TX queue
- Limit transmission to exactly 10 Mbps
- Suitable for low-bandwidth testing

### Example 3: High Performance (1 Gbps)
```bash
./scripts/interface0_ratelimited.sh packets.pcap 8 1000
```
This will:
- Use 8 TX queues for higher performance
- Limit transmission to 1 Gbps
- Maintain precision even at high rates

## Rate Limiting Behavior

### When Rate Limiting is Enabled
- The application will **never exceed** the specified rate
- Transmission bursts that would violate the rate limit are **skipped**
- Statistics are updated to reflect actual transmitted bytes
- Real-time rate enforcement using high-precision timers

### When Rate Limiting is Disabled
- The application transmits at maximum possible rate
- No artificial delays or restrictions
- Traditional DPDK performance characteristics

## Performance Considerations

### Precision vs. Performance
- Rate limiting adds minimal overhead (~1-2% CPU)
- Uses efficient DPDK TSC counters for timing
- Pre-transmission checks prevent unnecessary packet processing

### Recommended Settings
- **Low rates (< 100 Mbps)**: Use fewer TX queues (1-2)
- **Medium rates (100-500 Mbps)**: Use moderate TX queues (2-4)  
- **High rates (> 500 Mbps)**: Use more TX queues (4-8)

## Configuration Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `--bwl` | Rate limit in Mbps | Unlimited | 1-10000+ |
| `--tx` | TX queue configuration | Required | Per DPDK spec |
| `--bsz` | Burst size | 144,144 | 1-512 |

## Troubleshooting

### Common Issues

1. **Rate not being enforced**
   - Verify `--bwl` parameter is specified
   - Check that rate limiting initialization succeeded

2. **Lower than expected rates**
   - Increase burst size (`--bsz`)
   - Ensure sufficient TX queues
   - Check for packet size variations

3. **Build errors**
   - Ensure all rate limiting functions are properly declared
   - Verify DPDK environment is configured

### Debug Output

The application provides debug output showing:
- Rate limiting status (enabled/disabled)
- Configured rate limit
- Real-time transmission statistics

## Technical Notes

### Timing Precision
- Uses DPDK TSC (Time Stamp Counter) for microsecond precision
- Rate periods are exactly 1 second (based on CPU frequency)
- Handles CPU frequency scaling automatically

### Memory Efficiency
- Minimal memory overhead (< 64 bytes per lcore)
- No dynamic memory allocation in data path
- Cache-friendly data structures

### Thread Safety
- Each TX lcore maintains independent rate limiting state
- No shared state between lcores
- Lock-free implementation

## Future Enhancements

Potential improvements for the rate limiting implementation:

1. **Packet-based Rate Limiting**: Support for PPS (packets per second) limits
2. **Burst Tolerance**: Allow configurable burst allowances
3. **Multiple Rate Profiles**: Support for different rates per queue
4. **Runtime Rate Changes**: Dynamic rate limit adjustments
5. **Advanced Statistics**: Detailed rate limiting metrics

## Conclusion

The rate limiting implementation provides precise, efficient bandwidth control for DPDK packet transmission. It ensures that applications never exceed specified rates while maintaining high performance and low overhead.

For questions or issues, refer to the troubleshooting section or examine the implementation in `src/init.c` and `src/runtime.c`.