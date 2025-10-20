import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Symmetry modes for drawing
enum SymmetryMode {
  none,
  horizontal,
  vertical,
  radial,
  kaleidoscope,
}

/// Symmetry settings
class SymmetrySettings {
  final SymmetryMode mode;
  final Offset center;
  final int segments; // For radial/kaleidoscope mode
  final bool showGuidelines;
  final Color guidelineColor;

  const SymmetrySettings({
    this.mode = SymmetryMode.none,
    this.center = Offset.zero,
    this.segments = 4,
    this.showGuidelines = true,
    this.guidelineColor = Colors.blue,
  });

  /// Check if symmetry is enabled
  bool get isEnabled => mode != SymmetryMode.none;

  /// Get mode name
  String getModeName() {
    switch (mode) {
      case SymmetryMode.none:
        return 'None';
      case SymmetryMode.horizontal:
        return 'Horizontal';
      case SymmetryMode.vertical:
        return 'Vertical';
      case SymmetryMode.radial:
        return 'Radial ($segments-way)';
      case SymmetryMode.kaleidoscope:
        return 'Kaleidoscope ($segments segments)';
    }
  }

  /// Get mode icon
  IconData getModeIcon() {
    switch (mode) {
      case SymmetryMode.none:
        return Icons.close;
      case SymmetryMode.horizontal:
        return Icons.horizontal_split;
      case SymmetryMode.vertical:
        return Icons.vertical_split;
      case SymmetryMode.radial:
        return Icons.control_camera;
      case SymmetryMode.kaleidoscope:
        return Icons.kaleidoscope;
    }
  }

  /// Get mode description
  String getModeDescription() {
    switch (mode) {
      case SymmetryMode.none:
        return 'No symmetry applied';
      case SymmetryMode.horizontal:
        return 'Mirror horizontally across center';
      case SymmetryMode.vertical:
        return 'Mirror vertically across center';
      case SymmetryMode.radial:
        return 'Mirror in $segments directions';
      case SymmetryMode.kaleidoscope:
        return 'Kaleidoscope effect with $segments segments';
    }
  }

  SymmetrySettings copyWith({
    SymmetryMode? mode,
    Offset? center,
    int? segments,
    bool? showGuidelines,
    Color? guidelineColor,
  }) {
    return SymmetrySettings(
      mode: mode ?? this.mode,
      center: center ?? this.center,
      segments: segments ?? this.segments,
      showGuidelines: showGuidelines ?? this.showGuidelines,
      guidelineColor: guidelineColor ?? this.guidelineColor,
    );
  }
}
