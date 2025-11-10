import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/models/brush_settings.dart';
import 'package:kivixa/engines/brush_engine.dart';

/// Airbrush with Gaussian falloff and flow control
class AirbrushEngine extends BrushEngine {
  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);

    for (final point in spacedPoints) {
      final radius = calculatePressureSize(
        settings.size,
        point.pressure,
        settings,
      );

      final opacity = calculatePressureOpacity(
        settings.opacity * settings.flow,
        point.pressure,
        settings,
      );

      // Create radial gradient for soft edges (Gaussian-like falloff)
      final hardnessStop = 1.0 - settings.hardness;
      
      final gradient = ui.Gradient.radial(
        point.position,
        radius,
        [
          settings.color.withValues(alpha: opacity),
          settings.color.withValues(alpha: opacity * 0.5),
          settings.color.withValues(alpha: 0),
        ],
        [0.0, hardnessStop * 0.5, hardnessStop],
      );

      final paint = Paint()
        ..shader = gradient
        ..blendMode = settings.blendMode
        ..isAntiAlias = true;

      canvas.drawCircle(point.position, radius, paint);
    }
  }

  /// Advanced airbrush with multiple layers for more realistic effect
  void applyStrokeAdvanced(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);

    for (final point in spacedPoints) {
      final baseRadius = calculatePressureSize(
        settings.size,
        point.pressure,
        settings,
      );

      final baseOpacity = calculatePressureOpacity(
        settings.opacity * settings.flow,
        point.pressure,
        settings,
      );

      // Multiple layers for more realistic airbrush
      final layers = [
        const _AirbrushLayer(radiusMultiplier: 0.3, opacityMultiplier: 0.8),
        const _AirbrushLayer(radiusMultiplier: 0.6, opacityMultiplier: 0.5),
        const _AirbrushLayer(radiusMultiplier: 1.0, opacityMultiplier: 0.2),
      ];

      for (final layer in layers) {
        final radius = baseRadius * layer.radiusMultiplier;
        final opacity = baseOpacity * layer.opacityMultiplier;

        final hardnessStop = 1.0 - settings.hardness;

        final gradient = ui.Gradient.radial(
          point.position,
          radius,
          [
            settings.color.withValues(alpha: opacity),
            settings.color.withValues(alpha: opacity * 0.3),
            settings.color.withValues(alpha: 0),
          ],
          [0.0, hardnessStop * 0.3, hardnessStop],
        );

        final paint = Paint()
          ..shader = gradient
          ..blendMode = settings.blendMode;

        canvas.drawCircle(point.position, radius, paint);
      }
    }
  }
}

/// Helper class for airbrush layers
class _AirbrushLayer {
  final double radiusMultiplier;
  final double opacityMultiplier;

  const _AirbrushLayer({
    required this.radiusMultiplier,
    required this.opacityMultiplier,
  });
}
