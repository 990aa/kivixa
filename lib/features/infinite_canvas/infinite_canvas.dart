import 'package:flutter/material.dart';
import 'tile.dart';
import 'tile_manager.dart';
import 'minimap.dart';
import 'animated_background.dart';
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
