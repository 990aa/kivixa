import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/annotation_data.dart';
import '../models/annotation_layer.dart';
import '../models/drawing_tool.dart';
import '../painters/annotation_painter.dart';

/// Widget that captures touch/stylus input and renders annotations
/// 
/// This widget provides a drawing surface that:
/// - Captures MotionEvents from touch and stylus input
/// - Extracts pressure, tilt, and position data
/// - Renders smooth Bézier curves in real-time
/// - Supports pen, highlighter, and eraser tools
class AnnotationCanvas extends StatefulWidget {
  /// The annotation layer containing all strokes
  final AnnotationLayer annotationLayer;

  /// Current page number being annotated
  final int currentPage;

  /// Current drawing tool
  final DrawingTool currentTool;

  /// Current stroke color
  final Color currentColor;

  /// Callback when annotations change
  final VoidCallback? onAnnotationsChanged;

  /// Size of the canvas
  final Size canvasSize;

  const AnnotationCanvas({
    Key? key,
    required this.annotationLayer,
    required this.currentPage,
    this.currentTool = DrawingTool.pen,
    this.currentColor = Colors.black,
    this.onAnnotationsChanged,
    this.canvasSize = const Size(595, 842), // A4 size at 72 DPI
  }) : super(key: key);

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  /// Controller for managing drawing operations
  late AnnotationController _controller;

  /// Current stroke being drawn (for real-time rendering)
  AnnotationData? _currentStroke;

  /// Points in the current stroke
  final List<Offset> _currentStrokePoints = [];

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(AnnotationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller if tool or color changed
    if (oldWidget.currentTool != widget.currentTool) {
      _controller.setTool(widget.currentTool);
    }
    
    if (oldWidget.currentColor != widget.currentColor) {
      _controller.setColor(widget.currentColor);
    }
    
    if (oldWidget.currentPage != widget.currentPage) {
      _controller.setPage(widget.currentPage);
    }
  }

  void _initializeController() {
    _controller = AnnotationController(
      currentTool: widget.currentTool,
      currentColor: widget.currentColor,
      currentPage: widget.currentPage,
      onStrokeCompleted: _onStrokeCompleted,
    );
  }

  /// Called when a stroke is completed
  void _onStrokeCompleted(AnnotationData annotation) {
    // Add to annotation layer
    widget.annotationLayer.addAnnotation(annotation);
    
    // Clear current stroke
    setState(() {
      _currentStroke = null;
      _currentStrokePoints.clear();
    });

    // Notify changes
    widget.onAnnotationsChanged?.call();
  }

  /// Handles pointer down events (start of stroke)
  void _onPointerDown(PointerDownEvent event) {
    final localPosition = event.localPosition;
    
    // Get pressure from event (defaults to 1.0 for non-pressure devices)
    final pressure = event.pressure;
    
    // Start new stroke
    _currentStrokePoints.clear();
    _currentStrokePoints.add(localPosition);
    
    // Begin stroke in controller
    _controller.beginStroke(localPosition, pressure: pressure);
    
    // Create current stroke for real-time rendering
    setState(() {
      _currentStroke = AnnotationData(
        strokePath: List.from(_currentStrokePoints),
        colorValue: widget.currentColor.value,
        strokeWidth: _controller._getStrokeWidth(),
        toolType: widget.currentTool,
        pageNumber: widget.currentPage,
      );
    });
  }

  /// Handles pointer move events (drawing)
  void _onPointerMove(PointerMoveEvent event) {
    final localPosition = event.localPosition;
    final pressure = event.pressure;
    
    // Add point to current stroke
    _currentStrokePoints.add(localPosition);
    _controller.addPoint(localPosition, pressure: pressure);
    
    // Handle eraser tool
    if (widget.currentTool == DrawingTool.eraser) {
      _eraseAtPoint(localPosition);
    } else {
      // Update current stroke for real-time rendering
      setState(() {
        _currentStroke = AnnotationData(
          strokePath: List.from(_currentStrokePoints),
          colorValue: widget.currentColor.value,
          strokeWidth: _controller._getStrokeWidth(),
          toolType: widget.currentTool,
          pageNumber: widget.currentPage,
        );
      });
    }
  }

  /// Handles pointer up events (end of stroke)
  void _onPointerUp(PointerUpEvent event) {
    if (_currentStrokePoints.isEmpty) return;
    
    // End stroke in controller (will trigger onStrokeCompleted)
    if (widget.currentTool != DrawingTool.eraser) {
      _controller.endStroke();
    } else {
      // Clear current stroke for eraser
      setState(() {
        _currentStroke = null;
        _currentStrokePoints.clear();
      });
    }
  }

  /// Erases annotations within the eraser radius
  void _eraseAtPoint(Offset point) {
    const eraserRadius = 15.0; // Radius for eraser hit detection
    
    final pageAnnotations = widget.annotationLayer
        .getAnnotationsForPage(widget.currentPage);
    
    // Check each annotation to see if it intersects with eraser
    final toRemove = <AnnotationData>[];
    
    for (final annotation in pageAnnotations) {
      // Check if any point in the stroke is within eraser radius
      for (final strokePoint in annotation.strokePath) {
        final distance = (strokePoint - point).distance;
        if (distance <= eraserRadius) {
          toRemove.add(annotation);
          break;
        }
      }
    }
    
    // Remove intersecting annotations
    if (toRemove.isNotEmpty) {
      setState(() {
        for (final annotation in toRemove) {
          widget.annotationLayer.removeAnnotation(annotation);
        }
      });
      
      widget.onAnnotationsChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (event) => _onPointerUp(
        PointerUpEvent(
          timeStamp: event.timeStamp,
          pointer: event.pointer,
          kind: event.kind,
          device: event.device,
          position: event.position,
        ),
      ),
      child: CustomPaint(
        size: widget.canvasSize,
        painter: AnnotationPainter(
          annotations: widget.annotationLayer
              .getAnnotationsForPage(widget.currentPage),
          currentStroke: _currentStroke,
        ),
        child: Container(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          color: Colors.transparent,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
