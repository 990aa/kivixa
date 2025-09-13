import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DiagnosticsService {
  static final DiagnosticsService _instance = DiagnosticsService._internal();
  factory DiagnosticsService() => _instance;
  DiagnosticsService._internal();

  bool _telemetryEnabled = false;

  void setTelemetryStatus(bool isEnabled) {
    _telemetryEnabled = isEnabled;
    // If enabling, start collecting perf metrics, etc.
  }

  bool get isTelemetryEnabled => _telemetryEnabled;

  Future<File> createDiagnosticsBundle() async {
    final tempDir = await getTemporaryDirectory();
    final diagnosticsDir = Directory(p.join(tempDir.path, 'diagnostics'));
    if (await diagnosticsDir.exists()) {
      await diagnosticsDir.delete(recursive: true);
    }
    await diagnosticsDir.create();

    // Gather data
    await _gatherLogs(diagnosticsDir);
    await _gatherConfig(diagnosticsDir);
    await _gatherPerfMetrics(diagnosticsDir);
    await _gatherDbStats(diagnosticsDir);

    // Create zip bundle
    final encoder = ZipFileEncoder();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final zipPath = p.join(tempDir.path, 'kivixa_diagnostics_$timestamp.zip');
    encoder.zip(diagnosticsDir.path, zipPath);

    return File(zipPath);
  }

  Future<void> _gatherLogs(Directory targetDir) async {
    // Placeholder for log gathering. In a real app, this would copy
    // log files from a logging service like `log` or `flutter_logger`.
    final logFile = File(p.join(targetDir.path, 'app.log'));
    await logFile.writeAsString('Log entry 1\nLog entry 2\n');
  }

  Future<void> _gatherConfig(Directory targetDir) async {
    final configFile = File(p.join(targetDir.path, 'config.json'));
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};
    if (kIsWeb) {
      deviceData = (await deviceInfo.webBrowserInfo).data;
    } else {
      if (Platform.isAndroid) {
        deviceData = (await deviceInfo.androidInfo).data;
      } else if (Platform.isIOS) {
        deviceData = (await deviceInfo.iosInfo).data;
      } else if (Platform.isLinux) {
        deviceData = (await deviceInfo.linuxInfo).data;
      } else if (Platform.isMacOS) {
        deviceData = (await deviceInfo.macOsInfo).data;
      } else if (Platform.isWindows) {
        deviceData = (await deviceInfo.windowsInfo).data;
      }
    }

    // Redact sensitive information
    deviceData.remove('machine'); // Example of redaction
    deviceData.remove('userName');

    final configSnapshot = {
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'deviceInfo': deviceData,
      'settings': {
        'theme': 'dark', // Placeholder for actual settings
        'telemetryEnabled': _telemetryEnabled,
      }
    };
    await configFile.writeAsString(configSnapshot.toString());
  }

  Future<void> _gatherPerfMetrics(Directory targetDir) async {
    // Placeholder for performance metrics
    final perfFile = File(p.join(targetDir.path, 'perf.json'));
    final metrics = {
      'avgFrameRate': 59.8,
      'startupTimeMs': 1200,
    };
    await perfFile.writeAsString(metrics.toString());
  }

  Future<void> _gatherDbStats(Directory targetDir) async {
    // Placeholder for database statistics
    final dbStatsFile = File(p.join(targetDir.path, 'db_stats.json'));
    final stats = {
      'dbSizeMb': 15.4,
      'notesCount': 250,
      'tagsCount': 30,
    };
    await dbStatsFile.writeAsString(stats.toString());
  }
}
