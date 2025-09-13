import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class DiagnosticsService {
  bool _telemetryEnabled = false;

  bool get isTelemetryEnabled => _telemetryEnabled;

  void setTelemetryEnabled(bool enabled) {
    _telemetryEnabled = enabled;
    // In a real implementation, this would also be persisted to settings.
  }

  Future<String> _gatherLocalLogs() async {
    // Stub: In a real app, this would read from a logging service or file.
    return "Log file content goes here.\nError: Something happened.\n";
  }

  Future<String> _gatherConfigSnapshot() async {
    // Stub: In a real app, this would read from a settings service.
    // IMPORTANT: Redact any sensitive information like API keys or user data.
    final config = {
      'app_version': '1.0.0',
      'theme': 'dark',
      'sync_provider': 'none',
      'backup_enabled': true,
      'user_id': 'REDACTED',
    };
    return const JsonEncoder.withIndent('  ').convert(config);
  }

  Future<String> _gatherPerfMetrics() async {
    // Stub: In a real app, this would read from a performance monitoring service.
    final metrics = {
      'avg_frame_rate': 58.9,
      'avg_stroke_latency_ms': 12,
      'db_query_time_ms': {
        'avg': 5,
        'p95': 25,
      }
    };
    return const JsonEncoder.withIndent('  ').convert(metrics);
  }

  Future<String> _gatherDbStats() async {
    // Stub: In a real app, this would query the database for statistics.
    return "DB Stats:\n- Notes: 123\n- Pages: 456\n- Strokes: 7890\n";
  }

  /// Gathers all diagnostic information and exports it to a zip file.
  ///
  /// This is only triggered by an explicit user action in the settings.
  /// Returns the path to the created zip file.
  Future<String> exportDiagnostics() async {
    final tempDir = await getTemporaryDirectory();
    final diagnosticsDir = Directory('${tempDir.path}/diagnostics');
    if (await diagnosticsDir.exists()) {
      await diagnosticsDir.delete(recursive: true);
    }
    await diagnosticsDir.create();

    // Gather data
    final logs = await _gatherLocalLogs();
    final config = await _gatherConfigSnapshot();
    final perf = await _gatherPerfMetrics();
    final dbStats = await _gatherDbStats();

    // Write data to files
    await File('${diagnosticsDir.path}/logs.txt').writeAsString(logs);
    await File('${diagnosticsDir.path}/config.json').writeAsString(config);
    await File('${diagnosticsDir.path}/performance.json').writeAsString(perf);
    await File('${diagnosticsDir.path}/db_stats.txt').writeAsString(dbStats);

    // Create zip file
    final zipFilePath = '${tempDir.path}/kivixa_diagnostics_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);
    encoder.addDirectory(diagnosticsDir);
    encoder.close();

    // Clean up
    await diagnosticsDir.delete(recursive: true);

    return zipFilePath;
  }
}
