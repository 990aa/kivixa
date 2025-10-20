import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/vector_stroke.dart';

/// Resolution-aware canvas painter that regenerates strokes at current zoom level
class ResolutionAwareCanvasPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final double currentZoom;
  final Offset viewportOffset;
  final List<VectorStroke>? vectorStrokes; // Optional vector strokes
  final bool useVectorRendering;

  ResolutionAwareCanvasPainter({
    required this.layers,
    this.currentZoom = 1.0,
    this.viewportOffset = Offset.zero,
    this.vectorStrokes,
    this.useVectorRendering = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate effective resolution based on zoom
    final effectiveScale = currentZoom;

    canvas.save();
    canvas.translate(viewportOffset.dx, viewportOffset.dy);
    canvas.scale(effectiveScale);

    // Render vector strokes if available
    if (useVectorRendering && vectorStrokes != null) {
      for (final stroke in vectorStrokes!) {
        _renderVectorStroke(canvas, stroke, effectiveScale);
      }
    }

    // Render layer-based strokes
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Apply layer opacity and blend mode
      canvas.saveLayer(
        layer.bounds,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity),
      );

      for (final stroke in layer.strokes) {
        _renderStrokeAtResolution(canvas, stroke, effectiveScale);
      }

      canvas.restore();
    }

    canvas.restore();
  }

  /// Render vector stroke at current resolution
  void _renderVectorStroke(Canvas canvas, VectorStroke stroke, double scale) {
    if (stroke.points.isEmpty) return;

    final points = stroke.points;
    final widths = stroke.getWidthsAlongPath();
    final colors = stroke.getColorsAlongPath();

    if (points.length == 1) {
      // Single point - draw circle
      final scaledWidth = widths[0] / scale;
      final paint = Paint()
        ..color = colors[0]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[0].position, scaledWidth / 2, paint);
      return;
    }

    // Draw stroke segments with varying width and opacity
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      // Calculate average width and color for this segment
      final avgWidth = (widths[i] + widths[i + 1]) / 2;
      final scaledWidth = avgWidth / scale;

      // Interpolate color
      final avgColor = Color.lerp(colors[i], colors[i + 1], 0.5) ?? colors[i];

      final paint = Paint()
        ..color = avgColor
        ..strokeWidth = scaledWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(start.position, end.position, paint);
    }
  }

  /// Render regular stroke at resolution
  void _renderStrokeAtResolution(
    Canvas canvas,
    LayerStroke stroke,
    double scale,
  ) {
    final points = stroke.points;
    if (points.isEmpty) return;

    if (points.length == 1) {
      // Single point
      final paint = Paint()
        ..color = stroke.brushProperties.color
        ..style = PaintingStyle.fill;

      final scaledWidth = stroke.brushProperties.strokeWidth / scale;
      canvas.drawCircle(points[0].position, scaledWidth / 2, paint);
      return;
    }

    // Draw stroke path
    for (int i = 0; i < points.length - 1; i++) {
      final prev = points[i];
      final curr = points[i + 1];

      // Adjust brush width based on zoom for consistent appearance
      final baseWidth = stroke.brushProperties.strokeWidth;
      final scaledWidth = baseWidth / scale;

      final paint = Paint()
        ..color = stroke.brushProperties.color.withValues(alpha: curr.pressure)
        ..strokeWidth = scaledWidth * curr.pressure
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias =
            true // Critical for smooth rendering
        ..filterQuality = FilterQuality.high;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ResolutionAwareCanvasPainter oldDelegate) {
    return currentZoom != oldDelegate.currentZoom ||
        viewportOffset != oldDelegate.viewportOffset ||
        layers != oldDelegate.layers ||
        vectorStrokes != oldDelegate.vectorStrokes ||
        useVectorRendering != oldDelegate.useVectorRendering;
  }
}

/// Canvas painter specifically optimized for infinite zoom
class InfiniteZoomCanvasPainter extends CustomPainter {
  final List<VectorStroke> strokes;
  final double zoomLevel;
  final Offset panOffset;
  final Size canvasSize;

  InfiniteZoomCanvasPainter({
    required this.strokes,
    required this.zoomLevel,
    required this.panOffset,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate visible viewport in canvas space
    final viewport = Rect.fromLTWH(
      -panOffset.dx / zoomLevel,
      -panOffset.dy / zoomLevel,
      size.width / zoomLevel,
      size.height / zoomLevel,
    );

    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    // Only render visible strokes for performance
    for (final stroke in strokes) {
      final bounds = stroke.getBounds();
      if (!viewport.overlaps(bounds)) continue;

      _renderStrokeHighQuality(canvas, stroke, zoomLevel);
    }

    canvas.restore();
  }

  /// Render stroke with highest quality at any zoom level
  void _renderStrokeHighQuality(
    Canvas canvas,
    VectorStroke stroke,
    double zoom,
  ) {
    if (stroke.points.isEmpty) return;

    final points = stroke.points;
    final widths = stroke.getWidthsAlongPath();

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      // Dynamic width based on zoom and pressure
      final avgWidth = (widths[i] + widths[i + 1]) / 2;
      final renderWidth = avgWidth / zoom;

      // Dynamic opacity based on pressure
      final avgPressure = (start.pressure + end.pressure) / 2;
      final opacity = stroke.brushSettings.opacity * avgPressure;

      final paint = Paint()
        ..color = stroke.brushSettings.color.withValues(alpha: opacity)
        ..strokeWidth = renderWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawLine(start.position, end.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InfiniteZoomCanvasPainter oldDelegate) {
    return zoomLevel != oldDelegate.zoomLevel ||
        panOffset != oldDelegate.panOffset ||
        strokes != oldDelegate.strokes;
  }
}
