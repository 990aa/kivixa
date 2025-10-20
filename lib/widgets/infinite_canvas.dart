import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../models/stroke.dart';
import '../models/canvas_element.dart';
import '../painters/infinite_canvas_painter.dart';

/// Infinite canvas widget with pan and zoom capabilities
class InfiniteCanvas extends StatefulWidget {
  final List<Stroke> initialStrokes;
  final List<CanvasElement> initialElements;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isHighlighter;
  final Function(List<Stroke>)? onStrokesChanged;
  final Function(List<CanvasElement>)? onElementsChanged;

  const InfiniteCanvas({
    super.key,
    this.initialStrokes = const [],
    this.initialElements = const [],
    this.currentColor = Colors.black,
    this.currentStrokeWidth = 4.0,
    this.isHighlighter = false,
    this.onStrokesChanged,
    this.onElementsChanged,
  });

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  final TransformationController _controller = TransformationController();
  List<Stroke> strokes = [];
  List<CanvasElement> elements = [];
  Offset canvasOffset = Offset.zero;
  bool isDrawing = false;
  List<Offset> currentPoints = [];

  @override
  void initState() {
    super.initState();
    strokes = List.from(widget.initialStrokes);
    elements = List.from(widget.initialElements);
  }

  // Public methods to add elements
  void addElement(CanvasElement element) {
    setState(() {
      elements.add(element);
      widget.onElementsChanged?.call(elements);
    });
  }

  void updateElement(CanvasElement updatedElement) {
    setState(() {
      final index = elements.indexWhere((e) => e.id == updatedElement.id);
      if (index != -1) {
        elements[index] = updatedElement;
        widget.onElementsChanged?.call(elements);
      }
    });
  }

  void removeElement(String elementId) {
    setState(() {
      elements.removeWhere((e) => e.id == elementId);
      widget.onElementsChanged?.call(elements);
    });
  }

  List<CanvasElement> getElements() => elements;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!isDrawing) {
      setState(() {
        isDrawing = true;
        currentPoints = [_transformPoint(event.localPosition)];
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (isDrawing) {
      setState(() {
        currentPoints.add(_transformPoint(event.localPosition));
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (isDrawing && currentPoints.isNotEmpty) {
      setState(() {
        // Convert Offset list to PointVector list for Stroke
        final points = currentPoints.map((offset) {
          return PointVector(offset.dx, offset.dy);
        }).toList();

        final newStroke = Stroke(
          points: points,
          color: widget.currentColor,
          strokeWidth: widget.currentStrokeWidth,
          isHighlighter: widget.isHighlighter,
        );

        strokes.add(newStroke);
        currentPoints = [];
        isDrawing = false;

        widget.onStrokesChanged?.call(strokes);
      });
    }
  }

  /// Transform point from screen coordinates to canvas coordinates
  Offset _transformPoint(Offset point) {
    final matrix = _controller.value.clone();
    matrix.invert();
    final transformed = MatrixUtils.transformPoint(matrix, point);
    return transformed;
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 10.0,
      panEnabled: !isDrawing,
      scaleEnabled: !isDrawing,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        child: CustomPaint(
          size: Size.infinite,
          painter: InfiniteCanvasPainter(
            strokes: strokes,
            currentPoints: currentPoints,
            gridEnabled: true,
            transform: _controller.value,
            currentColor: widget.currentColor,
            currentStrokeWidth: widget.currentStrokeWidth,
            isHighlighter: widget.isHighlighter,
          ),
        ),
      ),
    );
  }
}
