import 'package:flutter/material.dart';
import '../models/symmetry_settings.dart';
import '../models/stroke_point.dart';
import 'dart:math' as math;

/// Symmetry tool for creating mirrored and radial drawings
class SymmetryTool {
  SymmetrySettings settings;

  SymmetryTool({required this.settings});

  /// Apply symmetry transformation to a point
  List<Offset> applySymmetry(Offset point) {
    switch (settings.mode) {
      case SymmetryMode.none:
        return [point];

      case SymmetryMode.horizontal:
        return _applyHorizontalSymmetry(point);

      case SymmetryMode.vertical:
        return _applyVerticalSymmetry(point);

      case SymmetryMode.radial:
        return _applyRadialSymmetry(point);

      case SymmetryMode.kaleidoscope:
        return _applyKaleidoscopeSymmetry(point);
    }
  }

  /// Apply symmetry to multiple points (for strokes)
  List<List<StrokePoint>> applySymmetryToStroke(List<StrokePoint> points) {
    if (settings.mode == SymmetryMode.none) {
      return [points];
    }

    final symmetryCount = _getSymmetryCount();
    final result = <List<StrokePoint>>[];

    // Create a stroke for each symmetry instance
    for (int i = 0; i < symmetryCount; i++) {
      final transformedPoints = <StrokePoint>[];
      for (final point in points) {
        final symmetricOffsets = applySymmetry(point.position);
        if (i < symmetricOffsets.length) {
          transformedPoints.add(
            StrokePoint(
              position: symmetricOffsets[i],
              pressure: point.pressure,
              tilt: point.tilt,
              orientation: point.orientation,
            ),
          );
        }
      }
      if (transformedPoints.isNotEmpty) {
        result.add(transformedPoints);
      }
    }

    return result;
  }

  /// Get number of symmetric instances
  int _getSymmetryCount() {
    switch (settings.mode) {
      case SymmetryMode.none:
        return 1;
      case SymmetryMode.horizontal:
      case SymmetryMode.vertical:
        return 2;
      case SymmetryMode.radial:
        return settings.segments;
      case SymmetryMode.kaleidoscope:
        return settings.segments * 2; // Both sides of each segment
    }
  }

  /// Horizontal mirror symmetry
  List<Offset> _applyHorizontalSymmetry(Offset point) {
    return [point, Offset(2 * settings.center.dx - point.dx, point.dy)];
  }

  /// Vertical mirror symmetry
  List<Offset> _applyVerticalSymmetry(Offset point) {
    return [point, Offset(point.dx, 2 * settings.center.dy - point.dy)];
  }

  /// Radial symmetry (N-way rotation)
  List<Offset> _applyRadialSymmetry(Offset point) {
    final result = <Offset>[];
    final dx = point.dx - settings.center.dx;
    final dy = point.dy - settings.center.dy;
    final angleStep = 2 * math.pi / settings.segments;

    for (int i = 0; i < settings.segments; i++) {
      final angle = i * angleStep;
      final cos = math.cos(angle);
      final sin = math.sin(angle);

      // Rotate point around center
      final rotatedX = dx * cos - dy * sin;
      final rotatedY = dx * sin + dy * cos;

      result.add(
        Offset(settings.center.dx + rotatedX, settings.center.dy + rotatedY),
      );
    }

    return result;
  }

  /// Kaleidoscope symmetry (radial + mirror)
  List<Offset> _applyKaleidoscopeSymmetry(Offset point) {
    final result = <Offset>[];
    final dx = point.dx - settings.center.dx;
    final dy = point.dy - settings.center.dy;
    final angleStep = 2 * math.pi / settings.segments;

    for (int i = 0; i < settings.segments; i++) {
      final angle = i * angleStep;
      final cos = math.cos(angle);
      final sin = math.sin(angle);

      // Rotate point around center
      final rotatedX = dx * cos - dy * sin;
      final rotatedY = dx * sin + dy * cos;

      // Add rotated point
      result.add(
        Offset(settings.center.dx + rotatedX, settings.center.dy + rotatedY),
      );

      // Add mirrored point (flip across the radial line)
      result.add(
        Offset(settings.center.dx + rotatedX, settings.center.dy - rotatedY),
      );
    }

    return result;
  }

  /// Draw symmetry guidelines
  void drawGuidelines(Canvas canvas, Size size) {
    if (!settings.showGuidelines || settings.mode == SymmetryMode.none) {
      return;
    }

    final paint = Paint()
      ..color = settings.guidelineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = settings.guidelineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    switch (settings.mode) {
      case SymmetryMode.horizontal:
        _drawHorizontalGuideline(canvas, size, paint);
        break;

      case SymmetryMode.vertical:
        _drawVerticalGuideline(canvas, size, paint);
        break;

      case SymmetryMode.radial:
        _drawRadialGuidelines(canvas, size, paint, dashedPaint);
        break;

      case SymmetryMode.kaleidoscope:
        _drawKaleidoscopeGuidelines(canvas, size, paint, dashedPaint);
        break;

      case SymmetryMode.none:
        break;
    }

    // Draw center point
    _drawCenterPoint(canvas, paint);
  }

  /// Draw horizontal guideline
  void _drawHorizontalGuideline(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(0, settings.center.dy),
      Offset(size.width, settings.center.dy),
      paint,
    );
  }

  /// Draw vertical guideline
  void _drawVerticalGuideline(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(settings.center.dx, 0),
      Offset(settings.center.dx, size.height),
      paint,
    );
  }

  /// Draw radial guidelines
  void _drawRadialGuidelines(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint dashedPaint,
  ) {
    final maxRadius = math.max(size.width, size.height);
    final angleStep = 2 * math.pi / settings.segments;

    for (int i = 0; i < settings.segments; i++) {
      final angle = i * angleStep;
      final endX = settings.center.dx + maxRadius * math.cos(angle);
      final endY = settings.center.dy + maxRadius * math.sin(angle);

      // Draw solid line for primary axis
      if (i == 0) {
        canvas.drawLine(settings.center, Offset(endX, endY), paint);
      } else {
        _drawDashedLine(
          canvas,
          settings.center,
          Offset(endX, endY),
          dashedPaint,
        );
      }
    }

    // Draw center circle
    canvas.drawCircle(settings.center, 50, dashedPaint);
  }

  /// Draw kaleidoscope guidelines
  void _drawKaleidoscopeGuidelines(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint dashedPaint,
  ) {
    final maxRadius = math.max(size.width, size.height);
    final angleStep = 2 * math.pi / settings.segments;

    for (int i = 0; i < settings.segments; i++) {
      final angle = i * angleStep;
      final endX = settings.center.dx + maxRadius * math.cos(angle);
      final endY = settings.center.dy + maxRadius * math.sin(angle);

      // Draw radial line
      _drawDashedLine(canvas, settings.center, Offset(endX, endY), dashedPaint);

      // Draw mirror line (perpendicular bisector between radial lines)
      final midAngle = angle + angleStep / 2;
      final mirrorEndX = settings.center.dx + maxRadius * math.cos(midAngle);
      final mirrorEndY = settings.center.dy + maxRadius * math.sin(midAngle);
      _drawDashedLine(
        canvas,
        settings.center,
        Offset(mirrorEndX, mirrorEndY),
        paint,
      );
    }

    // Draw center circles
    canvas.drawCircle(settings.center, 30, dashedPaint);
    canvas.drawCircle(settings.center, 60, dashedPaint);
  }

  /// Draw dashed line
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDash = distance + dashWidth;
        if (nextDash > metric.length) {
          final remainingPath = metric.extractPath(distance, metric.length);
          canvas.drawPath(remainingPath, paint);
          break;
        }
        final dashPath = metric.extractPath(distance, nextDash);
        canvas.drawPath(dashPath, paint);
        distance = nextDash + dashSpace;
      }
    }
  }

  /// Draw center point indicator
  void _drawCenterPoint(Canvas canvas, Paint paint) {
    // Outer circle
    canvas.drawCircle(
      settings.center,
      8,
      Paint()
        ..color = settings.guidelineColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    // Inner circle
    canvas.drawCircle(
      settings.center,
      4,
      Paint()
        ..color = settings.guidelineColor
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawCircle(
      settings.center,
      8,
      Paint()
        ..color = settings.guidelineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  /// Update symmetry center
  void setCenter(Offset newCenter) {
    settings = settings.copyWith(center: newCenter);
  }

  /// Update symmetry mode
  void setMode(SymmetryMode newMode) {
    settings = settings.copyWith(mode: newMode);
  }

  /// Update segment count
  void setSegments(int count) {
    if (count < 2) return;
    settings = settings.copyWith(segments: count);
  }

  /// Toggle guidelines visibility
  void toggleGuidelines() {
    settings = settings.copyWith(showGuidelines: !settings.showGuidelines);
  }
}
