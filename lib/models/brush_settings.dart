import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Comprehensive brush settings for all brush types
class BrushSettings {
  /// Type of brush ('pen', 'airbrush', 'watercolor', 'texture', etc.)
  final String brushType;

  /// Base color of the brush
  final Color color;

  /// Base size of the brush in pixels
  final double size;

  /// Opacity level (0.0-1.0)
  final double opacity;

  /// Edge softness/hardness (0.0=soft, 1.0=hard)
  final double hardness;

  /// Distance between brush stamps (0.0-1.0)
  final double spacing;

  /// Minimum size multiplier at low pressure (0.0-1.0)
  final double minSize;

  /// Maximum size multiplier at high pressure (0.0-1.0)
  final double maxSize;

  /// Blend mode for compositing
  final BlendMode blendMode;

  /// Texture image for texture-based brushes
  final ui.Image? textureImage;

  /// Enable pressure sensitivity
  final bool usePressure;

  /// Enable tilt sensitivity
  final bool useTilt;

  /// Stroke stabilization level (0.0=none, 1.0=maximum)
  final double stabilization;

  /// Flow rate for airbrush (0.0-1.0)
  final double flow;

  /// Scatter/jitter amount (0.0-1.0)
  final double scatter;

  /// Rotation angle in radians
  final double rotation;

  /// Enable rotation jitter
  final bool rotationJitter;

  /// Brush shape aspect ratio (1.0=circle, <1.0=ellipse)
  final double aspectRatio;

  const BrushSettings({
    required this.brushType,
    required this.color,
    this.size = 10.0,
    this.opacity = 1.0,
    this.hardness = 1.0,
    this.spacing = 0.1,
    this.minSize = 0.1,
    this.maxSize = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.textureImage,
    this.usePressure = true,
    this.useTilt = false,
    this.stabilization = 0.0,
    this.flow = 1.0,
    this.scatter = 0.0,
    this.rotation = 0.0,
    this.rotationJitter = false,
    this.aspectRatio = 1.0,
  });

  /// Create a copy with modified values
  BrushSettings copyWith({
    String? brushType,
    Color? color,
    double? size,
    double? opacity,
    double? hardness,
    double? spacing,
    double? minSize,
    double? maxSize,
    BlendMode? blendMode,
    ui.Image? textureImage,
    bool? usePressure,
    bool? useTilt,
    double? stabilization,
    double? flow,
    double? scatter,
    double? rotation,
    bool? rotationJitter,
    double? aspectRatio,
  }) {
    return BrushSettings(
      brushType: brushType ?? this.brushType,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      hardness: hardness ?? this.hardness,
      spacing: spacing ?? this.spacing,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      blendMode: blendMode ?? this.blendMode,
      textureImage: textureImage ?? this.textureImage,
      usePressure: usePressure ?? this.usePressure,
      useTilt: useTilt ?? this.useTilt,
      stabilization: stabilization ?? this.stabilization,
      flow: flow ?? this.flow,
      scatter: scatter ?? this.scatter,
      rotation: rotation ?? this.rotation,
      rotationJitter: rotationJitter ?? this.rotationJitter,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  /// Preset: Standard pen
  factory BrushSettings.pen({Color color = Colors.black, double size = 4.0}) {
    return BrushSettings(
      brushType: 'pen',
      color: color,
      size: size,
      opacity: 1.0,
      hardness: 1.0,
      spacing: 0.05,
      usePressure: true,
    );
  }

  /// Preset: Soft airbrush
  factory BrushSettings.airbrush({
    Color color = Colors.black,
    double size = 20.0,
  }) {
    return BrushSettings(
      brushType: 'airbrush',
      color: color,
      size: size,
      opacity: 0.3,
      hardness: 0.2,
      spacing: 0.05,
      flow: 0.3,
      usePressure: true,
    );
  }

  /// Preset: Watercolor
  factory BrushSettings.watercolor({
    Color color = ((Colors.b * 255.0).round() & 0xff),
    double size = 30.0,
  }) {
    return BrushSettings(
      brushType: 'watercolor',
      color: color,
      size: size,
      opacity: 0.5,
      hardness: 0.1,
      spacing: 0.15,
      flow: 0.4,
      scatter: 0.2,
      usePressure: true,
    );
  }

  /// Preset: Hard pencil
  factory BrushSettings.pencil({
    Color color = Colors.black,
    double size = 2.0,
  }) {
    return BrushSettings(
      brushType: 'pencil',
      color: color,
      size: size,
      opacity: 0.8,
      hardness: 0.9,
      spacing: 0.02,
      minSize: 0.5,
      maxSize: 1.0,
      usePressure: true,
    );
  }

  /// Preset: Marker
  factory BrushSettings.marker({
    Color color = Colors.black,
    double size = 15.0,
  }) {
    return BrushSettings(
      brushType: 'marker',
      color: color,
      size: size,
      opacity: 0.6,
      hardness: 0.8,
      spacing: 0.1,
      aspectRatio: 0.3,
      usePressure: false,
    );
  }

  /// Preset: Chalk/Pastel
  factory BrushSettings.chalk({
    Color color = Colors.white,
    double size = 10.0,
  }) {
    return BrushSettings(
      brushType: 'chalk',
      color: color,
      size: size,
      opacity: 0.7,
      hardness: 0.5,
      spacing: 0.08,
      scatter: 0.3,
      usePressure: true,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'brushType': brushType,
      'color': color.toARGB32(),
      'size': size,
      'opacity': opacity,
      'hardness': hardness,
      'spacing': spacing,
      'minSize': minSize,
      'maxSize': maxSize,
      'blendMode': blendMode.index,
      'usePressure': usePressure,
      'useTilt': useTilt,
      'stabilization': stabilization,
      'flow': flow,
      'scatter': scatter,
      'rotation': rotation,
      'rotationJitter': rotationJitter,
      'aspectRatio': aspectRatio,
    };
  }

  /// Create from JSON
  factory BrushSettings.fromJson(Map<String, dynamic> json) {
    return BrushSettings(
      brushType: json['brushType'] as String,
      color: Color(json['color'] as int),
      size: json['size'] as double,
      opacity: json['opacity'] as double,
      hardness: json['hardness'] as double,
      spacing: json['spacing'] as double,
      minSize: json['minSize'] as double,
      maxSize: json['maxSize'] as double,
      blendMode: BlendMode.toARGB32()s[json['blendMode'] as int],
      usePressure: json['usePressure'] as bool,
      useTilt: json['useTilt'] as bool,
      stabilization: json['stabilization'] as double,
      flow: json['flow'] as double,
      scatter: json['scatter'] as double,
      rotation: json['rotation'] as double,
      rotationJitter: json['rotationJitter'] as bool,
      aspectRatio: json['aspectRatio'] as double,
    );
  }

  @override
  String toString() {
    return 'BrushSettings('
        'type: $brushType, '
        'size: $size, '
        'opacity: $opacity, '
        'hardness: $hardness'
        ')';
  }
}
