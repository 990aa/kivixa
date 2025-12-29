// Performance benchmark configuration and utilities
// Used by integration tests to measure and report performance metrics

import 'dart:convert';
import 'dart:io';

/// Performance metric types
enum MetricType {
  startupTime,
  frameBuildTime,
  frameRasterTime,
  scrollPerformance,
  navigationTime,
}

/// Single performance measurement
class PerformanceMetric {
  final MetricType type;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;

  PerformanceMetric({
    required this.type,
    required this.name,
    required this.value,
    this.unit = 'ms',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Performance benchmark results
class BenchmarkResults {
  final List<PerformanceMetric> metrics = [];
  final String deviceInfo;
  final DateTime startTime;

  BenchmarkResults({required this.deviceInfo}) : startTime = DateTime.now();

  void addMetric(PerformanceMetric metric) {
    metrics.add(metric);
  }

  /// Calculate percentile value from a list of measurements
  static double percentile(List<double> values, int p) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final index = (p / 100 * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Get summary statistics for a metric type
  Map<String, double> getSummary(MetricType type) {
    final values = metrics
        .where((m) => m.type == type)
        .map((m) => m.value)
        .toList();

    if (values.isEmpty) {
      return {
        'count': 0,
        'min': 0,
        'max': 0,
        'avg': 0,
        'p50': 0,
        'p95': 0,
        'p99': 0,
      };
    }

    final sum = values.reduce((a, b) => a + b);
    return {
      'count': values.length.toDouble(),
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
      'avg': sum / values.length,
      'p50': percentile(values, 50),
      'p95': percentile(values, 95),
      'p99': percentile(values, 99),
    };
  }

  Map<String, dynamic> toJson() => {
    'deviceInfo': deviceInfo,
    'startTime': startTime.toIso8601String(),
    'endTime': DateTime.now().toIso8601String(),
    'metrics': metrics.map((m) => m.toJson()).toList(),
    'summary': {
      for (final type in MetricType.values) type.name: getSummary(type),
    },
  };

  /// Save results to JSON file
  Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
    );
  }
}

/// Performance thresholds for CI gating
class PerformanceThresholds {
  static const startupTimeMaxMs = 3000;
  static const frameBuildP95MaxMs = 12;
  static const frameRasterP95MaxMs = 8;
  static const regressionThresholdPercent = 15.0;

  /// Check if results pass all thresholds
  static List<String> validate(BenchmarkResults results) {
    final failures = <String>[];

    final startupSummary = results.getSummary(MetricType.startupTime);
    if (startupSummary['avg']! > startupTimeMaxMs) {
      failures.add(
        'Startup time ${startupSummary['avg']!.toStringAsFixed(0)}ms exceeds max ${startupTimeMaxMs}ms',
      );
    }

    final frameBuildSummary = results.getSummary(MetricType.frameBuildTime);
    if (frameBuildSummary['p95']! > frameBuildP95MaxMs) {
      failures.add(
        'Frame build p95 ${frameBuildSummary['p95']!.toStringAsFixed(1)}ms exceeds max ${frameBuildP95MaxMs}ms',
      );
    }

    final frameRasterSummary = results.getSummary(MetricType.frameRasterTime);
    if (frameRasterSummary['p95']! > frameRasterP95MaxMs) {
      failures.add(
        'Frame raster p95 ${frameRasterSummary['p95']!.toStringAsFixed(1)}ms exceeds max ${frameRasterP95MaxMs}ms',
      );
    }

    return failures;
  }
}
