import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:kivixa/models/drawing_layer.dart';
import 'package:kivixa/models/layer_stroke.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/models/tiled_layer.dart';
import 'package:kivixa/models/dirty_region_tracker.dart';
import 'package:kivixa/services/layer_memory_manager.dart';

/// Example: Complete workflow for memory-optimized layer rendering
///
/// This demonstrates the full rendering cycle from user input to screen:
/// 1. User draws stroke
/// 2. Mark dirty regions
/// 3. Invalidate affected tiles
/// 4. Render only changed tiles
/// 5. Composite layers
/// 6. Display to screen

class MemoryOptimizedCanvasExample extends StatefulWidget {
  const MemoryOptimizedCanvasExample({super.key});

  @override
  State<MemoryOptimizedCanvasExample> createState() =>
      _MemoryOptimizedCanvasExampleState();
}

class _MemoryOptimizedCanvasExampleState
    extends State<MemoryOptimizedCanvasExample> {
  // Canvas state
  final List<DrawingLayer> _layers = [];
  late final LayerMemoryManager _memoryManager;
  var _activeLayerIndex = 0;

  // Drawing state
  final List<StrokePoint> _currentStrokePoints = [];
  var _isDrawing = false;

  // Viewport
  final Offset _viewportOffset = Offset.zero;
  final _viewportScale = 1.0;

  @override
  void initState() {
    super.initState();

    // Initialize with a large canvas (8192x8192)
    const canvasSize = Size(8192, 8192);

    // Create memory manager with auto-configuration
    _memoryManager = LayerMemoryManager(
      canvasSize: canvasSize,
      enableTiling: LayerMemoryManager.shouldEnableTiling(canvasSize),
      tileSize: LayerMemoryManager.getRecommendedTileSize(canvasSize),
      maxTilesPerLayer: 50,
    );

    // Create initial layer
    _layers.add(DrawingLayer(name: 'Background'));

    // Setup periodic maintenance
    _setupMaintenance();
  }

  void _setupMaintenance() {
    // Optimize dirty regions every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _memoryManager.optimizeDirtyRegions();
        _setupMaintenance();
      }
    });

    // Prune old tiles every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _memoryManager.pruneOldTiles(maxAge: const Duration(minutes: 5));
        _setupMaintenance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory-Optimized Canvas'),
        actions: [
          // Display memory stats
          _buildMemoryStats(),
        ],
      ),
      body: Stack(
        children: [
          // Main canvas
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: MemoryOptimizedCanvasPainter(
                layers: _layers,
                memoryManager: _memoryManager,
                viewportOffset: _viewportOffset,
                viewportScale: _viewportScale,
              ),
              size: Size.infinite,
            ),
          ),

          // Layer panel
          Positioned(right: 16, top: 16, child: _buildLayerPanel()),
        ],
      ),
    );
  }

  // Step 1: User starts drawing
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentStrokePoints.clear();

      // Convert screen coordinates to canvas coordinates
      final canvasPoint = _screenToCanvas(details.localPosition);

      _currentStrokePoints.add(
        StrokePoint(
          position: canvasPoint,
          pressure: 0.5, // Would detect stylus pressure in real app
        ),
      );
    });
  }

  // Step 2: User continues drawing
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    setState(() {
      final canvasPoint = _screenToCanvas(details.localPosition);

      _currentStrokePoints.add(
        StrokePoint(
          position: canvasPoint,
          pressure: 0.8, // Would come from stylus in real app
        ),
      );

      // Mark dirty region for the new segment
      final dirtyRect = DirtyRegionTracker.fromPoints(
        _currentStrokePoints.map((p) => p.position).toList(),
        4.0,
      );

      _memoryManager.dirtyTracker.markDirty(dirtyRect);
    });
  }

  // Step 3: User completes stroke
  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;

      if (_currentStrokePoints.isNotEmpty) {
        // Create final stroke
        final stroke = LayerStroke(
          points: List.from(_currentStrokePoints),
          brushProperties: Paint()
            ..color = Colors.black
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..blendMode = BlendMode.srcOver,
        );

        // Add to active layer
        final activeLayer = _layers[_activeLayerIndex];
        activeLayer.addStroke(stroke);

        // Mark dirty and invalidate tiles
        _memoryManager.markStrokeDirty(stroke, activeLayer.id);

        // Invalidate layer cache
        activeLayer.invalidateCache();
      }

      _currentStrokePoints.clear();
    });
  }

  Offset _screenToCanvas(Offset screenPoint) {
    return (screenPoint - _viewportOffset) / _viewportScale;
  }

  Widget _buildMemoryStats() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final stats = _memoryManager.getStats();
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Memory: ${stats.memoryMB.toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                'Tiles: ${stats.totalCachedTiles}',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                'Dirty: ${stats.isFullyDirty ? "All" : stats.dirtyRegionCount}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayerPanel() {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Layers', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final entry in _layers.asMap().entries)
              Builder(
                builder: (context) {
                  final index = entry.key;
                  final layer = entry.value;
                  return ListTile(
                    title: Text(layer.name),
                    selected: index == _activeLayerIndex,
                    onTap: () {
                      setState(() {
                        _activeLayerIndex = index;
                      });
                    },
                    trailing: Text(
                      '${layer.strokes.length} strokes',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _memoryManager.dispose();
    super.dispose();
  }
}

/// Custom painter with memory optimization
class MemoryOptimizedCanvasPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final LayerMemoryManager memoryManager;
  final Offset viewportOffset;
  final double viewportScale;

  MemoryOptimizedCanvasPainter({
    required this.layers,
    required this.memoryManager,
    required this.viewportOffset,
    required this.viewportScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate viewport in canvas coordinates
    final viewport = _getCanvasViewport(size);

    // Check if we need to repaint
    if (!memoryManager.needsRepaint(viewport)) {
      return; // No changes, skip rendering
    }

    // Apply viewport transformation
    canvas.save();
    canvas.translate(viewportOffset.dx, viewportOffset.dy);
    canvas.scale(viewportScale);

    // Paint each layer
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Use saveLayer for blend modes and opacity
      canvas.saveLayer(
        viewport,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Color.fromRGBO(255, 255, 255, layer.opacity),
      );

      // Paint layer strokes
      _paintLayer(canvas, layer, viewport);

      canvas.restore();
    }

    canvas.restore();

    // Clear dirty regions after painting
    memoryManager.clearDirty();
  }

  void _paintLayer(Canvas canvas, DrawingLayer layer, ui.Rect viewport) {
    // Option 1: Tile-based rendering (for large canvases)
    if (memoryManager.enableTiling) {
      _paintLayerTiled(canvas, layer, viewport);
    } else {
      // Option 2: Direct rendering (for small canvases)
      _paintLayerDirect(canvas, layer, viewport);
    }
  }

  void _paintLayerTiled(Canvas canvas, DrawingLayer layer, ui.Rect viewport) {
    final tileSystem = memoryManager.getTileSystem(layer.id);
    final visibleTiles = tileSystem.getVisibleTiles(viewport);

    for (final tileCoord in visibleTiles) {
      // Get cached tile or render it
      final cachedTile = tileSystem.getTile(tileCoord.x, tileCoord.y);

      if (cachedTile != null) {
        // Draw cached tile
        final tileBounds = tileSystem.getTileBounds(tileCoord.x, tileCoord.y);
        canvas.drawImage(cachedTile, tileBounds.topLeft, Paint());
      } else {
        // Render tile (in real implementation, this would be async)
        // For now, just draw strokes directly
        _paintTileStrokes(canvas, layer, tileCoord, tileSystem);
      }
    }
  }

  void _paintTileStrokes(
    Canvas canvas,
    DrawingLayer layer,
    TileCoordinate tileCoord,
    TiledLayer tileSystem,
  ) {
    final tileBounds = tileSystem.getTileBounds(tileCoord.x, tileCoord.y);

    // Only draw strokes that intersect this tile
    for (final stroke in layer.strokes) {
      final strokeBounds = stroke.getBounds();
      if (strokeBounds.overlaps(tileBounds)) {
        _drawStroke(canvas, stroke);
      }
    }
  }

  void _paintLayerDirect(Canvas canvas, DrawingLayer layer, ui.Rect viewport) {
    // Only draw strokes visible in viewport
    for (final stroke in layer.strokes) {
      final strokeBounds = stroke.getBounds();
      if (strokeBounds.overlaps(viewport)) {
        _drawStroke(canvas, stroke);
      }
    }
  }

  void _drawStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();
    path.moveTo(
      stroke.points.first.position.dx,
      stroke.points.first.position.dy,
    );

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      path.lineTo(point.position.dx, point.position.dy);
    }

    canvas.drawPath(path, stroke.brushProperties);
  }

  ui.Rect _getCanvasViewport(Size screenSize) {
    final topLeft = (Offset.zero - viewportOffset) / viewportScale;
    final bottomRight =
        (Offset(screenSize.width, screenSize.height) - viewportOffset) /
        viewportScale;

    return ui.Rect.fromPoints(topLeft, bottomRight);
  }

  @override
  bool shouldRepaint(MemoryOptimizedCanvasPainter oldDelegate) {
    // Repaint if we have dirty regions
    return memoryManager.dirtyTracker.hasDirtyRegions ||
        viewportOffset != oldDelegate.viewportOffset ||
        viewportScale != oldDelegate.viewportScale;
  }
}
