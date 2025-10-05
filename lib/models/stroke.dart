import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'stroke.g.dart';

@HiveType(typeId: 0)
class DrawingStroke extends HiveObject {
  @HiveField(0)
  final List<Offset> points;
  
  @HiveField(1)
  final Color color;
  
  @HiveField(2)
  final double strokeWidth;
  
  @HiveField(3)
  final bool isHighlighter;
  
  @HiveField(4)
  final String id;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isHighlighter = false,
    required this.id,
  });
}