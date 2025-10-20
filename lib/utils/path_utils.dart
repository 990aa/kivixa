import 'package:flutter/material.dart';

class PathUtils {
  /// Creates a smooth path using Cubic Bézier curves from a list of points.
  static Path createBezierPath(List<Offset> points) {
    final path = Path();

    if (points.isEmpty) return path;

    if (points.length == 1) {
      // Single point: draw a small circle
      path.addOval(Rect.fromCircle(center: points[0], radius: 2.0));
      return path;
    }

    // Start the path at the first point
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      // Two points: draw a straight line
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Three or more points: use Cubic Bézier curves with Catmull-Rom interpolation
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      // Calculate Bézier control points using Catmull-Rom conversion
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6.0,
        p1.dy + (p2.dy - p0.dy) / 6.0,
      );

      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6.0,
        p2.dy - (p3.dy - p1.dy) / 6.0,
      );

      path.cubicTo(
        cp1.dx,
        cp1.dy, // First control point
        cp2.dx,
        cp2.dy, // Second control point
        p2.dx,
        p2.dy, // End point
      );
    }

    return path;
  }
}
