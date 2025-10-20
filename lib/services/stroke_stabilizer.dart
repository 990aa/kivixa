import 'dart:math';
import 'package:flutter/material.dart';
import '../models/stroke_point.dart';

/// Advanced stroke stabilization system for reducing hand tremor
/// and creating cleaner, smoother lines with multiple algorithms
class StrokeStabilizer {
  final List<StrokePoint> _buffer = [];
  final int _windowSize;

  StrokeStabilizer({int windowSize = 5}) : _windowSize = windowSize;

  /// StreamLine: Reduces minor jitter with exponential smoothing
  ///
  /// This algorithm interpolates between consecutive points, creating
  /// a lag effect that dampens high-frequency movements (tremors).
  ///
  /// [points] - Input stroke points
  /// [amount] - Smoothing strength (0.0 = no smoothing, 1.0 = maximum)
  ///
  /// Best for: Real-time drawing, reducing jitter without losing responsiveness
  List<StrokePoint> streamLine(List<StrokePoint> points, double amount) {
    if (points.length < 2 || amount == 0) return points;

    List<StrokePoint> smoothed = [points.first];

    for (int i = 1; i < points.length; i++) {
      final prev = smoothed.last;
      final curr = points[i];

      // Interpolate between previous and current based on amount
      // Higher amount = more smoothing (more lag)
      final lerpAmount = 1.0 - amount;
      final smoothedPos = Offset(
        prev.position.dx + (curr.position.dx - prev.position.dx) * lerpAmount,
        prev.position.dy + (curr.position.dy - prev.position.dy) * lerpAmount,
      );

      // Smooth pressure too for consistent stroke width
      final smoothedPressure =
          prev.pressure + (curr.pressure - prev.pressure) * lerpAmount;

      smoothed.add(
        StrokePoint(
          position: smoothedPos,
          pressure: smoothedPressure,
          tilt: curr.tilt,
          orientation: curr.orientation,
        ),
      );
    }

    return smoothed;
  }

  /// Moving Average Filter: Smooths overall path using a sliding window
  ///
  /// Each point is replaced by the average of its neighbors within a window.
  /// This reduces noise while preserving the general shape of the stroke.
  ///
  /// [points] - Input stroke points
  ///
  /// Best for: Post-processing, removing noise from completed strokes
  List<StrokePoint> movingAverage(List<StrokePoint> points) {
    if (points.length < _windowSize) return points;

    List<StrokePoint> smoothed = [];

    for (int i = 0; i < points.length; i++) {
      int start = max(0, i - _windowSize ~/ 2);
      int end = min(points.length, i + _windowSize ~/ 2 + 1);

      Offset avgPos = Offset.zero;
      double avgPressure = 0.0;
      double avgTilt = 0.0;

      for (int j = start; j < end; j++) {
        avgPos += points[j].position;
        avgPressure += points[j].pressure;
        avgTilt += points[j].tilt;
      }

      int count = end - start;
      avgPos = Offset(avgPos.dx / count, avgPos.dy / count);
      avgPressure /= count;
      avgTilt /= count;

      smoothed.add(
        StrokePoint(
          position: avgPos,
          pressure: avgPressure,
          tilt: avgTilt,
          orientation: points[i].orientation,
        ),
      );
    }

    return smoothed;
  }

  /// Weighted Moving Average: Like moving average but gives more weight to center
  ///
  /// Uses Gaussian-like weights for smoother results than simple averaging.
  ///
  /// [points] - Input stroke points
  /// [sigma] - Controls the spread of weights (higher = smoother)
  ///
  /// Best for: High-quality smoothing with minimal distortion
  List<StrokePoint> weightedMovingAverage(
    List<StrokePoint> points, {
    double sigma = 1.0,
  }) {
    if (points.length < _windowSize) return points;

    List<StrokePoint> smoothed = [];

    for (int i = 0; i < points.length; i++) {
      int start = max(0, i - _windowSize ~/ 2);
      int end = min(points.length, i + _windowSize ~/ 2 + 1);

      Offset weightedPos = Offset.zero;
      double weightedPressure = 0.0;
      double weightedTilt = 0.0;
      double totalWeight = 0.0;

      for (int j = start; j < end; j++) {
        // Gaussian weight based on distance from center
        final distance = (j - i).abs();
        final weight = exp(-(distance * distance) / (2 * sigma * sigma));

        weightedPos += points[j].position * weight;
        weightedPressure += points[j].pressure * weight;
        weightedTilt += points[j].tilt * weight;
        totalWeight += weight;
      }

      weightedPos = Offset(
        weightedPos.dx / totalWeight,
        weightedPos.dy / totalWeight,
      );
      weightedPressure /= totalWeight;
      weightedTilt /= totalWeight;

      smoothed.add(
        StrokePoint(
          position: weightedPos,
          pressure: weightedPressure,
          tilt: weightedTilt,
          orientation: points[i].orientation,
        ),
      );
    }

    return smoothed;
  }

  /// Catmull-Rom Spline: Creates smooth curves through points
  ///
  /// This generates a smooth curve that passes through all control points.
  /// Subdivisions control how many intermediate points are created.
  ///
  /// [points] - Input stroke points (minimum 4 required)
  /// [subdivisions] - Number of points to generate between each pair
  ///
  /// Best for: Creating flowing, natural-looking curves
  List<StrokePoint> catmullRomSpline(
    List<StrokePoint> points,
    int subdivisions,
  ) {
    if (points.length < 4) return points;

    List<StrokePoint> interpolated = [points.first];

    for (int i = 0; i < points.length - 3; i++) {
      for (int t = 0; t <= subdivisions; t++) {
        if (i == 0 && t == 0) continue; // Skip duplicate first point

        double u = t / subdivisions;
        final p = _catmullRom(
          points[i].position,
          points[i + 1].position,
          points[i + 2].position,
          points[i + 3].position,
          u,
        );

        // Interpolate pressure for natural stroke width variation
        final pressure = _catmullRomScalar(
          points[i].pressure,
          points[i + 1].pressure,
          points[i + 2].pressure,
          points[i + 3].pressure,
          u,
        );

        interpolated.add(
          StrokePoint(
            position: p,
            pressure: pressure.clamp(0.0, 1.0),
            tilt: points[i + 1].tilt,
            orientation: points[i + 1].orientation,
          ),
        );
      }
    }

    // Add the last point
    interpolated.add(points.last);
    return interpolated;
  }

  /// Bezier Spline: Creates smooth curves using cubic Bezier segments
  ///
  /// Converts the stroke into connected cubic Bezier curves for ultra-smooth paths.
  ///
  /// [points] - Input stroke points
  /// [subdivisions] - Number of points per segment
  ///
  /// Best for: -quality smooth curves, vector-like strokes
  List<StrokePoint> bezierSpline(List<StrokePoint> points, int subdivisions) {
    if (points.length < 2) return points;
    if (points.length == 2) return points;

    List<StrokePoint> smoothed = [points.first];

    // Generate control points for cubic Bezier curves
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      // Calculate control points
      final prev = i > 0 ? points[i - 1] : p0;
      final next = i < points.length - 2 ? points[i + 2] : p1;

      final cp1 = Offset(
        p0.position.dx + (p1.position.dx - prev.position.dx) / 4,
        p0.position.dy + (p1.position.dy - prev.position.dy) / 4,
      );

      final cp2 = Offset(
        p1.position.dx - (next.position.dx - p0.position.dx) / 4,
        p1.position.dy - (next.position.dy - p0.position.dy) / 4,
      );

      // Generate interpolated points along the Bezier curve
      for (int t = 1; t <= subdivisions; t++) {
        final u = t / subdivisions;
        final pos = _cubicBezier(p0.position, cp1, cp2, p1.position, u);
        final pressure = p0.pressure + (p1.pressure - p0.pressure) * u;

        smoothed.add(
          StrokePoint(
            position: pos,
            pressure: pressure,
            tilt: p0.tilt + (p1.tilt - p0.tilt) * u,
            orientation: p0.orientation + (p1.orientation - p0.orientation) * u,
          ),
        );
      }
    }

    return smoothed;
  }

  /// Chaikin's Corner Cutting: Iterative subdivision for smooth curves
  ///
  /// Each iteration cuts corners by creating new points at 1/4 and 3/4 positions.
  /// Multiple iterations create progressively smoother curves.
  ///
  /// [points] - Input stroke points
  /// [iterations] - Number of refinement passes (1-4 recommended)
  ///
  /// Best for: Quick smoothing with adjustable quality
  List<StrokePoint> chaikinSmooth(List<StrokePoint> points, int iterations) {
    if (points.length < 3) return points;

    List<StrokePoint> smoothed = List.from(points);

    for (int iter = 0; iter < iterations; iter++) {
      List<StrokePoint> next = [smoothed.first];

      for (int i = 0; i < smoothed.length - 1; i++) {
        final p0 = smoothed[i];
        final p1 = smoothed[i + 1];

        // Create two new points at 1/4 and 3/4 positions
        final q = StrokePoint(
          position: Offset(
            0.75 * p0.position.dx + 0.25 * p1.position.dx,
            0.75 * p0.position.dy + 0.25 * p1.position.dy,
          ),
          pressure: 0.75 * p0.pressure + 0.25 * p1.pressure,
          tilt: 0.75 * p0.tilt + 0.25 * p1.tilt,
          orientation: 0.75 * p0.orientation + 0.25 * p1.orientation,
        );

        final r = StrokePoint(
          position: Offset(
            0.25 * p0.position.dx + 0.75 * p1.position.dx,
            0.25 * p0.position.dy + 0.75 * p1.position.dy,
          ),
          pressure: 0.25 * p0.pressure + 0.75 * p1.pressure,
          tilt: 0.25 * p0.tilt + 0.75 * p1.tilt,
          orientation: 0.25 * p0.orientation + 0.75 * p1.orientation,
        );

        next.add(q);
        next.add(r);
      }

      next.add(smoothed.last);
      smoothed = next;
    }

    return smoothed;
  }

  /// Pull String: Simulates pulling a string tight through points
  ///
  /// Iteratively adjusts points to create a more direct path while
  /// maintaining the general shape. Great for cleaning up wobbly lines.
  ///
  /// [points] - Input stroke points
  /// [iterations] - Number of pulling passes
  /// [strength] - How much to pull (0.0-1.0)
  ///
  /// Best for: Straightening shaky lines while preserving intent
  List<StrokePoint> pullString(
    List<StrokePoint> points, {
    int iterations = 3,
    double strength = 0.5,
  }) {
    if (points.length < 3) return points;

    List<StrokePoint> smoothed = List.from(points);

    for (int iter = 0; iter < iterations; iter++) {
      List<StrokePoint> next = [smoothed.first];

      for (int i = 1; i < smoothed.length - 1; i++) {
        final prev = smoothed[i - 1];
        final curr = smoothed[i];
        final nextPoint = smoothed[i + 1];

        // Calculate the midpoint between neighbors
        final midpoint = Offset(
          (prev.position.dx + nextPoint.position.dx) / 2,
          (prev.position.dy + nextPoint.position.dy) / 2,
        );

        // Pull current point toward the midpoint
        final pulled = Offset(
          curr.position.dx + (midpoint.dx - curr.position.dx) * strength,
          curr.position.dy + (midpoint.dy - curr.position.dy) * strength,
        );

        next.add(
          StrokePoint(
            position: pulled,
            pressure: curr.pressure,
            tilt: curr.tilt,
            orientation: curr.orientation,
          ),
        );
      }

      next.add(smoothed.last);
      smoothed = next;
    }

    return smoothed;
  }

  /// Adaptive Smoothing: Applies more smoothing to shaky sections
  ///
  /// Analyzes the stroke for high-frequency changes and applies
  /// more aggressive smoothing to those areas.
  ///
  /// [points] - Input stroke points
  /// [threshold] - Minimum angle change to trigger smoothing
  ///
  /// Best for: Intelligent smoothing that preserves intentional features
  List<StrokePoint> adaptiveSmooth(
    List<StrokePoint> points, {
    double threshold = 0.3,
  }) {
    if (points.length < 3) return points;

    List<StrokePoint> smoothed = [points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      // Calculate angle change (curvature)
      final v1 = curr.position - prev.position;
      final v2 = next.position - curr.position;
      final angle = _angleBetween(v1, v2);

      // Apply smoothing based on angle
      final smoothFactor = (angle / pi).clamp(0.0, 1.0);

      if (smoothFactor > threshold) {
        // High curvature - apply smoothing
        final smoothedPos = Offset(
          (prev.position.dx + curr.position.dx + next.position.dx) / 3,
          (prev.position.dy + curr.position.dy + next.position.dy) / 3,
        );
        smoothed.add(
          StrokePoint(
            position: smoothedPos,
            pressure: curr.pressure,
            tilt: curr.tilt,
            orientation: curr.orientation,
          ),
        );
      } else {
        // Low curvature - keep original
        smoothed.add(curr);
      }
    }

    smoothed.add(points.last);
    return smoothed;
  }

  /// Combined smoothing: Applies multiple algorithms in sequence
  ///
  /// Recommended combination for best results:
  /// 1. StreamLine for real-time jitter reduction
  /// 2. Moving Average for noise removal
  /// 3. Catmull-Rom for final smoothing
  List<StrokePoint> combinedSmooth(
    List<StrokePoint> points, {
    double streamLineAmount = 0.3,
    int subdivisions = 2,
  }) {
    if (points.length < 4) return points;

    // Step 1: StreamLine for jitter
    var smoothed = streamLine(points, streamLineAmount);

    // Step 2: Moving average for noise
    smoothed = movingAverage(smoothed);

    // Step 3: Catmull-Rom for final smoothing
    smoothed = catmullRomSpline(smoothed, subdivisions);

    return smoothed;
  }

  // Helper: Catmull-Rom interpolation for 2D points
  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final x =
        0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y =
        0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  // Helper: Catmull-Rom interpolation for scalar values
  double _catmullRomScalar(
    double p0,
    double p1,
    double p2,
    double p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    return 0.5 *
        ((2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
  }

  // Helper: Cubic Bezier curve
  Offset _cubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x =
        uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y =
        uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;

    return Offset(x, y);
  }

  // Helper: Calculate angle between two vectors
  double _angleBetween(Offset v1, Offset v2) {
    if (v1.distance == 0 || v2.distance == 0) return 0;

    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final cross = v1.dx * v2.dy - v1.dy * v2.dx;

    return atan2(cross, dot).abs();
  }

  /// Clear internal buffer
  void clear() {
    _buffer.clear();
  }
}
