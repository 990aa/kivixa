import 'package:flutter/material.dart';

enum ToolType {
  pen,
  highlighter,
  eraser,
}

class DrawingTool {
  final ToolType type;
  final Color color;
  final double strokeWidth;

  DrawingTool({
    required this.type,
    this.color = Colors.black,
    this.strokeWidth = 3.0,
  });

  DrawingTool copyWith({
    ToolType? type,
    Color? color,
    double? strokeWidth,
  }) {
    return DrawingTool(
      type: type ?? this.type,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}