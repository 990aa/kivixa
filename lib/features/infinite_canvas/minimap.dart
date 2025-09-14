import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    // Assuming context.size is available or passed if needed,
    // but for minimap, it's transforming the InteractiveViewer's viewport
    // which is usually the full screen or available size.
    // If this 'size' (from paint method) is the minimap's own drawing area,
    // then we need to know what rect it's supposed to represent from the main canvas.
    // The original code used Offset.zero & size (of the CustomPaint area for minimap)
    // This seems correct for calculating the visible rect *within the minimap's own coordinate space*,
    // representing what the InteractiveViewer is showing.
    final viewport = MatrixUtils.transformRect(invMatrix, Offset.zero & size);

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
