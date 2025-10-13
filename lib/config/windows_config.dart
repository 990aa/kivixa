/// Windows-specific configuration for Kivixa PDF Annotator
///
/// This file handles Windows platform initialization:
/// - Window sizing and positioning
/// - Stylus/pen input configuration  
/// - High DPI support
/// - File associations (optional)

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';class WindowsConfig {
  /// Minimum window size for usable UI
  static const double minWidth = 1280;
  static const double minHeight = 720;

  /// Default window size
  static const double defaultWidth = 1440;
  static const double defaultHeight = 900;

  /// Initialize Windows-specific configurations
  static Future<void> initialize() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('Initializing Windows configuration...');

      // Set minimum window size via platform channel
      try {
        await _setWindowSize();
        await _configureStylusInput();

        debugPrint('Windows configuration completed');
      } catch (e) {
        debugPrint('Error initializing Windows config: $e');
      }
    }
  }

  /// Configure window size and constraints
  static Future<void> _setWindowSize() async {
    // In production, would use window_manager package or platform channels
    // For now, documented as configuration requirement

    debugPrint('Window size configuration:');
    debugPrint('  Min: ${minWidth}x$minHeight');
    debugPrint('  Default: ${defaultWidth}x$defaultHeight');

    // Note: To implement programmatic window control, add window_manager package:
    // await windowManager.ensureInitialized();
    // await windowManager.setMinimumSize(Size(minWidth, minHeight));
    // await windowManager.setSize(Size(defaultWidth, defaultHeight));
  }

  /// Configure stylus and pen input
  static Future<void> _configureStylusInput() async {
    debugPrint('Stylus input configuration:');
    debugPrint('  Windows Ink: Supported');
    debugPrint('  Surface Pen: Supported');
    debugPrint('  Wacom: Supported');
    debugPrint('  Pressure sensitivity: Available via PointerEvent');

    // Flutter automatically handles stylus input on Windows via PointerEvent
    // Pressure and tilt are available through:
    // - PointerEvent.pressure (0.0 to 1.0)
    // - PointerEvent.tilt (angle from perpendicular)
    // - PointerEvent.orientation (rotation)
  }

  /// Check if stylus is being used
  static bool isStylusEvent(PointerEvent event) {
    return event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  /// Check if mouse is being used
  static bool isMouseEvent(PointerEvent event) {
    return event.kind == PointerDeviceKind.mouse;
  }

  /// Check if touch is being used
  static bool isTouchEvent(PointerEvent event) {
    return event.kind == PointerDeviceKind.touch;
  }

  /// Get device kind as string for debugging
  static String getDeviceKindString(PointerDeviceKind kind) {
    switch (kind) {
      case PointerDeviceKind.touch:
        return 'Touch';
      case PointerDeviceKind.mouse:
        return 'Mouse';
      case PointerDeviceKind.stylus:
        return 'Stylus';
      case PointerDeviceKind.invertedStylus:
        return 'Inverted Stylus (Eraser)';
      case PointerDeviceKind.trackpad:
        return 'Trackpad';
      case PointerDeviceKind.unknown:
        return 'Unknown';
    }
  }

  /// Register PDF file association (Windows only)
  ///
  /// This would allow double-clicking PDFs to open in Kivixa
  /// Requires Windows registry modifications
  static Future<void> registerFileAssociation() async {
    debugPrint('PDF file association registration:');
    debugPrint('  Status: Not implemented (requires registry access)');
    debugPrint(
      '  Manual setup: Associate .pdf files with kivixa.exe in Windows',
    );

    // To implement:
    // 1. Add Windows registry entries via installer
    // 2. Or use shell integration package
    // 3. Handle file path argument in main()
  }

  /// Parse command-line arguments for file opening
  static String? parseFileArgument(List<String> args) {
    // Check if PDF file path was passed as argument
    if (args.isNotEmpty) {
      final filePath = args[0];
      if (filePath.toLowerCase().endsWith('.pdf')) {
        debugPrint('Opening PDF from command line: $filePath');
        return filePath;
      }
    }
    return null;
  }
}

/// Extension for stylus-specific features
extension StylusFeatures on PointerEvent {
  /// Get pressure value (0.0 = no pressure, 1.0 = max pressure)
  double get stylusPressure => pressure;

  /// Check if this is a stylus event
  bool get isStylus =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  /// Check if stylus eraser is active
  bool get isStylusEraser => kind == PointerDeviceKind.invertedStylus;

  /// Get tilt angle (0.0 = perpendicular, π/2 = parallel to surface)
  double get stylusTilt => tilt;

  /// Get stylus orientation (rotation around axis)
  double get stylusOrientation => orientation;
}
