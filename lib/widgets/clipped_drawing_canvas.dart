import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/vector_stroke.dart';

/// Canvas widget with strict boundary enforcement
///
/// Implements ClipRect to prevent any strokes from bleeding outside
/// the defined canvas bounds, regardless of brush size or stroke position.
class ClippedDrawingCanvas extends StatelessWidget {
  final Size canvasSize;
  final List<DrawingLayer> layers;
  final VectorStroke? currentVectorStroke;
  final LayerStroke? currentLayerStroke;
  final Matrix4 transform;
  final Color backgroundColor;
  final bool showShadow;

  const ClippedDrawingCanvas({
    super.key,
    required this.canvasSize,
    required this.layers,
    this.currentVectorStroke,
    this.currentLayerStroke,
    required this.transform,
    this.backgroundColor = Colors.white,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: transform,
      child: Container(
        width: canvasSize.width,
        height: canvasSize.height,
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        // CRITICAL: ClipRect prevents any drawing outside bounds
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: CustomPaint(
            painter: ClippedLayerPainter(
              layers: layers,
              currentVectorStroke: currentVectorStroke,
              currentLayerStroke: currentLayerStroke,
            ),
            size: canvasSize,
          ),
        ),
      ),
    );
  }
}

/// Custom painter with hardware-level clipping enforcement
///
/// Uses canvas.clipRect() to ensure no pixels can be drawn outside
/// the canvas bounds at the GPU level.
class ClippedLayerPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final VectorStroke? currentVectorStroke;
  final LayerStroke? currentLayerStroke;

  ClippedLayerPainter({
    required this.layers,
    this.currentVectorStroke,
    this.currentLayerStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // CRITICAL: Enforce canvas bounds at paint level
    // This provides hardware-level clipping that's impossible to bypass
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Save canvas state before rendering
    canvas.save();

    // Render all layers
    _renderAllLayers(canvas, size);

    // Render current stroke being drawn (if any)
    if (currentLayerStroke != null) {
      _renderLayerStroke(canvas, currentLayerStroke!);
    } else if (currentVectorStroke != null) {
      _renderVectorStroke(canvas, currentVectorStroke!);
    }

    // Restore canvas state
    canvas.restore();
  }

  /// Render all visible layers
  void _renderAllLayers(Canvas canvas, Size size) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Save canvas state for layer
      canvas.save();

      // Apply layer opacity if needed
      if (layer.opacity < 1.0) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = Colors.white.withValues(alpha: layer.opacity),
        );
      }

      // Render all strokes in the layer
      for (final stroke in layer.strokes) {
        _renderLayerStroke(canvas, stroke);
      }

      canvas.restore();
    }
  }

  /// Render a single LayerStroke
  void _renderLayerStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    // Create smooth path through all points
    if (stroke.points.length == 1) {
      // Single point - draw a circle
      canvas.drawCircle(
        stroke.points[0].position,
        stroke.brushProperties.strokeWidth / 2,
        stroke.brushProperties,
      );
      return;
    }

    // Use quadratic bezier for smooth curves
    for (int i = 1; i < stroke.points.length; i++) {
      final p1 = stroke.points[i].position;

      if (i == stroke.points.length - 1) {
        // Last segment - line to endpoint
        path.lineTo(p1.dx, p1.dy);
      } else {
        // Intermediate segment - quadratic curve
        final p2 = stroke.points[i + 1].position;
        final controlPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, controlPoint.dx, controlPoint.dy);
      }
    }

    // Draw the path with the stroke's paint properties
    canvas.drawPath(path, stroke.brushProperties);
  }

  /// Render a single VectorStroke
  void _renderVectorStroke(Canvas canvas, VectorStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.brushSettings.color
      ..strokeWidth = stroke.brushSettings.size
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    if (stroke.points.length == 1) {
      // Single point - draw a circle
      canvas.drawCircle(
        stroke.points[0].position,
        stroke.brushSettings.size / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Create smooth vector path
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].position.dx, stroke.points[i].position.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ClippedLayerPainter oldDelegate) {
    // Repaint if layers changed or current stroke changed
    return layers != oldDelegate.layers ||
        currentVectorStroke != oldDelegate.currentVectorStroke ||
        currentLayerStroke != oldDelegate.currentLayerStroke;
  }
}

/// Simple clipped canvas for single layer rendering
///
/// Useful for simpler use cases where you don't need multiple layers.
class SimpleClippedCanvas extends StatelessWidget {
  final Size canvasSize;
  final List<LayerStroke> strokes;
  final LayerStroke? currentStroke;
  final Matrix4 transform;
  final Color backgroundColor;

  const SimpleClippedCanvas({
    super.key,
    required this.canvasSize,
    required this.strokes,
    this.currentStroke,
    required this.transform,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: transform,
      child: Container(
        width: canvasSize.width,
        height: canvasSize.height,
        color: backgroundColor,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: CustomPaint(
            painter: SimpleStrokePainter(
              strokes: strokes,
              currentStroke: currentStroke,
            ),
            size: canvasSize,
          ),
        ),
      ),
    );
  }
}

/// Simple painter for single-layer rendering with clipping
class SimpleStrokePainter extends CustomPainter {
  final List<LayerStroke> strokes;
  final LayerStroke? currentStroke;

  SimpleStrokePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Apply hardware-level clipping
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Render all completed strokes
    for (final stroke in strokes) {
      _renderStroke(canvas, stroke);
    }

    // Render current stroke
    if (currentStroke != null) {
      _renderStroke(canvas, currentStroke!);
    }
  }

  void _renderStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].position.dx, stroke.points[i].position.dy);
    }

    canvas.drawPath(path, stroke.brushProperties);
  }

  @override
  bool shouldRepaint(covariant SimpleStrokePainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentStroke != oldDelegate.currentStroke;
  }
}
