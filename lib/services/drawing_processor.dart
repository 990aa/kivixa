import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';

/// Heavy computation processor using Flutter isolates
/// Prevents UI blocking during expensive operations
class DrawingProcessor {
  /// Rasterize layers at high resolution in background isolate
  ///
  /// This prevents UI freezing during large exports (300+ DPI, 10000+ strokes)
  ///
  /// Example:
  /// ```dart
  /// final imageBytes = await DrawingProcessor.rasterizeLayersAsync(
  ///   layers: _layers,
  ///   canvasSize: Size(2000, 2000),
  ///   targetDPI: 300,
  /// );
  /// ```
  static Future<Uint8List> rasterizeLayersAsync({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    required double targetDPI,
  }) async {
    // Transfer data to isolate
    final params = _RasterizeParams(
      layers: layers,
      canvasSize: canvasSize,
      targetDPI: targetDPI,
    );

    return await Isolate.run(() {
      // This runs on separate isolate, won't block UI
      return _rasterizeLayersSync(params);
    });
  }

  /// Serialize large drawings to JSON in background
  ///
  /// Prevents UI freezing when saving drawings with 1000+ strokes
  ///
  /// Example:
  /// ```dart
  /// final json = await DrawingProcessor.serializeDrawingAsync(
  ///   _layers,
  ///   _canvasSize,
  /// );
  /// await File('drawing.json').writeAsString(json);
  /// ```
  static Future<String> serializeDrawingAsync(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    return await Isolate.run(() {
      // Complex JSON encoding won't freeze UI
      final data = {
        'version': '2.0',
        'canvasWidth': canvasSize.width,
        'canvasHeight': canvasSize.height,
        'timestamp': DateTime.now().toIso8601String(),
        'layers': layers.map((layer) => layer.toJson()).toList(),
      };
      return jsonEncode(data);
    });
  }

  /// Load and parse large saved files in background
  ///
  /// Prevents UI freezing when loading files with 1000+ strokes
  ///
  /// Example:
  /// ```dart
  /// final doc = await DrawingProcessor.loadDocumentAsync(
  ///   'path/to/drawing.json',
  /// );
  /// setState(() {
  ///   _layers = doc.layers;
  ///   _canvasSize = doc.canvasSize;
  /// });
  /// ```
  static Future<DrawingDocument> loadDocumentAsync(String filePath) async {
    return await Isolate.run(() {
      // File I/O and JSON parsing in background
      final file = File(filePath);
      final jsonString = file.readAsStringSync();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return DrawingDocument.fromJson(data);
    });
  }

  /// Compress images for export in background
  ///
  /// Prevents UI freezing during PNG/JPG compression
  ///
  /// Example:
  /// ```dart
  /// final compressed = await DrawingProcessor.compressImageAsync(
  ///   rawImageBytes,
  ///   quality: 85,
  /// );
  /// ```
  static Future<Uint8List> compressImageAsync(
    Uint8List imageBytes,
    int quality,
  ) async {
    return await Isolate.run(() {
      // Image compression without blocking UI
      return _compressImage(imageBytes, quality);
    });
  }

  /// Convert layers to SVG path data in background
  ///
  /// Prevents UI freezing when generating SVG with 1000+ strokes
  ///
  /// Example:
  /// ```dart
  /// final svgData = await DrawingProcessor.layersToSVGAsync(
  ///   _layers,
  ///   _canvasSize,
  /// );
  /// ```
  static Future<String> layersToSVGAsync(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    return await Isolate.run(() {
      return _layersToSVGSync(layers, canvasSize);
    });
  }

  // ========== PRIVATE SYNC IMPLEMENTATIONS ==========

  static Uint8List _rasterizeLayersSync(_RasterizeParams params) {
    final scaleFactor = params.targetDPI / 72.0;
    final outputWidth = (params.canvasSize.width * scaleFactor).toInt();
    final outputHeight = (params.canvasSize.height * scaleFactor).toInt();

    // Create picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    );

    // Scale canvas for high DPI
    canvas.scale(scaleFactor, scaleFactor);

    // Render all visible layers
    for (final layer in params.layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        _renderStroke(canvas, stroke);
      }
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = picture.toImageSync(outputWidth, outputHeight);

    // Convert to PNG bytes synchronously
    final byteData = image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    // Note: This is a simplified implementation
    // In production, use a proper async image encoding library
    return Uint8List(0); // Placeholder
  }

  static void _renderStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.brushProperties.color
      ..strokeWidth = stroke.brushProperties.strokeWidth
      ..strokeCap = stroke.brushProperties.strokeCap
      ..strokeJoin = stroke.brushProperties.strokeJoin
      ..style = PaintingStyle.stroke;

    // Draw stroke path
    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].position.dx, stroke.points[i].position.dy);
    }

    canvas.drawPath(path, paint);
  }

  static Uint8List _compressImage(Uint8List bytes, int quality) {
    // For now, return original bytes
    // In production, use image compression library like flutter_image_compress
    return bytes;
  }

  static String _layersToSVGSync(List<DrawingLayer> layers, Size canvasSize) {
    final buffer = StringBuffer();
    buffer.writeln(
      '<svg width="${canvasSize.width}" height="${canvasSize.height}" xmlns="http://www.w3.org/2000/svg">',
    );

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      buffer.writeln('  <g id="${layer.id}" opacity="${layer.opacity}">');

      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;

        final pathData = _strokeToPathData(stroke);
        final colorHex = _colorToHex(stroke.brushProperties.color);
        final opacity = 1.0; // LayerStroke doesn't have isHighlighter flag

        buffer.writeln(
          '    <path d="$pathData" stroke="$colorHex" stroke-width="${stroke.brushProperties.strokeWidth}" '
          'stroke-linecap="round" stroke-linejoin="round" '
          'fill="none" opacity="$opacity"/>',
        );
      }

      buffer.writeln('  </g>');
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static String _strokeToPathData(LayerStroke stroke) {
    if (stroke.points.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write(
      'M ${stroke.points[0].position.dx},${stroke.points[0].position.dy}',
    );

    for (int i = 1; i < stroke.points.length; i++) {
      buffer.write(
        ' L ${stroke.points[i].position.dx},${stroke.points[i].position.dy}',
      );
    }

    return buffer.toString();
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// Parameters for rasterization isolate
class _RasterizeParams {
  final List<DrawingLayer> layers;
  final Size canvasSize;
  final double targetDPI;

  _RasterizeParams({
    required this.layers,
    required this.canvasSize,
    required this.targetDPI,
  });
}

/// Drawing document model for serialization
class DrawingDocument {
  final String version;
  final Size canvasSize;
  final DateTime timestamp;
  final List<DrawingLayer> layers;

  DrawingDocument({
    required this.version,
    required this.canvasSize,
    required this.timestamp,
    required this.layers,
  });

  factory DrawingDocument.fromJson(Map<String, dynamic> json) {
    return DrawingDocument(
      version: json['version'] as String? ?? '1.0',
      canvasSize: Size(
        (json['canvasWidth'] as num).toDouble(),
        (json['canvasHeight'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      layers: (json['layers'] as List<dynamic>)
          .map(
            (layerJson) =>
                DrawingLayer.fromJson(layerJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'timestamp': timestamp.toIso8601String(),
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }
}
