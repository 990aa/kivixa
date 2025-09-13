import 'package:flutter/material.dart';
import 'tile.dart';
import 'tile_manager.dart';
import 'minimap.dart';
import 'dart:math';

class InfiniteCanvas extends StatefulWidget {
  const InfiniteCanvas({super.key});

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  final TransformationController _transformationController = TransformationController();
  final TileManager _tileManager = TileManager();
  final Size _canvasSize = const Size(20000, 20000);

  @override
  void initState() {
    super.initState();
    _tileManager.addListener(_onTilesChanged);
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _tileManager.removeListener(_onTilesChanged);
    _transformationController.removeListener(_onTransformChanged);
    _tileManager.dispose();
    super.dispose();
  }

  void _onTilesChanged() {
    setState(() {});
  }

  void _onTransformChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          onInteractionUpdate: (details) {
            final viewport = _getViewport();
            _tileManager.updateVisibleTiles(viewport);
          },
          child: Stack(
            children: [
              CustomPaint(
                size: _canvasSize,
                painter: _InfiniteCanvasPainter(),
              ),
              ..._tileManager.visibleTiles.map((tile) {
                return Tile(
                  size: _tileManager.tileSize,
                  x: tile.x,
                  y: tile.y,
                );
              }),
            ],
          ),
        ),
        Minimap(
          transformationController: _transformationController,
          canvasSize: _canvasSize,
        ),
      ],
    );
  }

  Rect _getViewport() {
    final matrix = _transformationController.value;
    final invMatrix = Matrix4.inverted(matrix);
    final viewport = invMatrix.transformRect(Offset.zero & context.size!);
    return viewport;
  }
}

class _InfiniteCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw a grid
    for (var i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    for (var i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
