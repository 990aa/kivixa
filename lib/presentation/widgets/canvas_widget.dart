// lib/presentation/widgets/canvas_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/note.dart';
import '../../application/drawing_provider.dart';

class CanvasWidget extends ConsumerStatefulWidget {
  final NotePage page;
  final int pageIndex;

  const CanvasWidget({
    super.key,
    required this.page,
    required this.pageIndex,
  });

  @override
  ConsumerState<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends ConsumerState<CanvasWidget> {
  final List<Offset> _currentPoints = [];

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingProvider);
    
    return Container(
      width: 595, // A4 width at 72 DPI
      height: 842, // A4 height at 72 DPI
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Page background template
          _buildPageTemplate(),
          // Existing strokes
          ...widget.page.strokes.map((stroke) => CustomPaint(
            painter: StrokePainter(stroke: stroke),
          )).toList(),
          // Current drawing stroke
          if (_currentPoints.isNotEmpty) CustomPaint(
            painter: CurrentStrokePainter(
              points: _currentPoints,
              tool: drawingState.selectedTool,
              color: drawingState.selectedColor,
              thickness: drawingState.thickness,
            ),
          ),
          // Gesture detector for drawing
          GestureDetector(
            onPanStart: (details) => _onPanStart(details, context),
            onPanUpdate: (details) => _onPanUpdate(details, context),
            onPanEnd: (details) => _onPanEnd(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTemplate() {
    switch (widget.page.template) {
      case PageTemplate.ruled:
        return _RuledTemplate();
      case PageTemplate.grid:
        return _GridTemplate();
      case PageTemplate.plain:
      default:
        return Container(color: Colors.white);
    }
  }

  void _onPanStart(DragStartDetails details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _currentPoints.add(localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _currentPoints.add(localPosition);
    });
  }

  void _onPanEnd() {
    if (_currentPoints.isNotEmpty) {
      final drawingState = ref.read(drawingProvider);
      final stroke = Stroke(
        tool: drawingState.selectedTool,
        points: List.from(_currentPoints),
        color: drawingState.selectedColor,
        thickness: drawingState.thickness,
        createdAt: DateTime.now(),
      );
      // Save stroke to state/provider
      _currentPoints.clear();
    }
  }
}

class StrokePainter extends CustomPainter {
  final Stroke stroke;

  StrokePainter({required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.tool == DrawingTool.highlighter) {
      paint.color = stroke.color.withOpacity(0.3);
      paint.blendMode = BlendMode.multiply;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CurrentStrokePainter extends CustomPainter {
  final List<Offset> points;
  final DrawingTool tool;
  final Color color;
  final double thickness;

  CurrentStrokePainter({
    required this.points,
    required this.tool,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (tool == DrawingTool.highlighter) {
      paint.color = color.withOpacity(0.3);
      paint.blendMode = BlendMode.multiply;
    }

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RuledTemplate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RuledLinePainter(),
    );
  }
}

class _GridTemplate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
    );
  }
}

class RuledLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    const lineSpacing = 20.0;
    for (var y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    
    // Vertical lines
    for (var x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}