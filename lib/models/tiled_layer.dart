import 'dart:ui' as ui;

/// Tile-based rendering system for large canvases
/// Divides canvas into tiles to reduce memory consumption
class TiledLayer {
  /// Cache of rendered tiles, keyed by "x_y" coordinates
  final Map<String, ui.Image> _tiles = {};
  
  /// Size of each tile in pixels (power of 2 for efficient calculation)
  final int tileSize;
  
  /// Maximum number of tiles to keep in cache
  final int maxCachedTiles;
  
  /// LRU tracking for cache eviction
  final Map<String, DateTime> _tileAccessTimes = {};
  
  /// ID of the layer this tile system belongs to
  final String layerId;
  
  TiledLayer({
    required this.layerId,
    this.tileSize = 512,
    this.maxCachedTiles = 50,
  });
  
  /// Get a tile at the specified tile coordinates
  /// Returns null if tile is not cached
  ui.Image? getTile(int tileX, int tileY) {
    final key = _getTileKey(tileX, tileY);
    final tile = _tiles[key];
    
    if (tile != null) {
      // Update access time for LRU
      _tileAccessTimes[key] = DateTime.now();
    }
    
    return tile;
  }
  
  /// Get a tile asynchronously (for compatibility with async rendering)
  Future<ui.Image?> getTileAsync(int tileX, int tileY) async {
    return getTile(tileX, tileY);
  }
  
  /// Cache a rendered tile
  void cacheTile(int tileX, int tileY, ui.Image image) {
    final key = _getTileKey(tileX, tileY);
    
    // Evict old tiles if cache is full
    if (_tiles.length >= maxCachedTiles) {
      _evictLeastRecentlyUsed();
    }
    
    _tiles[key] = image;
    _tileAccessTimes[key] = DateTime.now();
  }
  
  /// Invalidate a specific tile, forcing redraw on next access
  void invalidateTile(int tileX, int tileY) {
    final key = _getTileKey(tileX, tileY);
    
    // Dispose the image to free memory
    _tiles[key]?.dispose();
    
    _tiles.remove(key);
    _tileAccessTimes.remove(key);
  }
  
  /// Invalidate all tiles in a rectangular region
  void invalidateRegion(ui.Rect region) {
    final startTileX = (region.left / tileSize).floor();
    final startTileY = (region.top / tileSize).floor();
    final endTileX = (region.right / tileSize).ceil();
    final endTileY = (region.bottom / tileSize).ceil();
    
    for (int tileY = startTileY; tileY <= endTileY; tileY++) {
      for (int tileX = startTileX; tileX <= endTileX; tileX++) {
        invalidateTile(tileX, tileY);
      }
    }
  }
  
  /// Invalidate all tiles (e.g., when layer properties change globally)
  void invalidateAll() {
    // Dispose all images to free memory
    for (final image in _tiles.values) {
      image.dispose();
    }
    
    _tiles.clear();
    _tileAccessTimes.clear();
  }
  
  /// Get tiles that overlap with the viewport
  List<TileCoordinate> getVisibleTiles(ui.Rect viewport) {
    final startTileX = (viewport.left / tileSize).floor();
    final startTileY = (viewport.top / tileSize).floor();
    final endTileX = (viewport.right / tileSize).ceil();
    final endTileY = (viewport.bottom / tileSize).ceil();
    
    final visibleTiles = <TileCoordinate>[];
    
    for (int tileY = startTileY; tileY <= endTileY; tileY++) {
      for (int tileX = startTileX; tileX <= endTileX; tileX++) {
        visibleTiles.add(TileCoordinate(tileX, tileY));
      }
    }
    
    return visibleTiles;
  }
  
  /// Get the bounds of a tile in canvas coordinates
  ui.Rect getTileBounds(int tileX, int tileY) {
    return ui.Rect.fromLTWH(
      tileX * tileSize.toDouble(),
      tileY * tileSize.toDouble(),
      tileSize.toDouble(),
      tileSize.toDouble(),
    );
  }
  
  /// Check if a tile exists in cache
  bool hasTile(int tileX, int tileY) {
    return _tiles.containsKey(_getTileKey(tileX, tileY));
  }
  
  /// Get cache statistics
  TileCacheStats getStats() {
    return TileCacheStats(
      cachedTileCount: _tiles.length,
      maxCachedTiles: maxCachedTiles,
      cacheUtilization: _tiles.length / maxCachedTiles,
      estimatedMemoryBytes: _estimateMemoryUsage(),
    );
  }
  
  /// Clear tiles that haven't been accessed recently
  void pruneOldTiles(Duration maxAge) {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _tileAccessTimes.forEach((key, accessTime) {
      if (now.difference(accessTime) > maxAge) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _tiles[key]?.dispose();
      _tiles.remove(key);
      _tileAccessTimes.remove(key);
    }
  }
  
  /// Prefetch tiles around the viewport for smooth scrolling
  List<TileCoordinate> getPrefetchTiles(
    ui.Rect viewport,
    int prefetchRadius,
  ) {
    final visibleTiles = getVisibleTiles(viewport);
    final prefetchTiles = <TileCoordinate>[];
    
    for (final tile in visibleTiles) {
      // Add surrounding tiles
      for (int dy = -prefetchRadius; dy <= prefetchRadius; dy++) {
        for (int dx = -prefetchRadius; dx <= prefetchRadius; dx++) {
          final prefetchTile = TileCoordinate(
            tile.x + dx,
            tile.y + dy,
          );
          
          if (!hasTile(prefetchTile.x, prefetchTile.y)) {
            prefetchTiles.add(prefetchTile);
          }
        }
      }
    }
    
    return prefetchTiles;
  }
  
  /// Dispose all resources
  void dispose() {
    for (final image in _tiles.values) {
      image.dispose();
    }
    _tiles.clear();
    _tileAccessTimes.clear();
  }
  
  // Private helpers
  
  String _getTileKey(int tileX, int tileY) => '${tileX}_$tileY';
  
  void _evictLeastRecentlyUsed() {
    if (_tiles.isEmpty) return;
    
    // Find the oldest tile
    String? oldestKey;
    DateTime? oldestTime;
    
    _tileAccessTimes.forEach((key, time) {
      if (oldestTime == null || time.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = time;
      }
    });
    
    if (oldestKey != null) {
      _tiles[oldestKey]?.dispose();
      _tiles.remove(oldestKey);
      _tileAccessTimes.remove(oldestKey);
    }
  }
  
  int _estimateMemoryUsage() {
    // Each tile is tileSize x tileSize pixels
    // RGBA = 4 bytes per pixel
    final bytesPerTile = tileSize * tileSize * 4;
    return _tiles.length * bytesPerTile;
  }
}

/// Tile coordinate in the tile grid
class TileCoordinate {
  final int x;
  final int y;
  
  const TileCoordinate(this.x, this.y);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TileCoordinate && other.x == x && other.y == y;
  }
  
  @override
  int get hashCode => Object.hash(x, y);
  
  @override
  String toString() => 'TileCoordinate($x, $y)';
}

/// Statistics about the tile cache
class TileCacheStats {
  final int cachedTileCount;
  final int maxCachedTiles;
  final double cacheUtilization;
  final int estimatedMemoryBytes;
  
  const TileCacheStats({
    required this.cachedTileCount,
    required this.maxCachedTiles,
    required this.cacheUtilization,
    required this.estimatedMemoryBytes,
  });
  
  double get memoryMB => estimatedMemoryBytes / (1024 * 1024);
  
  @override
  String toString() {
    return 'TileCacheStats('
        'tiles: $cachedTileCount/$maxCachedTiles, '
        'utilization: ${(cacheUtilization * 100).toStringAsFixed(1)}%, '
        'memory: ${memoryMB.toStringAsFixed(2)} MB'
        ')';
  }
}
