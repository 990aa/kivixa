import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/vector_stroke.dart';
import '../models/layer_stroke.dart';

/// Export format options
enum ExportFormat {
  png,
  jpg,
  rawRgba,
}

/// Export quality levels
enum ExportQuality {
  screen, // 72 DPI
  highQuality, // 150 DPI
  print, // 300 DPI
  custom, // Custom DPI
}

/// High-resolution export system for creating print-quality images
class HighResolutionExporter {
  /// Standard screen DPI
  static const double screenDPI = 72.0;

  /// Print quality DPI
  static const double printDPI = 300.0;

  /// High quality screen DPI
  static const double highQualityDPI = 150.0;

  /// Get DPI for quality level
  static double getDPIForQuality(ExportQuality quality, {double? customDPI}) {
    switch (quality) {
      case ExportQuality.screen:
        return screenDPI;
      case ExportQuality.highQuality:
        return highQualityDPI;
      case ExportQuality.print:
        return printDPI;
      case ExportQuality.custom:
        return customDPI ?? printDPI;
    }
  }

  /// Export at specified DPI with format selection
  Future<Uint8List> exportAtDPI({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    required double targetDPI,
    ExportFormat format = ExportFormat.png,
    Color backgroundColor = Colors.white,
    int jpegQuality = 95,
  }) async {
    // Calculate scale factor
    final scaleFactor = targetDPI / screenDPI;

    // Calculate output dimensions
    final outputWidth = (canvasSize.width * scaleFactor).toInt();
    final outputHeight = (canvasSize.height * scaleFactor).toInt();

    // Create picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = backgroundColor,
    );

    // Scale canvas to target resolution
    canvas.scale(scaleFactor);

    // Render all layers at high resolution
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Apply layer opacity and blend mode
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: layer.opacity)
        ..blendMode = layer.blendMode;

      canvas.saveLayer(null, paint);

      // Render each stroke
      for (final stroke in layer.strokes) {
        _renderStrokeHighQuality(canvas, stroke, scaleFactor);
      }

      canvas.restore();
    }

    // Convert to image at high resolution
    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);

    // Export based on format
    final byteData = await _exportImage(image, format, jpegQuality);

    return byteData;
  }

  /// Export with quality preset
  Future<Uint8List> exportWithQuality({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    required ExportQuality quality,
    double? customDPI,
    ExportFormat format = ExportFormat.png,
    Color backgroundColor = Colors.white,
  }) async {
    final dpi = getDPIForQuality(quality, customDPI: customDPI);
    return exportAtDPI(
      layers: layers,
      canvasSize: canvasSize,
      targetDPI: dpi,
      format: format,
      backgroundColor: backgroundColor,
    );
  }

  /// Export vector strokes at high resolution
  Future<Uint8List> exportVectorStrokesAtDPI({
    required List<VectorStroke> strokes,
    required Size canvasSize,
    required double targetDPI,
    ExportFormat format = ExportFormat.png,
    Color backgroundColor = Colors.white,
  }) async {
    // Calculate scale factor
    final scaleFactor = targetDPI / screenDPI;

    // Calculate output dimensions
    final outputWidth = (canvasSize.width * scaleFactor).toInt();
    final outputHeight = (canvasSize.height * scaleFactor).toInt();

    // Create picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = backgroundColor,
    );

    // Scale canvas to target resolution
    canvas.scale(scaleFactor);

    // Render all vector strokes
    for (final stroke in strokes) {
      _renderVectorStrokeHighQuality(canvas, stroke);
    }

    // Convert to image at high resolution
    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);

    // Export based on format
    final byteData = await _exportImage(image, format, 95);

    return byteData;
  }

  /// Render regular stroke with maximum quality
  void _renderStrokeHighQuality(
    Canvas canvas,
    LayerStroke stroke,
    double scaleFactor,
  ) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      // Single point - render as circle
      final point = stroke.points.first;
      final paint = Paint()
        ..color = stroke.brushProperties.color.withValues(
          alpha: stroke.brushProperties.opacity * point.pressure,
        )
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawCircle(
        point.position,
        stroke.brushProperties.strokeWidth * point.pressure / 2,
        paint,
      );
      return;
    }

    // Render with full anti-aliasing and maximum quality
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      final avgPressure = (prev.pressure + curr.pressure) / 2;

      final paint = Paint()
        ..color = stroke.brushProperties.color
        ..strokeWidth = stroke.brushProperties.strokeWidth * avgPressure
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high; // Maximum quality

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  /// Render vector stroke with maximum quality
  void _renderVectorStrokeHighQuality(Canvas canvas, VectorStroke stroke) {
    if (stroke.points.isEmpty) return;

    final widths = stroke.getWidthsAlongPath();
    final colors = stroke.getColorsAlongPath();

    if (stroke.points.length == 1) {
      // Single point - render as circle
      final paint = Paint()
        ..color = colors.first
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawCircle(
        stroke.points.first.position,
        widths.first / 2,
        paint,
      );
      return;
    }

    // Render with full anti-aliasing and maximum quality
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      final avgWidth = (widths[i - 1] + widths[i]) / 2;
      final avgColor = Color.lerp(colors[i - 1], colors[i], 0.5) ?? colors[i];

      final paint = Paint()
        ..color = avgColor
        ..strokeWidth = avgWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high; // Maximum quality

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  /// Export image based on format
  Future<Uint8List> _exportImage(
    ui.Image image,
    ExportFormat format,
    int jpegQuality,
  ) async {
    ui.ImageByteFormat byteFormat;

    switch (format) {
      case ExportFormat.png:
        byteFormat = ui.ImageByteFormat.png;
        break;
      case ExportFormat.jpg:
        // Note: Flutter doesn't directly support JPEG quality parameter
        // This uses PNG and would need additional processing for true JPEG
        byteFormat = ui.ImageByteFormat.png;
        break;
      case ExportFormat.rawRgba:
        byteFormat = ui.ImageByteFormat.rawRgba;
        break;
    }

    final byteData = await image.toByteData(format: byteFormat);
    return byteData!.buffer.asUint8List();
  }

  /// Calculate export dimensions for target DPI
  Size calculateExportDimensions(Size canvasSize, double targetDPI) {
    final scaleFactor = targetDPI / screenDPI;
    return Size(
      canvasSize.width * scaleFactor,
      canvasSize.height * scaleFactor,
    );
  }

  /// Calculate file size estimate in MB
  double estimateFileSizeMB(Size canvasSize, double targetDPI,
      {ExportFormat format = ExportFormat.png}) {
    final dimensions = calculateExportDimensions(canvasSize, targetDPI);
    final pixels = dimensions.width * dimensions.height;

    // Rough estimates
    double bytesPerPixel;
    switch (format) {
      case ExportFormat.png:
        bytesPerPixel = 4.0; // RGBA, but PNG compresses
        return (pixels * bytesPerPixel * 0.3) / (1024 * 1024); // 30% compression
      case ExportFormat.jpg:
        bytesPerPixel = 3.0; // RGB
        return (pixels * bytesPerPixel * 0.1) / (1024 * 1024); // 10% compression
      case ExportFormat.rawRgba:
        bytesPerPixel = 4.0; // RGBA, no compression
        return (pixels * bytesPerPixel) / (1024 * 1024);
    }
  }

  /// Get recommended DPI for canvas size (to avoid excessive file sizes)
  double getRecommendedMaxDPI(Size canvasSize) {
    // Limit to ~100 megapixels
    const maxPixels = 100000000;
    final currentPixels = canvasSize.width * canvasSize.height;

    if (currentPixels == 0) return printDPI;

    final maxScaleFactor = maxPixels / currentPixels;
    final maxDPI = screenDPI * maxScaleFactor;

    return maxDPI.clamp(screenDPI, printDPI * 2); // Max 600 DPI
  }

  /// Export progress callback
  typedef ExportProgressCallback = void Function(double progress, String status);

  /// Export with progress tracking (for large exports)
  Future<Uint8List> exportWithProgress({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    required double targetDPI,
    ExportFormat format = ExportFormat.png,
    Color backgroundColor = Colors.white,
    ExportProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.0, 'Preparing canvas...');

    // Calculate scale factor
    final scaleFactor = targetDPI / screenDPI;
    final outputWidth = (canvasSize.width * scaleFactor).toInt();
    final outputHeight = (canvasSize.height * scaleFactor).toInt();

    onProgress?.call(0.1, 'Creating high-resolution canvas...');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = backgroundColor,
    );

    canvas.scale(scaleFactor);

    onProgress?.call(0.2, 'Rendering layers...');

    // Render layers with progress
    for (int layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      final layer = layers[layerIndex];
      if (!layer.isVisible) continue;

      final layerProgress =
          0.2 + (0.6 * (layerIndex / layers.length.toDouble()));
      onProgress?.call(
        layerProgress,
        'Rendering layer ${layerIndex + 1}/${layers.length}...',
      );

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: layer.opacity)
        ..blendMode = layer.blendMode;

      canvas.saveLayer(null, paint);

      for (final stroke in layer.strokes) {
        _renderStrokeHighQuality(canvas, stroke, scaleFactor);
      }

      canvas.restore();
    }

    onProgress?.call(0.8, 'Converting to image...');

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);

    onProgress?.call(0.9, 'Encoding image...');

    final byteData = await _exportImage(image, format, 95);

    onProgress?.call(1.0, 'Export complete!');

    return byteData;
  }
}
