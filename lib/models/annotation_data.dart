import 'dart:ui';
import 'package:flutter/material.dart';
import 'drawing_tool.dart';

/// Model representing a single annotation stroke on a PDF page
/// 
/// This class stores vector-based stroke data (not rasterized pixels) to ensure
/// annotations remain smooth and crisp at any zoom level. Each annotation contains
/// a series of offset points that form a path, along with styling information.
class AnnotationData {
  /// List of vector coordinates (x, y) that define the stroke path
  /// These points are used to render Bézier curves for smooth lines
  final List<Offset> strokePath;
  
  /// Color of the stroke stored as an integer (ARGB format)
  /// Can be converted to/from Color using Color(colorValue) and color.value
  final int colorValue;
  
  /// Width of the stroke in logical pixels
  /// Pen strokes typically range from 1.0 to 5.0
  /// Highlighter strokes range from 8.0 to 15.0
  final double strokeWidth;
  
  /// Type of tool used to create this annotation
  final DrawingTool toolType;
  
  /// Page number this annotation belongs to (0-indexed)
  final int pageNumber;
  
  /// Timestamp when the annotation was created
  /// Useful for sorting, version control, and undo/redo operations
  final DateTime timestamp;

  AnnotationData({
    required this.strokePath,
    required this.colorValue,
    required this.strokeWidth,
    required this.toolType,
    required this.pageNumber,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts the annotation to a JSON map for persistence
  /// 
  /// Stroke paths are serialized as a flat list of doubles [x1, y1, x2, y2, ...]
  /// This format is compact and efficient for storage
  Map<String, dynamic> toJson() {
    return {
      'strokePath': strokePath
          .expand((offset) => [offset.dx, offset.dy])
          .toList(),
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
      'toolType': toolType.name,
      'pageNumber': pageNumber,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates an AnnotationData instance from a JSON map
  /// 
  /// Reconstructs the stroke path from the flat list of coordinates
  /// Handles missing or invalid data gracefully with defaults
  factory AnnotationData.fromJson(Map<String, dynamic> json) {
    // Parse the flat coordinate list back into Offset objects
    final List<double> flatPath = List<double>.from(json['strokePath']);
    final List<Offset> strokePath = [];
    
    for (int i = 0; i < flatPath.length; i += 2) {
      if (i + 1 < flatPath.length) {
        strokePath.add(Offset(flatPath[i], flatPath[i + 1]));
      }
    }

    return AnnotationData(
      strokePath: strokePath,
      colorValue: json['colorValue'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      toolType: DrawingTool.values.firstWhere(
        (tool) => tool.name == json['toolType'],
        orElse: () => DrawingTool.pen,
      ),
      pageNumber: json['pageNumber'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Creates a copy of this annotation with optional field overrides
  AnnotationData copyWith({
    List<Offset>? strokePath,
    int? colorValue,
    double? strokeWidth,
    DrawingTool? toolType,
    int? pageNumber,
    DateTime? timestamp,
  }) {
    return AnnotationData(
      strokePath: strokePath ?? this.strokePath,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      toolType: toolType ?? this.toolType,
      pageNumber: pageNumber ?? this.pageNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Helper getter to convert integer color value to Color object
  Color get color => Color(colorValue);

  @override
  String toString() {
    return 'AnnotationData(points: ${strokePath.length}, '
        'tool: $toolType, page: $pageNumber)';
  }
}
