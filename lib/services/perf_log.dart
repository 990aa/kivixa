import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum PerfMetricType {
  strokeLatency,
  replayThroughput,
  queryTiming,
}

class PerfRecord {
  final DateTime timestamp;
  final PerfMetricType type;
  final String? key; // e.g., query name
  final num value; // e.g., milliseconds, strokes/sec

  PerfRecord({required this.timestamp, required this.type, this.key, required this.value});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'key': key,
    'value': value,
  };
}

/// A service for logging performance metrics.
///
/// In a real implementation, this would write to a dedicated `perf_log` table
/// in the database. For this stub, it logs to an in-memory list.
class PerfLog {
  final List<PerfRecord> _records = [];

  /// Logs the latency of a single stroke.
  void logStrokeLatency(int milliseconds) {
    _records.add(PerfRecord(
      timestamp: DateTime.now(),
      type: PerfMetricType.strokeLatency,
      value: milliseconds,
    ));
  }

  /// Logs the throughput of the replay engine.
  void logReplayThroughput(int strokesPerSecond) {
    _records.add(PerfRecord(
      timestamp: DateTime.now(),
      type: PerfMetricType.replayThroughput,
      value: strokesPerSecond,
    ));
  }

  /// Logs the timing of a specific database query.
  void logQueryTiming(String queryName, int milliseconds) {
    _records.add(PerfRecord(
      timestamp: DateTime.now(),
      type: PerfMetricType.queryTiming,
      key: queryName,
      value: milliseconds,
    ));
  }

  /// Generates a JSON report of all collected performance data.
  String generateReport() {
    final reportData = _records.map((r) => r.toJson()).toList();
    return jsonEncode(reportData);
  }

  /// Exports the performance report to a JSON file.
  ///
  /// In a real app, this might be triggered during development or from a
  /// diagnostics panel.
  Future<String> exportReportToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final perfDir = Directory('${directory.path}/perf');
    if (!await perfDir.exists()) {
      await perfDir.create();
    }

    final report = generateReport();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${perfDir.path}/perf_report_$timestamp.json');
    await file.writeAsString(report);

    return file.path;
  }

  /// Clears all recorded performance data.
  void clear() {
    _records.clear();
  }
}
