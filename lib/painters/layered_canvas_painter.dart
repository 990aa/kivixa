import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../services/layer_rendering_service.dart';

/// Custom painter for rendering multiple layers with optimization
class LayeredCanvasPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final Rect? viewport;
  final bool useOptimization;

  LayeredCanvasPainter({
    required this.layers,
    this.viewport,
    this.useOptimization = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // CRITICAL: Enforce canvas bounds at paint level
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.save();
    
    // Use optimized rendering if viewport is provided
    if (useOptimization && viewport != null) {
      LayerRenderingService.paintLayersOptimized(
        canvas,
        layers,
        size,
        viewport!,
      );
    } else {
      // Standard rendering
      LayerRenderingService.paintLayers(canvas, layers, size);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(LayeredCanvasPainter oldDelegate) {
    // Repaint if layers changed or viewport changed significantly
    if (oldDelegate.layers.length != layers.length) return true;

    // Check if any layer properties changed
    for (int i = 0; i < layers.length; i++) {
      final oldLayer = oldDelegate.layers[i];
      final newLayer = layers[i];

      if (oldLayer.id != newLayer.id ||
          oldLayer.isVisible != newLayer.isVisible ||
          oldLayer.opacity != newLayer.opacity ||
          oldLayer.blendMode != newLayer.blendMode ||
          oldLayer.strokes.length != newLayer.strokes.length ||
          oldLayer.modifiedAt != newLayer.modifiedAt) {
        return true;
      }
    }

    // Check if viewport changed significantly
    if (viewport != oldDelegate.viewport) {
      if (viewport == null || oldDelegate.viewport == null) return true;
      return !_viewportsAreClose(viewport!, oldDelegate.viewport!);
    }

    return false;
  }

  /// Check if two viewports are close enough to skip repainting
  bool _viewportsAreClose(Rect a, Rect b) {
    const threshold = 10.0; // pixels
    return (a.left - b.left).abs() < threshold &&
        (a.top - b.top).abs() < threshold &&
        (a.width - b.width).abs() < threshold &&
        (a.height - b.height).abs() < threshold;
  }
}

/// Painter for drawing a single layer (useful for layer preview)
class SingleLayerPainter extends CustomPainter {
  final DrawingLayer layer;
  final Size canvasSize;

  SingleLayerPainter({required this.layer, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (!layer.isVisible) return;

    // CRITICAL: Enforce canvas bounds at paint level
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, layer.opacity)
      ..blendMode = layer.blendMode;

    if (layer.cachedImage != null) {
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      canvas.drawImage(layer.cachedImage!, Offset.zero, Paint());
      canvas.restore();
    } else {
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke);
      }

      canvas.restore();
    }
  }

  void _drawStroke(Canvas canvas, stroke) {
    if (stroke.points.isEmpty) return;

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      final prevPoint = stroke.points[i - 1];

      final paint = Paint()
        ..color = stroke.brushProperties.color
        ..strokeWidth = stroke.brushProperties.strokeWidth * point.pressure
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(prevPoint.position, point.position, paint);
    }
  }

  @override
  bool shouldRepaint(SingleLayerPainter oldDelegate) {
    return oldDelegate.layer.id != layer.id ||
        oldDelegate.layer.modifiedAt != layer.modifiedAt ||
        oldDelegate.layer.isVisible != layer.isVisible ||
        oldDelegate.layer.opacity != layer.opacity ||
        oldDelegate.layer.blendMode != layer.blendMode;
  }
}
