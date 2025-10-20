import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Memory manager for large images
///
/// Prevents out-of-memory crashes by:
/// - Tracking memory usage of all images
/// - Enforcing memory limits
/// - Evicting oldest images when limit exceeded
/// - Aggressive disposal of unused images
///
/// Usage:
/// ```dart
/// final memoryMgr = MemoryManager(maxMemoryMB: 500);
///
/// // Track image
/// memoryMgr.trackImage('photo1', image);
///
/// // Check if can load more
/// if (memoryMgr.canAllocate(estimatedSizeMB: 50)) {
///   final newImage = await loadImage();
///   memoryMgr.trackImage('photo2', newImage);
/// }
///
/// // Cleanup
/// memoryMgr.dispose();
/// ```
class MemoryManager {
  /// Maximum memory allowed for images (in MB)
  final double maxMemoryMB;

  /// Whether to show debug logs
  final bool verbose;

  /// Map of image ID to tracked image
  final Map<String, _TrackedImage> _images = {};

  /// Total memory usage in bytes
  int _totalMemoryBytes = 0;

  MemoryManager({this.maxMemoryMB = 500.0, this.verbose = false});

  /// Track a new image
  ///
  /// Returns true if image was added, false if rejected due to memory limits
  bool trackImage(String id, ui.Image image, {String? tag}) {
    final sizeMB = _calculateImageSizeMB(image);

    _log('Tracking image: $id (${sizeMB.toStringAsFixed(2)} MB)');

    // Check if adding this image would exceed limit
    final totalAfterAdd = (_totalMemoryBytes / (1024 * 1024)) + sizeMB;
    if (totalAfterAdd > maxMemoryMB) {
      _log('Adding image would exceed limit, attempting to free space...');

      // Try to free enough space
      if (!_freeMemory(sizeMB)) {
        _log('Cannot free enough memory, rejecting image');
        return false;
      }
    }

    // Remove existing if already tracked
    if (_images.containsKey(id)) {
      untrackImage(id);
    }

    // Track the new image
    final tracked = _TrackedImage(
      id: id,
      image: image,
      sizeBytes: (sizeMB * 1024 * 1024).toInt(),
      addedTime: DateTime.now(),
      tag: tag,
    );

    _images[id] = tracked;
    _totalMemoryBytes += tracked.sizeBytes;

    _log(
      'Image tracked. Total memory: ${(_totalMemoryBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    return true;
  }

  /// Untrack an image and dispose it
  void untrackImage(String id) {
    final tracked = _images[id];
    if (tracked == null) return;

    _log(
      'Untracking image: $id (${(tracked.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB)',
    );

    _images.remove(id);
    _totalMemoryBytes -= tracked.sizeBytes;

    // Dispose the image
    tracked.image.dispose();

    _log(
      'Image disposed. Total memory: ${(_totalMemoryBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
    );
  }

  /// Check if can allocate specified memory
  bool canAllocate({required double estimatedSizeMB}) {
    final currentMB = _totalMemoryBytes / (1024 * 1024);
    return (currentMB + estimatedSizeMB) <= maxMemoryMB;
  }

  /// Get current memory usage in MB
  double get currentMemoryMB => _totalMemoryBytes / (1024 * 1024);

  /// Get percentage of memory used
  double get memoryUsagePercent => (currentMemoryMB / maxMemoryMB) * 100;

  /// Get number of tracked images
  int get imageCount => _images.length;

  /// Check if specific image is tracked
  bool isTracked(String id) => _images.containsKey(id);

  /// Get image by ID
  ui.Image? getImage(String id) {
    final tracked = _images[id];
    if (tracked != null) {
      tracked.lastAccessTime = DateTime.now();
    }
    return tracked?.image;
  }

  /// Update last access time for an image
  void markAccessed(String id) {
    final tracked = _images[id];
    if (tracked != null) {
      tracked.lastAccessTime = DateTime.now();
    }
  }

  /// Get memory statistics
  Map<String, dynamic> getStats() {
    return {
      'currentMemoryMB': currentMemoryMB,
      'maxMemoryMB': maxMemoryMB,
      'usagePercent': memoryUsagePercent,
      'imageCount': imageCount,
      'images': _images.values
          .map(
            (img) => {
              'id': img.id,
              'sizeMB': img.sizeBytes / (1024 * 1024),
              'age': DateTime.now().difference(img.addedTime).inSeconds,
              'lastAccess': DateTime.now()
                  .difference(img.lastAccessTime)
                  .inSeconds,
              'tag': img.tag,
            },
          )
          .toList(),
    };
  }

  /// Free memory by evicting old images
  ///
  /// Returns true if enough memory was freed
  bool _freeMemory(double requiredMB) {
    final requiredBytes = (requiredMB * 1024 * 1024).toInt();
    int freedBytes = 0;

    _log('Attempting to free ${requiredMB.toStringAsFixed(2)} MB');

    // Sort by last access time (oldest first)
    final sortedImages = _images.values.toList()
      ..sort((a, b) => a.lastAccessTime.compareTo(b.lastAccessTime));

    for (final img in sortedImages) {
      if (freedBytes >= requiredBytes) break;

      _log(
        'Evicting image: ${img.id} (last accessed ${DateTime.now().difference(img.lastAccessTime).inSeconds}s ago)',
      );

      freedBytes += img.sizeBytes;
      untrackImage(img.id);
    }

    final freedMB = freedBytes / (1024 * 1024);
    _log('Freed ${freedMB.toStringAsFixed(2)} MB');

    return freedBytes >= requiredBytes;
  }

  /// Evict images older than specified duration
  void evictOlderThan(Duration duration) {
    final cutoffTime = DateTime.now().subtract(duration);
    final toEvict = <String>[];

    for (final entry in _images.entries) {
      if (entry.value.lastAccessTime.isBefore(cutoffTime)) {
        toEvict.add(entry.key);
      }
    }

    _log(
      'Evicting ${toEvict.length} images older than ${duration.inMinutes} minutes',
    );

    for (final id in toEvict) {
      untrackImage(id);
    }
  }

  /// Evict images with specific tag
  void evictByTag(String tag) {
    final toEvict = _images.entries
        .where((e) => e.value.tag == tag)
        .map((e) => e.key)
        .toList();

    _log('Evicting ${toEvict.length} images with tag: $tag');

    for (final id in toEvict) {
      untrackImage(id);
    }
  }

  /// Clear all images
  void clear() {
    _log('Clearing all images (${_images.length} images)');

    final ids = _images.keys.toList();
    for (final id in ids) {
      untrackImage(id);
    }

    _totalMemoryBytes = 0;
  }

  /// Dispose all images and cleanup
  void dispose() {
    _log('Disposing memory manager');
    clear();
  }

  /// Calculate image size in MB
  double _calculateImageSizeMB(ui.Image image) {
    // Each pixel is 4 bytes (RGBA)
    final bytes = image.width * image.height * 4;
    return bytes / (1024 * 1024);
  }

  void _log(String message) {
    if (verbose) {
      debugPrint('[MemoryManager] $message');
    }
  }
}

/// Tracked image with metadata
class _TrackedImage {
  final String id;
  final ui.Image image;
  final int sizeBytes;
  final DateTime addedTime;
  final String? tag;
  DateTime lastAccessTime;

  _TrackedImage({
    required this.id,
    required this.image,
    required this.sizeBytes,
    required this.addedTime,
    this.tag,
  }) : lastAccessTime = addedTime;
}

/// Extension to estimate image size before loading
extension ImageSizeEstimation on ui.Image {
  /// Get estimated size in MB
  double get estimatedSizeMB {
    final bytes = width * height * 4; // RGBA
    return bytes / (1024 * 1024);
  }

  /// Check if image is considered "large"
  bool get isLargeImage => estimatedSizeMB > 10.0;

  /// Get memory info
  Map<String, dynamic> get memoryInfo => {
    'width': width,
    'height': height,
    'pixels': width * height,
    'bytes': width * height * 4,
    'sizeMB': estimatedSizeMB,
    'isLarge': isLargeImage,
  };
}

/// Extension for Size to estimate image memory
extension SizeMemoryEstimation on Size {
  /// Estimate memory for image of this size
  double estimateImageMemoryMB() {
    final bytes = (width * height * 4).toInt();
    return bytes / (1024 * 1024);
  }
}
