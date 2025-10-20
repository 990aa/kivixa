import 'package:flutter/material.dart';
import 'stroke_point.dart';

/// Represents an eraser stroke that creates transparency
/// 
/// Unlike regular strokes, eraser strokes don't add pixels -
/// they remove pixels and create transparent regions.
class EraserStroke {
  final String id;
  final List<StrokePoint> points;
  final double size;
  final DateTime timestamp;

  EraserStroke({
    required this.id,
    required this.points,
    required this.size,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'eraser',
      'size': size,
      'timestamp': timestamp.toIso8601String(),
      'points': points.map((p) => {
        'x': p.position.dx,
        'y': p.position.dy,
        'pressure': p.pressure,
        'tilt': p.tilt,
        'orientation': p.orientation,
      }).toList(),
    };
  }

  /// Create from JSON
  factory EraserStroke.fromJson(Map<String, dynamic> json) {
    return EraserStroke(
      id: json['id'] as String,
      size: (json['size'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      points: (json['points'] as List).map((p) {
        return StrokePoint(
          position: Offset(
            (p['x'] as num).toDouble(),
            (p['y'] as num).toDouble(),
          ),
          pressure: (p['pressure'] as num?)?.toDouble() ?? 1.0,
          tilt: (p['tilt'] as num?)?.toDouble() ?? 0.0,
          orientation: (p['orientation'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
    );
  }

  /// Create a copy with modified values
  EraserStroke copyWith({
    String? id,
    List<StrokePoint>? points,
    double? size,
    DateTime? timestamp,
  }) {
    return EraserStroke(
      id: id ?? this.id,
      points: points ?? List.from(this.points),
      size: size ?? this.size,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Get bounding box of eraser stroke
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

    // Expand by eraser size
    final padding = size;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// Check if this eraser stroke intersects with a rectangle
  bool intersects(Rect rect) {
    final bounds = getBounds();
    return rect.overlaps(bounds);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EraserStroke &&
        other.id == id &&
        other.size == size &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(id, size, timestamp);

  @override
  String toString() {
    return 'EraserStroke(id: $id, size: $size, points: ${points.length})';
  }
}
