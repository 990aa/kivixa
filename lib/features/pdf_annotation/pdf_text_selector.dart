import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'annotation_toolbar.dart';

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
    _extractText();
  }

  Future<void> _extractText() async {
    final file = File(widget.pdfPath);
    final document = pw.Document();
    final pdf = PdfDocument.openFile(widget.pdfPath);
    final page = await pdf.getPage(1);
    final content = await page.getText();
    // This is a simplified text extraction. A more robust solution would
    // involve a more sophisticated PDF parsing library.
    final lines = content.split('\n');
    final textLines = <_TextLine>[];
    double y = 0;
    for (final line in lines) {
      textLines.add(_TextLine(line, Rect.fromLTWH(0, y, widget.pageSize.width, 20)));
      y += 20;
    }
    setState(() {
      _textLines = textLines;
    });
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
          _selectionRect = Rect.fromPoints(_startHandlePosition!, _endHandlePosition!)
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
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final selectionRect = Rect.fromPoints(startHandlePosition, endHandlePosition);

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
