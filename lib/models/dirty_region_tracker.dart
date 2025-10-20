import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Tracks which regions of the canvas have changed to minimize redraws
/// Maintains 60fps even with complex artwork by only redrawing dirty regions
class DirtyRegionTracker {
  /// List of regions that need to be redrawn
  final List<ui.Rect> _dirtyRegions = [];
  
  /// Whether the entire canvas is dirty (e.g., after major change)
  bool _isFullyDirty = false;
  
  /// Minimum size threshold for merging nearby regions (in pixels)
  final double mergeThreshold;
  
  /// Maximum number of dirty regions before forcing full redraw
  final int maxRegions;
  
  DirtyRegionTracker({
    this.mergeThreshold = 50.0,
    this.maxRegions = 100,
  });
  
  /// Mark a region as dirty
  void markDirty(ui.Rect region) {
    if (_isFullyDirty) return; // Already dirty everywhere
    
    // Merge with nearby regions to reduce fragmentation
    final merged = _tryMergeWithExisting(region);
    
    if (!merged) {
      _dirtyRegions.add(region);
      
      // If too many regions, just mark everything dirty
      if (_dirtyRegions.length > maxRegions) {
        markAllDirty();
      }
    }
  }
  
  /// Mark multiple regions as dirty at once
  void markDirtyBatch(List<ui.Rect> regions) {
    for (final region in regions) {
      markDirty(region);
    }
  }
  
  /// Mark the entire canvas as dirty
  void markAllDirty() {
    _isFullyDirty = true;
    _dirtyRegions.clear();
  }
  
  /// Check if a viewport region needs repainting
  bool needsRepaint(ui.Rect viewportRect) {
    if (_isFullyDirty) return true;
    if (_dirtyRegions.isEmpty) return false;
    
    return _dirtyRegions.any((dirty) => dirty.overlaps(viewportRect));
  }
  
  /// Get all dirty regions that overlap with the viewport
  List<ui.Rect> getDirtyRegionsInViewport(ui.Rect viewport) {
    if (_isFullyDirty) return [viewport];
    
    return _dirtyRegions
        .where((region) => region.overlaps(viewport))
        .toList();
  }
  
  /// Get the union of all dirty regions
  ui.Rect? getDirtyBounds() {
    if (_isFullyDirty) return null; // Entire canvas
    if (_dirtyRegions.isEmpty) return null; // Nothing dirty
    
    return _dirtyRegions.reduce((a, b) => a.expandToInclude(b));
  }
  
  /// Clear all dirty regions (call after repaint)
  void clearDirty() {
    _dirtyRegions.clear();
    _isFullyDirty = false;
  }
  
  /// Check if entire canvas is dirty
  bool get isFullyDirty => _isFullyDirty;
  
  /// Check if there are any dirty regions
  bool get hasDirtyRegions => _isFullyDirty || _dirtyRegions.isNotEmpty;
  
  /// Get number of dirty regions
  int get dirtyRegionCount => _isFullyDirty ? -1 : _dirtyRegions.length;
  
  /// Get a copy of all dirty regions
  List<ui.Rect> get dirtyRegions => List.unmodifiable(_dirtyRegions);
  
  /// Optimize dirty regions by merging overlapping/nearby rectangles
  void optimize() {
    if (_isFullyDirty || _dirtyRegions.isEmpty) return;
    
    final optimized = <ui.Rect>[];
    final processed = <bool>[];
    
    for (int i = 0; i < _dirtyRegions.length; i++) {
      processed.add(false);
    }
    
    for (int i = 0; i < _dirtyRegions.length; i++) {
      if (processed[i]) continue;
      
      var current = _dirtyRegions[i];
      processed[i] = true;
      
      // Try to merge with remaining regions
      bool merged;
      do {
        merged = false;
        for (int j = i + 1; j < _dirtyRegions.length; j++) {
          if (processed[j]) continue;
          
          final other = _dirtyRegions[j];
          if (_shouldMerge(current, other)) {
            current = current.expandToInclude(other);
            processed[j] = true;
            merged = true;
          }
        }
      } while (merged);
      
      optimized.add(current);
    }
    
    _dirtyRegions.clear();
    _dirtyRegions.addAll(optimized);
  }
  
  /// Get statistics about dirty regions
  DirtyRegionStats getStats() {
    if (_isFullyDirty) {
      return DirtyRegionStats(
        regionCount: -1,
        totalArea: double.infinity,
        coverage: 1.0,
        isOptimized: true,
      );
    }
    
    final totalArea = _dirtyRegions.fold<double>(
      0.0,
      (sum, rect) => sum + (rect.width * rect.height),
    );
    
    return DirtyRegionStats(
      regionCount: _dirtyRegions.length,
      totalArea: totalArea,
      coverage: 0.0, // Would need canvas size to calculate
      isOptimized: _dirtyRegions.length <= maxRegions,
    );
  }
  
  /// Create a dirty region from stroke bounds with padding
  static ui.Rect fromStrokeBounds(ui.Rect bounds, double strokeWidth) {
    final padding = strokeWidth / 2 + 2; // Extra padding for anti-aliasing
    return bounds.inflate(padding);
  }
  
  /// Create dirty regions from a list of points (e.g., drawing path)
  static ui.Rect fromPoints(List<ui.Offset> points, double strokeWidth) {
    if (points.isEmpty) return ui.Rect.zero;
    
    double minX = points.first.dx;
    double minY = points.first.dy;
    double maxX = points.first.dx;
    double maxY = points.first.dy;
    
    for (final point in points) {
      minX = minX < point.dx ? minX : point.dx;
      minY = minY < point.dy ? minY : point.dy;
      maxX = maxX > point.dx ? maxX : point.dx;
      maxY = maxY > point.dy ? maxY : point.dy;
    }
    
    final bounds = ui.Rect.fromLTRB(minX, minY, maxX, maxY);
    return fromStrokeBounds(bounds, strokeWidth);
  }
  
  // Private helpers
  
  bool _tryMergeWithExisting(ui.Rect region) {
    for (int i = 0; i < _dirtyRegions.length; i++) {
      final existing = _dirtyRegions[i];
      
      if (_shouldMerge(region, existing)) {
        _dirtyRegions[i] = existing.expandToInclude(region);
        return true;
      }
    }
    return false;
  }
  
  bool _shouldMerge(ui.Rect a, ui.Rect b) {
    // Merge if they overlap
    if (a.overlaps(b)) return true;
    
    // Merge if they're close enough
    final distance = _rectDistance(a, b);
    return distance < mergeThreshold;
  }
  
  double _rectDistance(ui.Rect a, ui.Rect b) {
    // Calculate minimum distance between two rectangles
    final dx = (a.left > b.right)
        ? a.left - b.right
        : (b.left > a.right)
            ? b.left - a.right
            : 0.0;
    
    final dy = (a.top > b.bottom)
        ? a.top - b.bottom
        : (b.top > a.bottom)
            ? b.top - a.bottom
            : 0.0;
    
    return dx + dy; // Manhattan distance for rectangles
  }
}

/// Statistics about dirty regions
class DirtyRegionStats {
  /// Number of dirty regions (-1 if fully dirty)
  final int regionCount;
  
  /// Total area of all dirty regions in pixels
  final double totalArea;
  
  /// Percentage of canvas covered (0.0-1.0)
  final double coverage;
  
  /// Whether the regions are optimized (not fragmented)
  final bool isOptimized;
  
  const DirtyRegionStats({
    required this.regionCount,
    required this.totalArea,
    required this.coverage,
    required this.isOptimized,
  });
  
  @override
  String toString() {
    if (regionCount == -1) {
      return 'DirtyRegionStats(fully dirty)';
    }
    
    return 'DirtyRegionStats('
        'regions: $regionCount, '
        'area: ${totalArea.toStringAsFixed(0)} px², '
        'coverage: ${(coverage * 100).toStringAsFixed(1)}%, '
        'optimized: $isOptimized'
        ')';
  }
}

/// Extension methods for Rect operations
extension RectExtensions on ui.Rect {
  /// Check if this rect overlaps with another
  bool overlaps(ui.Rect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }
  
  /// Expand this rect to include another rect
  ui.Rect expandToInclude(ui.Rect other) {
    return ui.Rect.fromLTRB(
      left < other.left ? left : other.left,
      top < other.top ? top : other.top,
      right > other.right ? right : other.right,
      bottom > other.bottom ? bottom : other.bottom,
    );
  }
}
