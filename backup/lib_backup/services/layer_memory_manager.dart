import 'dart:ui' as ui;
import 'package:kivixa/models/tiled_layer.dart';
import 'package:kivixa/models/dirty_region_tracker.dart';
import 'package:kivixa/models/drawing_layer.dart';
import 'package:kivixa/models/layer_stroke.dart';

/// Central memory management for layer rendering
/// Coordinates tile caching and dirty region tracking
class LayerMemoryManager {
  /// Tile systems for each layer
  final Map<String, TiledLayer> _layerTiles = {};

  /// Dirty region tracker for the canvas
  final DirtyRegionTracker dirtyTracker;

  /// Canvas size for viewport calculations
  ui.Size _canvasSize;

  /// Whether tiled rendering is enabled
  final bool enableTiling;

  /// Tile size (must match TiledLayer)
  final int tileSize;

  /// Maximum cached tiles per layer
  final int maxTilesPerLayer;

  LayerMemoryManager({
    required ui.Size canvasSize,
    this.enableTiling = true,
    this.tileSize = 512,
    this.maxTilesPerLayer = 50,
    DirtyRegionTracker? dirtyTracker,
  }) : _canvasSize = canvasSize,
       dirtyTracker = dirtyTracker ?? DirtyRegionTracker();

  /// Update canvas size
  void setCanvasSize(ui.Size size) {
    if (_canvasSize != size) {
      _canvasSize = size;
      // Invalidate all tiles since canvas changed
      invalidateAllLayers();
      dirtyTracker.markAllDirty();
    }
  }

  /// Get or create tile system for a layer
  TiledLayer getTileSystem(String layerId) {
    return _layerTiles.putIfAbsent(
      layerId,
      () => TiledLayer(
        layerId: layerId,
        tileSize: tileSize,
        maxCachedTiles: maxTilesPerLayer,
      ),
    );
  }

  /// Mark a stroke as dirty (call when stroke is added/modified)
  void markStrokeDirty(LayerStroke stroke, String layerId) {
    final bounds = stroke.getBounds();
    final dirtyRect = DirtyRegionTracker.fromStrokeBounds(
      bounds,
      stroke.brushProperties.strokeWidth,
    );

    dirtyTracker.markDirty(dirtyRect);

    // Invalidate affected tiles
    if (enableTiling) {
      final tiles = getTileSystem(layerId);
      tiles.invalidateRegion(dirtyRect);
    }
  }

  /// Mark a layer as dirty (call when layer properties change)
  void markLayerDirty(DrawingLayer layer) {
    // If bounds are known, use them
    if (layer.bounds != null) {
      dirtyTracker.markDirty(layer.bounds!);

      if (enableTiling) {
        final tiles = getTileSystem(layer.id);
        tiles.invalidateRegion(layer.bounds!);
      }
    } else {
      // No bounds, invalidate entire layer
      invalidateLayer(layer.id);
      dirtyTracker.markAllDirty();
    }
  }

  /// Mark entire canvas as dirty
  void markCanvasDirty() {
    dirtyTracker.markAllDirty();
    if (enableTiling) {
      for (final tiles in _layerTiles.values) {
        tiles.invalidateAll();
      }
    }
  }

  /// Invalidate a specific layer's cache
  void invalidateLayer(String layerId) {
    if (enableTiling) {
      final tiles = _layerTiles[layerId];
      tiles?.invalidateAll();
    }

    // Mark the entire canvas dirty since we don't know layer bounds
    dirtyTracker.markAllDirty();
  }

  /// Invalidate all layers
  void invalidateAllLayers() {
    if (enableTiling) {
      for (final tiles in _layerTiles.values) {
        tiles.invalidateAll();
      }
    }
    dirtyTracker.markAllDirty();
  }

  /// Check if viewport needs repainting
  bool needsRepaint(ui.Rect viewport) {
    return dirtyTracker.needsRepaint(viewport);
  }

  /// Get visible tiles for a layer in the current viewport
  List<TileCoordinate> getVisibleTiles(String layerId, ui.Rect viewport) {
    if (!enableTiling) return [];

    final tiles = getTileSystem(layerId);
    return tiles.getVisibleTiles(viewport);
  }

  /// Get tiles that need to be rendered for a layer
  List<TileCoordinate> getTilesToRender(String layerId, ui.Rect viewport) {
    if (!enableTiling) return [];

    final tiles = getTileSystem(layerId);
    final visible = tiles.getVisibleTiles(viewport);

    // Filter to only uncached tiles
    return visible.where((coord) {
      return !tiles.hasTile(coord.x, coord.y);
    }).toList();
  }

  /// Prefetch tiles around viewport for smooth scrolling
  List<TileCoordinate> getPrefetchTiles(
    String layerId,
    ui.Rect viewport, {
    int radius = 1,
  }) {
    if (!enableTiling) return [];

    final tiles = getTileSystem(layerId);
    return tiles.getPrefetchTiles(viewport, radius);
  }

  /// Clear dirty regions after repaint
  void clearDirty() {
    dirtyTracker.clearDirty();
  }

  /// Optimize dirty regions by merging nearby rectangles
  void optimizeDirtyRegions() {
    dirtyTracker.optimize();
  }

  /// Prune old cached tiles to free memory
  void pruneOldTiles({Duration maxAge = const Duration(minutes: 5)}) {
    if (!enableTiling) return;

    for (final tiles in _layerTiles.values) {
      tiles.pruneOldTiles(maxAge);
    }
  }

  /// Get memory usage statistics
  MemoryManagerStats getStats() {
    int totalTiles = 0;
    int totalMemoryBytes = 0;

    if (enableTiling) {
      for (final tiles in _layerTiles.values) {
        final stats = tiles.getStats();
        totalTiles += stats.cachedTileCount;
        totalMemoryBytes += stats.estimatedMemoryBytes;
      }
    }

    return MemoryManagerStats(
      layerCount: _layerTiles.length,
      totalCachedTiles: totalTiles,
      estimatedMemoryBytes: totalMemoryBytes,
      dirtyRegionCount: dirtyTracker.dirtyRegionCount,
      isFullyDirty: dirtyTracker.isFullyDirty,
      tilingEnabled: enableTiling,
    );
  }

  /// Get detailed stats for a specific layer
  TileCacheStats? getLayerStats(String layerId) {
    if (!enableTiling) return null;

    final tiles = _layerTiles[layerId];
    return tiles?.getStats();
  }

  /// Remove a layer's tile system (call when layer is deleted)
  void removeLayer(String layerId) {
    if (enableTiling) {
      final tiles = _layerTiles.remove(layerId);
      tiles?.dispose();
    }
  }

  /// Dispose all resources
  void dispose() {
    if (enableTiling) {
      for (final tiles in _layerTiles.values) {
        tiles.dispose();
      }
      _layerTiles.clear();
    }
    dirtyTracker.clearDirty();
  }

  /// Get recommended tile size based on canvas size
  static int getRecommendedTileSize(ui.Size canvasSize) {
    final maxDimension = canvasSize.width > canvasSize.height
        ? canvasSize.width
        : canvasSize.height;

    // For very large canvases, use larger tiles
    if (maxDimension > 10000) return 1024;
    if (maxDimension > 5000) return 512;
    return 256;
  }

  /// Check if tiling should be enabled based on canvas size
  static bool shouldEnableTiling(ui.Size canvasSize) {
    // Enable tiling for canvases larger than 2048x2048
    return canvasSize.width > 2048 || canvasSize.height > 2048;
  }
}

/// Statistics about memory management
class MemoryManagerStats {
  final int layerCount;
  final int totalCachedTiles;
  final int estimatedMemoryBytes;
  final int dirtyRegionCount;
  final bool isFullyDirty;
  final bool tilingEnabled;

  const MemoryManagerStats({
    required this.layerCount,
    required this.totalCachedTiles,
    required this.estimatedMemoryBytes,
    required this.dirtyRegionCount,
    required this.isFullyDirty,
    required this.tilingEnabled,
  });

  double get memoryMB => estimatedMemoryBytes / (1024 * 1024);

  @override
  String toString() {
    return 'MemoryManagerStats(\n'
        '  layers: $layerCount,\n'
        '  tiles: $totalCachedTiles,\n'
        '  memory: ${memoryMB.toStringAsFixed(2)} MB,\n'
        '  dirty: ${isFullyDirty ? "fully" : "$dirtyRegionCount regions"},\n'
        '  tiling: ${tilingEnabled ? "enabled" : "disabled"}\n'
        ')';
  }
}

/// Workflow helper for complete layer rendering cycle
class LayerRenderingWorkflow {
  final LayerMemoryManager memoryManager;

  LayerRenderingWorkflow(this.memoryManager);

  /// Step 1: User draws stroke
  void onStrokeAdded(LayerStroke stroke, DrawingLayer layer) {
    // Add to layer's stroke list (done in CanvasState)
    // Mark dirty
    memoryManager.markStrokeDirty(stroke, layer.id);
  }

  /// Step 2: Stroke complete
  void onStrokeComplete(LayerStroke stroke, DrawingLayer layer) {
    // Invalidate layer's cached image
    layer.invalidateCache();

    // Mark dirty region
    memoryManager.markStrokeDirty(stroke, layer.id);
  }

  /// Step 3: Check if frame needs rendering
  bool shouldRenderFrame(ui.Rect viewport) {
    return memoryManager.needsRepaint(viewport);
  }

  /// Step 4: Get tiles to render for visible layers
  Map<String, List<TileCoordinate>> getTilesToRender(
    List<DrawingLayer> layers,
    ui.Rect viewport,
  ) {
    final result = <String, List<TileCoordinate>>{};

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      final tiles = memoryManager.getTilesToRender(layer.id, viewport);
      if (tiles.isNotEmpty) {
        result[layer.id] = tiles;
      }
    }

    return result;
  }

  /// Step 5: Clear dirty regions after paint
  void onFrameComplete() {
    memoryManager.clearDirty();
  }

  /// Periodic cleanup
  void performMaintenance() {
    // Optimize dirty regions
    memoryManager.optimizeDirtyRegions();

    // Prune old tiles
    memoryManager.pruneOldTiles();
  }
}
