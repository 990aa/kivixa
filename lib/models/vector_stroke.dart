import 'package:flutter/material.dart';
import '../models/stroke_point.dart';
import '../models/brush_settings.dart';
import 'dart:math' as math;

/// Vector stroke that can be rendered at any resolution
class VectorStroke {
  final String id;
  final List<StrokePoint> points; // Original input points
  final BrushSettings brushSettings;
  final DateTime timestamp;

  VectorStroke({
    required this.id,
    required this.points,
    required this.brushSettings,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to SVG Path for export
  String toSVGPath() {
    if (points.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('M ${points.first.position.dx} ${points.first.position.dy}');

    if (points.length == 1) {
      // Single point - draw a small circle
      return 'M ${points.first.position.dx} ${points.first.position.dy} '
          'a ${brushSettings.size / 2},${brushSettings.size / 2} 0 1,0 1,0 '
          'a ${brushSettings.size / 2},${brushSettings.size / 2} 0 1,0 -1,0';
    }

    if (points.length == 2) {
      // Two points - draw line
      buffer.write(' L ${points[1].position.dx} ${points[1].position.dy}');
      return buffer.toString();
    }

    // Use Cubic Bezier curves for smooth strokes
    for (int i = 1; i < points.length - 2; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final p2 = points[i + 2];

      // Calculate control points for smooth curve
      final cp1x = p0.position.dx + (p1.position.dx - p0.position.dx) * 0.5;
      final cp1y = p0.position.dy + (p1.position.dy - p0.position.dy) * 0.5;
      final cp2x = p1.position.dx + (p2.position.dx - p1.position.dx) * 0.5;
      final cp2y = p1.position.dy + (p2.position.dy - p1.position.dy) * 0.5;

      buffer.write(
          ' C $cp1x $cp1y, $cp2x $cp2y, ${p1.position.dx} ${p1.position.dy}');
    }

    // Add final point
    if (points.length > 2) {
      final last = points.last;
      buffer.write(' L ${last.position.dx} ${last.position.dy}');
    }

    return buffer.toString();
  }

  /// Store stroke width variations along path
  List<double> getWidthsAlongPath() {
    return points.map((p) {
      final pressureFactor = brushSettings.usePressure ? p.pressure : 1.0;
      return brushSettings.size *
          pressureFactor *
          (brushSettings.minSize +
              (brushSettings.maxSize - brushSettings.minSize));
    }).toList();
  }

  /// Get colors along path (for gradient brushes)
  List<Color> getColorsAlongPath() {
    return points
        .map((p) => brushSettings.color.withValues(
              alpha: brushSettings.opacity * p.pressure,
            ))
        .toList();
  }

  /// Calculate bounding box
  Rect getBounds() {
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

    // Add padding for stroke width
    final maxWidth = brushSettings.size * brushSettings.maxSize;
    return Rect.fromLTRB(
      minX - maxWidth,
      minY - maxWidth,
      maxX + maxWidth,
      maxY + maxWidth,
    );
  }

  /// Get total path length
  double getPathLength() {
    if (points.length < 2) return 0.0;

    double length = 0.0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].position.dx - points[i - 1].position.dx;
      final dy = points[i].position.dy - points[i - 1].position.dy;
      length += math.sqrt(dx * dx + dy * dy);
    }
    return length;
  }

  /// Simplify stroke by removing redundant points
  VectorStroke simplify({double tolerance = 2.0}) {
    if (points.length <= 2) return this;

    final simplified = _douglasPeucker(points, tolerance);
    return VectorStroke(
      id: id,
      points: simplified,
      brushSettings: brushSettings,
      timestamp: timestamp,
    );
  }

  /// Douglas-Peucker algorithm for path simplification
  List<StrokePoint> _douglasPeucker(List<StrokePoint> points, double tolerance) {
    if (points.length <= 2) return points;

    // Find point with maximum distance from line between start and end
    double maxDistance = 0.0;
    int maxIndex = 0;

    final start = points.first.position;
    final end = points.last.position;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i].position, start, end);
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

  /// Calculate perpendicular distance from point to line
  double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    if (dx == 0 && dy == 0) {
      // Line is a point
      final pdx = point.dx - lineStart.dx;
      final pdy = point.dy - lineStart.dy;
      return math.sqrt(pdx * pdx + pdy * pdy);
    }

    final numerator = ((point.dx - lineStart.dx) * dy -
            (point.dy - lineStart.dy) * dx)
        .abs();
    final denominator = math.sqrt(dx * dx + dy * dy);

    return numerator / denominator;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'brushSettings': brushSettings.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory VectorStroke.fromJson(Map<String, dynamic> json) {
    return VectorStroke(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      brushSettings:
          BrushSettings.fromJson(json['brushSettings'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with modified values
  VectorStroke copyWith({
    String? id,
    List<StrokePoint>? points,
    BrushSettings? brushSettings,
    DateTime? timestamp,
  }) {
    return VectorStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      brushSettings: brushSettings ?? this.brushSettings,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
