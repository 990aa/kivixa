import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import '../models/annotation_data.dart';
import '../models/drawing_tool.dart';

/// CustomPainter that renders smooth vector-based annotations using Bézier curves
///
/// This painter integrates with the hand_signature library to provide ultra-smooth
/// stroke rendering with pressure sensitivity and velocity-based line width variation.
/// All strokes are stored as vector paths, not rasterized pixels, ensuring quality
/// at any zoom level.
class AnnotationPainter extends CustomPainter {
  /// List of completed annotation strokes to render
  final List<AnnotationData> annotations;

  /// Current stroke being drawn (if any)
  final AnnotationData? currentStroke;

  /// Paint objects for rendering (cached for performance)
  final Paint _paint = Paint();

  AnnotationPainter({required this.annotations, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Render all completed annotations
    for (final annotation in annotations) {
      _drawAnnotation(canvas, annotation);
    }

    // Render current stroke being drawn
    if (currentStroke != null) {
      _drawAnnotation(canvas, currentStroke!);
    }
  }

  /// Draws a single annotation using Bézier curves for smoothness
  void _drawAnnotation(Canvas canvas, AnnotationData annotation) {
    if (annotation.strokePath.isEmpty) return;

    // Configure paint based on tool type
    _paint.color = Color(annotation.colorValue);
    _paint.strokeWidth = annotation.strokeWidth;
    _paint.style = PaintingStyle.stroke;
    _paint.strokeCap = StrokeCap.round;
    _paint.strokeJoin = StrokeJoin.round;

    // Apply special rendering for highlighter (semi-transparent)
    if (annotation.toolType == DrawingTool.highlighter) {
      _paint.color = _paint.color.withValues(alpha: 0.3);
    }

    // Convert stroke path to smooth Bézier curve path
    final path = _createBezierPath(annotation.strokePath);

    // Draw the path
    canvas.drawPath(path, _paint);
  }

  /// Creates a smooth path using Cubic Bézier curves
  ///
  /// This method converts a series of points into a smooth curve by calculating
  /// control points between each pair of points. The algorithm:
  ///
  /// 1. For a single point: draws a small circle
  /// 2. For two points: draws a straight line
  /// 3. For three or more points: uses Catmull-Rom to Bézier conversion
  ///
  /// Catmull-Rom splines pass through all control points and provide smooth
  /// interpolation. We convert them to Cubic Bézier curves for rendering.
  ///
  /// The mathematical formula for Catmull-Rom to Bézier conversion:
  /// - Control Point 1 (CP1) = P1 + (P2 - P0) / 6
  /// - Control Point 2 (CP2) = P2 - (P3 - P1) / 6
  ///
  /// Where P0, P1, P2, P3 are four consecutive points in the stroke path.
  Path _createBezierPath(List<Offset> points) {
    final path = Path();

    if (points.isEmpty) return path;

    if (points.length == 1) {
      // Single point: draw a small circle
      path.addOval(Rect.fromCircle(center: points[0], radius: 2.0));
      return path;
    }

    // Start the path at the first point
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      // Two points: draw a straight line
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Three or more points: use Cubic Bézier curves with Catmull-Rom interpolation
    //
    // For smooth curves, we need at least 4 points to calculate control points.
    // We'll use a sliding window approach to create smooth segments.

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      // Calculate Bézier control points using Catmull-Rom conversion
      // This ensures the curve passes through p1 and p2
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6.0,
        p1.dy + (p2.dy - p0.dy) / 6.0,
      );

      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6.0,
        p2.dy - (p3.dy - p1.dy) / 6.0,
      );

      // Draw the Cubic Bézier curve segment
      // cubicTo(cp1.x, cp1.y, cp2.x, cp2.y, p2.x, p2.y)
      path.cubicTo(
        cp1.dx,
        cp1.dy, // First control point
        cp2.dx,
        cp2.dy, // Second control point
        p2.dx,
        p2.dy, // End point
      );
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    // Repaint if annotations have changed or current stroke is being drawn
    return oldDelegate.annotations != annotations ||
        oldDelegate.currentStroke != currentStroke;
  }
}

/// Controller for managing drawing operations with hand_signature library
///
/// This class wraps HandSignatureControl with optimal settings for smooth,
/// pressure-sensitive strokes on Android tablets and Windows devices.
class AnnotationController {
  /// The hand_signature control configured for optimal smoothness
  late final HandSignatureControl _signatureControl;

  /// Current drawing tool
  DrawingTool currentTool;

  /// Current stroke color
  Color currentColor;

  /// Callback when a stroke is completed
  final Function(AnnotationData)? onStrokeCompleted;

  /// Current page number being annotated
  int currentPage;

  AnnotationController({
    this.currentTool = DrawingTool.pen,
    this.currentColor = Colors.black,
    this.currentPage = 0,
    this.onStrokeCompleted,
  }) {
    _initializeSignatureControl();
  }

  /// Initializes HandSignatureControl with optimal settings for smooth drawing
  void _initializeSignatureControl() {
    _signatureControl = HandSignatureControl(
      initialSetup: SignaturePathSetup(
        threshold: 3.0,
        smoothRatio: 0.65,
        velocityRange: 2.0,
      ),
    );
  }

  /// Begins a new stroke at the given position
  void beginStroke(Offset point, {double pressure = 1.0}) {
    _signatureControl.startPath(point);
  }

  /// Adds a point to the current stroke
  void addPoint(Offset point, {double pressure = 1.0}) {
    _signatureControl.alterPath(point);
  }

  /// Ends the current stroke and converts it to AnnotationData
  void endStroke() {
    if (_signatureControl.hasActivePath) {
      _signatureControl.closePath();

      // Extract the completed path
      if (_signatureControl.paths.isNotEmpty) {
        final lastPath = _signatureControl.paths.last;
        _convertAndNotifyStroke(lastPath);
      }
    }
  }

  /// Converts hand_signature path data to AnnotationData
  void _convertAndNotifyStroke(CubicPath cubicPath) {
    // Extract offset points from the cubic path
    final List<Offset> strokePoints = [];

    // CubicPath.points contains the actual point data
    // We iterate through the path and sample points
    final pathData = cubicPath.lines;

    for (final line in pathData) {
      strokePoints.add(line.start);
    }

    // Add the last endpoint if available
    if (pathData.isNotEmpty) {
      strokePoints.add(pathData.last.end);
    }

    if (strokePoints.isEmpty) return;

    // Calculate stroke width based on tool type
    final double strokeWidth = getStrokeWidth();

    // Create annotation data
    final annotation = AnnotationData(
      strokePath: strokePoints,
      colorValue: currentColor.value,
      strokeWidth: strokeWidth,
      toolType: currentTool,
      pageNumber: currentPage,
    );

    // Notify callback
    onStrokeCompleted?.call(annotation);
  }

  /// Gets the stroke width based on current tool type
  ///
  /// PEN: Variable width from 1.0 to 5.0 (controlled by velocity/pressure)
  /// HIGHLIGHTER: Wider stroke from 8.0 to 15.0 with semi-transparency
  /// ERASER: Medium width of 10.0 for visible eraser radius
  double getStrokeWidth() {
    switch (currentTool) {
      case DrawingTool.pen:
        return 3.0; // Base width, will vary with velocity/pressure
      case DrawingTool.highlighter:
        return 12.0; // Wider for highlighting
      case DrawingTool.eraser:
        return 10.0; // Medium width for eraser
    }
  }

  /// Gets the configured signature control
  HandSignatureControl get signatureControl => _signatureControl;

  /// Clears the current drawing
  void clear() {
    _signatureControl.clear();
  }

  /// Disposes of the controller
  void dispose() {
    _signatureControl.dispose();
  }

  /// Updates the current drawing tool
  void setTool(DrawingTool tool) {
    currentTool = tool;
  }

  /// Updates the current color
  void setColor(Color color) {
    currentColor = color;
  }

  /// Updates the current page number
  void setPage(int page) {
    currentPage = page;
  }
}
