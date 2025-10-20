import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'stroke_point.dart';

/// A stroke with path data and brush properties for layer-based drawing
class LayerStroke {
  final String id;
  final List<StrokePoint> points; // Path data
  final Paint brushProperties; // Color, width, style
  final DateTime timestamp; // For undo/redo

  LayerStroke({
    String? id,
    required this.points,
    required this.brushProperties,
    DateTime? timestamp,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  /// Create a copy with modified values
  LayerStroke copyWith({
    String? id,
    List<StrokePoint>? points,
    Paint? brushProperties,
    DateTime? timestamp,
  }) {
    return LayerStroke(
      id: id ?? this.id,
      points: points ?? List.from(this.points),
      brushProperties: brushProperties ?? _copyPaint(this.brushProperties),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Helper to copy Paint object
  static Paint _copyPaint(Paint paint) {
    return Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin
      ..blendMode = paint.blendMode
      ..isAntiAlias = paint.isAntiAlias
      ..filterQuality = paint.filterQuality;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'brushProperties': {
        'color': brushProperties.color.toARGB32(),
        'strokeWidth': brushProperties.strokeWidth,
        'style': brushProperties.style.index,
        'strokeCap': brushProperties.strokeCap.index,
        'strokeJoin': brushProperties.strokeJoin.index,
        'blendMode': brushProperties.blendMode.index,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LayerStroke.fromJson(Map<String, dynamic> json) {
    final brushProps = json['brushProperties'] as Map<String, dynamic>;
    return LayerStroke(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      brushProperties: Paint()
        ..color = Color(brushProps['color'] as int)
        ..strokeWidth = brushProps['strokeWidth'] as double
        ..style = PaintingStyle.values[brushProps['style'] as int]
        ..strokeCap = StrokeCap.values[brushProps['strokeCap'] as int]
        ..strokeJoin = StrokeJoin.values[brushProps['strokeJoin'] as int]
        ..blendMode = BlendMode.values[brushProps['blendMode'] as int],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Calculate bounding rectangle for this stroke
  Rect getBounds() {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.position.dx;
    double maxX = points.first.position.dx;
    double minY = points.first.position.dy;
    double maxY = points.first.position.dy;

    for (final point in points) {
      if (point.position.dx < minX) minX = point.position.dx;
      if (point.position.dx > maxX) maxX = point.position.dx;
      if (point.position.dy < minY) minY = point.position.dy;
      if (point.position.dy > maxY) maxY = point.position.dy;
    }

    final padding = brushProperties.strokeWidth * 2;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }
}
