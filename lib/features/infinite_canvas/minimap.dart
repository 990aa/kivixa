import 'package:flutter/material.dart';

class Minimap extends StatelessWidget {
  final TransformationController transformationController;
  final Size canvasSize;
  final Size minimapSize;

  const Minimap({
    super.key,
    required this.transformationController,
    required this.canvasSize,
    this.minimapSize = const Size(200, 200),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: minimapSize.width,
        height: minimapSize.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          color: Colors.grey[200]!.withAlpha((0.8 * 255).round()),
        ),
        child: CustomPaint(
          painter: _MinimapPainter(
            transformationController: transformationController,
            canvasSize: canvasSize,
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final TransformationController transformationController;
  final Size canvasSize;

  _MinimapPainter({
    required this.transformationController,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final matrix = transformationController.value;
    final invMatrix = Matrix4.inverted(matrix);
    final viewport = invMatrix.transformRect(Offset.zero & size);

    final paint = Paint()
      ..color = Colors.blue.withAlpha((0.5 * 255).round())
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        -viewport.left * scale,
        -viewport.top * scale,
        viewport.width * scale,
        viewport.height * scale,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
