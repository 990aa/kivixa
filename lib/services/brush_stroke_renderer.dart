import 'package:flutter/material.dart';
import '../models/stroke_point.dart';
import '../models/brush_settings.dart';
import '../engines/brush_engine.dart';
import 'stroke_stabilizer.dart';

/// Manages brush stroke application and rendering
class BrushStrokeRenderer {
  final StrokeStabilizer _stabilizer = StrokeStabilizer(windowSize: 5);

  /// Initialize brush engines
  void initialize() {
    BrushEngineFactory.initializeDefaults();
  }

  /// Render a stroke using the appropriate brush engine
  /// Automatically applies stabilization if configured in settings
  void renderStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    // Apply stabilization if enabled
    var processedPoints = points;
    if (settings.stabilization > 0 && points.length > 2) {
      processedPoints = _stabilizer.streamLine(points, settings.stabilization);
    }

    final engine = BrushEngineFactory.get(settings.brushType);

    if (engine == null) {
      debugPrint('Unknown brush type: ${settings.brushType}');
      // Fallback to pen brush
      PenBrush().applyStroke(canvas, processedPoints, settings);
      return;
    }

    engine.applyStroke(canvas, processedPoints, settings);
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
  /// Uses the advanced StrokeStabilizer with multiple algorithms
  ///
  /// Available modes:
  /// - 'streamline': Real-time jitter reduction (default)
  /// - 'moving': Moving average filter
  /// - 'weighted': Weighted moving average with Gaussian weights
  /// - 'catmull': Catmull-Rom spline interpolation
  /// - 'bezier': Cubic Bezier spline
  /// - 'chaikin': Chaikin corner cutting
  /// - 'pull': Pull string algorithm
  /// - 'adaptive': Adaptive smoothing based on curvature
  /// - 'combined': Multi-stage smoothing (best quality)
  List<StrokePoint> stabilizePoints(
    List<StrokePoint> points,
    double stabilization, {
    String mode = 'streamline',
  }) {
    if (points.length < 3 || stabilization <= 0) return points;

    switch (mode) {
      case 'streamline':
        return _stabilizer.streamLine(points, stabilization);
      case 'moving':
        return _stabilizer.movingAverage(points);
      case 'weighted':
        return _stabilizer.weightedMovingAverage(
          points,
          sigma: stabilization * 2,
        );
      case 'catmull':
        return _stabilizer.catmullRomSpline(
          points,
          (stabilization * 5).round().clamp(1, 5),
        );
      case 'bezier':
        return _stabilizer.bezierSpline(
          points,
          (stabilization * 5).round().clamp(1, 5),
        );
      case 'chaikin':
        return _stabilizer.chaikinSmooth(
          points,
          (stabilization * 3).round().clamp(1, 3),
        );
      case 'pull':
        return _stabilizer.pullString(
          points,
          iterations: 3,
          strength: stabilization,
        );
      case 'adaptive':
        return _stabilizer.adaptiveSmooth(points, threshold: stabilization);
      case 'combined':
        return _stabilizer.combinedSmooth(
          points,
          streamLineAmount: stabilization,
        );
      default:
        return _stabilizer.streamLine(points, stabilization);
    }
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
        final interpolatedX =
            curr.position.dx + (next.position.dx - curr.position.dx) * t;
        final interpolatedY =
            curr.position.dy + (next.position.dy - curr.position.dy) * t;
        final interpolatedPressure =
            curr.pressure + (next.pressure - curr.pressure) * t;

        result.add(
          StrokePoint(
            position: Offset(interpolatedX, interpolatedY),
            pressure: interpolatedPressure,
            tilt: curr.tilt + (next.tilt - curr.tilt) * t,
            orientation:
                curr.orientation + (next.orientation - curr.orientation) * t,
          ),
        );
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

  List<StrokePoint> _douglasPeucker(
    List<StrokePoint> points,
    double tolerance,
  ) {
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
      final left = _douglasPeucker(points.sublist(0, maxIndex + 1), tolerance);
      final right = _douglasPeucker(points.sublist(maxIndex), tolerance);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  double _perpendicularDistance(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    if (dx == 0 && dy == 0) {
      return (point - lineStart).distance;
    }

    final t =
        ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        (dx * dx + dy * dy);

    final projection = t < 0
        ? lineStart
        : t > 1
        ? lineEnd
        : Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);

    return (point - projection).distance;
  }
}
