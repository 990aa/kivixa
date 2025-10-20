import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';

/// Service for rendering layers with offscreen buffers
class LayerRenderingService {
  /// Render a layer to an offscreen image using PictureRecorder
  static Future<ui.Image> renderLayerToImage(
    DrawingLayer layer,
    Size canvasSize,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw all strokes in this layer
    for (final stroke in layer.strokes) {
      _drawStroke(canvas, stroke);
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );

    return image;
  }

  /// Draw a single stroke on the canvas
  static void _drawStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();

    // Build path from stroke points
    path.moveTo(
      stroke.points.first.position.dx,
      stroke.points.first.position.dy,
    );

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      final prevPoint = stroke.points[i - 1];

      // Adjust brush width based on pressure
      final paint = Paint()
        ..color = stroke.brushProperties.color
        ..strokeWidth = stroke.brushProperties.strokeWidth * point.pressure
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // Draw line segment with pressure-sensitive width
      canvas.drawLine(prevPoint.position, point.position, paint);
    }
  }

  /// Paint multiple layers with compositing
  static void paintLayers(Canvas canvas, List<DrawingLayer> layers, Size size) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Create paint with opacity and blend mode
      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, layer.opacity)
        ..blendMode = layer.blendMode;

      // If layer has cached image, use it
      if (layer.cachedImage != null) {
        // Save layer for compositing effects
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), paint);

        // Draw cached layer image
        canvas.drawImage(layer.cachedImage!, Offset.zero, Paint());

        // Restore and composite with previous layers
        canvas.restore();
      } else {
        // Draw strokes directly if no cache
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), paint);

        for (final stroke in layer.strokes) {
          _drawStroke(canvas, stroke);
        }

        canvas.restore();
      }
    }
  }

  /// Paint layers with viewport optimization (only visible region)
  static void paintLayersOptimized(
    Canvas canvas,
    List<DrawingLayer> layers,
    Size size,
    Rect viewport,
  ) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Skip layer if bounds don't intersect viewport
      if (layer.bounds != null && !layer.bounds!.overlaps(viewport)) {
        continue;
      }

      // Create paint with opacity and blend mode
      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, layer.opacity)
        ..blendMode = layer.blendMode;

      if (layer.cachedImage != null) {
        canvas.saveLayer(viewport, paint);
        canvas.drawImage(layer.cachedImage!, Offset.zero, Paint());
        canvas.restore();
      } else {
        canvas.saveLayer(viewport, paint);

        // Only draw strokes that intersect with viewport
        for (final stroke in layer.strokes) {
          final strokeBounds = stroke.getBounds();
          if (strokeBounds.overlaps(viewport)) {
            _drawStroke(canvas, stroke);
          }
        }

        canvas.restore();
      }
    }
  }

  /// Cache all layers by rendering them to images
  static Future<void> cacheAllLayers(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    for (final layer in layers) {
      if (layer.strokes.isNotEmpty && layer.cachedImage == null) {
        layer.cachedImage = await renderLayerToImage(layer, canvasSize);
      }
    }
  }

  /// Invalidate cache for specific layer
  static void invalidateLayerCache(DrawingLayer layer) {
    layer.invalidateCache();
  }

  /// Invalidate cache for all layers
  static void invalidateAllCaches(List<DrawingLayer> layers) {
    for (final layer in layers) {
      layer.invalidateCache();
    }
  }

  /// Update cache for a specific layer
  static Future<void> updateLayerCache(
    DrawingLayer layer,
    Size canvasSize,
  ) async {
    if (layer.strokes.isNotEmpty) {
      layer.cachedImage = await renderLayerToImage(layer, canvasSize);
    } else {
      layer.cachedImage = null;
    }
  }

  /// Merge multiple layers into a single image
  static Future<ui.Image> mergeLayers(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    paintLayers(canvas, layers, canvasSize);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );

    return image;
  }

  /// Get available blend modes (matching  apps like ibis Paint)
  static List<BlendMode> getAvailableBlendModes() {
    return [
      BlendMode.srcOver, // Normal
      BlendMode.multiply, // Multiply
      BlendMode.screen, // Screen
      BlendMode.overlay, // Overlay
      BlendMode.darken, // Darken
      BlendMode.lighten, // Lighten
      BlendMode.colorDodge, // Color Dodge
      BlendMode.colorBurn, // Color Burn
      BlendMode.hardLight, // Hard Light
      BlendMode.softLight, // Soft Light
      BlendMode.difference, // Difference
      BlendMode.exclusion, // Exclusion
      BlendMode.hue, // Hue
      BlendMode.saturation, // Saturation
      BlendMode.color, // Color
      BlendMode.luminosity, // Luminosity
      BlendMode.plus, // Add
      BlendMode.modulate, // Modulate
      BlendMode.dst, // Destination
      BlendMode.src, // Source
      BlendMode.dstOver, // Destination Over
      BlendMode.srcIn, // Source In
      BlendMode.dstIn, // Destination In
      BlendMode.srcOut, // Source Out
      BlendMode.dstOut, // Destination Out
      BlendMode.srcATop, // Source Atop
      BlendMode.dstATop, // Destination Atop
      BlendMode.xor, // XOR
    ];
  }

  /// Get blend mode name for UI display
  static String getBlendModeName(BlendMode mode) {
    switch (mode) {
      case BlendMode.srcOver:
        return 'Normal';
      case BlendMode.multiply:
        return 'Multiply';
      case BlendMode.screen:
        return 'Screen';
      case BlendMode.overlay:
        return 'Overlay';
      case BlendMode.darken:
        return 'Darken';
      case BlendMode.lighten:
        return 'Lighten';
      case BlendMode.colorDodge:
        return 'Color Dodge';
      case BlendMode.colorBurn:
        return 'Color Burn';
      case BlendMode.hardLight:
        return 'Hard Light';
      case BlendMode.softLight:
        return 'Soft Light';
      case BlendMode.difference:
        return 'Difference';
      case BlendMode.exclusion:
        return 'Exclusion';
      case BlendMode.hue:
        return 'Hue';
      case BlendMode.saturation:
        return 'Saturation';
      case BlendMode.color:
        return 'Color';
      case BlendMode.luminosity:
        return 'Luminosity';
      case BlendMode.plus:
        return 'Add';
      case BlendMode.modulate:
        return 'Modulate';
      default:
        return mode.toString().split('.').last;
    }
  }
}
