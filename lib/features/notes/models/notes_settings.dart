import 'package:flutter/material.dart';

enum PaperType { ruled, grid, plain, dotGrid }

enum PaperSize { a4, letter, custom }

enum ExportQuality { high, medium, low }

enum AutoSaveFrequency { sec15, sec30, min1, manual }

enum AutoCleanup { days30, days60, days90, never }

class NotesSettings {
  // Notes-specific settings
  PaperType defaultPaperType;
  Color defaultPenColor;
  double defaultStrokeWidth;
  AutoSaveFrequency autoSaveFrequency;
  PaperSize paperSize;
  ExportQuality exportQuality;

  // Drawing preferences
  bool stylusOnlyMode;
  double palmRejectionSensitivity;
  double pressureSensitivity;
  bool zoomGestureEnabled;

  // Storage and sync settings
  AutoCleanup autoCleanup;
  double maxStorageLimit; // in MB
  String exportLocation;
  String documentNamePattern;

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
}
