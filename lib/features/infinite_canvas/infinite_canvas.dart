import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'tile.dart';
import 'tile_manager.dart';
import 'minimap.dart';
import 'animated_background.dart';

class InfiniteCanvas extends StatefulWidget {
  const InfiniteCanvas({super.key});

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  final TransformationController _transformationController =
      TransformationController();
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
    final viewport = _getViewport();
    final scale = _transformationController.value.getMaxScaleOnAxis();
    _tileManager.updateVisibleTiles(viewport, scale);
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
          onInteractionEnd: (details) {
            final viewport = _getViewport();
            final scale = _transformationController.value.getMaxScaleOnAxis();
            _tileManager.updateVisibleTiles(viewport, scale);
          },
          child: Stack(
            children: [
              const AnimatedBackground(),
              ..._tileManager.visibleTiles.map((tile) {
                return Tile(
                  size: _tileManager.tileSize,
                  x: tile.x,
                  y: tile.y,
                  scale: _tileManager.scale,
                );
              }),
              CustomPaint(
                size: _canvasSize,
                painter: _BoundaryPainter(
                  viewport: _getViewport(),
                  canvasSize: _canvasSize,
                ),
              ),
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
    final viewport = MatrixUtils.transformRect(
      invMatrix,
      Offset.zero & context.size!,
    );
    return viewport;
  }
}

class _BoundaryPainter extends CustomPainter {
  final Rect viewport;
  final Size canvasSize;

  _BoundaryPainter({required this.viewport, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final double leftProximity = (viewport.left / 1000).clamp(0.0, 1.0);
    final double topProximity = (viewport.top / 1000).clamp(0.0, 1.0);
    final double rightProximity = ((canvasSize.width - viewport.right) / 1000)
        .clamp(0.0, 1.0);
    final double bottomProximity =
        ((canvasSize.height - viewport.bottom) / 1000).clamp(0.0, 1.0);

    if (viewport.left < 1000) {
      paint.strokeWidth = 5 * (1 - leftProximity);
      canvas.drawLine(const Offset(0, 0), Offset(0, canvasSize.height), paint);
    }
    if (viewport.top < 1000) {
      paint.strokeWidth = 5 * (1 - topProximity);
      canvas.drawLine(const Offset(0, 0), Offset(canvasSize.width, 0), paint);
    }
    if (viewport.right > canvasSize.width - 1000) {
      paint.strokeWidth = 5 * (1 - rightProximity);
      canvas.drawLine(
        Offset(canvasSize.width, 0),
        Offset(canvasSize.width, canvasSize.height),
        paint,
      );
    }
    if (viewport.bottom > canvasSize.height - 1000) {
      paint.strokeWidth = 5 * (1 - bottomProximity);
      canvas.drawLine(
        Offset(0, canvasSize.height),
        Offset(canvasSize.width, canvasSize.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
