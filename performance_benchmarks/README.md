# Performance Benchmarks

This directory contains performance benchmark utilities and results for the Kivixa app.

## Structure

- `benchmark_utils.dart` - Core utilities for measuring and reporting performance
- `results/` - JSON output from benchmark runs

## Running Benchmarks

### Manual Performance Testing
1. Build in profile mode: `flutter run --profile`
2. Use DevTools Performance tab to capture traces
3. Record frame times during key interactions

### CI Integration
The benchmark utilities provide threshold validation for:
- Startup time: max 3000ms
- Frame build p95: max 12ms  
- Frame raster p95: max 8ms
- Regression threshold: 15%

## Thresholds

| Metric | Threshold |
|--------|-----------|
| Startup time | < 3000ms |
| Frame build p95 | < 12ms |
| Frame raster p95 | < 8ms |
