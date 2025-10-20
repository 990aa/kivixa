import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../models/stroke.dart';

class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;

  StrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.cachedImage != null) {
        canvas.drawImage(stroke.cachedImage!, Offset.zero, Paint());
      } else {
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.strokeWidth
          ..style = PaintingStyle.fill;

        final outlinePoints = getStroke(stroke.points,
            options: StrokeOptions(size: stroke.strokeWidth));

        final path = Path();
        if (outlinePoints.isNotEmpty) {
          path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
          for (var i = 1; i < outlinePoints.length; i++) {
            path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
          }
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    return true;
  }
}
