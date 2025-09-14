import 'package:flutter/material.dart';
import 'annotation_toolbar.dart';

// Now using pdfx for PDF parsing and text extraction

class PdfTextSelector extends StatefulWidget {
  final String pdfPath;
  final Size pageSize;

  const PdfTextSelector({
    super.key,
    required this.pdfPath,
    required this.pageSize,
  });

  @override
  State<PdfTextSelector> createState() => _PdfTextSelectorState();
}

class _PdfTextSelectorState extends State<PdfTextSelector> {
  Offset? _startHandlePosition;
  Offset? _endHandlePosition;
  List<_TextLine> _textLines = [];
  Rect? _selectionRect;

  @override
  void initState() {
    super.initState();
    // Visual selection only: create a grid of rectangles as mock text lines
    final textLines = <_TextLine>[];
    double y = 0;
    for (int i = 0; i < 20; i++) {
      textLines.add(
        _TextLine(
          'Line ${i + 1}',
          Rect.fromLTWH(0, y, widget.pageSize.width, 20),
        ),
      );
      y += 20;
    }
    _textLines = textLines;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        setState(() {
          _startHandlePosition = details.localPosition;
          _endHandlePosition = details.localPosition;
        });
      },
      onLongPressMoveUpdate: (details) {
        setState(() {
          _endHandlePosition = details.localPosition;
        });
      },
      onLongPressEnd: (details) {
        setState(() {
          _selectionRect = Rect.fromPoints(
            _startHandlePosition!,
            _endHandlePosition!,
          );
        });
      },
      child: Stack(
        children: [
          if (_startHandlePosition != null && _endHandlePosition != null)
            CustomPaint(
              painter: _TextSelectionPainter(
                startHandlePosition: _startHandlePosition!,
                endHandlePosition: _endHandlePosition!,
                textLines: _textLines,
              ),
            ),
          if (_selectionRect != null)
            AnnotationToolbar(
              selectionRect: _selectionRect!,
              onHighlight: () {},
              onUnderline: () {},
              onAddNote: () {},
            ),
        ],
      ),
    );
  }
}

// Removed class openFile {}

class _TextSelectionPainter extends CustomPainter {
  final Offset startHandlePosition;
  final Offset endHandlePosition;
  final List<_TextLine> textLines;

  _TextSelectionPainter({
    required this.startHandlePosition,
    required this.endHandlePosition,
    required this.textLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
          .withAlpha((0.5 * 255).round()) // Replaced withOpacity
      ..style = PaintingStyle.fill;

    final selectionRect = Rect.fromPoints(
      startHandlePosition,
      endHandlePosition,
    );

    for (final line in textLines) {
      if (line.bounds.overlaps(selectionRect)) {
        canvas.drawRect(line.bounds, paint);
      }
    }

    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(startHandlePosition, 8.0, handlePaint);
    canvas.drawCircle(endHandlePosition, 8.0, handlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _TextLine {
  final String text;
  final Rect bounds;

  _TextLine(this.text, this.bounds);
}
