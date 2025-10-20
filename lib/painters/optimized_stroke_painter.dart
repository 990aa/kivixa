import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../models/stroke.dart';

/// Performance-optimized painter that only renders visible strokes
class OptimizedStrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Rect viewport;
  final double zoom;

  OptimizedStrokePainter({
    required this.strokes,
    required this.viewport,
    this.zoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Get only visible strokes using spatial filtering
    final visibleStrokes = _getVisibleStrokes(viewport);

    // Render each visible stroke
    for (final stroke in visibleStrokes) {
      _drawStroke(canvas, stroke);
    }
  }

  /// Get strokes that overlap with the viewport
  List<Stroke> _getVisibleStrokes(Rect viewport) {
    return strokes.where((stroke) {
      // Calculate stroke bounds
      final bounds = _getStrokeBounds(stroke);

      // Check if stroke bounds overlap with viewport
      return viewport.overlaps(bounds);
    }).toList();
  }

  /// Calculate bounding rectangle for a stroke
  Rect _getStrokeBounds(Stroke stroke) {
    if (stroke.points.isEmpty) {
      return Rect.zero;
    }

    double minX = stroke.points.first.x;
    double maxX = stroke.points.first.x;
    double minY = stroke.points.first.y;
    double maxY = stroke.points.first.y;

    for (final point in stroke.points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    // Add padding for stroke width
    final padding = stroke.strokeWidth * 2;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// Draw a single stroke using perfect_freehand
  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // Use cached image if available (for better performance)
    if (stroke.cachedImage != null) {
      _drawCachedStroke(canvas, stroke);
      return;
    }

    // Generate outline using perfect_freehand with correct options
    final outlinePoints = getStroke(
      stroke.points,
      options: StrokeOptions(
        size: stroke.strokeWidth,
        thinning: 0.7,
        smoothing: 0.5,
        streamline: 0.5,
      ),
    );

    // Create path from outline points
    final path = Path();
    if (outlinePoints.isEmpty) return;

    path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
    for (int i = 1; i < outlinePoints.length; i++) {
      final point = outlinePoints[i];
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    // Configure paint
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Apply highlighter effect if needed
    if (stroke.isHighlighter) {
      paint.color = stroke.color.withValues(alpha: 0.3);
      paint.blendMode = BlendMode.multiply;
    }

    // Draw the stroke
    canvas.drawPath(path, paint);
  }

  /// Draw stroke using cached image (much faster for complex strokes)
  void _drawCachedStroke(Canvas canvas, Stroke stroke) {
    final image = stroke.cachedImage;
    if (image == null) return;

    final bounds = _getStrokeBounds(stroke);
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = bounds;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    if (stroke.isHighlighter) {
      paint.color = stroke.color.withValues(alpha: 0.3);
      paint.blendMode = BlendMode.multiply;
    }

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(OptimizedStrokePainter oldDelegate) {
    // Repaint if strokes changed or viewport changed significantly
    return oldDelegate.strokes != strokes ||
        !_viewportsAreClose(oldDelegate.viewport, viewport);
  }

  /// Check if two viewports are close enough to skip repainting
  bool _viewportsAreClose(Rect a, Rect b) {
    const threshold = 10.0; // pixels
    return (a.left - b.left).abs() < threshold &&
        (a.top - b.top).abs() < threshold &&
        (a.width - b.width).abs() < threshold &&
        (a.height - b.height).abs() < threshold;
  }
}

/// Extension to create a spatial index for faster stroke lookup
/// This is a simple implementation - for very large canvases, consider quadtree
extension StrokeSpatialIndex on List<Stroke> {
  /// Create a simple grid-based spatial index
  Map<String, List<Stroke>> createSpatialIndex({double cellSize = 500.0}) {
    final index = <String, List<Stroke>>{};

    for (final stroke in this) {
      final bounds = _getStrokeBounds(stroke);

      // Calculate which grid cells this stroke occupies
      final minCellX = (bounds.left / cellSize).floor();
      final maxCellX = (bounds.right / cellSize).floor();
      final minCellY = (bounds.top / cellSize).floor();
      final maxCellY = (bounds.bottom / cellSize).floor();

      // Add stroke to all cells it intersects
      for (int x = minCellX; x <= maxCellX; x++) {
        for (int y = minCellY; y <= maxCellY; y++) {
          final key = '$x,$y';
          index.putIfAbsent(key, () => []).add(stroke);
        }
      }
    }

    return index;
  }

  Rect _getStrokeBounds(Stroke stroke) {
    if (stroke.points.isEmpty) return Rect.zero;

    double minX = stroke.points.first.x;
    double maxX = stroke.points.first.x;
    double minY = stroke.points.first.y;
    double maxY = stroke.points.first.y;

    for (final point in stroke.points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    final padding = stroke.strokeWidth * 2;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }
}
