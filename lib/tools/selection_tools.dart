import 'dart:ui' as ui;
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/selection_mode.dart';

/// Base class for all selection tools
abstract class SelectionTool {
  /// Current selection path
  Path? selectionPath;

  /// Selection bounds
  Rect? selectionBounds;

  /// Whether selection is active
  bool get hasSelection => selectionPath != null;

  /// Start new selection
  void startSelection(Offset point);

  /// Update selection
  void updateSelection(Offset point);

  /// Finalize selection
  void finishSelection();

  /// Clear selection
  void clearSelection() {
    selectionPath = null;
    selectionBounds = null;
  }

  /// Check if point is inside selection
  bool isPointInSelection(Offset point);

  /// Draw selection on canvas
  void drawSelection(
    Canvas canvas,
    SelectionSettings settings, {
    double animationValue = 0.0,
  });

  /// Get selection mask (for operations)
  Future<ui.Image?> getSelectionMask(Size canvasSize);
}

/// Rectangular selection tool
class RectangularSelection extends SelectionTool {
  Offset? _startPoint;
  Rect? _selectionRect;

  @override
  void startSelection(Offset point) {
    _startPoint = point;
    _selectionRect = Rect.fromLTWH(point.dx, point.dy, 0, 0);
    selectionPath = Path()..addRect(_selectionRect!);
  }

  @override
  void updateSelection(Offset current) {
    if (_startPoint == null) return;

    _selectionRect = Rect.fromPoints(_startPoint!, current);
    selectionPath = Path()..addRect(_selectionRect!);
    selectionBounds = _selectionRect;
  }

  @override
  void finishSelection() {
    // Selection is already complete
  }

  @override
  bool isPointInSelection(Offset point) {
    return _selectionRect?.contains(point) ?? false;
  }

  @override
  void drawSelection(
    Canvas canvas,
    SelectionSettings settings, {
    double animationValue = 0.0,
  }) {
    if (selectionPath == null) return;

    // Draw filled selection area with transparency
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(selectionPath!, fillPaint);

    // Draw selection border
    _drawSelectionBorder(canvas, selectionPath!, settings, animationValue);
  }

  void _drawSelectionBorder(
    Canvas canvas,
    Path path,
    SelectionSettings settings,
    double animationValue,
  ) {
    if (settings.showMarchingAnts) {
      // Marching ants effect
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final dashPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw solid white border
      canvas.drawPath(path, paint);

      // Draw animated dashed black border
      _drawDashedPath(canvas, path, dashPaint, animationValue);
    } else {
      // Simple solid border
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double animationValue,
  ) {
    final dashWidth = 6.0;
    final dashSpace = 6.0;
    final dashOffset = animationValue * (dashWidth + dashSpace);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = dashOffset;
      bool draw = true;

      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);

        if (draw) {
          final extractPath = metric.extractPath(start, end);
          canvas.drawPath(extractPath, paint);
        }

        distance += draw ? dashWidth : dashSpace;
        draw = !draw;
      }
    }
  }

  @override
  Future<ui.Image?> getSelectionMask(Size canvasSize) async {
    if (_selectionRect == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(_selectionRect!, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }
}

/// Elliptical selection tool
class EllipseSelection extends SelectionTool {
  Offset? _startPoint;
  Rect? _boundingRect;

  @override
  void startSelection(Offset point) {
    _startPoint = point;
    _boundingRect = Rect.fromLTWH(point.dx, point.dy, 0, 0);
    selectionPath = Path()..addOval(_boundingRect!);
  }

  @override
  void updateSelection(Offset current) {
    if (_startPoint == null) return;

    _boundingRect = Rect.fromPoints(_startPoint!, current);
    selectionPath = Path()..addOval(_boundingRect!);
    selectionBounds = _boundingRect;
  }

  @override
  void finishSelection() {
    // Selection is already complete
  }

  @override
  bool isPointInSelection(Offset point) {
    if (_boundingRect == null) return false;

    // Check if point is inside ellipse
    final center = _boundingRect!.center;
    final rx = _boundingRect!.width / 2;
    final ry = _boundingRect!.height / 2;

    if (rx == 0 || ry == 0) return false;

    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1;
  }

  @override
  void drawSelection(
    Canvas canvas,
    SelectionSettings settings, {
    double animationValue = 0.0,
  }) {
    if (selectionPath == null) return;

    // Draw filled selection area
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(selectionPath!, fillPaint);

    // Draw selection border (reuse from RectangularSelection)
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(selectionPath!, borderPaint);
  }

  @override
  Future<ui.Image?> getSelectionMask(Size canvasSize) async {
    if (_boundingRect == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawOval(_boundingRect!, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }
}

/// Lasso (freeform) selection tool
class LassoSelection extends SelectionTool {
  List<Offset> _selectionPoints = [];

  @override
  void startSelection(Offset point) {
    _selectionPoints = [point];
    selectionPath = Path()..moveTo(point.dx, point.dy);
  }

  @override
  void updateSelection(Offset point) {
    _selectionPoints.add(point);

    // Rebuild path
    if (_selectionPoints.isNotEmpty) {
      selectionPath = Path();
      selectionPath!.moveTo(
        _selectionPoints.first.dx,
        _selectionPoints.first.dy,
      );

      for (int i = 1; i < _selectionPoints.length; i++) {
        selectionPath!.lineTo(_selectionPoints[i].dx, _selectionPoints[i].dy);
      }
    }
  }

  @override
  void finishSelection() {
    if (_selectionPoints.length < 3) {
      clearSelection();
      return;
    }

    // Close the path
    selectionPath?.close();

    // Calculate bounds
    _calculateBounds();
  }

  void _calculateBounds() {
    if (_selectionPoints.isEmpty) return;

    double left = _selectionPoints.first.dx;
    double top = _selectionPoints.first.dy;
    double right = _selectionPoints.first.dx;
    double bottom = _selectionPoints.first.dy;

    for (final point in _selectionPoints) {
      left = min(left, point.dx);
      top = min(top, point.dy);
      right = max(right, point.dx);
      bottom = max(bottom, point.dy);
    }

    selectionBounds = Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool isPointInSelection(Offset point) {
    return selectionPath?.contains(point) ?? false;
  }

  @override
  void drawSelection(
    Canvas canvas,
    SelectionSettings settings, {
    double animationValue = 0.0,
  }) {
    if (_selectionPoints.isEmpty) return;

    // Draw selection path
    if (selectionPath != null) {
      // Filled area
      final fillPaint = Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      canvas.drawPath(selectionPath!, fillPaint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(selectionPath!, borderPaint);
    }
  }

  @override
  Future<ui.Image?> getSelectionMask(Size canvasSize) async {
    if (selectionPath == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(selectionPath!, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }

  @override
  void clearSelection() {
    super.clearSelection();
    _selectionPoints.clear();
  }
}

/// Polygonal lasso selection tool
class PolygonalSelection extends SelectionTool {
  List<Offset> _points = [];

  @override
  void startSelection(Offset point) {
    _points = [point];
    selectionPath = Path()..moveTo(point.dx, point.dy);
  }

  /// Add point to polygon
  void addPoint(Offset point) {
    _points.add(point);

    // Rebuild path
    selectionPath = Path();
    selectionPath!.moveTo(_points.first.dx, _points.first.dy);

    for (int i = 1; i < _points.length; i++) {
      selectionPath!.lineTo(_points[i].dx, _points[i].dy);
    }
  }

  @override
  void updateSelection(Offset point) {
    // Show preview line to next point
  }

  @override
  void finishSelection() {
    if (_points.length < 3) {
      clearSelection();
      return;
    }

    selectionPath?.close();
    _calculateBounds();
  }

  void _calculateBounds() {
    if (_points.isEmpty) return;

    double left = _points.first.dx;
    double top = _points.first.dy;
    double right = _points.first.dx;
    double bottom = _points.first.dy;

    for (final point in _points) {
      left = min(left, point.dx);
      top = min(top, point.dy);
      right = max(right, point.dx);
      bottom = max(bottom, point.dy);
    }

    selectionBounds = Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool isPointInSelection(Offset point) {
    return selectionPath?.contains(point) ?? false;
  }

  @override
  void drawSelection(
    Canvas canvas,
    SelectionSettings settings, {
    double animationValue = 0.0,
  }) {
    if (_points.isEmpty) return;

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final point in _points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw lines
    if (_points.length > 1) {
      final linePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 1; i < _points.length; i++) {
        canvas.drawLine(_points[i - 1], _points[i], linePaint);
      }
    }

    // Draw closed selection if finished
    if (selectionPath != null) {
      final fillPaint = Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      canvas.drawPath(selectionPath!, fillPaint);
    }
  }

  @override
  Future<ui.Image?> getSelectionMask(Size canvasSize) async {
    if (selectionPath == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(selectionPath!, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }

  @override
  void clearSelection() {
    super.clearSelection();
    _points.clear();
  }

  /// Get current points
  List<Offset> get points => List.unmodifiable(_points);
}

/// Magic wand (color-based) selection tool
class MagicWandSelection extends SelectionTool {
  Set<Offset> _selectedPixels = {};
  Offset? _startPoint;

  @override
  void startSelection(Offset point) {
    _startPoint = point;
    _selectedPixels.clear();
  }

  @override
  void updateSelection(Offset point) {
    // Magic wand doesn't update continuously
  }

  @override
  void finishSelection() {
    if (_selectedPixels.isEmpty) {
      clearSelection();
      return;
    }

    // Create path from selected pixels
    selectionPath = _createPathFromPixels();
    _calculateBounds();
  }

  /// Perform flood fill selection
  Future<void> selectByColor(
    ui.Image image,
    Offset startPoint,
    double tolerance,
  ) async {
    _selectedPixels.clear();

    // Convert image to byte data
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    // Get starting pixel color
    final startX = startPoint.dx.toInt().clamp(0, width - 1);
    final startY = startPoint.dy.toInt().clamp(0, height - 1);
    final startIndex = (startY * width + startX) * 4;

    final targetR = pixels[startIndex];
    final targetG = pixels[startIndex + 1];
    final targetB = pixels[startIndex + 2];
    final targetA = pixels[startIndex + 3];

    // Flood fill with tolerance
    final visited = <int>{};
    final queue = Queue<Offset>();
    queue.add(Offset(startX.toDouble(), startY.toDouble()));

    final maxColorDiff = tolerance * 255 * sqrt(4); // RGBA

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final x = current.dx.toInt();
      final y = current.dy.toInt();

      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      final index = (y * width + x) * 4;
      if (visited.contains(index)) continue;

      visited.add(index);

      // Check color similarity
      final r = pixels[index];
      final g = pixels[index + 1];
      final b = pixels[index + 2];
      final a = pixels[index + 3];

      final colorDiff = sqrt(
        pow((r - targetR).toDouble(), 2) +
            pow((g - targetG).toDouble(), 2) +
            pow((b - targetB).toDouble(), 2) +
            pow((a - targetA).toDouble(), 2),
      );

      if (colorDiff <= maxColorDiff) {
        _selectedPixels.add(Offset(x.toDouble(), y.toDouble()));

        // Add neighbors to queue
        queue.add(Offset((x + 1).toDouble(), y.toDouble()));
        queue.add(Offset((x - 1).toDouble(), y.toDouble()));
        queue.add(Offset(x.toDouble(), (y + 1).toDouble()));
        queue.add(Offset(x.toDouble(), (y - 1).toDouble()));
      }
    }
  }

  Path _createPathFromPixels() {
    if (_selectedPixels.isEmpty) return Path();

    // Create path from pixel boundary
    // This is a simplified version - production would use marching squares
    final path = Path();
    bool first = true;

    for (final pixel in _selectedPixels) {
      if (first) {
        path.moveTo(pixel.dx, pixel.dy);
        first = false;
      } else {
        path.lineTo(pixel.dx, pixel.dy);
      }
    }

    path.close();
    return path;
  }

  void _calculateBounds() {
    if (_selectedPixels.isEmpty) return;

    final first = _selectedPixels.first;
    double left = first.dx;
    double top = first.dy;
    double right = first.dx;
    double bottom = first.dy;

    for (final pixel in _selectedPixels) {
      left = min(left, pixel.dx);
      top = min(top, pixel.dy);
      right = max(right, pixel.dx);
      bottom = max(bottom, pixel.dy);
    }

    selectionBounds = Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool isPointInSelection(Offset point) {
    return _selectedPixels.contains(point);
  }

  @override
  void drawSelection(
    Canvas canvas,
    SelectionSettings settings, {
    double animationValue = 0.0,
  }) {
    if (_selectedPixels.isEmpty) return;

    // Draw selected pixels
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final pixel in _selectedPixels) {
      canvas.drawRect(Rect.fromLTWH(pixel.dx, pixel.dy, 1, 1), paint);
    }

    // Draw border if path exists
    if (selectionPath != null) {
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(selectionPath!, borderPaint);
    }
  }

  @override
  Future<ui.Image?> getSelectionMask(Size canvasSize) async {
    if (_selectedPixels.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pixel in _selectedPixels) {
      canvas.drawRect(Rect.fromLTWH(pixel.dx, pixel.dy, 1, 1), paint);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }

  @override
  void clearSelection() {
    super.clearSelection();
    _selectedPixels.clear();
  }

  /// Get number of selected pixels
  int get selectionSize => _selectedPixels.length;
}
