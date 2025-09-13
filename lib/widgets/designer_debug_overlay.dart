import 'package:flutter/material.dart';

class DesignerDebugOverlay extends StatelessWidget {
  final Widget child;
  final bool showSpacing;
  final bool showColors;
  final bool showAnimationTimings;

  const DesignerDebugOverlay({
    super.key,
    required this.child,
    this.showSpacing = false,
    this.showColors = false,
    this.showAnimationTimings = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showSpacing)
          IgnorePointer(
            child: CustomPaint(painter: _SpacingPainter(), child: Container()),
          ),
        if (showColors)
          IgnorePointer(
            child: Container(color: Colors.purple.withOpacity(0.05)),
          ),
        if (showAnimationTimings)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.7),
              child: const Text(
                'Animation: 400ms',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpacingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
