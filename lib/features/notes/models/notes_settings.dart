import 'package:flutter/material.dart';

enum PaperType { ruled, grid, plain, dotGrid }
enum PaperSize { a4, letter, custom }
enum ExportQuality { high, medium, low }
enum AutoSaveFrequency { sec15, sec30, min1, manual }
enum AutoCleanup { days30, days60, days90, never }

class NotesSettings {
  // Notes-specific settings
  final PaperType defaultPaperType;
  final Color defaultPenColor;
  final double defaultStrokeWidth;
  final AutoSaveFrequency autoSaveFrequency;
  final PaperSize paperSize;
  final ExportQuality exportQuality;

  // Drawing preferences
  final bool stylusOnlyMode;
  final double palmRejectionSensitivity;
  final double pressureSensitivity;
  final bool zoomGestureEnabled;

  // Storage and sync settings
  final AutoCleanup autoCleanup;
  final double maxStorageLimit; // in MB
  final String exportLocation;
  final String documentNamePattern;

  NotesSettings({
    this.defaultPaperType = PaperType.plain,
    this.defaultPenColor = Colors.black,
    this.defaultStrokeWidth = 2.0,
    this.autoSaveFrequency = AutoSaveFrequency.sec15,
    this.paperSize = PaperSize.a4,
    this.exportQuality = ExportQuality.medium,
    this.stylusOnlyMode = false,
    this.palmRejectionSensitivity = 0.5,
    this.pressureSensitivity = 0.5,
    this.zoomGestureEnabled = true,
    this.autoCleanup = AutoCleanup.never,
    this.maxStorageLimit = 500.0,
    this.exportLocation = '',
    this.documentNamePattern = 'Note_{YYYY}-{MM}-{DD}',
  });

  NotesSettings copyWith({
    PaperType? defaultPaperType,
    Color? defaultPenColor,
    double? defaultStrokeWidth,
    AutoSaveFrequency? autoSaveFrequency,
    PaperSize? paperSize,
    ExportQuality? exportQuality,
    bool? stylusOnlyMode,
    double? palmRejectionSensitivity,
    double? pressureSensitivity,
    bool? zoomGestureEnabled,
    AutoCleanup? autoCleanup,
    double? maxStorageLimit,
    String? exportLocation,
    String? documentNamePattern,
  }) {
    return NotesSettings(
      defaultPaperType: defaultPaperType ?? this.defaultPaperType,
      defaultPenColor: defaultPenColor ?? this.defaultPenColor,
      defaultStrokeWidth: defaultStrokeWidth ?? this.defaultStrokeWidth,
      autoSaveFrequency: autoSaveFrequency ?? this.autoSaveFrequency,
      paperSize: paperSize ?? this.paperSize,
      exportQuality: exportQuality ?? this.exportQuality,
      stylusOnlyMode: stylusOnlyMode ?? this.stylusOnlyMode,
      palmRejectionSensitivity: palmRejectionSensitivity ?? this.palmRejectionSensitivity,
      pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
      zoomGestureEnabled: zoomGestureEnabled ?? this.zoomGestureEnabled,
      autoCleanup: autoCleanup ?? this.autoCleanup,
      maxStorageLimit: maxStorageLimit ?? this.maxStorageLimit,
      exportLocation: exportLocation ?? this.exportLocation,
      documentNamePattern: documentNamePattern ?? this.documentNamePattern,
    );
  }
}
