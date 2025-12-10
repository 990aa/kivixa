import 'dart:convert';

import 'package:flutter/material.dart';

/// A simple point with pressure for handwriting
class QuickNotePoint {
  const QuickNotePoint(this.x, this.y, [this.pressure = 1.0]);

  final double x;
  final double y;
  final double pressure;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure};

  factory QuickNotePoint.fromJson(Map<String, dynamic> json) {
    return QuickNotePoint(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['p'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Offset toOffset() => Offset(x, y);
}

/// A single stroke in a quick note
class QuickNoteStroke {
  QuickNoteStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  final List<QuickNotePoint> points;
  final Color color;
  final double strokeWidth;

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  factory QuickNoteStroke.fromJson(Map<String, dynamic> json) {
    return QuickNoteStroke(
      points: (json['points'] as List)
          .map((p) => QuickNotePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
    );
  }

  Path toPath() {
    if (points.isEmpty) return Path();

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    return path;
  }
}

/// Data model for quick note handwriting
class QuickNoteHandwritingData {
  QuickNoteHandwritingData({List<QuickNoteStroke>? strokes})
    : strokes = strokes ?? [];

  final List<QuickNoteStroke> strokes;

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  factory QuickNoteHandwritingData.fromJsonString(String json) {
    return QuickNoteHandwritingData.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  factory QuickNoteHandwritingData.fromJson(Map<String, dynamic> json) {
    return QuickNoteHandwritingData(
      strokes:
          (json['strokes'] as List?)
              ?.map((s) => QuickNoteStroke.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isEmpty => strokes.isEmpty;
  bool get isNotEmpty => strokes.isNotEmpty;
}

/// A simple canvas for quick handwritten notes
class QuickNoteCanvas extends StatefulWidget {
  const QuickNoteCanvas({
    super.key,
    this.initialData,
    this.onChanged,
    this.height = 150,
    this.strokeColor,
    this.strokeWidth = 2.0,
    this.backgroundColor,
    this.readOnly = false,
  });

  final QuickNoteHandwritingData? initialData;
  final ValueChanged<QuickNoteHandwritingData>? onChanged;
  final double height;
  final Color? strokeColor;
  final double strokeWidth;
  final Color? backgroundColor;
  final bool readOnly;

  @override
  State<QuickNoteCanvas> createState() => QuickNoteCanvasState();
}

class QuickNoteCanvasState extends State<QuickNoteCanvas> {
  late QuickNoteHandwritingData _data;
  QuickNoteStroke? _currentStroke;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? QuickNoteHandwritingData();
  }

  QuickNoteHandwritingData get data => _data;

  void clear() {
    setState(() {
      _data = QuickNoteHandwritingData();
      _currentStroke = null;
    });
    widget.onChanged?.call(_data);
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.readOnly) return;

    final colorScheme = ColorScheme.of(context);
    final point = QuickNotePoint(
      details.localPosition.dx,
      details.localPosition.dy,
    );

    setState(() {
      _currentStroke = QuickNoteStroke(
        points: [point],
        color: widget.strokeColor ?? colorScheme.onSurface,
        strokeWidth: widget.strokeWidth,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.readOnly || _currentStroke == null) return;

    final point = QuickNotePoint(
      details.localPosition.dx,
      details.localPosition.dy,
    );

    setState(() {
      _currentStroke!.points.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.readOnly || _currentStroke == null) return;

    setState(() {
      _data.strokes.add(_currentStroke!);
      _currentStroke = null;
    });

    widget.onChanged?.call(_data);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: CustomPaint(
            painter: _QuickNotePainter(
              strokes: _data.strokes,
              currentStroke: _currentStroke,
              defaultColor: widget.strokeColor ?? colorScheme.onSurface,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _QuickNotePainter extends CustomPainter {
  _QuickNotePainter({
    required this.strokes,
    this.currentStroke,
    required this.defaultColor,
  });

  final List<QuickNoteStroke> strokes;
  final QuickNoteStroke? currentStroke;
  final Color defaultColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, QuickNoteStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      // Single point - draw a dot
      canvas.drawCircle(
        stroke.points.first.toOffset(),
        stroke.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Draw the path
    final path = stroke.toPath();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuickNotePainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentStroke != oldDelegate.currentStroke;
  }
}

/// A read-only preview of handwriting data
class QuickNoteHandwritingPreview extends StatelessWidget {
  const QuickNoteHandwritingPreview({
    super.key,
    required this.data,
    this.height = 60,
    this.backgroundColor,
  });

  final QuickNoteHandwritingData data;
  final double height;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 300,
            height: 150,
            child: CustomPaint(
              painter: _QuickNotePainter(
                strokes: data.strokes,
                currentStroke: null,
                defaultColor: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
