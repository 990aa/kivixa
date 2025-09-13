import 'package:flutter/material.dart';

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
      child: Stack(
        children: [
          if (_startHandlePosition != null && _endHandlePosition != null)
            CustomPaint(
              painter: _TextSelectionPainter(
                startHandlePosition: _startHandlePosition!,
                endHandlePosition: _endHandlePosition!,
              ),
            ),
        ],
      ),
    );
  }
}

class _TextSelectionPainter extends CustomPainter {
  final Offset startHandlePosition;
  final Offset endHandlePosition;

  _TextSelectionPainter({
    required this.startHandlePosition,
    required this.endHandlePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromPoints(startHandlePosition, endHandlePosition),
      paint,
    );

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
