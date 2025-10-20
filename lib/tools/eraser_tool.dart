import 'package:flutter/material.dart';
import '../models/stroke_point.dart';
import '../models/eraser_mode.dart';
import '../models/drawing_layer.dart';

/// Eraser tool with multiple modes and features
class EraserTool {
  /// Erase using the specified mode and settings
  void erase(Canvas canvas, List<StrokePoint> points, EraserSettings settings) {
    if (points.isEmpty) return;

    switch (settings.mode) {
      case EraserMode.standard:
        _eraseStandard(canvas, points, settings);
        break;
      case EraserMode.blendColor:
        _eraseBlendColor(canvas, points, settings);
        break;
      case EraserMode.alpha:
        _eraseAlpha(canvas, points, settings);
        break;
      case EraserMode.stroke:
        // Stroke mode is handled at layer level
        _eraseStandard(canvas, points, settings);
        break;
    }
  }

  /// Standard eraser - removes to transparency
  void _eraseStandard(
    Canvas canvas,
    List<StrokePoint> points,
    EraserSettings settings,
  ) {
    if (points.length < 2) {
      // Single point - draw circle
      if (points.isNotEmpty) {
        final point = points.first;
        final size = _calculateSize(point.pressure, settings);
        final paint = Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.fill;

        canvas.drawCircle(point.position, size / 2, paint);
      }
      return;
    }

    // Draw eraser path
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear;

    if (settings.hardness < 1.0) {
      // Soft eraser with gradient edges
      _drawSoftEraser(canvas, points, settings);
    } else {
      // Hard eraser
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];

        final size = _calculateSize(curr.pressure, settings);
        paint.strokeWidth = size;

        canvas.drawLine(prev.position, curr.position, paint);
      }
    }
  }

  /// Blend color eraser - paints with background color
  void _eraseBlendColor(
    Canvas canvas,
    List<StrokePoint> points,
    EraserSettings settings,
  ) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        final point = points.first;
        final size = _calculateSize(point.pressure, settings);
        final paint = Paint()
          ..color = settings.backgroundColor.withValues(alpha: settings.opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(point.position, size / 2, paint);
      }
      return;
    }

    final paint = Paint()
      ..color = settings.backgroundColor.withValues(alpha: settings.opacity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final size = _calculateSize(curr.pressure, settings);
      paint.strokeWidth = size;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  /// Alpha eraser - reduces opacity only
  void _eraseAlpha(
    Canvas canvas,
    List<StrokePoint> points,
    EraserSettings settings,
  ) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        final point = points.first;
        final size = _calculateSize(point.pressure, settings);
        final paint = Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.white.withValues(alpha: settings.opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(point.position, size / 2, paint);
      }
      return;
    }

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.dstOut
      ..color = Colors.white.withValues(alpha: settings.opacity);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final size = _calculateSize(curr.pressure, settings);
      paint.strokeWidth = size;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  /// Soft eraser with gradient edges
  void _drawSoftEraser(
    Canvas canvas,
    List<StrokePoint> points,
    EraserSettings settings,
  ) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final size = _calculateSize(point.pressure, settings);

      // Create radial gradient for soft edges
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 1.0 - settings.hardness),
          Colors.transparent,
        ],
        stops: [0.0, settings.hardness, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: point.position, radius: size / 2),
        )
        ..blendMode = BlendMode.clear;

      canvas.drawCircle(point.position, size / 2, paint);
    }
  }

  /// Calculate eraser size based on pressure and settings
  double _calculateSize(double pressure, EraserSettings settings) {
    if (!settings.usePressure) {
      return settings.size;
    }

    final range = settings.maxSize - settings.minSize;
    return settings.size * (settings.minSize + range * pressure);
  }

  /// Check if a point is within eraser path (for stroke mode)
  bool isPointInEraserPath(
    Offset point,
    List<StrokePoint> eraserPoints,
    EraserSettings settings,
  ) {
    for (final eraserPoint in eraserPoints) {
      final size = _calculateSize(eraserPoint.pressure, settings);
      final distance = (point - eraserPoint.position).distance;

      if (distance <= size / 2) {
        return true;
      }
    }
    return false;
  }

  /// Find strokes that intersect with eraser path
  List<int> findIntersectingStrokes(
    List<StrokePoint> eraserPoints,
    EraserSettings settings,
    DrawingLayer layer,
  ) {
    final intersectingIndices = <int>[];

    for (int i = 0; i < layer.strokes.length; i++) {
      final stroke = layer.strokes[i];

      for (final strokePoint in stroke.points) {
        if (isPointInEraserPath(strokePoint.position, eraserPoints, settings)) {
          intersectingIndices.add(i);
          break; // Move to next stroke
        }
      }
    }

    return intersectingIndices;
  }

  /// Get eraser bounds for dirty region tracking
  Rect getEraserBounds(List<StrokePoint> points, EraserSettings settings) {
    if (points.isEmpty) return Rect.zero;

    double left = points.first.position.dx;
    double top = points.first.position.dy;
    double right = points.first.position.dx;
    double bottom = points.first.position.dy;

    double maxSize = settings.size * settings.maxSize;

    for (final point in points) {
      final size = _calculateSize(point.pressure, settings);
      final radius = size / 2;

      left = (point.position.dx - radius).clamp(left, double.infinity);
      top = (point.position.dy - radius).clamp(top, double.infinity);
      right = (point.position.dx + radius).clamp(0, right);
      bottom = (point.position.dy + radius).clamp(0, bottom);
    }

    // Add padding for soft edges
    final padding = maxSize;
    return Rect.fromLTRB(
      left - padding,
      top - padding,
      right + padding,
      bottom + padding,
    );
  }

  /// Draw eraser preview/cursor
  void drawEraserPreview(
    Canvas canvas,
    Offset position,
    EraserSettings settings,
    double pressure,
  ) {
    final size = _calculateSize(pressure, settings);

    // Outer circle
    final outerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(position, size / 2, outerPaint);

    // Inner circle (indicates active area)
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(position, size / 2 * 0.9, innerPaint);

    // Center dot
    final centerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 2, centerPaint);

    // Mode indicator (small icon)
    _drawModeIndicator(canvas, position, settings, size);
  }

  /// Draw mode indicator in preview
  void _drawModeIndicator(
    Canvas canvas,
    Offset position,
    EraserSettings settings,
    double size,
  ) {
    final indicatorPos = Offset(
      position.dx + size / 2 + 8,
      position.dy - size / 2 - 8,
    );

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(indicatorPos, 8, bgPaint);

    // Mode-specific indicator
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    switch (settings.mode) {
      case EraserMode.standard:
        // X mark
        canvas.drawLine(
          indicatorPos + const Offset(-4, -4),
          indicatorPos + const Offset(4, 4),
          indicatorPaint..strokeWidth = 2,
        );
        canvas.drawLine(
          indicatorPos + const Offset(4, -4),
          indicatorPos + const Offset(-4, 4),
          indicatorPaint..strokeWidth = 2,
        );
        break;

      case EraserMode.blendColor:
        // Filled circle
        canvas.drawCircle(indicatorPos, 4, indicatorPaint);
        break;

      case EraserMode.alpha:
        // Half circle
        canvas.drawArc(
          Rect.fromCircle(center: indicatorPos, radius: 4),
          0,
          3.14159, // π
          true,
          indicatorPaint,
        );
        break;

      case EraserMode.stroke:
        // Wavy line
        final path = Path();
        path.moveTo(indicatorPos.dx - 4, indicatorPos.dy);
        path.quadraticBezierTo(
          indicatorPos.dx - 2,
          indicatorPos.dy - 3,
          indicatorPos.dx,
          indicatorPos.dy,
        );
        path.quadraticBezierTo(
          indicatorPos.dx + 2,
          indicatorPos.dy + 3,
          indicatorPos.dx + 4,
          indicatorPos.dy,
        );
        canvas.drawPath(path, indicatorPaint..strokeWidth = 2);
        break;
    }
  }
}
