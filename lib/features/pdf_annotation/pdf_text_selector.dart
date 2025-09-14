import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart'; // This is for creating PDFs, not reading existing ones
import 'package:native_pdf_renderer/native_pdf_renderer.dart' as pdf_render;
// This is for creating PDFs
import 'annotation_toolbar.dart';

// TODO: Import a PDF parsing library that provides PdfDocument.openFile
// e.g., import 'package:native_pdf_renderer/native_pdf_renderer.dart' as pdf_render;
// Then use: final pdf = await pdf_render.PdfDocument.openFile(widget.pdfPath);

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
    // final file = File(widget.pdfPath); // File object already available via path
    // final document = pw.Document(); // This is for creating PDFs
    
    // The line below will cause an error until you add a PDF parsing library
    // that provides PdfDocument.openFile and import it.
    // For example, if using native_pdf_renderer aliased as pdf_render:
    // final pdf_render.PdfDocument pdf = await pdf_render.PdfDocument.openFile(widget.pdfPath);
    // Or, if your chosen library's PdfDocument doesn't clash, it might be:
    // final PdfDocument pdf = await PdfDocument.openFile(widget.pdfPath);
    
    // Use native_pdf_renderer to open the PDF file
    final pdf = await pdf_render.PdfDocument.openFile(widget.pdfPath);
    final page = await pdf.getPage(1);
    final content = await page.text;
    // This is a simplified text extraction. A more robust solution would
    // involve a more sophisticated PDF parsing library.
    final lines = content?.split('\n') ?? [];
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
          _selectionRect = Rect.fromPoints(_startHandlePosition!, _endHandlePosition!);
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
      ..color = Colors.blue.withAlpha((0.5 * 255).round()) // Replaced withOpacity
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
