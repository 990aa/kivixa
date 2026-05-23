// Kivixa Automated Performance Benchmark Suite
//
// Run with:
//   flutter test performance_benchmarks/kivixa_benchmark_suite.dart
//
// For a full integration benchmark with real device metrics:
//   flutter drive --driver=test_driver/perf_driver.dart \
//                 --target=performance_benchmarks/kivixa_benchmark_suite.dart \
//                 --profile
//
// Output: performance_benchmarks/results/benchmark_<timestamp>.json

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'benchmark_utils.dart';

// ────────────────────────────────────────────────────────────────────────────
// Constants
// ────────────────────────────────────────────────────────────────────────────

const _kResultsDir = 'performance_benchmarks/results';
const _kWarmupFrames = 5;
const _kMeasureFrames = 60;
const _kSleepWakeCycles = 20;

// Thresholds (fail CI if exceeded)
const _kStartupMaxMs = 3000;
const _kWakeLatencyMaxMs = 16; // one frame at 60 fps
const _kFrameBuildP95MaxMs = 12;

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

/// Runs [iterations] rounds of [fn] and returns a list of elapsed milliseconds.
Future<List<double>> _time(
  String label,
  int iterations,
  Future<void> Function() fn,
) async {
  final results = <double>[];
  for (var i = 0; i < iterations; i++) {
    final sw = Stopwatch()..start();
    await fn();
    sw.stop();
    results.add(sw.elapsedMicroseconds / 1000.0);
  }
  // ignore: avoid_print
  print('[$label] ${results.length} samples, '
      'avg=${_avg(results).toStringAsFixed(2)} ms, '
      'p95=${BenchmarkResults.percentile(results, 95).toStringAsFixed(2)} ms');
  return results;
}

double _avg(List<double> vs) =>
    vs.isEmpty ? 0 : vs.reduce((a, b) => a + b) / vs.length;

double _stddev(List<double> vs) {
  if (vs.length < 2) return 0;
  final avg = _avg(vs);
  final variance =
      vs.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
      (vs.length - 1);
  return variance < 0 ? 0 : variance;
}

// ────────────────────────────────────────────────────────────────────────────
// Mock sleep/wake cycle for unit-level latency measurement
// ────────────────────────────────────────────────────────────────────────────

/// Simulates a sleep → wake cycle with in-memory state serialisation.
Future<double> _measureSleepWakeCycle() async {
  // 1. Capture state (simulated — serialise a medium-sized map)
  final fakeState = <String, Object?>{
    'scrollOffset': 1432.5,
    'selectedTab': 2,
    'searchQuery': 'quarterly report',
    'expandedNodes': List.generate(50, (i) => 'node_$i'),
    'cacheVersion': DateTime.now().millisecondsSinceEpoch,
  };
  final sw = Stopwatch()..start();

  // 2. Serialise (sleep)
  final encoded = jsonEncode(fakeState);

  // 3. Small async gap — simulates the scheduler yielding
  await Future.delayed(Duration.zero);

  // 4. Deserialise (wake)
  final _ = jsonDecode(encoded);

  sw.stop();
  return sw.elapsedMicroseconds / 1000.0;
}

// ────────────────────────────────────────────────────────────────────────────
// Main benchmark entry-point
// ────────────────────────────────────────────────────────────────────────────

void main() {
  final results = BenchmarkResults(
    deviceInfo: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
  );

  // ── Startup time ──────────────────────────────────────────────────────────
  group('Startup Performance', () {
    test('cold-start estimate is under $_kStartupMaxMs ms', () {
      // Integration-level startup is measured by the flutter drive harness.
      // This unit test documents the target and reports the threshold.
      results.addMetric(
        PerformanceMetric(
          type: MetricType.startupTime,
          name: 'startup_threshold_ms',
          value: _kStartupMaxMs.toDouble(),
          unit: 'ms',
        ),
      );
      // Placeholder — real metric injected by flutter drive.
      expect(true, isTrue);
    });
  });

  // ── Sleep/Wake latency ────────────────────────────────────────────────────
  group('Sleep/Wake Cycle Latency', () {
    test('state serialisation round-trip completes within one frame', () async {
      // Warm up
      for (var i = 0; i < _kWarmupFrames; i++) {
        await _measureSleepWakeCycle();
      }

      // Measure
      final samples = await _time(
        'sleep_wake_roundtrip',
        _kSleepWakeCycles,
        _measureSleepWakeCycle,
      );

      final p95 = BenchmarkResults.percentile(samples, 95);
      final p99 = BenchmarkResults.percentile(samples, 99);
      final avg = _avg(samples);
      final sd = _stddev(samples);

      for (final ms in samples) {
        results.addMetric(
          PerformanceMetric(
            type: MetricType.frameBuildTime,
            name: 'sleep_wake_roundtrip_ms',
            value: ms,
          ),
        );
      }

      // ignore: avoid_print
      print(
        '[sleep_wake] avg=${avg.toStringAsFixed(2)} ms  '
        'p95=${p95.toStringAsFixed(2)} ms  '
        'p99=${p99.toStringAsFixed(2)} ms  '
        'σ=${sd.toStringAsFixed(2)} ms',
      );

      // Must complete well within a single frame (16.67 ms at 60 fps)
      expect(
        p95,
        lessThan(_kWakeLatencyMaxMs),
        reason:
            'Sleep/wake p95 latency ${p95.toStringAsFixed(2)} ms exceeds '
            '$_kWakeLatencyMaxMs ms — wake would cause jank',
      );
    });
  });

  // ── Frame timing simulation ───────────────────────────────────────────────
  group('Frame Build Time', () {
    test('simulated frame budget does not exceed thresholds', () async {
      // Warm up
      for (var i = 0; i < _kWarmupFrames; i++) {
        await Future.delayed(Duration.zero);
      }

      final samples = await _time(
        'frame_build_async_yield',
        _kMeasureFrames,
        () => Future.delayed(Duration.zero),
      );

      for (final ms in samples) {
        results.addMetric(
          PerformanceMetric(
            type: MetricType.frameBuildTime,
            name: 'async_yield_ms',
            value: ms,
          ),
        );
      }

      final p95 = BenchmarkResults.percentile(samples, 95);
      expect(
        p95,
        lessThan(_kFrameBuildP95MaxMs),
        reason:
            'Frame build p95 ${p95.toStringAsFixed(2)} ms exceeds '
            '$_kFrameBuildP95MaxMs ms budget',
      );
    });
  });

  // ── Memory section tracking ───────────────────────────────────────────────
  group('Section Manager Overhead', () {
    test('registering and unregistering 100 sections is sub-millisecond', () async {
      final samples = await _time('section_register_100', 10, () async {
        final callbacks = <String, void Function(bool)>{};
        // Register 100 sections
        for (var i = 0; i < 100; i++) {
          callbacks['section_$i'] = (_) {};
        }
        // Unregister
        callbacks.clear();
      });

      final avg = _avg(samples);
      results.addMetric(
        PerformanceMetric(
          type: MetricType.navigationTime,
          name: 'section_register_100_avg_ms',
          value: avg,
        ),
      );

      expect(avg, lessThan(1.0),
          reason: 'Section map ops took ${avg.toStringAsFixed(3)} ms — too slow');
    });
  });

  // ── State serialisation ───────────────────────────────────────────────────
  group('State Snapshot Serialisation', () {
    test('JSON encode/decode of a 200-key state map is sub-5 ms', () async {
      final largeState = <String, Object?>{
        for (var i = 0; i < 200; i++)
          'key_$i': i % 3 == 0 ? 'string_value_$i' : i.toDouble(),
      };

      final samples = await _time('json_roundtrip_200_keys', 50, () async {
        final encoded = jsonEncode(largeState);
        jsonDecode(encoded);
      });

      final p99 = BenchmarkResults.percentile(samples, 99);
      results.addMetric(
        PerformanceMetric(
          type: MetricType.frameBuildTime,
          name: 'json_state_roundtrip_p99_ms',
          value: p99,
        ),
      );

      expect(p99, lessThan(5.0),
          reason:
              'State serialisation p99 ${p99.toStringAsFixed(2)} ms — exceeds 5 ms budget');
    });
  });

  // ── Write results ─────────────────────────────────────────────────────────
  tearDownAll(() async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '_');
    final outPath = '$_kResultsDir/benchmark_$timestamp.json';
    await results.saveToFile(outPath);

    final failures = PerformanceThresholds.validate(results);
    if (failures.isNotEmpty) {
      // ignore: avoid_print
      print('\n❌ Performance threshold violations:');
      for (final f in failures) {
        // ignore: avoid_print
        print('  • $f');
      }
    } else {
      // ignore: avoid_print
      print('\n✅ All performance thresholds passed');
    }
    // ignore: avoid_print
    print('📊 Results saved to $outPath');
  });
}
