import 'diagnostics_service.dart';

/// Manages user privacy settings and related actions.
///
/// This service ensures that privacy-sensitive features like telemetry are
/// disabled by default and provides transparency about data usage.
class PrivacySettings {
  // Telemetry is off by default to respect user privacy.
  bool _telemetryEnabled = false;

  final DiagnosticsService _diagnosticsService;

  PrivacySettings(this._diagnosticsService);

  /// A clear, human-readable data usage policy.
  static const String dataUsagePolicy = """
Kivixa is designed to be an offline-first application. Your notes, documents,
and personal data are stored locally on your device.

- **Telemetry**: Anonymous usage statistics and crash reports are optional and
  disabled by default. If you choose to enable it, this data helps us improve
  the app and does not include any of your personal content.

- **Cloud Sync**: Cloud sync with providers like Google Drive or OneDrive is
  optional and disabled by default. If you enable it, the app will require
  access to your cloud storage to sync your documents.

- **Diagnostics**: If you encounter an issue, you can manually export a
  diagnostics report. This report is saved locally to your device and is
- **Diagnostics**: If you encounter an issue, you can manually export a
  diagnostics report. This report is saved locally to your device and is
  never sent automatically. You can review its contents before sharing it
  with our support team.
""";

  /// Returns whether the user has opted into telemetry. Defaults to `false`.
  bool get isTelemetryEnabled => _telemetryEnabled;

  /// Sets the user's telemetry preference.
  ///
  /// This would be persisted to local user settings.
  void setTelemetryEnabled(bool enabled) {
    if (_telemetryEnabled == enabled) return;
    _telemetryEnabled = enabled;
    // In a real implementation, this change would be persisted.
    // For example:
    // _settingsStore.setBool('telemetryEnabled', enabled);
    print("Telemetry enabled status set to: $_telemetryEnabled");
  }

  /// Generates a local diagnostics report without any network calls.
  ///
  /// This method leverages the `DiagnosticsService` to package local logs,
  /// redacted configuration, and performance metrics into a zip file that
  /// the user can inspect and share manually.
  ///
  /// Returns the file path of the generated zip file.
  Future<String> generateLocalDiagnosticsExport() async {
    print("Generating local diagnostics export. No network calls will be made.");
    return _diagnosticsService.exportDiagnostics();
  }
}
