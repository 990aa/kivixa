import 'package:flutter/material.dart';
import 'package:kivixa/models/stroke_point.dart';

/// Implements true transparency-based eraser (not white painting)
///
/// CRITICAL: Must use saveLayer + BlendMode.clear to create real transparency.
/// Without saveLayer, BlendMode.clear draws black instead of transparent.
class TransparentEraser {
  /// Erase with transparency using BlendMode.clear
  ///
  /// This creates TRUE transparency, not white pixels.
  /// This is the correct way to implement an eraser for transparent exports.
  static void eraseWithTransparency(
    Canvas canvas,
    List<StrokePoint> eraserPath,
    double eraserSize,
    Size canvasSize,
  ) {
    if (eraserPath.isEmpty) return;

    // STEP 1: Save layer - this is CRITICAL for transparency
    // Without this, BlendMode.clear will draw black instead of transparent
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint(),
    );

    // STEP 2: Draw eraser path with BlendMode.clear
    for (int i = 1; i < eraserPath.length; i++) {
      final prev = eraserPath[i - 1];
      final curr = eraserPath[i];

      final eraserPaint = Paint()
        ..strokeWidth = eraserSize * curr.pressure
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode
            .clear // This creates transparency
        ..isAntiAlias = true;

      canvas.drawLine(prev.position, curr.position, eraserPaint);
    }

    // STEP 3: Restore - composites the layer with transparency
    canvas.restore();
  }

  /// Erase a circular area with transparency
  static void eraseCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Size canvasSize,
  ) {
    // Save layer for transparency
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint(),
    );

    // Draw circle with clear blend mode
    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, eraserPaint);

    canvas.restore();
  }

  /// Erase a rectangular area with transparency
  static void eraseRect(Canvas canvas, Rect rect, Size canvasSize) {
    // Save layer for transparency
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint(),
    );

    // Draw rectangle with clear blend mode
    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRect(rect, eraserPaint);

    canvas.restore();
  }

  /// Erase using a custom path with transparency
  static void erasePath(
    Canvas canvas,
    Path eraserPath,
    double strokeWidth,
    Size canvasSize,
  ) {
    // Save layer for transparency
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint(),
    );

    // Draw path with clear blend mode
    final eraserPaint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;

    canvas.drawPath(eraserPath, eraserPaint);

    canvas.restore();
  }

  /// Erase with soft edge (feathered eraser)
  static void eraseSoftEdge(
    Canvas canvas,
    List<StrokePoint> eraserPath,
    double eraserSize,
    Size canvasSize, {
    double softness = 0.5,
  }) {
    if (eraserPath.isEmpty) return;

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint(),
    );

    // Draw multiple passes with decreasing size for soft edge
    const passes = 5;
    for (int pass = 0; pass < passes; pass++) {
      final sizeFactor = 1.0 - (pass / passes) * softness;
      final alphaMask = 1.0 - (pass / passes);

      for (int i = 1; i < eraserPath.length; i++) {
        final prev = eraserPath[i - 1];
        final curr = eraserPath[i];

        final eraserPaint = Paint()
          ..strokeWidth = eraserSize * curr.pressure * sizeFactor
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear
          ..color = Colors.white.withValues(alpha: alphaMask)
          ..isAntiAlias = true;

        canvas.drawLine(prev.position, curr.position, eraserPaint);
      }
    }

    canvas.restore();
  }

  /// Check if eraser overlaps with a point (for stroke hit detection)
  static bool eraserOverlapsPoint(
    Offset eraserPosition,
    double eraserRadius,
    Offset point,
    double strokeWidth,
  ) {
    final distance = (eraserPosition - point).distance;
    return distance < (eraserRadius + strokeWidth / 2);
  }

  /// Check if eraser path intersects with a stroke
  static bool eraserIntersectsStroke(
    List<StrokePoint> eraserPath,
    double eraserRadius,
    List<StrokePoint> strokePoints,
    double strokeWidth,
  ) {
    for (final eraserPoint in eraserPath) {
      for (final strokePoint in strokePoints) {
        if (eraserOverlapsPoint(
          eraserPoint.position,
          eraserRadius,
          strokePoint.position,
          strokeWidth,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  /// Create an eraser stroke (for recording eraser actions)
  static Paint createEraserPaint(double size, {double pressure = 1.0}) {
    return Paint()
      ..strokeWidth = size * pressure
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;
  }
}

/// Extension for easier eraser usage on Canvas
extension CanvasEraserExtension on Canvas {
  /// Convenience method to erase with transparency
  void eraseTransparent(
    List<StrokePoint> eraserPath,
    double eraserSize,
    Size canvasSize,
  ) {
    TransparentEraser.eraseWithTransparency(
      this,
      eraserPath,
      eraserSize,
      canvasSize,
    );
  }

  /// Convenience method to erase a circle
  void eraseCircleTransparent(Offset center, double radius, Size canvasSize) {
    TransparentEraser.eraseCircle(this, center, radius, canvasSize);
  }

  /// Convenience method to erase a rectangle
  void eraseRectTransparent(Rect rect, Size canvasSize) {
    TransparentEraser.eraseRect(this, rect, canvasSize);
  }
}
