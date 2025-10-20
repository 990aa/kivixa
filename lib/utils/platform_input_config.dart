import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';

/// Platform-specific input configuration for gesture handling
class PlatformInputConfig {
  // Platform detection
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isWeb => kIsWeb;

  /// Get supported devices for drawing operations
  /// Mobile: Touch and stylus
  /// Desktop: Touch, mouse, stylus (NOT trackpad)
  static Set<PointerDeviceKind> getDrawingDevices() {
    if (isMobile) {
      return {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
    } else if (isDesktop) {
      return {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        // Exclude trackpad for drawing to prevent conflicts
      };
    } else {
      // Web or unknown platform
      return {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
    }
  }

  /// Get supported devices for navigation operations (pan, zoom)
  /// Mobile: Multi-touch gestures
  /// Desktop: Trackpad, multi-touch, mouse with modifiers
  static Set<PointerDeviceKind> getNavigationDevices() {
    if (isMobile) {
      return {
        PointerDeviceKind.touch, // Multi-touch only
      };
    } else if (isDesktop) {
      return {
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse, // With modifier keys (Ctrl, Space, etc.)
      };
    } else {
      return {PointerDeviceKind.touch, PointerDeviceKind.mouse};
    }
  }

  /// Check if device should use single-finger drawing
  /// Mobile: Yes (1 finger = draw, 2+ fingers = navigate)
  /// Desktop: No (1 mouse click = draw, trackpad gestures = navigate)
  static bool get useSingleFingerDrawing => isMobile;

  /// Check if device supports trackpad gestures
  static bool get supportsTrackpadGestures =>
      isDesktop && (isWindows || isMacOS);

  /// Get minimum pointer count for navigation
  /// Mobile: 2 fingers
  /// Desktop: 1 (but with different device or modifier)
  static int get minNavigationPointers => isMobile ? 2 : 1;

  /// Get pressure sensitivity support
  static bool get supportsPressure => true; // Most modern devices

  /// Get tilt sensitivity support
  static bool get supportsTilt => !isWeb; // Native platforms only

  /// Check if platform supports pen/stylus hover
  static bool get supportsHover => isDesktop || isAndroid;

  /// Platform-specific gesture configuration
  static GestureConfiguration getGestureConfiguration() {
    return GestureConfiguration(
      useSingleFingerDrawing: useSingleFingerDrawing,
      minNavigationPointers: minNavigationPointers,
      supportsPressure: supportsPressure,
      supportsTilt: supportsTilt,
      supportsHover: supportsHover,
      supportsTrackpadGestures: supportsTrackpadGestures,
    );
  }

  /// Get platform-specific gesture settings
  static String getPlatformName() {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isWeb) return 'Web';
    return 'Unknown';
  }

  /// Debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'platform': getPlatformName(),
      'isMobile': isMobile,
      'isDesktop': isDesktop,
      'drawingDevices': getDrawingDevices().map((d) => d.name).toList(),
      'navigationDevices': getNavigationDevices().map((d) => d.name).toList(),
      'singleFingerDrawing': useSingleFingerDrawing,
      'minNavigationPointers': minNavigationPointers,
      'supportsPressure': supportsPressure,
      'supportsTilt': supportsTilt,
      'supportsHover': supportsHover,
      'supportsTrackpad': supportsTrackpadGestures,
    };
  }
}

/// Configuration for gesture handling
class GestureConfiguration {
  final bool useSingleFingerDrawing;
  final int minNavigationPointers;
  final bool supportsPressure;
  final bool supportsTilt;
  final bool supportsHover;
  final bool supportsTrackpadGestures;

  const GestureConfiguration({
    required this.useSingleFingerDrawing,
    required this.minNavigationPointers,
    required this.supportsPressure,
    required this.supportsTilt,
    required this.supportsHover,
    required this.supportsTrackpadGestures,
  });

  @override
  String toString() {
    return 'GestureConfiguration('
        'singleFinger: $useSingleFingerDrawing, '
        'minNav: $minNavigationPointers, '
        'pressure: $supportsPressure, '
        'tilt: $supportsTilt, '
        'hover: $supportsHover, '
        'trackpad: $supportsTrackpadGestures'
        ')';
  }
}
