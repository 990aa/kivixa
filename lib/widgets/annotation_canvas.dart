import 'package:flutter/material.dart';
import '../models/annotation_data.dart';
import '../models/annotation_layer.dart';
import '../models/drawing_tool.dart';

class AnnotationCanvas extends StatefulWidget {
  final AnnotationLayer annotationLayer;
  final int currentPage;
  final DrawingTool currentTool;
  final Color currentColor;
  final Size canvasSize;
  final VoidCallback onAnnotationsChanged;

  const AnnotationCanvas({
    super.key,
    required this.annotationLayer,
    required this.currentPage,
    required this.currentTool,
    required this.currentColor,
    required this.canvasSize,
    required this.onAnnotationsChanged,
  });

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  final List<Offset> _currentPoints = [];

  void _handlePanStart(DragStartDetails details) {
    if (widget.currentTool == DrawingTool.pen || widget.currentTool == DrawingTool.highlighter) {
       setState(() {
      _currentPoints.add(details.localPosition);
    });
    }

   
  }

  void _handlePanUpdate(DragUpdateDetails details) {
   if (widget.currentTool == DrawingTool.pen || widget.currentTool == DrawingTool.highlighter) {
       setState(() {
      _currentPoints.add(details.localPosition);
    });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if ((widget.currentTool == DrawingTool.pen || widget.currentTool == DrawingTool.highlighter) && _currentPoints.isNotEmpty) {
       final annotation = AnnotationData(
      points: List.from(_currentPoints),
      color: widget.currentColor,
      strokeWidth: widget.currentTool == DrawingTool.highlighter ? 12.0 : 4.0,
      tool: widget.currentTool,
      pageNumber: widget.currentPage,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    widget.annotationLayer.addAnnotation(annotation);
    _currentPoints.clear();
    widget.onAnnotationsChanged();
    }

   
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        size: widget.canvasSize,
        painter: _AnnotationPainter(
          annotations: widget.annotationLayer.getAnnotationsForPage(widget.currentPage),
          currentPoints: _currentPoints,
          currentColor: widget.currentColor,
          currentTool: widget.currentTool,
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<AnnotationData> annotations;
  final List<Offset> currentPoints;
  final Color currentColor;
  final DrawingTool currentTool;

  _AnnotationPainter({
    required this.annotations,
    required this.currentPoints,
    required this.currentColor,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      _drawAnnotation(canvas, annotation);
    }

    if (currentPoints.isNotEmpty) {
      _drawCurrentPath(canvas);
    }
  }

  void _drawAnnotation(Canvas canvas, AnnotationData annotation) {
    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (annotation.tool == DrawingTool.highlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    final path = Path();
    if (annotation.points.isNotEmpty) {
      path.moveTo(annotation.points.first.dx, annotation.points.first.dy);
      for (var i = 1; i < annotation.points.length; i++) {
        path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawCurrentPath(Canvas canvas) {
    final paint = Paint()
      ..color = currentColor
      ..strokeWidth = currentTool == DrawingTool.highlighter ? 12.0 : 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (currentTool == DrawingTool.highlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    final path = Path();
    if (currentPoints.isNotEmpty) {
      path.moveTo(currentPoints.first.dx, currentPoints.first.dy);
      for (var i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return oldDelegate.annotations.length != annotations.length ||
        oldDelegate.currentPoints.length != currentPoints.length;
  }
}
