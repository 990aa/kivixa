import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Canvas size presets
enum CanvasPreset {
  custom,
  infinite,
  a4Portrait,
  a4Landscape,
  square1024,
  square2048,
  square4096,
  hdPortrait,
  hdLandscape,
  fullHd,
  fourK,
}

/// Canvas settings model
class CanvasSettings {
  final CanvasPreset preset;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final bool showGrid;
  final double gridSize;
  final Color gridColor;
  final bool showRulers;
  final bool snapToGrid;

  const CanvasSettings({
    this.preset = CanvasPreset.custom,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.showGrid = false,
    this.gridSize = 50.0,
    this.gridColor = Colors.grey,
    this.showRulers = false,
    this.snapToGrid = false,
  });

  /// Check if canvas is infinite
  bool get isInfinite => preset == CanvasPreset.infinite;

  /// Get actual canvas width (null for infinite)
  double? get canvasWidth {
    if (isInfinite) return null;
    if (width != null) return width;
    return _getPresetSize().width;
  }

  /// Get actual canvas height (null for infinite)
  double? get canvasHeight {
    if (isInfinite) return null;
    if (height != null) return height;
    return _getPresetSize().height;
  }

  /// Get preset dimensions
  Size _getPresetSize() {
    switch (preset) {
      case CanvasPreset.a4Portrait:
        return const Size(595, 842); // A4 at 72 DPI
      case CanvasPreset.a4Landscape:
        return const Size(842, 595);
      case CanvasPreset.square1024:
        return const Size(1024, 1024);
      case CanvasPreset.square2048:
        return const Size(2048, 2048);
      case CanvasPreset.square4096:
        return const Size(4096, 4096);
      case CanvasPreset.hdPortrait:
        return const Size(1080, 1920);
      case CanvasPreset.hdLandscape:
        return const Size(1920, 1080);
      case CanvasPreset.fullHd:
        return const Size(1920, 1080);
      case CanvasPreset.fourK:
        return const Size(3840, 2160);
      case CanvasPreset.custom:
      case CanvasPreset.infinite:
        return const Size(800, 600);
    }
  }

  /// Get preset name
  String getPresetName() {
    switch (preset) {
      case CanvasPreset.custom:
        return 'Custom';
      case CanvasPreset.infinite:
        return 'Infinite Canvas';
      case CanvasPreset.a4Portrait:
        return 'A4 Portrait';
      case CanvasPreset.a4Landscape:
        return 'A4 Landscape';
      case CanvasPreset.square1024:
        return 'Square 1024×1024';
      case CanvasPreset.square2048:
        return 'Square 2048×2048';
      case CanvasPreset.square4096:
        return 'Square 4096×4096';
      case CanvasPreset.hdPortrait:
        return 'HD Portrait (1080×1920)';
      case CanvasPreset.hdLandscape:
        return 'HD Landscape (1920×1080)';
      case CanvasPreset.fullHd:
        return 'Full HD (1920×1080)';
      case CanvasPreset.fourK:
        return '4K (3840×2160)';
    }
  }

  /// Get preset icon
  IconData getPresetIcon() {
    switch (preset) {
      case CanvasPreset.custom:
        return Icons.aspect_ratio;
      case CanvasPreset.infinite:
        return Icons.all_out;
      case CanvasPreset.a4Portrait:
      case CanvasPreset.a4Landscape:
        return Icons.description;
      case CanvasPreset.square1024:
      case CanvasPreset.square2048:
      case CanvasPreset.square4096:
        return Icons.crop_square;
      default:
        return Icons.photo_size_select_large;
    }
  }

  CanvasSettings copyWith({
    CanvasPreset? preset,
    double? width,
    double? height,
    Color? backgroundColor,
    bool? showGrid,
    double? gridSize,
    Color? gridColor,
    bool? showRulers,
    bool? snapToGrid,
  }) {
    return CanvasSettings(
      preset: preset ?? this.preset,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      gridSize: gridSize ?? this.gridSize,
      gridColor: gridColor ?? this.gridColor,
      showRulers: showRulers ?? this.showRulers,
      snapToGrid: snapToGrid ?? this.snapToGrid,
    );
  }
}

/// Canvas transformation state
class CanvasTransform {
  final double scale;
  final Offset translation;
  final double rotation;

  const CanvasTransform({
    this.scale = 1.0,
    this.translation = Offset.zero,
    this.rotation = 0.0,
  });

  CanvasTransform copyWith({
    double? scale,
    Offset? translation,
    double? rotation,
  }) {
    return CanvasTransform(
      scale: scale ?? this.scale,
      translation: translation ?? this.translation,
      rotation: rotation ?? this.rotation,
    );
  }

  /// Get as Matrix4
  Matrix4 toMatrix4() {
    return Matrix4.identity()
      ..translateByVector3(vector.Vector3(translation.dx, translation.dy, 0))
      ..scaleByVector3(vector.Vector3(scale, scale, 1.0))
      ..rotateZ(rotation);
  }

  /// Create from Matrix4
  factory CanvasTransform.fromMatrix4(Matrix4 matrix) {
    final translation = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();
    // For simplicity, we'll track rotation separately
    return CanvasTransform(
      scale: scale,
      translation: Offset(translation.x, translation.y),
      rotation: 0.0,
    );
  }

  /// Reset to identity
  static const identity = CanvasTransform();
}
