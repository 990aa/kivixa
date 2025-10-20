import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';

/// Tile-based rendering manager for massive canvases
///
/// Prevents memory overflow by rendering only visible tiles.
/// Critical for canvases larger than 10,000x10,000 pixels.
///
/// Example:
/// ```dart
/// final tileManager = TileManager();
///
/// // In CustomPainter.paint()
/// tileManager.renderVisibleTiles(
///   canvas,
///   layers,
///   viewport,
///   zoomLevel,
/// );
/// ```
class TileManager {
  static const int tileSize = 512; // Pixels per tile

  final Map<String, CachedTile> _tileCache = {};
  final int _maxCachedTiles =
      50; // Limit memory usage (~50MB at 512x512)  // Track which tiles are visible
  Set<String> _visibleTileKeys = {};

  // Rendering queue for async tile generation
  final Set<String> _renderingTiles = {};

  /// Only render visible tiles based on viewport
  ///
  /// This is the main method to call from your CustomPainter
  void renderVisibleTiles(
    Canvas canvas,
    List<DrawingLayer> layers,
    Rect viewportRect,
    double zoom,
  ) {
    // Calculate which tiles are visible
    final visibleTiles = _getVisibleTiles(viewportRect, zoom);
    _visibleTileKeys = visibleTiles.map((t) => t.key).toSet();

    for (final tile in visibleTiles) {
      final cached = _getTileFromCache(tile);

      if (cached == null) {
        // Show placeholder while loading
        _drawPlaceholder(canvas, tile.bounds);

        // Start rendering in background if not already rendering
        if (!_renderingTiles.contains(tile.key)) {
          _renderingTiles.add(tile.key);
          _renderTileAsync(tile, layers);
        }
      } else {
        // Draw cached tile
        canvas.drawImage(cached.image, tile.bounds.topLeft, Paint());
      }
    }

    // Cleanup old tiles to prevent memory leak
    _evictOldTiles();
  }

  /// Calculate which tiles intersect the viewport
  List<TileCoordinate> _getVisibleTiles(Rect viewport, double zoom) {
    final scaledTileSize = tileSize / zoom;

    final startX = (viewport.left / scaledTileSize).floor();
    final endX = (viewport.right / scaledTileSize).ceil();
    final startY = (viewport.top / scaledTileSize).floor();
    final endY = (viewport.bottom / scaledTileSize).ceil();
    List<TileCoordinate> tiles = [];

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        tiles.add(
          TileCoordinate(
            x: x,
            y: y,
            zoom: zoom,
            bounds: Rect.fromLTWH(
              x * scaledTileSize,
              y * scaledTileSize,
              scaledTileSize,
              scaledTileSize,
            ),
          ),
        );
      }
    }

    return tiles;
  }

  /// Get tile from cache and update access time
  CachedTile? _getTileFromCache(TileCoordinate tile) {
    final cached = _tileCache[tile.key];
    if (cached != null) {
      cached.lastAccessTime = DateTime.now();
    }
    return cached;
  }

  /// Render tile asynchronously (in microtask, not isolate for UI access)
  Future<void> _renderTileAsync(
    TileCoordinate tile,
    List<DrawingLayer> layers,
  ) async {
    try {
      // Render tile on next frame
      await Future.microtask(() {
        final image = _renderTile(tile, layers);

        _tileCache[tile.key] = CachedTile(
          image: image,
          lastAccessTime: DateTime.now(),
        );

        _renderingTiles.remove(tile.key);
      });
    } catch (e) {
      _renderingTiles.remove(tile.key);
      debugPrint('Error rendering tile ${tile.key}: $e');
    }
  }

  /// Synchronously render a single tile
  ui.Image _renderTile(TileCoordinate tile, List<DrawingLayer> layers) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, tileSize.toDouble(), tileSize.toDouble()),
    );

    // Transform canvas to tile coordinate space
    canvas.translate(-tile.bounds.left, -tile.bounds.top);

    // Only render strokes that intersect this tile
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Apply layer opacity
      canvas.saveLayer(
        tile.bounds,
        Paint()..color = Colors.white.withValues(alpha: layer.opacity),
      );

      for (final stroke in layer.strokes) {
        if (_strokeIntersectsTile(stroke, tile.bounds)) {
          _renderStrokeSegment(canvas, stroke, tile.bounds);
        }
      }

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(tileSize, tileSize);
    picture.dispose();

    return image;
  }

  /// Check if stroke intersects tile bounds
  static bool _strokeIntersectsTile(LayerStroke stroke, Rect tileBounds) {
    // Quick bounds check
    final strokeBounds = stroke.getBounds();
    if (!tileBounds.overlaps(strokeBounds)) {
      return false;
    }

    // Detailed check: any point within tile
    return stroke.points.any((point) => tileBounds.contains(point.position));
  }

  /// Remove tiles not currently visible, keeping most recently used
  void _evictOldTiles() {
    if (_tileCache.length <= _maxCachedTiles) return;

    // Remove tiles not currently visible
    final tilesToRemove = _tileCache.keys
        .where((key) => !_visibleTileKeys.contains(key))
        .toList();

    // Sort by last access time, remove oldest
    tilesToRemove.sort((a, b) {
      final timeA = _tileCache[a]!.lastAccessTime;
      final timeB = _tileCache[b]!.lastAccessTime;
      return timeA.compareTo(timeB);
    });

    // Remove oldest tiles beyond limit
    final removeCount = _tileCache.length - _maxCachedTiles;
    for (int i = 0; i < removeCount && i < tilesToRemove.length; i++) {
      final tile = _tileCache.remove(tilesToRemove[i]);
      tile?.image.dispose(); // Free GPU memory
    }
  }

  /// Draw placeholder for loading tiles
  void _drawPlaceholder(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    canvas.drawRect(bounds, paint);

    // Optional: Draw loading indicator
    final center = bounds.center;
    final indicatorPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 20, indicatorPaint);
  }

  /// Render only the portion of stroke within tile
  static void _renderStrokeSegment(
    Canvas canvas,
    LayerStroke stroke,
    Rect tileBounds,
  ) {
    if (stroke.points.isEmpty) return;

    // Build path only for points within tile (with padding)
    final padding = stroke.brushProperties.strokeWidth * 2;
    final paddedBounds = tileBounds.inflate(padding);

    final path = Path();
    bool pathStarted = false;

    for (int i = 0; i < stroke.points.length; i++) {
      final point = stroke.points[i].position;

      if (paddedBounds.contains(point)) {
        if (!pathStarted) {
          path.moveTo(point.dx, point.dy);
          pathStarted = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      } else if (pathStarted) {
        // Continue path outside tile to avoid gaps
        path.lineTo(point.dx, point.dy);
      }
    }

    if (pathStarted) {
      canvas.drawPath(path, stroke.brushProperties);
    }
  }

  /// Clear all cached tiles (call when layers change significantly)
  void clearCache() {
    for (final tile in _tileCache.values) {
      tile.image.dispose();
    }
    _tileCache.clear();
    _visibleTileKeys.clear();
    _renderingTiles.clear();
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedTiles': _tileCache.length,
      'visibleTiles': _visibleTileKeys.length,
      'renderingTiles': _renderingTiles.length,
      'maxTiles': _maxCachedTiles,
      'estimatedMemoryMB':
          (_tileCache.length * tileSize * tileSize * 4) / (1024 * 1024),
    };
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

/// Tile coordinate in grid space
class TileCoordinate {
  final int x, y;
  final double zoom;
  final Rect bounds;

  TileCoordinate({
    required this.x,
    required this.y,
    required this.zoom,
    required this.bounds,
  });

  String get key => '${x}_${y}_${zoom.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          zoom == other.zoom;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ zoom.hashCode;
}

/// Cached tile with access tracking
class CachedTile {
  final ui.Image image;
  DateTime lastAccessTime;

  CachedTile({required this.image, required this.lastAccessTime});
}
