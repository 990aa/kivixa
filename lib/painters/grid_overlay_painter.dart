import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Grid overlay painter for canvas
class GridOverlayPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;
  final double scale;
  final bool showMajorLines;
  final int majorLineInterval;

  GridOverlayPainter({
    required this.gridSize,
    required this.gridColor,
    this.scale = 1.0,
    this.showMajorLines = true,
    this.majorLineInterval = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Adjust grid size based on zoom level for better visibility
    final adjustedGridSize = gridSize * scale;

    // Skip drawing if grid is too small or too large
    if (adjustedGridSize < 5 || adjustedGridSize > 500) return;

    final minorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.2)
      ..strokeWidth = 1.0 / scale;

    final majorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 2.0 / scale;

    // Calculate visible bounds
    const startX = 0.0;
    final endX = size.width;
    const startY = 0.0;
    final endY = size.height;

    // Draw vertical lines
    int lineCount = 0;
    for (double x = startX; x <= endX; x += gridSize) {
      final isMajorLine =
          showMajorLines && (lineCount % majorLineInterval == 0);
      final paint = isMajorLine ? majorPaint : minorPaint;
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      lineCount++;
    }

    // Draw horizontal lines
    lineCount = 0;
    for (double y = startY; y <= endY; y += gridSize) {
      final isMajorLine =
          showMajorLines && (lineCount % majorLineInterval == 0);
      final paint = isMajorLine ? majorPaint : minorPaint;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      lineCount++;
    }
  }

  @override
  bool shouldRepaint(GridOverlayPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.scale != scale ||
        oldDelegate.showMajorLines != showMajorLines ||
        oldDelegate.majorLineInterval != majorLineInterval;
  }
}

/// Ruler overlay painter
class RulerOverlayPainter extends CustomPainter {
  final double rulerThickness;
  final Color rulerColor;
  final Color textColor;
  final double scale;
  final Offset offset;
  final double tickSpacing;

  RulerOverlayPainter({
    this.rulerThickness = 30.0,
    this.rulerColor = const Color(0xFFE0E0E0),
    this.textColor = Colors.black87,
    required this.scale,
    required this.offset,
    this.tickSpacing = 50.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw horizontal ruler (top)
    _drawHorizontalRuler(canvas, size);

    // Draw vertical ruler (left)
    _drawVerticalRuler(canvas, size);

    // Draw corner square
    final cornerPaint = Paint()..color = rulerColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, rulerThickness, rulerThickness),
      cornerPaint,
    );
  }

  void _drawHorizontalRuler(Canvas canvas, Size size) {
    final paint = Paint()..color = rulerColor;
    canvas.drawRect(
      Rect.fromLTWH(
        rulerThickness,
        0,
        size.width - rulerThickness,
        rulerThickness,
      ),
      paint,
    );

    final tickPaint = Paint()
      ..color = textColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate visible range
    final startX = (-offset.dx / scale).floor();
    final endX = ((size.width - offset.dx) / scale).ceil();

    for (
      int i = (startX / tickSpacing).floor();
      i <= (endX / tickSpacing).ceil();
      i++
    ) {
      final x = i * tickSpacing;
      final screenX = x * scale + offset.dx + rulerThickness;

      if (screenX < rulerThickness || screenX > size.width) continue;

      // Draw tick
      final tickHeight = i % 5 == 0
          ? rulerThickness * 0.6
          : rulerThickness * 0.4;
      canvas.drawLine(
        Offset(screenX, rulerThickness),
        Offset(screenX, rulerThickness - tickHeight),
        tickPaint,
      );

      // Draw label for major ticks
      if (i % 5 == 0) {
        textPainter.text = TextSpan(
          text: '${x.toInt()}',
          style: TextStyle(color: textColor, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(screenX - textPainter.width / 2, 2));
      }
    }
  }

  void _drawVerticalRuler(Canvas canvas, Size size) {
    final paint = Paint()..color = rulerColor;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        rulerThickness,
        rulerThickness,
        size.height - rulerThickness,
      ),
      paint,
    );

    final tickPaint = Paint()
      ..color = textColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate visible range
    final startY = (-offset.dy / scale).floor();
    final endY = ((size.height - offset.dy) / scale).ceil();

    for (
      int i = (startY / tickSpacing).floor();
      i <= (endY / tickSpacing).ceil();
      i++
    ) {
      final y = i * tickSpacing;
      final screenY = y * scale + offset.dy + rulerThickness;

      if (screenY < rulerThickness || screenY > size.height) continue;

      // Draw tick
      final tickLength = i % 5 == 0
          ? rulerThickness * 0.6
          : rulerThickness * 0.4;
      canvas.drawLine(
        Offset(rulerThickness, screenY),
        Offset(rulerThickness - tickLength, screenY),
        tickPaint,
      );

      // Draw label for major ticks
      if (i % 5 == 0) {
        canvas.save();
        canvas.translate(rulerThickness / 2, screenY);
        canvas.rotate(-math.pi / 2);

        textPainter.text = TextSpan(
          text: '${y.toInt()}',
          style: TextStyle(color: textColor, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(RulerOverlayPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.rulerColor != rulerColor ||
        oldDelegate.textColor != textColor;
  }
}

/// Canvas boundary painter for finite canvas
class CanvasBoundaryPainter extends CustomPainter {
  final double canvasWidth;
  final double canvasHeight;
  final Color boundaryColor;
  final Color shadowColor;

  CanvasBoundaryPainter({
    required this.canvasWidth,
    required this.canvasHeight,
    this.boundaryColor = Colors.black,
    this.shadowColor = Colors.black54,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw canvas background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), bgPaint);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(
      Rect.fromLTWH(5, 5, canvasWidth, canvasHeight),
      shadowPaint,
    );

    // Draw boundary
    final borderPaint = Paint()
      ..color = boundaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CanvasBoundaryPainter oldDelegate) {
    return oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        oldDelegate.boundaryColor != boundaryColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
