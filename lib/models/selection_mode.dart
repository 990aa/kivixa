import 'package:flutter/material.dart';

/// Selection tool modes
enum SelectionMode {
  /// Rectangular selection
  rectangular,

  /// Elliptical selection
  ellipse,

  /// Freeform lasso selection
  lasso,

  /// Polygonal lasso (click to add points)
  polygonal,

  /// Magic wand (color-based selection)
  magicWand,
}

/// Selection operation types
enum SelectionOperation {
  /// Create new selection
  newSelection,

  /// Add to existing selection
  add,

  /// Subtract from existing selection
  subtract,

  /// Intersect with existing selection
  intersect,
}

/// Settings for selection tools
class SelectionSettings {
  /// Selection mode
  final SelectionMode mode;

  /// Selection operation
  final SelectionOperation operation;

  /// Tolerance for magic wand (0.0-1.0)
  final double tolerance;

  /// Feather/soften edge amount (pixels)
  final double feather;

  /// Anti-aliasing enabled
  final bool antiAlias;

  /// Show marching ants animation
  final bool showMarchingAnts;

  const SelectionSettings({
    this.mode = SelectionMode.rectangular,
    this.operation = SelectionOperation.newSelection,
    this.tolerance = 0.1,
    this.feather = 0.0,
    this.antiAlias = true,
    this.showMarchingAnts = true,
  });

  /// Create a copy with modified values
  SelectionSettings copyWith({
    SelectionMode? mode,
    SelectionOperation? operation,
    double? tolerance,
    double? feather,
    bool? antiAlias,
    bool? showMarchingAnts,
  }) {
    return SelectionSettings(
      mode: mode ?? this.mode,
      operation: operation ?? this.operation,
      tolerance: tolerance ?? this.tolerance,
      feather: feather ?? this.feather,
      antiAlias: antiAlias ?? this.antiAlias,
      showMarchingAnts: showMarchingAnts ?? this.showMarchingAnts,
    );
  }

  /// Get description for each mode
  static String getModeDescription(SelectionMode mode) {
    switch (mode) {
      case SelectionMode.rectangular:
        return 'Select rectangular areas';
      case SelectionMode.ellipse:
        return 'Select elliptical/circular areas';
      case SelectionMode.lasso:
        return 'Draw freeform selection';
      case SelectionMode.polygonal:
        return 'Click to create polygon selection';
      case SelectionMode.magicWand:
        return 'Select similar colors';
    }
  }

  /// Get icon for each mode
  static IconData getModeIcon(SelectionMode mode) {
    switch (mode) {
      case SelectionMode.rectangular:
        return Icons.crop_square;
      case SelectionMode.ellipse:
        return Icons.circle_outlined;
      case SelectionMode.lasso:
        return Icons.gesture;
      case SelectionMode.polygonal:
        return Icons.polyline;
      case SelectionMode.magicWand:
        return Icons.auto_fix_high;
    }
  }

  @override
  String toString() {
    return 'SelectionSettings(mode: $mode, operation: $operation)';
  }
}
