import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';

/// Service for serializing and deserializing layer data
class LayerSerializationService {
  /// Version of the serialization format
  static const String currentVersion = '1.0';

  /// Serialize drawing layers to JSON
  static Map<String, dynamic> serializeDrawing(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) {
    return {
      'version': currentVersion,
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'layers': layers.map((layer) => _serializeLayer(layer)).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Serialize a single layer
  static Map<String, dynamic> _serializeLayer(DrawingLayer layer) {
    return {
      'id': layer.id,
      'name': layer.name,
      'opacity': layer.opacity,
      'blendMode': layer.blendMode.toString(),
      'isVisible': layer.isVisible,
      'isLocked': layer.isLocked,
      'bounds': layer.bounds != null
          ? {
              'left': layer.bounds!.left,
              'top': layer.bounds!.top,
              'right': layer.bounds!.right,
              'bottom': layer.bounds!.bottom,
            }
          : null,
      'createdAt': layer.createdAt.toIso8601String(),
      'modifiedAt': layer.modifiedAt.toIso8601String(),
      'strokes': layer.strokes.map((stroke) => _serializeStroke(stroke)).toList(),
    };
  }

  /// Serialize a stroke
  static Map<String, dynamic> _serializeStroke(LayerStroke stroke) {
    return {
      'id': stroke.id,
      'timestamp': stroke.timestamp.toIso8601String(),
      'brush': {
        'color': stroke.brushProperties.color.toARGB32(),
        'strokeWidth': stroke.brushProperties.strokeWidth,
        'strokeCap': stroke.brushProperties.strokeCap.toString(),
        'strokeJoin': stroke.brushProperties.strokeJoin.toString(),
        'style': stroke.brushProperties.style.toString(),
        'blendMode': stroke.brushProperties.blendMode.toString(),
      },
      'points': stroke.points.map((point) => _serializePoint(point)).toList(),
    };
  }

  /// Serialize a stroke point
  static Map<String, dynamic> _serializePoint(StrokePoint point) {
    return {
      'x': point.position.dx,
      'y': point.position.dy,
      'pressure': point.pressure,
      'tilt': point.tilt,
      'orientation': point.orientation,
    };
  }

  /// Deserialize drawing from JSON
  static DrawingData deserializeDrawing(Map<String, dynamic> json) {
    final version = json['version'] as String;
    if (version != currentVersion) {
      // Handle version migration if needed
      debugPrint('Warning: Loading drawing with version $version (current: $currentVersion)');
    }

    final canvasSize = Size(
      json['canvasWidth'] as double,
      json['canvasHeight'] as double,
    );

    final layers = (json['layers'] as List)
        .map((layerJson) => _deserializeLayer(layerJson as Map<String, dynamic>))
        .toList();

    return DrawingData(
      layers: layers,
      canvasSize: canvasSize,
      version: version,
    );
  }

  /// Deserialize a single layer
  static DrawingLayer _deserializeLayer(Map<String, dynamic> json) {
    final strokes = (json['strokes'] as List)
        .map((strokeJson) => _deserializeStroke(strokeJson as Map<String, dynamic>))
        .toList();

    return DrawingLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      opacity: json['opacity'] as double,
      blendMode: _parseBlendMode(json['blendMode'] as String),
      isVisible: json['isVisible'] as bool,
      isLocked: json['isLocked'] as bool,
      bounds: json['bounds'] != null
          ? Rect.fromLTRB(
              json['bounds']['left'] as double,
              json['bounds']['top'] as double,
              json['bounds']['right'] as double,
              json['bounds']['bottom'] as double,
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      strokes: strokes,
    );
  }

  /// Deserialize a stroke
  static LayerStroke _deserializeStroke(Map<String, dynamic> json) {
    final brush = json['brush'] as Map<String, dynamic>;
    final points = (json['points'] as List)
        .map((pointJson) => _deserializePoint(pointJson as Map<String, dynamic>))
        .toList();

    final paint = Paint()
      ..color = Color(brush['color'] as int)
      ..strokeWidth = brush['strokeWidth'] as double
      ..strokeCap = _parseStrokeCap(brush['strokeCap'] as String)
      ..strokeJoin = _parseStrokeJoin(brush['strokeJoin'] as String)
      ..style = _parsePaintingStyle(brush['style'] as String)
      ..blendMode = _parseBlendMode(brush['blendMode'] as String)
      ..isAntiAlias = true;

    return LayerStroke(
      id: json['id'] as String,
      points: points,
      brushProperties: paint,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Deserialize a stroke point
  static StrokePoint _deserializePoint(Map<String, dynamic> json) {
    return StrokePoint(
      position: Offset(
        json['x'] as double,
        json['y'] as double,
      ),
      pressure: json['pressure'] as double,
      tilt: json['tilt'] as double,
      orientation: json['orientation'] as double,
    );
  }

  /// Parse BlendMode from string
  static BlendMode _parseBlendMode(String value) {
    final name = value.split('.').last;
    return BlendMode.values.firstWhere(
      (e) => e.toString().split('.').last == name,
      orElse: () => BlendMode.srcOver,
    );
  }

  /// Parse StrokeCap from string
  static StrokeCap _parseStrokeCap(String value) {
    final name = value.split('.').last;
    return StrokeCap.values.firstWhere(
      (e) => e.toString().split('.').last == name,
      orElse: () => StrokeCap.round,
    );
  }

  /// Parse StrokeJoin from string
  static StrokeJoin _parseStrokeJoin(String value) {
    final name = value.split('.').last;
    return StrokeJoin.values.firstWhere(
      (e) => e.toString().split('.').last == name,
      orElse: () => StrokeJoin.round,
    );
  }

  /// Parse PaintingStyle from string
  static PaintingStyle _parsePaintingStyle(String value) {
    final name = value.split('.').last;
    return PaintingStyle.values.firstWhere(
      (e) => e.toString().split('.').last == name,
      orElse: () => PaintingStyle.stroke,
    );
  }

  /// Save project to file (JSON + PNG hybrid approach)
  static Future<void> saveProject({
    required String filePath,
    required List<DrawingLayer> layers,
    required Size canvasSize,
    bool savePngLayers = true,
  }) async {
    // 1. Serialize layer metadata to JSON
    final metadata = serializeDrawing(layers, canvasSize);
    final jsonFile = File('$filePath.json');
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );

    // 2. Save each layer as separate PNG image (optional)
    if (savePngLayers) {
      for (int i = 0; i < layers.length; i++) {
        final layer = layers[i];
        if (layer.cachedImage != null) {
          await _saveLayerImage(
            layer.cachedImage!,
            '$filePath-layer-${layer.id}.png',
          );
        }
      }
    }
  }

  /// Save a layer image to PNG file
  static Future<void> _saveLayerImage(ui.Image image, String filePath) async {
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData != null) {
      final imageFile = File(filePath);
      await imageFile.writeAsBytes(byteData.buffer.asUint8List());
    }
  }

  /// Load project from file
  static Future<DrawingData> loadProject(String filePath) async {
    final jsonFile = File('$filePath.json');
    final jsonString = await jsonFile.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return deserializeDrawing(json);
  }

  /// Load layer images separately
  static Future<void> loadLayerImages({
    required String filePath,
    required List<DrawingLayer> layers,
  }) async {
    for (final layer in layers) {
      final imageFile = File('$filePath-layer-${layer.id}.png');
      if (await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        layer.cachedImage = frame.image;
      }
    }
  }

  /// Export to JSON string
  static String exportToJson(List<DrawingLayer> layers, Size canvasSize) {
    final data = serializeDrawing(layers, canvasSize);
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import from JSON string
  static DrawingData importFromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return deserializeDrawing(json);
  }

  /// Get file size estimate (for UI display)
  static int estimateFileSize(List<DrawingLayer> layers, Size canvasSize) {
    final jsonData = serializeDrawing(layers, canvasSize);
    final jsonString = jsonEncode(jsonData);
    int totalSize = jsonString.length;

    // Estimate PNG size (rough approximation)
    for (final layer in layers) {
      if (layer.strokes.isNotEmpty) {
        // Rough estimate: 4 bytes per pixel (RGBA) compressed to ~30%
        final pixelCount = canvasSize.width * canvasSize.height;
        totalSize += (pixelCount * 4 * 0.3).toInt();
      }
    }

    return totalSize;
  }
}

/// Data class for deserialized drawing
class DrawingData {
  final List<DrawingLayer> layers;
  final Size canvasSize;
  final String version;

  DrawingData({
    required this.layers,
    required this.canvasSize,
    required this.version,
  });
}
