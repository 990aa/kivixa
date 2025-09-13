import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SanitizedLogsService {
  final List<String> _logs = [];

  void addLog(String message) {
    _logs.add(_sanitize(message));
  }

  String get _sanitizedLogs {
    return _logs.join('\n');
  }

  String _sanitize(String message) {
    // Naive implementation to remove potential PII
    // In a real app, use more robust filtering
    return message
        .replaceAll(RegExp(r'C:\Users\[^\\]+'), r'C:\Users\[REDACTED]')
        .replaceAll(RegExp(r'bearer [a-zA-Z0-9\._-]+', caseSensitive: false), 'bearer [REDACTED]')
        .replaceAll(RegExp(r'token [a-zA-Z0-9\._-]+', caseSensitive: false), 'token [REDACTED]');
  }

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _sanitizedLogs));
  }

  Future<String> saveToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/kivixa_logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt';
    final file = File(path);
    await file.writeAsString(_sanitizedLogs);
    return path;
  }

  void clear() {
    _logs.clear();
  }
}
