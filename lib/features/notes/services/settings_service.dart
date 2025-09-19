import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:kivixa/features/notes/models/notes_settings.dart';

class SettingsService {
  static const String _prefix = 'notes_settings_';

  // Keys for SharedPreferences
  static const String _defaultPaperTypeKey = '${_prefix}defaultPaperType';
  static const String _defaultPenColorKey = '${_prefix}defaultPenColor';
  static const String _defaultStrokeWidthKey = '${_prefix}defaultStrokeWidth';
  static const String _autoSaveFrequencyKey = '${_prefix}autoSaveFrequency';
  static const String _paperSizeKey = '${_prefix}paperSize';
  static const String _exportQualityKey = '${_prefix}exportQuality';
  static const String _stylusOnlyModeKey = '${_prefix}stylusOnlyMode';
  static const String _palmRejectionSensitivityKey = '${_prefix}palmRejectionSensitivity';
  static const String _pressureSensitivityKey = '${_prefix}pressureSensitivity';
  static const String _zoomGestureEnabledKey = '${_prefix}zoomGestureEnabled';
  static const String _autoCleanupKey = '${_prefix}autoCleanup';
  static const String _maxStorageLimitKey = '${_prefix}maxStorageLimit';
  static const String _exportLocationKey = '${_prefix}exportLocation';
  static const String _documentNamePatternKey = '${_prefix}documentNamePattern';

  Future<void> saveSettings(NotesSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultPaperTypeKey, settings.defaultPaperType.index);
    await prefs.setInt(_defaultPenColorKey, settings.defaultPenColor.value);
    await prefs.setDouble(_defaultStrokeWidthKey, settings.defaultStrokeWidth);
    await prefs.setInt(_autoSaveFrequencyKey, settings.autoSaveFrequency.index);
    await prefs.setInt(_paperSizeKey, settings.paperSize.index);
    await prefs.setInt(_exportQualityKey, settings.exportQuality.index);
    await prefs.setBool(_stylusOnlyModeKey, settings.stylusOnlyMode);
    await prefs.setDouble(_palmRejectionSensitivityKey, settings.palmRejectionSensitivity);
    await prefs.setDouble(_pressureSensitivityKey, settings.pressureSensitivity);
    await prefs.setBool(_zoomGestureEnabledKey, settings.zoomGestureEnabled);
    await prefs.setInt(_autoCleanupKey, settings.autoCleanup.index);
    await prefs.setDouble(_maxStorageLimitKey, settings.maxStorageLimit);
    await prefs.setString(_exportLocationKey, settings.exportLocation);
    await prefs.setString(_documentNamePatternKey, settings.documentNamePattern);
  }

  Future<NotesSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotesSettings(
      defaultPaperType: PaperType.values[prefs.getInt(_defaultPaperTypeKey) ?? PaperType.plain.index],
      defaultPenColor: Color(prefs.getInt(_defaultPenColorKey) ?? 0xFF000000),
      defaultStrokeWidth: prefs.getDouble(_defaultStrokeWidthKey) ?? 2.0,
      autoSaveFrequency: AutoSaveFrequency.values[prefs.getInt(_autoSaveFrequencyKey) ?? AutoSaveFrequency.sec15.index],
      paperSize: PaperSize.values[prefs.getInt(_paperSizeKey) ?? PaperSize.a4.index],
      exportQuality: ExportQuality.values[prefs.getInt(_exportQualityKey) ?? ExportQuality.medium.index],
      stylusOnlyMode: prefs.getBool(_stylusOnlyModeKey) ?? false,
      palmRejectionSensitivity: prefs.getDouble(_palmRejectionSensitivityKey) ?? 0.5,
      pressureSensitivity: prefs.getDouble(_pressureSensitivityKey) ?? 0.5,
      zoomGestureEnabled: prefs.getBool(_zoomGestureEnabledKey) ?? true,
      autoCleanup: AutoCleanup.values[prefs.getInt(_autoCleanupKey) ?? AutoCleanup.never.index],
      maxStorageLimit: prefs.getDouble(_maxStorageLimitKey) ?? 500.0,
      exportLocation: prefs.getString(_exportLocationKey) ?? '',
      documentNamePattern: prefs.getString(_documentNamePatternKey) ?? 'Note_{YYYY}-{MM}-{DD}',
    );
  }
}
