import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';

/// Renders layers to images with proper transparency support
///
/// CRITICAL: Canvas background (white/gray) is a visual aid only
/// and must NEVER be exported with the artwork.
class LayerRenderer {
  /// Render a single layer to an image with transparent background
  ///
  /// This is the key method for exporting artwork without background.
  /// The canvas background is purely for visual aid during editing.
  static Future<ui.Image> renderLayerToImage(
    DrawingLayer layer,
    Size canvasSize,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // CRITICAL: DO NOT draw background color - leave transparent!
    // This is the key difference from display rendering
    // The user's artwork should be on a transparent background

    // Draw all strokes with proper alpha handling
    for (final stroke in layer.strokes) {
      _renderLayerStroke(canvas, stroke);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );

    return image;
  }

  /// Render multiple layers to a single image with transparency
  ///
  /// Respects layer visibility, opacity, and blend modes.
  static Future<ui.Image> renderLayersToImage(
    List<DrawingLayer> layers,
    Size canvasSize, {
    bool includeInvisibleLayers = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // DO NOT draw background - keep transparent

    for (final layer in layers) {
      if (!layer.isVisible && !includeInvisibleLayers) continue;

      // Save layer state for opacity and blend mode
      if (layer.opacity < 1.0 || layer.blendMode != BlendMode.srcOver) {
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: layer.opacity)
          ..blendMode = layer.blendMode;

        canvas.saveLayer(
          Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
          paint,
        );
      }

      // Render all strokes in the layer
      for (final stroke in layer.strokes) {
        _renderLayerStroke(canvas, stroke);
      }

      if (layer.opacity < 1.0 || layer.blendMode != BlendMode.srcOver) {
        canvas.restore();
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );

    return image;
  }

  /// Render a LayerStroke with proper alpha handling
  static void _renderLayerStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      // Single point - draw a circle
      canvas.drawCircle(
        stroke.points[0].position,
        stroke.brushProperties.strokeWidth / 2,
        stroke.brushProperties,
      );
      return;
    }

    // Draw line segments with pressure variation
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      // Create paint with current pressure
      final paint = Paint()
        ..color = stroke.brushProperties.color
        ..strokeWidth = stroke.brushProperties.strokeWidth * curr.pressure
        ..strokeCap = stroke.brushProperties.strokeCap
        ..strokeJoin = stroke.brushProperties.strokeJoin
        ..blendMode = stroke.brushProperties.blendMode
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  /// Export layer as PNG bytes with transparency
  static Future<List<int>> exportLayerAsPNG(
    DrawingLayer layer,
    Size canvasSize,
  ) async {
    final image = await renderLayerToImage(layer, canvasSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to encode image as PNG');
    }

    return byteData.buffer.asUint8List();
  }

  /// Export multiple layers as PNG bytes with transparency
  static Future<List<int>> exportLayersAsPNG(
    List<DrawingLayer> layers,
    Size canvasSize, {
    bool includeInvisibleLayers = false,
  }) async {
    final image = await renderLayersToImage(
      layers,
      canvasSize,
      includeInvisibleLayers: includeInvisibleLayers,
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to encode image as PNG');
    }

    return byteData.buffer.asUint8List();
  }

  /// Render layer to image at higher resolution for export
  static Future<ui.Image> renderLayerAtDPI(
    DrawingLayer layer,
    Size canvasSize,
    double targetDPI, {
    double baseDPI = 72.0,
  }) async {
    final scale = targetDPI / baseDPI;
    final scaledSize = Size(
      canvasSize.width * scale,
      canvasSize.height * scale,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale canvas for higher resolution
    canvas.scale(scale);

    // DO NOT draw background color

    // Render all strokes
    for (final stroke in layer.strokes) {
      _renderLayerStroke(canvas, stroke);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      scaledSize.width.toInt(),
      scaledSize.height.toInt(),
    );

    return image;
  }

  /// Create a preview thumbnail of a layer
  static Future<ui.Image> createLayerThumbnail(
    DrawingLayer layer,
    Size canvasSize,
    Size thumbnailSize,
  ) async {
    // Calculate scale to fit
    final scaleX = thumbnailSize.width / canvasSize.width;
    final scaleY = thumbnailSize.height / canvasSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale down
    canvas.scale(scale);

    // Render strokes
    for (final stroke in layer.strokes) {
      _renderLayerStroke(canvas, stroke);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (canvasSize.width * scale).toInt(),
      (canvasSize.height * scale).toInt(),
    );

    return image;
  }
}
