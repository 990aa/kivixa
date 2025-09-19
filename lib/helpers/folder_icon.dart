import 'dart:math';
import 'package:flutter/material.dart';

class FolderPainter extends CustomPainter {
  final Color folderColor;

  FolderPainter(this.folderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = folderColor;

    // Folder body
    final folderBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 20, size.width, size.height - 20),
      const Radius.circular(12),
    );
    canvas.drawRRect(folderBody, paint);

    // Tab on top-left
    final tabWidth = size.width * 0.3;
    final tabHeight = 20.0;
    final tabPath = Path()
      ..moveTo(0, 0)
      ..lineTo(tabWidth, 0)
      ..lineTo(tabWidth, tabHeight)
      ..lineTo(0, tabHeight)
      ..close();
    canvas.drawPath(tabPath, paint);

    // Thread lock
    final buttonPaint = Paint()..color = Colors.black;
    final threadPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final topY = size.height * 0.45;
    final bottomY = size.height * 0.55;
    final buttonRadius = 6.0;

    // Buttons
    canvas.drawCircle(Offset(centerX, topY), buttonRadius, buttonPaint);
    canvas.drawCircle(Offset(centerX, bottomY), buttonRadius, buttonPaint);

    // Thread connecting both buttons
    canvas.drawLine(
      Offset(centerX - 12, topY),
      Offset(centerX + 12, bottomY),
      threadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FolderIcon extends StatelessWidget {
  final Color folderColor;

  const FolderIcon({super.key, required this.folderColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 140),
      painter: FolderPainter(folderColor),
    );
  }
}

Color getRandomColor() {
  final random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(200) + 30, // Avoid overly dark colors
    random.nextInt(200) + 30,
    random.nextInt(200) + 30,
  );
}
