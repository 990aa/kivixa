import 'package:flutter/material.dart';

// 1. Paper Size Definitions
class PaperSize {
  final double width;
  final double height;
  const PaperSize(this.width, this.height);

  static const a4 = PaperSize(595, 842);
  static const a3 = PaperSize(842, 1191);
  static const letter = PaperSize(612, 792);
  static const legal = PaperSize(612, 1008);
}

// 2. Paper Type Enum
enum PaperType { plain, ruled, grid, dotGrid, graph }

// 3. Abstract class for paper options
abstract class PaperOptions {
  final Color backgroundColor;
  final String? watermark;

  PaperOptions({this.backgroundColor = Colors.white, this.watermark});

  Map<String, dynamic> toJson();
}

// 4. Specific implementations for each paper type's options
class PlainPaperOptions extends PaperOptions {
  PlainPaperOptions({super.backgroundColor, super.watermark});

  @override
  Map<String, dynamic> toJson() => {
    'backgroundColor':
        '#${backgroundColor.toARGB32().toRadixString(16).substring(2)}',
    'watermark': watermark,
  };
}

class RuledPaperOptions extends PaperOptions {
  final double lineSpacing;
  final double marginLeft;
  final Color lineColor;
  final Color marginColor;

  RuledPaperOptions({
    super.backgroundColor,
    super.watermark,
    this.lineSpacing = 24.0,
    this.marginLeft = 60.0,
    this.lineColor = Colors.blueGrey,
    this.marginColor = Colors.pink,
  });

  @override
  Map<String, dynamic> toJson() => {
    'backgroundColor':
        '#${backgroundColor.toARGB32().toRadixString(16).substring(2)}',
    'watermark': watermark,
    'lineSpacing': lineSpacing,
    'marginLeft': marginLeft,
    'lineColor': '#${lineColor.toARGB32().toRadixString(16).substring(2)}',
    'marginColor': '#${marginColor.toARGB32().toRadixString(16).substring(2)}',
  };
}

class GridPaperOptions extends PaperOptions {
  final double gridSize;
  final Color color;

  GridPaperOptions({
    super.backgroundColor,
    super.watermark,
    this.gridSize = 20.0,
    this.color = Colors.grey,
  });

  @override
  Map<String, dynamic> toJson() => {
    'backgroundColor':
        '#${backgroundColor.toARGB32().toRadixString(16).substring(2)}',
    'watermark': watermark,
    'gridSize': gridSize,
    'color': '#${color.toARGB32().toRadixString(16).substring(2)}',
  };
}

class DotGridPaperOptions extends PaperOptions {
  final double dotSpacing;
  final double dotSize;
  final Color color;

  DotGridPaperOptions({
    super.backgroundColor,
    super.watermark,
    this.dotSpacing = 20.0,
    this.dotSize = 1.0,
    this.color = Colors.grey,
  });

  @override
  Map<String, dynamic> toJson() => {
    'backgroundColor':
        '#${backgroundColor.toARGB32().toRadixString(16).substring(2)}',
    'watermark': watermark,
    'dotSpacing': dotSpacing,
    'dotSize': dotSize,
    'color': '#${color.toARGB32().toRadixString(16).substring(2)}',
  };
}

class GraphPaperOptions extends PaperOptions {
  final double gridSize;
  final int majorEvery;
  final Color minorColor;
  final Color majorColor;

  GraphPaperOptions({
    super.backgroundColor,
    super.watermark,
    this.gridSize = 15.0,
    this.majorEvery = 5,
    this.minorColor = const Color(0xFFE0E0E0),
    this.majorColor = const Color(0xFFC0C0C0),
  });

  @override
  Map<String, dynamic> toJson() => {
    'backgroundColor':
        '#${backgroundColor.toARGB32().toRadixString(16).substring(2)}',
    'watermark': watermark,
    'gridSize': gridSize,
    'majorEvery': majorEvery,
    'minorColor': '#${minorColor.toARGB32().toRadixString(16).substring(2)}',
    'majorColor': '#${majorColor.toARGB32().toRadixString(16).substring(2)}',
  };
}
