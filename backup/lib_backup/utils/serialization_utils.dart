import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:kivixa/models/stroke.dart';
import 'package:kivixa/models/canvas_element.dart';
import 'package:kivixa/models/shape_tool.dart';

/// Utilities for serializing and deserializing canvas data
class SerializationUtils {
  /// Serialize PointVector list to JSON string
  static String serializePoints(List<PointVector> points) {
    return jsonEncode(
      points.map((p) => {'x': p.x, 'y': p.y, 'p': p.pressure}).toList(),
    );
  }

  /// Deserialize JSON string to PointVector list
  static List<PointVector> deserializePoints(String json) {
    final List<dynamic> data = jsonDecode(json);
    return data
        .map(
          (p) => PointVector(
            p['x'] as double,
            p['y'] as double,
            p['p'] as double?,
          ),
        )
        .toList();
  }

  /// Serialize Stroke to JSON
  static Map<String, dynamic> serializeStroke(Stroke stroke) {
    return {
      'id': stroke.id,
      'points': serializePoints(stroke.points),
      'color': stroke.color.toARGB32(),
      'strokeWidth': stroke.strokeWidth,
      'isHighlighter': stroke.isHighlighter,
    };
  }

  /// Deserialize JSON to Stroke
  static Stroke deserializeStroke(Map<String, dynamic> json) {
    return Stroke(
      points: deserializePoints(json['points'] as String),
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double,
      isHighlighter: json['isHighlighter'] as bool,
    );
  }

  /// Serialize TextElement to JSON
  static String serializeTextElement(TextElement element) {
    return jsonEncode({
      'text': element.text,
      'fontSize': element.style.fontSize,
      'color': element.style.color?.toARGB32(),
      'fontWeight': element.style.fontWeight?.index,
      'fontStyle': element.style.fontStyle?.index,
    });
  }

  /// Deserialize JSON to TextElement
  static TextElement deserializeTextElement(
    String json,
    Offset position,
    double rotation,
    double scale,
  ) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return TextElement(
      position: position,
      rotation: rotation,
      scale: scale,
      text: data['text'] as String,
      style: TextStyle(
        fontSize: data['fontSize'] as double?,
        color: data['color'] != null ? Color(data['color'] as int) : null,
        fontWeight: data['fontWeight'] != null
            ? FontWeight.values[data['fontWeight'] as int]
            : null,
        fontStyle: data['fontStyle'] != null
            ? FontStyle.values[data['fontStyle'] as int]
            : null,
      ),
    );
  }

  /// Serialize ImageElement to JSON
  static String serializeImageElement(ImageElement element) {
    return jsonEncode({
      'width': element.width,
      'height': element.height,
      'imageData': base64Encode(element.imageData),
    });
  }

  /// Deserialize JSON to ImageElement
  static ImageElement deserializeImageElement(
    String json,
    Offset position,
    double rotation,
    double scale,
  ) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return ImageElement(
      position: position,
      rotation: rotation,
      scale: scale,
      width: data['width'] as double,
      height: data['height'] as double,
      imageData: base64Decode(data['imageData'] as String),
    );
  }

  /// Serialize Shape to JSON
  static String serializeShape(Shape shape) {
    return jsonEncode(shape.toJson());
  }

  /// Deserialize JSON to Shape
  static Shape deserializeShape(String json) {
    return Shape.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Serialize generic CanvasElement to JSON with type
  static Map<String, dynamic> serializeCanvasElement(CanvasElement element) {
    String type;
    String dataJson;

    if (element is TextElement) {
      type = 'text';
      dataJson = serializeTextElement(element);
    } else if (element is ImageElement) {
      type = 'image';
      dataJson = serializeImageElement(element);
    } else {
      throw Exception('Unknown canvas element type');
    }

    return {
      'type': type,
      'dataJson': dataJson,
      'posX': element.position.dx,
      'posY': element.position.dy,
      'rotation': element.rotation,
      'scale': element.scale,
    };
  }

  /// Deserialize database row to CanvasElement
  static CanvasElement deserializeCanvasElement(
    String type,
    String dataJson,
    double posX,
    double posY,
    double rotation,
    double scale,
  ) {
    final position = Offset(posX, posY);

    switch (type) {
      case 'text':
        return deserializeTextElement(dataJson, position, rotation, scale);
      case 'image':
        return deserializeImageElement(dataJson, position, rotation, scale);
      default:
        throw Exception('Unknown element type: $type');
    }
  }

  /// Color to hex string
  static String colorToHex(Color color) {
    final r = ((color.r * 255.0).round() & 0xff);
    final g = ((color.g * 255.0).round() & 0xff);
    final b = ((color.b * 255.0).round() & 0xff);
    final a = ((color.a * 255.0).round() & 0xff);
    return '#${a.toRadixString(16).padLeft(2, '0')}'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// Hex string to Color
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
