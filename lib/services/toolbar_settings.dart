import 'package:flutter/foundation.dart';

/// Defines the behavior of touch input.
enum FingerBehavior {
  /// Finger input pans and zooms the canvas.
  panAndZoom,
  /// Finger input draws on the canvas.
  draw,
}

/// Manages the settings for the editor toolbar.
///
/// This service provides a fast, in-memory view of toolbar settings
/// for synchronous UI updates, while handling persistence in the background.
class ToolbarSettings with ChangeNotifier {
  // Private in-memory cache for immediate access.
  bool _immersiveMode = true;
  FingerBehavior _fingerBehavior = FingerBehavior.panAndZoom;

  /// Creates a new instance of [ToolbarSettings].
  ///
  /// On creation, it would typically load the persisted settings.
  ToolbarSettings() {
    // In a real implementation, you would load persisted settings here.
    // For example:
    // _loadSettings();
  }

  /// Whether the toolbar is in immersive mode (e.g., auto-hiding).
  bool get isImmersiveMode => _immersiveMode;

  /// The current behavior for finger input.
  FingerBehavior get fingerBehavior => _fingerBehavior;

  /// Toggles the toolbar's immersive mode.
  ///
  /// Updates the in-memory value synchronously and notifies listeners
  /// for immediate UI feedback.
  void setImmersiveMode(bool enabled) {
    if (_immersiveMode == enabled) return;

    _immersiveMode = enabled;
    // In a real implementation, this would be persisted asynchronously.
    // _persistSetting('immersiveMode', _immersiveMode);
    notifyListeners();
  }

  /// Sets the behavior for finger input.
  ///
  /// Updates the in-memory value synchronously and notifies listeners
  /// for immediate UI feedback.
  void setFingerBehavior(FingerBehavior behavior) {
    if (_fingerBehavior == behavior) return;

    _fingerBehavior = behavior;
    // In a real implementation, this would be persisted asynchronously.
    // _persistSetting('fingerBehavior', _fingerBehavior.index);
    notifyListeners();
  }

  // Example of how persistence might be handled.
  /*
  Future<void> _loadSettings() async {
    // final prefs = await SharedPreferences.getInstance();
    // _immersiveMode = prefs.getBool('immersiveMode') ?? true;
    // final fingerBehaviorIndex = prefs.getInt('fingerBehavior') ?? 0;
    // _fingerBehavior = FingerBehavior.values[fingerBehaviorIndex];
    notifyListeners();
  }

  Future<void> _persistSetting(String key, dynamic value) async {
    // final prefs = await SharedPreferences.getInstance();
    // if (value is bool) {
    //   await prefs.setBool(key, value);
    // } else if (value is int) {
    //   await prefs.setInt(key, value);
    // }
  }
  */
}