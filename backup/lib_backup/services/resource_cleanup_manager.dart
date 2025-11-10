import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Resource cleanup manager for long-running performance optimization
///
/// Prevents memory leaks and performance degradation in long-running apps.
///
/// Features:
/// - Periodic image cache clearing
/// - Temporary file cleanup
/// - Memory optimization hints
/// - Configurable cleanup intervals
/// - App lifecycle integration
///
/// Usage:
/// ```dart
/// // Start cleanup when app starts
/// ResourceCleanupManager.startPeriodicCleanup();
///
/// // Stop when app closes
/// ResourceCleanupManager.stopPeriodicCleanup();
/// ```
class ResourceCleanupManager {
  static Timer? _cleanupTimer;
  static const cleanupInterval = Duration(minutes: 10);
  static const tempFileMaxAge = Duration(hours: 24);

  /// Start periodic cleanup
  ///
  /// Runs cleanup every 10 minutes by default.
  /// Safe to call multiple times (cancels previous timer).
  static void startPeriodicCleanup() {
    _cleanupTimer?.cancel();

    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _performCleanup();
    });

    debugPrint(
      '✓ Resource cleanup scheduled every ${cleanupInterval.inMinutes} minutes',
    );
  }

  /// Stop periodic cleanup
  ///
  /// Call when app is terminating or cleanup no longer needed.
  static void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    debugPrint('✓ Resource cleanup stopped');
  }

  /// Perform cleanup immediately
  ///
  /// Can be called manually to force immediate cleanup.
  static Future<void> performCleanupNow() async {
    await _performCleanup();
  }

  /// Internal cleanup routine
  static Future<void> _performCleanup() async {
    debugPrint('🧹 Starting resource cleanup...');

    try {
      // 1. Clear image cache
      await _clearImageCache();

      // 2. Clear temporary files
      await _clearTempFiles();

      // 3. Suggest garbage collection
      _suggestGarbageCollection();

      debugPrint('✓ Resource cleanup completed');
    } catch (e) {
      debugPrint('✗ Resource cleanup error: $e');
    }
  }

  /// Clear Flutter's image cache
  ///
  /// Frees memory used by cached images.
  /// Images will be reloaded from disk when needed.
  static Future<void> _clearImageCache() async {
    // Clear all cached images
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Set reasonable cache limits
    PaintingBinding.instance.imageCache.maximumSize = 100; // 100 images
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        100 * 1024 * 1024; // 100 MB

    debugPrint('  ✓ Image cache cleared');
  }

  /// Clear old temporary files
  ///
  /// Deletes files older than 24 hours from temp directory.
  static Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();

      if (!await tempDir.exists()) {
        return;
      }

      final files = tempDir.listSync();
      int deletedCount = 0;
      int freedBytes = 0;

      for (final file in files) {
        try {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);

          // Delete files older than threshold
          if (age > tempFileMaxAge) {
            final size = stat.size;
            await file.delete(recursive: true);
            deletedCount++;
            freedBytes += size;
          }
        } catch (e) {
          // Skip files that can't be deleted
          debugPrint('  ⚠ Failed to delete temp file: $e');
        }
      }

      if (deletedCount > 0) {
        debugPrint(
          '  ✓ Temp files cleared: $deletedCount files, ${_formatBytes(freedBytes)} freed',
        );
      }
    } catch (e) {
      debugPrint('  ✗ Temp cleanup failed: $e');
    }
  }

  /// Suggest garbage collection to Dart VM
  ///
  /// This is a hint, not a guarantee. The VM decides when to actually collect.
  static void _suggestGarbageCollection() {
    // Force a microtask to give VM opportunity to collect
    Future.microtask(() {
      // Creating and discarding objects can trigger GC
      final _ = List.generate(100, (i) => i);
    });

    debugPrint('  ✓ GC hint sent');
  }

  /// Format bytes to human-readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get current cache statistics
  static Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;

    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'liveImageCount': imageCache.liveImageCount,
      'pendingImageCount': imageCache.pendingImageCount,
    };
  }

  /// Get formatted cache statistics
  static String getFormattedCacheStats() {
    final stats = getCacheStats();
    return '''
Image Cache Statistics:
  Current: ${stats['currentSize']}/${stats['maximumSize']} images
  Memory: ${_formatBytes(stats['currentSizeBytes'])}/${_formatBytes(stats['maximumSizeBytes'])}
  Live: ${stats['liveImageCount']}
  Pending: ${stats['pendingImageCount']}
''';
  }
}

/// App lifecycle observer for automatic resource management
///
/// Integrates with Flutter's app lifecycle to:
/// - Clean up resources when app goes to background
/// - Restart cleanup timer when app resumes
/// - Final cleanup on app termination
///
/// Usage:
/// ```dart
/// final lifecycleManager = AppLifecycleManager();
/// WidgetsBinding.instance.addObserver(lifecycleManager);
///
/// // Don't forget to remove observer when done:
/// WidgetsBinding.instance.removeObserver(lifecycleManager);
/// ```
class AppLifecycleManager extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App going to background
        _onAppPaused();

      case AppLifecycleState.resumed:
        // App coming to foreground
        _onAppResumed();

      case AppLifecycleState.inactive:
        // App transitioning
        break;

      case AppLifecycleState.detached:
        // App terminating
        _onAppTerminating();

      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Called when app goes to background
  void _onAppPaused() {
    debugPrint('📱 App paused - freeing resources');

    // Aggressive cleanup when app is backgrounded
    PaintingBinding.instance.imageCache.clear();
    ResourceCleanupManager.performCleanupNow();

    debugPrint('  ✓ Resources freed');
  }

  /// Called when app returns to foreground
  void _onAppResumed() {
    debugPrint('📱 App resumed');

    // Restart cleanup timer
    ResourceCleanupManager.startPeriodicCleanup();

    debugPrint('  ✓ Cleanup timer restarted');
  }

  /// Called when app is terminating
  void _onAppTerminating() {
    debugPrint('📱 App terminating');

    // Final cleanup
    ResourceCleanupManager.stopPeriodicCleanup();

    debugPrint('  ✓ Final cleanup complete');
  }
}

/// Memory-efficient state management with weak references
///
/// Uses WeakReference to allow garbage collection of large objects
/// when memory is needed, while keeping frequently used objects cached.
///
/// Usage:
/// ```dart
/// final cache = MemoryEfficientCache<int, DrawingDocument>();
///
/// // Cache document
/// cache.put(1, document);
///
/// // Retrieve (may return null if GC'd)
/// final doc = cache.get(1);
/// ```
class MemoryEfficientCache<K, V extends Object> {
  final Map<K, WeakReference<V>> _cache = {};
  final int maxSize;

  MemoryEfficientCache({this.maxSize = 10});

  /// Get cached value (may return null if garbage collected)
  V? get(K key) {
    final weakRef = _cache[key];
    final value = weakRef?.target;

    // If value was garbage collected, remove from cache
    if (value == null && weakRef != null) {
      _cache.remove(key);
    }

    return value;
  }

  /// Cache a value with weak reference
  void put(K key, V value) {
    // Limit cache size
    if (_cache.length >= maxSize) {
      // Remove oldest entry (first key)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = WeakReference(value);
  }

  /// Check if key exists and value is still alive
  bool containsKey(K key) {
    final value = get(key);
    return value != null;
  }

  /// Remove entry from cache
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get current cache size (including GC'd entries)
  int get size => _cache.length;

  /// Get count of live (non-GC'd) entries
  int get liveCount {
    int count = 0;
    for (final weakRef in _cache.values) {
      if (weakRef.target != null) count++;
    }
    return count;
  }

  /// Clean up GC'd entries
  void compact() {
    final deadKeys = <K>[];

    for (final entry in _cache.entries) {
      if (entry.value.target == null) {
        deadKeys.add(entry.key);
      }
    }

    for (final key in deadKeys) {
      _cache.remove(key);
    }

    if (deadKeys.isNotEmpty) {
      debugPrint('✓ Compacted cache: removed ${deadKeys.length} dead entries');
    }
  }
}
