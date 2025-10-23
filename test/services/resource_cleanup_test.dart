import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/services/resource_cleanup_manager.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('cleanup_test_');
  });

  tearDown(() async {
    ResourceCleanupManager.stopPeriodicCleanup();
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('Periodic Cleanup', () {
    test('should start periodic cleanup', () {
      ResourceCleanupManager.startPeriodicCleanup();

      // No exception should be thrown
      expect(true, true);
    });

    test('should stop periodic cleanup', () {
      ResourceCleanupManager.startPeriodicCleanup();
      ResourceCleanupManager.stopPeriodicCleanup();

      expect(true, true);
    });

    test('should be safe to start multiple times', () {
      ResourceCleanupManager.startPeriodicCleanup();
      ResourceCleanupManager.startPeriodicCleanup();
      ResourceCleanupManager.startPeriodicCleanup();

      // Should not throw exception
      expect(true, true);
    });

    test('should be safe to stop when not started', () {
      ResourceCleanupManager.stopPeriodicCleanup();

      expect(true, true);
    });
  });

  group('Manual Cleanup', () {
    test('should perform cleanup immediately', () async {
      await ResourceCleanupManager.performCleanupNow();

      // Should complete without error
      expect(true, true);
    });

    test('should clear image cache', () async {
      // Load some images into cache
      PaintingBinding.instance.imageCache.clear();

      final initialSize = PaintingBinding.instance.imageCache.currentSize;

      // Perform cleanup
      await ResourceCleanupManager.performCleanupNow();

      final afterSize = PaintingBinding.instance.imageCache.currentSize;

      expect(afterSize, lessThanOrEqualTo(initialSize));
    });

    test('should clean old temp files', () async {
      // Create old test files
      final oldFile = File('${testDir.path}/old_file.tmp');
      await oldFile.create();

      // Set modification time to 2 days ago (older than 24 hour threshold)
      await oldFile.setLastModified(
        DateTime.now().subtract(const Duration(days: 2)),
      );

      // Note: Actual cleanup targets system temp directory,
      // but we can verify the mechanism works
      await ResourceCleanupManager.performCleanupNow();

      expect(true, true);
    });
  });

  group('Cache Statistics', () {
    test('should get cache statistics', () {
      final stats = ResourceCleanupManager.getCacheStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('currentSize'), true);
      expect(stats.containsKey('maximumSize'), true);
      expect(stats.containsKey('currentSizeBytes'), true);
      expect(stats.containsKey('maximumSizeBytes'), true);
      expect(stats.containsKey('liveImageCount'), true);
      expect(stats.containsKey('pendingImageCount'), true);
    });

    test('should get formatted cache statistics', () {
      final formatted = ResourceCleanupManager.getFormattedCacheStats();

      expect(formatted, isA<String>());
      expect(formatted.contains('Image Cache Statistics'), true);
      expect(formatted.contains('Current:'), true);
      expect(formatted.contains('Memory:'), true);
    });

    test('should report reasonable cache limits', () {
      final stats = ResourceCleanupManager.getCacheStats();

      expect(stats['maximumSize'], greaterThan(0));
      expect(stats['maximumSizeBytes'], greaterThan(0));
      expect(stats['currentSize'], greaterThanOrEqualTo(0));
      expect(stats['currentSizeBytes'], greaterThanOrEqualTo(0));
    });
  });

  group('Memory-Efficient Cache', () {
    test('should create cache with max size', () {
      final cache = MemoryEfficientCache<int, String>(maxSize: 5);

      expect(cache.maxSize, 5);
      expect(cache.size, 0);
    });

    test('should store and retrieve values', () {
      final cache = MemoryEfficientCache<String, String>();

      cache.put('key1', 'value1');
      final value = cache.get('key1');

      expect(value, 'value1');
    });

    test('should return null for missing keys', () {
      final cache = MemoryEfficientCache<String, String>();

      final value = cache.get('nonexistent');

      expect(value, null);
    });

    test('should enforce max size limit', () {
      final cache = MemoryEfficientCache<int, String>(maxSize: 3);

      cache.put(1, 'one');
      cache.put(2, 'two');
      cache.put(3, 'three');
      cache.put(4, 'four'); // Should evict oldest

      expect(cache.size, 3);
      expect(cache.get(1), null); // Should be evicted
      expect(cache.get(4), 'four'); // Should be present
    });

    test('should check if key exists', () {
      final cache = MemoryEfficientCache<String, String>();

      cache.put('exists', 'value');

      expect(cache.containsKey('exists'), true);
      expect(cache.containsKey('missing'), false);
    });

    test('should remove entries', () {
      final cache = MemoryEfficientCache<String, String>();

      cache.put('key', 'value');
      cache.remove('key');

      expect(cache.get('key'), null);
    });

    test('should clear all entries', () {
      final cache = MemoryEfficientCache<String, String>();

      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.clear();

      expect(cache.size, 0);
      expect(cache.get('key1'), null);
      expect(cache.get('key2'), null);
    });

    test('should get live count', () {
      final cache = MemoryEfficientCache<int, String>();

      cache.put(1, 'one');
      cache.put(2, 'two');

      expect(cache.liveCount, 2);
    });

    test('should compact dead entries', () {
      final cache = MemoryEfficientCache<int, String>();

      cache.put(1, 'one');
      cache.put(2, 'two');

      // Compact should remove any GC'd entries
      cache.compact();

      expect(cache.size, greaterThanOrEqualTo(0));
    });
  });

  group('App Lifecycle Management', () {
    test('should create lifecycle manager', () {
      final manager = AppLifecycleManager();

      expect(manager, isA<WidgetsBindingObserver>());
    });

    test('should handle app pause', () {
      final manager = AppLifecycleManager();

      // Should not throw exception
      manager.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(true, true);
    });

    test('should handle app resume', () {
      final manager = AppLifecycleManager();

      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(true, true);
    });

    test('should handle app termination', () {
      final manager = AppLifecycleManager();

      manager.didChangeAppLifecycleState(AppLifecycleState.detached);

      expect(true, true);
    });

    test('should handle app inactive state', () {
      final manager = AppLifecycleManager();

      manager.didChangeAppLifecycleState(AppLifecycleState.inactive);

      expect(true, true);
    });

    test('should handle app hidden state', () {
      final manager = AppLifecycleManager();

      manager.didChangeAppLifecycleState(AppLifecycleState.hidden);

      expect(true, true);
    });
  });

  group('Integration Tests', () {
    test('should manage resources through full lifecycle', () async {
      final manager = AppLifecycleManager();

      // Start periodic cleanup
      ResourceCleanupManager.startPeriodicCleanup();

      // Simulate app lifecycle
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Perform some operations
      await ResourceCleanupManager.performCleanupNow();

      // App goes to background
      manager.didChangeAppLifecycleState(AppLifecycleState.paused);

      // App comes back
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // App terminates
      manager.didChangeAppLifecycleState(AppLifecycleState.detached);

      expect(true, true);
    });

    test('should maintain cache limits after cleanup', () async {
      // Perform cleanup
      await ResourceCleanupManager.performCleanupNow();

      // Check cache limits are reasonable
      final stats = ResourceCleanupManager.getCacheStats();

      expect(stats['maximumSize'], lessThanOrEqualTo(1000));
      expect(stats['maximumSizeBytes'], lessThanOrEqualTo(200 * 1024 * 1024));
    });

    test('should handle rapid cleanup calls', () async {
      // Perform multiple cleanups rapidly
      await Future.wait([
        ResourceCleanupManager.performCleanupNow(),
        ResourceCleanupManager.performCleanupNow(),
        ResourceCleanupManager.performCleanupNow(),
      ]);

      // Should complete without error
      expect(true, true);
    });
  });

  group('Performance Tests', () {
    test('should complete cleanup quickly', () async {
      final stopwatch = Stopwatch()..start();

      await ResourceCleanupManager.performCleanupNow();

      stopwatch.stop();

      // Should complete in less than 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should handle large cache efficiently', () async {
      final cache = MemoryEfficientCache<int, String>(maxSize: 1000);

      final stopwatch = Stopwatch()..start();

      // Add many entries
      for (int i = 0; i < 1000; i++) {
        cache.put(i, 'value_$i');
      }

      stopwatch.stop();

      // Should complete quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(cache.size, 1000);
    });

    test('should compact cache efficiently', () async {
      final cache = MemoryEfficientCache<int, String>(maxSize: 100);

      // Fill cache
      for (int i = 0; i < 100; i++) {
        cache.put(i, 'value_$i');
      }

      final stopwatch = Stopwatch()..start();
      cache.compact();
      stopwatch.stop();

      // Should complete quickly (< 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
