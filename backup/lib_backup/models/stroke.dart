import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:uuid/uuid.dart';

class Stroke {
  final String id;
  final List<PointVector> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;
  ui.Image? cachedImage;

  Stroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 4.0,
    this.isHighlighter = false,
  }) : id = const Uuid().v4();
}
