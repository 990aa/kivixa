import 'package:flutter/material.dart';
import 'dart:ui';

import 'drawing_tool.dart';

class AnnotationData {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;
  final int pageNumber;
  final int timestamp;

  AnnotationData({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    required this.pageNumber,
    required this.timestamp,
  });

  // Convert AnnotationData to JSON
  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'tool': tool.toString(),
        'pageNumber': pageNumber,
        'timestamp': timestamp,
      };

  // Create AnnotationData from JSON
  factory AnnotationData.fromJson(Map<String, dynamic> json) {
    return AnnotationData(
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'], p['dy']))
          .toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      tool: DrawingTool.values
          .firstWhere((e) => e.toString() == json['tool']),
      pageNumber: json['pageNumber'],
      timestamp: json['timestamp'],
    );
  }
}
