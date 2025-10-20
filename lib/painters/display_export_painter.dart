import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';

/// Painter for displaying canvas with visual background
///
/// CRITICAL: This is for DISPLAY ONLY. The background is a visual aid
/// and should NEVER be included in exports.
class CanvasDisplayPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final Color backgroundColor;
  final bool showBackground;

  CanvasDisplayPainter({
    required this.layers,
    this.backgroundColor = Colors.white,
    this.showBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // FOR DISPLAY ONLY: Show background
    if (showBackground) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );
    }

    // Render layers on top
    _renderLayers(canvas, layers, size);
  }

  /// Render all visible layers with proper compositing
  void _renderLayers(Canvas canvas, List<DrawingLayer> layers, Size size) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      final layerPaint = Paint()
        ..color = Colors.white.withValues(alpha: layer.opacity)
        ..blendMode = layer.blendMode;

      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        layerPaint,
      );

      for (final stroke in layer.strokes) {
        _renderStroke(canvas, stroke);
      }

      canvas.restore();
    }
  }

  /// Render a single stroke
  void _renderStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      // Single point - draw circle
      canvas.drawCircle(
        stroke.points[0].position,
        stroke.brushProperties.strokeWidth / 2,
        stroke.brushProperties,
      );
      return;
    }

    // Multiple points - draw lines
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

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

  @override
  bool shouldRepaint(covariant CanvasDisplayPainter oldDelegate) {
    return oldDelegate.layers != layers ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showBackground != showBackground;
  }
}

/// Painter for exporting canvas WITHOUT background
///
/// CRITICAL: NO background is drawn during export.
/// Canvas remains transparent, preserving alpha channel.
class CanvasExportPainter {
  /// Render layers for export with transparent background
  static Future<ui.Image> renderForExport(
    List<DrawingLayer> layers,
    Size size, {
    double scaleFactor = 1.0,
  }) async {
    final outputWidth = (size.width * scaleFactor).toInt();
    final outputHeight = (size.height * scaleFactor).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale for high-resolution export
    if (scaleFactor != 1.0) {
      canvas.scale(scaleFactor);
    }

    // CRITICAL: NO background color drawn here!
    // Canvas is transparent by default

    _renderLayers(canvas, layers, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);

    picture.dispose();
    return image;
  }

  /// Synchronous version (for smaller images)
  static ui.Image renderForExportSync(
    List<DrawingLayer> layers,
    Size size, {
    double scaleFactor = 1.0,
  }) {
    final outputWidth = (size.width * scaleFactor).toInt();
    final outputHeight = (size.height * scaleFactor).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (scaleFactor != 1.0) {
      canvas.scale(scaleFactor);
    }

    // NO background color
    _renderLayers(canvas, layers, size);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(outputWidth, outputHeight);

    picture.dispose();
    return image;
  }

  /// Render all visible layers with proper compositing
  static void _renderLayers(
    Canvas canvas,
    List<DrawingLayer> layers,
    Size size,
  ) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      final layerPaint = Paint()
        ..color = Colors.white.withValues(alpha: layer.opacity)
        ..blendMode = layer.blendMode;

      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        layerPaint,
      );

      for (final stroke in layer.strokes) {
        _renderStroke(canvas, stroke);
      }

      canvas.restore();
    }
  }

  /// Render a single stroke
  static void _renderStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points[0].position,
        stroke.brushProperties.strokeWidth / 2,
        stroke.brushProperties,
      );
      return;
    }

    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      final paint = Paint()
        ..color = stroke.brushProperties.color
        ..strokeWidth = stroke.brushProperties.strokeWidth * curr.pressure
        ..strokeCap = stroke.brushProperties.strokeCap
        ..strokeJoin = stroke.brushProperties.strokeJoin
        ..blendMode = stroke.brushProperties.blendMode
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  /// Render with eraser strokes applied
  static Future<ui.Image> renderWithErasers(
    List<DrawingLayer> layers,
    Size size, {
    double scaleFactor = 1.0,
  }) async {
    final outputWidth = (size.width * scaleFactor).toInt();
    final outputHeight = (size.height * scaleFactor).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (scaleFactor != 1.0) {
      canvas.scale(scaleFactor);
    }

    // NO background - transparent canvas
    // Render layers with eraser strokes using BlendMode.clear
    _renderLayersWithErasers(canvas, layers, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);

    picture.dispose();
    return image;
  }

  /// Render layers with eraser strokes applied using BlendMode.clear
  static void _renderLayersWithErasers(
    Canvas canvas,
    List<DrawingLayer> layers,
    Size size,
  ) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      final layerPaint = Paint()
        ..color = Colors.white.withValues(alpha: layer.opacity)
        ..blendMode = layer.blendMode;

      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        layerPaint,
      );

      for (final stroke in layer.strokes) {
        // Check if this is an eraser stroke (BlendMode.clear)
        if (stroke.brushProperties.blendMode == BlendMode.clear) {
          _renderEraserStroke(canvas, stroke);
        } else {
          _renderStroke(canvas, stroke);
        }
      }

      canvas.restore();
    }
  }

  /// Render eraser stroke with BlendMode.clear
  static void _renderEraserStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (stroke.points.length == 1) {
      // Single point - erase circle
      canvas.drawCircle(
        stroke.points[0].position,
        stroke.brushProperties.strokeWidth / 2,
        eraserPaint..style = PaintingStyle.fill,
      );
      return;
    }

    // Multiple points - erase along path
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      eraserPaint.strokeWidth =
          stroke.brushProperties.strokeWidth * curr.pressure;

      canvas.drawLine(prev.position, curr.position, eraserPaint);
    }
  }
}

/// Widget for displaying canvas with visual aids
class CanvasDisplayWidget extends StatelessWidget {
  final List<DrawingLayer> layers;
  final Size canvasSize;
  final Color backgroundColor;
  final bool showBackground;

  const CanvasDisplayWidget({
    super.key,
    required this.layers,
    required this.canvasSize,
    this.backgroundColor = Colors.white,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CanvasDisplayPainter(
        layers: layers,
        backgroundColor: backgroundColor,
        showBackground: showBackground,
      ),
      size: canvasSize,
    );
  }
}
