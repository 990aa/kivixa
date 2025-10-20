import 'package:flutter/material.dart';
import '../models/stroke_point.dart';
import '../models/brush_settings.dart';
import '../engines/brush_engine.dart';

/// Manages brush stroke application and rendering
class BrushStrokeRenderer {
  /// Initialize brush engines
  void initialize() {
    BrushEngineFactory.initializeDefaults();
  }

  /// Render a stroke using the appropriate brush engine
  void renderStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    final engine = BrushEngineFactory.get(settings.brushType);

    if (engine == null) {
      debugPrint('Unknown brush type: ${settings.brushType}');
      // Fallback to pen brush
      PenBrush().applyStroke(canvas, points, settings);
      return;
    }

    engine.applyStroke(canvas, points, settings);
  }

  /// Get stroke bounds for dirty region tracking
  Rect getStrokeBounds(List<StrokePoint> points, BrushSettings settings) {
    final engine = BrushEngineFactory.get(settings.brushType);

    if (engine == null) {
      return PenBrush().getStrokeBounds(points, settings);
    }

    return engine.getStrokeBounds(points, settings);
  }

  /// Apply stroke stabilization to smooth out jittery input
  List<StrokePoint> stabilizePoints(
    List<StrokePoint> points,
    double stabilization,
  ) {
    if (points.length < 3 || stabilization <= 0) return points;

    final result = <StrokePoint>[points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      // Weighted average for smoothing
      final weight = 1.0 - stabilization;
      final stabilizedX = curr.position.dx * weight +
          (prev.position.dx + next.position.dx) * stabilization / 2;
      final stabilizedY = curr.position.dy * weight +
          (prev.position.dy + next.position.dy) * stabilization / 2;

      result.add(StrokePoint(
        position: Offset(stabilizedX, stabilizedY),
        pressure: curr.pressure,
        tilt: curr.tilt,
        orientation: curr.orientation,
      ));
    }

    result.add(points.last);
    return result;
  }

  /// Interpolate between points for smoother strokes
  List<StrokePoint> interpolatePoints(
    List<StrokePoint> points, {
    int interpolationSteps = 2,
  }) {
    if (points.length < 2) return points;

    final result = <StrokePoint>[];

    for (int i = 0; i < points.length - 1; i++) {
      final curr = points[i];
      final next = points[i + 1];

      result.add(curr);

      // Add interpolated points
      for (int step = 1; step < interpolationSteps; step++) {
        final t = step / interpolationSteps;
        final interpolatedX = curr.position.dx + (next.position.dx - curr.position.dx) * t;
        final interpolatedY = curr.position.dy + (next.position.dy - curr.position.dy) * t;
        final interpolatedPressure = curr.pressure + (next.pressure - curr.pressure) * t;

        result.add(StrokePoint(
          position: Offset(interpolatedX, interpolatedY),
          pressure: interpolatedPressure,
          tilt: curr.tilt + (next.tilt - curr.tilt) * t,
          orientation: curr.orientation + (next.orientation - curr.orientation) * t,
        ));
      }
    }

    result.add(points.last);
    return result;
  }

  /// Simplify stroke by removing redundant points (Douglas-Peucker algorithm)
  List<StrokePoint> simplifyStroke(
    List<StrokePoint> points, {
    double tolerance = 2.0,
  }) {
    if (points.length < 3) return points;

    return _douglasPeucker(points, tolerance);
  }

  List<StrokePoint> _douglasPeucker(List<StrokePoint> points, double tolerance) {
    // Find point with maximum distance from line segment
    double maxDistance = 0;
    int maxIndex = 0;
    final end = points.length - 1;

    for (int i = 1; i < end; i++) {
      final distance = _perpendicularDistance(
        points[i].position,
        points.first.position,
        points.last.position,
      );

      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        tolerance,
      );
      final right = _douglasPeucker(
        points.sublist(maxIndex),
        tolerance,
      );

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    if (dx == 0 && dy == 0) {
      return (point - lineStart).distance;
    }

    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        (dx * dx + dy * dy);

    final projection = t < 0
        ? lineStart
        : t > 1
            ? lineEnd
            : Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);

    return (point - projection).distance;
  }
}
