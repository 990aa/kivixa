import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Enum for different tool types
enum ToolType {
  pen,
  highlighter,
  eraser,
  line,
  rectangle,
  circle,
  arrow,
}

/// Shape tool for creating geometric shapes
class ShapeTool {
  final ToolType type;
  final Color color;
  final double strokeWidth;
  final bool filled;

  ShapeTool({
    required this.type,
    required this.color,
    this.strokeWidth = 4.0,
    this.filled = false,
  });

  /// Generate a shape path from start to end points
  Path generateShape(Offset start, Offset end) {
    switch (type) {
      case ToolType.line:
        return _createLinePath(start, end);

      case ToolType.rectangle:
        return _createRectanglePath(start, end);

      case ToolType.circle:
        return _createCirclePath(start, end);

      case ToolType.arrow:
        return _createArrowPath(start, end);

      default:
        return Path();
    }
  }

  Path _createLinePath(Offset start, Offset end) {
    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
  }

  Path _createRectanglePath(Offset start, Offset end) {
    return Path()..addRect(Rect.fromPoints(start, end));
  }

  Path _createCirclePath(Offset start, Offset end) {
    final radius = (end - start).distance / 2;
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  Path _createArrowPath(Offset start, Offset end) {
    final path = Path();

    // Draw the main line
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    // Calculate arrow head angle
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = strokeWidth * 5;

    // Draw arrow head
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );

    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );

    return path;
  }

  /// Copy with modified properties
  ShapeTool copyWith({
    ToolType? type,
    Color? color,
    double? strokeWidth,
    bool? filled,
  }) {
    return ShapeTool(
      type: type ?? this.type,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      filled: filled ?? this.filled,
    );
  }
}

/// Model for a completed shape on the canvas
class Shape {
  final String id;
  final ToolType type;
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double strokeWidth;
  final bool filled;

  Shape({
    required this.id,
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.color,
    this.strokeWidth = 4.0,
    this.filled = false,
  });

  Path getPath() {
    final tool = ShapeTool(
      type: type,
      color: color,
      strokeWidth: strokeWidth,
      filled: filled,
    );
    return tool.generateShape(startPoint, endPoint);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startPoint': {'dx': startPoint.dx, 'dy': startPoint.dy},
      'endPoint': {'dx': endPoint.dx, 'dy': endPoint.dy},
      'color': color.value,
      'strokeWidth': strokeWidth,
      'filled': filled,
    };
  }

  factory Shape.fromJson(Map<String, dynamic> json) {
    return Shape(
      id: json['id'] as String,
      type: ToolType.values.firstWhere((e) => e.name == json['type']),
      startPoint: Offset(
        json['startPoint']['dx'] as double,
        json['startPoint']['dy'] as double,
      ),
      endPoint: Offset(
        json['endPoint']['dx'] as double,
        json['endPoint']['dy'] as double,
      ),
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double,
      filled: json['filled'] as bool,
    );
  }
}
