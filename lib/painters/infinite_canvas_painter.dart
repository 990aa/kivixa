import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:kivixa/models/stroke.dart';

/// Canvas painter for infinite canvas with grid and stroke rendering
class InfiniteCanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Matrix4 transform;
  final bool gridEnabled;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isHighlighter;

  InfiniteCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.transform,
    this.gridEnabled = true,
    this.currentColor = Colors.black,
    this.currentStrokeWidth = 4.0,
    this.isHighlighter = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw background grid
    if (gridEnabled) {
      _drawGrid(canvas, size, transform);
    }

    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke being drawn
    if (currentPoints.isNotEmpty) {
      _drawCurrentStroke(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Matrix4 transform) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Calculate visible area based on transform
    final scale = transform.getMaxScaleOnAxis();
    const gridSpacing = 50.0;

    // Adjust grid density based on zoom level
    double adjustedSpacing = gridSpacing;
    if (scale < 0.5) {
      adjustedSpacing = gridSpacing * 2;
    } else if (scale > 2.0) {
      adjustedSpacing = gridSpacing / 2;
    }

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += adjustedSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += adjustedSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.isHighlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    // Use perfect_freehand to get smooth stroke outline
    final outlinePoints = getStroke(
      stroke.points,
      options: StrokeOptions(
        size: stroke.strokeWidth,
        thinning: stroke.isHighlighter ? 0.0 : 0.7,
        smoothing: 0.5,
        streamline: 0.5,
      ),
    );

    if (outlinePoints.isEmpty) return;

    final path = Path();
    path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);

    for (int i = 1; i < outlinePoints.length; i++) {
      final p0 = outlinePoints[i - 1];
      final p1 = outlinePoints[i];

      // Use quadratic bezier curves for smoothness
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCurrentStroke(Canvas canvas) {
    if (currentPoints.isEmpty) return;

    final paint = Paint()
      ..color = currentColor
      ..strokeWidth = currentStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isHighlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    final path = Path();
    path.moveTo(currentPoints.first.dx, currentPoints.first.dy);

    for (int i = 1; i < currentPoints.length; i++) {
      final p0 = currentPoints[i - 1];
      final p1 = currentPoints[i];

      // Use quadratic bezier for smooth drawing
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant InfiniteCanvasPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentPoints.length != currentPoints.length ||
        oldDelegate.gridEnabled != gridEnabled ||
        oldDelegate.transform != transform;
  }
}
