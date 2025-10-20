import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/stroke_point.dart';
import '../models/brush_settings.dart';

/// Abstract base class for all brush engines
abstract class BrushEngine {
  /// Apply a stroke to the canvas using the given points and settings
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  );

  /// Get the estimated bounds of the stroke (for dirty region tracking)
  Rect getStrokeBounds(List<StrokePoint> points, BrushSettings settings) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.position.dx;
    double maxX = points.first.position.dx;
    double minY = points.first.position.dy;
    double maxY = points.first.position.dy;

    for (final point in points) {
      if (point.position.dx < minX) minX = point.position.dx;
      if (point.position.dx > maxX) maxX = point.position.dx;
      if (point.position.dy < minY) minY = point.position.dy;
      if (point.position.dy > maxY) maxY = point.position.dy;
    }

    final padding = settings.size * settings.maxSize + 10;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// Calculate pressure-responsive size
  double calculatePressureSize(
    double baseSize,
    double pressure,
    BrushSettings settings,
  ) {
    if (!settings.usePressure) return baseSize;

    final sizeRange = settings.maxSize - settings.minSize;
    final pressureMultiplier = settings.minSize + (sizeRange * pressure);
    return baseSize * pressureMultiplier;
  }

  /// Calculate pressure-responsive opacity
  double calculatePressureOpacity(
    double baseOpacity,
    double pressure,
    BrushSettings settings,
  ) {
    if (!settings.usePressure) return baseOpacity;
    return baseOpacity * pressure;
  }

  /// Apply spacing to points (filter points that are too close)
  List<StrokePoint> applySpacing(
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty || settings.spacing <= 0) return points;

    final result = <StrokePoint>[points.first];
    final minDistance = settings.size * settings.spacing;

    for (int i = 1; i < points.length; i++) {
      final lastPoint = result.last.position;
      final currentPoint = points[i].position;
      final distance = (currentPoint - lastPoint).distance;

      if (distance >= minDistance) {
        result.add(points[i]);
      }
    }

    return result;
  }

  /// Apply scatter/jitter to a point
  Offset applyScatter(
    Offset position,
    double scatter,
    double brushSize,
    int seed,
  ) {
    if (scatter <= 0) return position;

    // Use seed for deterministic randomness
    final random = _seededRandom(seed);
    final scatterAmount = brushSize * scatter;
    final dx = (random - 0.5) * 2 * scatterAmount;
    final dy = (random - 0.5) * 2 * scatterAmount;

    return Offset(position.dx + dx, position.dy + dy);
  }

  /// Simple seeded random number generator
  double _seededRandom(int seed) {
    final x = (seed * 0x5DEECE66D + 0xB) & ((1 << 48) - 1);
    return (x >> 16) / (1 << 32);
  }
}

/// Factory for creating brush engines
class BrushEngineFactory {
  static final Map<String, BrushEngine> _engines = {};

  /// Register a brush engine
  static void register(String type, BrushEngine engine) {
    _engines[type] = engine;
  }

  /// Get a brush engine by type
  static BrushEngine? get(String type) {
    return _engines[type];
  }

  /// Initialize default engines
  static void initializeDefaults() {
    register('pen', PenBrush());
    register('airbrush', AirbrushEngine());
    register('pencil', PencilBrush());
    register('marker', MarkerBrush());
    register('watercolor', WatercolorBrush());
    register('chalk', ChalkBrush());
  }

  /// Get all registered brush types
  static List<String> get availableTypes => _engines.keys.toList();
}

/// Standard pen/pencil brush with hard edges
class PenBrush extends BrushEngine {
  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);
    if (spacedPoints.length < 2) return;

    for (int i = 1; i < spacedPoints.length; i++) {
      final prev = spacedPoints[i - 1];
      final curr = spacedPoints[i];

      // Calculate pressure-responsive width
      final strokeWidth = calculatePressureSize(
        settings.size,
        prev.pressure,
        settings,
      );

      // Calculate pressure-responsive opacity
      final opacity = calculatePressureOpacity(
        settings.opacity,
        prev.pressure,
        settings,
      );

      // Create paint
      final paint = Paint()
        ..color = settings.color.withOpacity(opacity)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = settings.blendMode
        ..isAntiAlias = true;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }
}

/// Pencil brush with texture-like appearance
class PencilBrush extends BrushEngine {
  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);

    for (int i = 0; i < spacedPoints.length; i++) {
      final point = spacedPoints[i];
      final size = calculatePressureSize(settings.size, point.pressure, settings);
      final opacity = calculatePressureOpacity(settings.opacity, point.pressure, settings);

      // Multiple small circles for pencil texture
      final layers = 3;
      for (int layer = 0; layer < layers; layer++) {
        final layerOpacity = opacity * (0.3 + layer * 0.2);
        final layerSize = size * (0.8 + layer * 0.1);

        final paint = Paint()
          ..color = settings.color.withOpacity(layerOpacity)
          ..style = PaintingStyle.fill
          ..blendMode = settings.blendMode;

        canvas.drawCircle(point.position, layerSize / 2, paint);
      }
    }
  }
}

/// Marker brush with flat/elliptical shape
class MarkerBrush extends BrushEngine {
  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);
    if (spacedPoints.length < 2) return;

    for (int i = 1; i < spacedPoints.length; i++) {
      final prev = spacedPoints[i - 1];
      final curr = spacedPoints[i];

      final size = settings.size;
      final paint = Paint()
        ..color = settings.color.withOpacity(settings.opacity)
        ..strokeWidth = size * settings.aspectRatio
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = settings.blendMode;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }
}

/// Chalk/pastel brush with scatter effect
class ChalkBrush extends BrushEngine {
  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);

    for (int i = 0; i < spacedPoints.length; i++) {
      final point = spacedPoints[i];
      final size = calculatePressureSize(settings.size, point.pressure, settings);
      final opacity = calculatePressureOpacity(settings.opacity, point.pressure, settings);

      // Multiple scattered particles for chalk texture
      final particleCount = 8;
      for (int p = 0; p < particleCount; p++) {
        final scatteredPos = applyScatter(
          point.position,
          settings.scatter,
          size,
          i * particleCount + p,
        );

        final particleOpacity = opacity * (0.3 + (p / particleCount) * 0.4);
        final particleSize = size * (0.2 + (p / particleCount) * 0.3);

        final paint = Paint()
          ..color = settings.color.withOpacity(particleOpacity)
          ..style = PaintingStyle.fill
          ..blendMode = settings.blendMode;

        canvas.drawCircle(scatteredPos, particleSize, paint);
      }
    }
  }
}

/// Watercolor brush with soft edges and flow
class WatercolorBrush extends BrushEngine {
  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);

    for (int i = 0; i < spacedPoints.length; i++) {
      final point = spacedPoints[i];
      final size = calculatePressureSize(settings.size, point.pressure, settings);
      final opacity = calculatePressureOpacity(
        settings.opacity * settings.flow,
        point.pressure,
        settings,
      );

      // Create soft gradient for watercolor effect
      final gradient = ui.Gradient.radial(
        point.position,
        size,
        [
          settings.color.withOpacity(opacity),
          settings.color.withOpacity(opacity * 0.5),
          settings.color.withOpacity(0),
        ],
        [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient
        ..blendMode = settings.blendMode;

      canvas.drawCircle(point.position, size, paint);

      // Add scattered droplets for texture
      if (settings.scatter > 0) {
        final dropletCount = 3;
        for (int d = 0; d < dropletCount; d++) {
          final dropletPos = applyScatter(
            point.position,
            settings.scatter * 1.5,
            size,
            i * dropletCount + d,
          );

          final dropletPaint = Paint()
            ..color = settings.color.withOpacity(opacity * 0.3)
            ..style = PaintingStyle.fill
            ..blendMode = settings.blendMode;

          canvas.drawCircle(dropletPos, size * 0.2, dropletPaint);
        }
      }
    }
  }
}
