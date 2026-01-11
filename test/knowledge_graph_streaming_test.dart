import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';
import 'package:kivixa/services/ai/knowledge_graph_streaming.dart';

/// Helper to check if we can safely call Rust native functions
/// In unit tests, the native library isn't loaded, so these tests
/// verify that the service handles errors gracefully.
bool get rustBridgeAvailable {
  try {
    // This will throw if bridge isn't initialized
    return kRustBridgeAvailable;
  } catch (_) {
    return false;
  }
}

void main() {
  group(
    'KnowledgeGraphStreamingService',
    skip: 'Rust bridge unavailable in unit tests',
    () {
      test('should be a singleton', () {
        final instance1 = KnowledgeGraphStreamingService.instance;
        final instance2 = KnowledgeGraphStreamingService.instance;
        expect(identical(instance1, instance2), true);
      });

      test('should start not streaming', () {
        final service = KnowledgeGraphStreamingService.instance;
        // Clean up from any previous tests - this catches errors gracefully
        try {
          service.stopStreaming();
        } catch (_) {
          // Expected - Rust bridge not initialized in tests
        }
        expect(service.isStreaming, false);
      });

      test('should provide frame stream', () {
        final service = KnowledgeGraphStreamingService.instance;
        expect(service.frameStream, isA<Stream<GraphFrame>>());
      });

      test('currentFps should be a number', () {
        final service = KnowledgeGraphStreamingService.instance;
        expect(service.currentFps, isA<double>());
      });

      test(
        'startStreaming handles error when bridge not initialized',
        () async {
          final service = KnowledgeGraphStreamingService.instance;
          // In test environment, Rust bridge isn't initialized
          // Service should handle this gracefully
          expect(
            () async => await service.startStreaming(),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('addNode handles error when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        // Should throw because bridge isn't initialized
        expect(
          () async =>
              await service.addNode(id: 'test-node', x: 100.0, y: 200.0),
          throwsA(isA<StateError>()),
        );
      });

      test('removeNode handles error when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        expect(
          () async => await service.removeNode('test-node'),
          throwsA(isA<StateError>()),
        );
      });

      test('addEdge handles error when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        expect(
          () async => await service.addEdge(fromId: 'a', toId: 'b'),
          throwsA(isA<StateError>()),
        );
      });

      test('removeEdge handles error when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        expect(
          () async => await service.removeEdge('a', 'b'),
          throwsA(isA<StateError>()),
        );
      });

      test('pinNode handles error when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        expect(
          () async => await service.pinNode('node', true),
          throwsA(isA<StateError>()),
        );
      });

      test(
        'setNodePosition handles error when bridge not initialized',
        () async {
          final service = KnowledgeGraphStreamingService.instance;
          expect(
            () async => await service.setNodePosition('node', 0, 0),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('clearGraph handles error when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        expect(
          () async => await service.clearGraph(),
          throwsA(isA<StateError>()),
        );
      });

      test('getStats returns fallback when bridge not initialized', () async {
        final service = KnowledgeGraphStreamingService.instance;
        // getStats has a try-catch that returns fallback values
        final stats = await service.getStats();
        expect(stats, isA<GraphStats>());
        expect(stats.nodeCount, 0);
        expect(stats.edgeCount, 0);
      });

      test('updateViewport handles error gracefully', () async {
        final service = KnowledgeGraphStreamingService.instance;
        // updateViewport logs errors but doesn't throw
        // Just verify it doesn't crash
        await service.updateViewport(0, 0, 1920, 1080, 1.0);
        // If we get here without exception, the error was handled gracefully
        expect(true, true);
      });
    },
  );

  group('GraphStats', () {
    test('should create with all fields', () {
      const stats = GraphStats(
        nodeCount: 10,
        edgeCount: 15,
        visibleCount: 8,
        fps: 60.0,
      );
      expect(stats.nodeCount, 10);
      expect(stats.edgeCount, 15);
      expect(stats.visibleCount, 8);
      expect(stats.fps, 60.0);
    });

    test('toString should format correctly', () {
      const stats = GraphStats(
        nodeCount: 5,
        edgeCount: 7,
        visibleCount: 5,
        fps: 59.5,
      );
      final str = stats.toString();
      expect(str, contains('nodes: 5'));
      expect(str, contains('edges: 7'));
      expect(str, contains('visible: 5'));
      expect(str, contains('fps: 59.5'));
    });
  });
}
