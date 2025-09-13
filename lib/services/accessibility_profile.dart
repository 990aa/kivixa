import 'package:flutter/foundation.dart';

/// Manages accessibility preferences for the application.
///
/// These settings would be persisted in a `user_settings` store and loaded
/// on app startup. The UI would then bind to this profile to adjust its
/// appearance and behavior accordingly.
class AccessibilityProfile with ChangeNotifier {
  bool _highContrast = false;
  bool _largeHitTargets = false;

  // A simple map for semantic labels. In a real app, this might be
  // part of a larger internationalization (i18n) system.
  final Map<String, String> _semanticLabels = {
    'main_toolbar': 'Main Toolbar',
    'color_picker': 'Color Picker',
    'undo_button': 'Undo last action',
    'redo_button': 'Redo last action',
    'add_page_button': 'Add a new page',
  };

  /// Whether high-contrast mode is enabled.
  ///
  /// UI elements should use a higher contrast color palette when this is true.
  bool get isHighContrast => _highContrast;

  /// Whether large hit targets are enabled.
  ///
  /// UI controls like buttons and sliders should increase their touch area
  /// when this is true.
  bool get useLargeHitTargets => _largeHitTargets;

  /// Sets the high-contrast preference.
  void setHighContrast(bool enabled) {
    if (_highContrast == enabled) return;
    _highContrast = enabled;
    // In a real app: await _persist('highContrast', enabled);
    notifyListeners();
  }

  /// Sets the large hit targets preference.
  void setLargeHitTargets(bool enabled) {
    if (_largeHitTargets == enabled) return;
    _largeHitTargets = enabled;
    // In a real app: await _persist('largeHitTargets', enabled);
    notifyListeners();
  }

  /// Gets the semantic label for a core UI control.
  ///
  /// Returns the controlId if no specific label is found.
  String getLabel(String controlId) {
    return _semanticLabels[controlId] ?? controlId;
  }

  /// Provides screen reader friendly metadata for a given context.
  ///
  /// This is a stub; a real implementation would provide more dynamic
  /// and context-aware information.
  String getScreenReaderMetadata({String? pageNumber, int? layerCount}) {
    final parts = <String>[];
    if (pageNumber != null) {
      parts.add('Currently on page $pageNumber.');
    }
    if (layerCount != null) {
      parts.add('This page has $layerCount layers.');
    }
    return parts.join(' ');
  }
}
