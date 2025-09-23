import 'package:flutter/material.dart';

enum PaperType { blank, lined, grid }

class PaperBackground extends StatelessWidget {
  final PaperType paperType;

  const PaperBackground({super.key, this.paperType = PaperType.blank});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PaperPainter(paperType), child: Container());
  }
}

class _PaperPainter extends CustomPainter {
  final PaperType paperType;

  _PaperPainter(this.paperType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha((255 * 0.5).round())
      ..strokeWidth = 1.0;

    if (paperType == PaperType.lined) {
      for (var i = 0.0; i < size.height; i += 24.0) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    } else if (paperType == PaperType.grid) {
      for (var i = 0.0; i < size.width; i += 24.0) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      }
      for (var i = 0.0; i < size.height; i += 24.0) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
