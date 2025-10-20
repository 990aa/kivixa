import 'package:flutter/material.dart';

/// Eraser modes for different erasing behaviors
enum EraserMode {
  /// Standard eraser - removes to transparency
  standard,

  /// Blend to background color (like painting with white)
  blendColor,

  /// Only removes alpha channel (preserves color)
  alpha,

  /// Smart eraser - erases strokes completely
  stroke,
}

/// Settings for eraser tool
class EraserSettings {
  /// Eraser mode
  final EraserMode mode;

  /// Size of the eraser in pixels
  final double size;

  /// Opacity/strength of erasing (0.0-1.0)
  final double opacity;

  /// Background color for blendColor mode
  final Color backgroundColor;

  /// Pressure sensitivity enabled
  final bool usePressure;

  /// Minimum size multiplier at low pressure
  final double minSize;

  /// Maximum size multiplier at high pressure
  final double maxSize;

  /// Softness/hardness of eraser edges (0.0=soft, 1.0=hard)
  final double hardness;

  const EraserSettings({
    this.mode = EraserMode.standard,
    this.size = 20.0,
    this.opacity = 1.0,
    this.backgroundColor = Colors.white,
    this.usePressure = true,
    this.minSize = 0.5,
    this.maxSize = 1.0,
    this.hardness = 1.0,
  });

  /// Create a copy with modified values
  EraserSettings copyWith({
    EraserMode? mode,
    double? size,
    double? opacity,
    Color? backgroundColor,
    bool? usePressure,
    double? minSize,
    double? maxSize,
    double? hardness,
  }) {
    return EraserSettings(
      mode: mode ?? this.mode,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      usePressure: usePressure ?? this.usePressure,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      hardness: hardness ?? this.hardness,
    );
  }

  /// Get description for each mode
  static String getModeDescription(EraserMode mode) {
    switch (mode) {
      case EraserMode.standard:
        return 'Erases to transparency (removes pixels completely)';
      case EraserMode.blendColor:
        return 'Paints with background color (like drawing with white)';
      case EraserMode.alpha:
        return 'Reduces opacity only (preserves color information)';
      case EraserMode.stroke:
        return 'Removes entire strokes that are touched';
    }
  }

  /// Get icon for each mode
  static IconData getModeIcon(EraserMode mode) {
    switch (mode) {
      case EraserMode.standard:
        return Icons.auto_fix_high;
      case EraserMode.blendColor:
        return Icons.brush;
      case EraserMode.alpha:
        return Icons.opacity;
      case EraserMode.stroke:
        return Icons.gesture;
    }
  }

  @override
  String toString() {
    return 'EraserSettings(mode: $mode, size: $size, opacity: $opacity)';
  }
}
