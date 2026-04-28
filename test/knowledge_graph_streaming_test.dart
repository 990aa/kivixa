import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';
import 'package:kivixa/services/ai/knowledge_graph_streaming.dart';

void main() {
  group('KnowledgeGraphStreamingService', () {
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
      'startStreaming degrades gracefully when bridge not initialized',
      () async {
        final service = KnowledgeGraphStreamingService.instance;
        await service.startStreaming();
        expect(service.isStreaming, false);
      },
    );

    test('addNode degrades gracefully when bridge not initialized', () async {
      final service = KnowledgeGraphStreamingService.instance;
      await service.addNode(id: 'test-node', x: 100.0, y: 200.0);
      expect(service.isStreaming, false);
    });

    test(
      'removeNode degrades gracefully when bridge not initialized',
      () async {
        final service = KnowledgeGraphStreamingService.instance;
        await service.removeNode('test-node');
        expect(service.isStreaming, false);
      },
    );

    test('addEdge degrades gracefully when bridge not initialized', () async {
      final service = KnowledgeGraphStreamingService.instance;
      await service.addEdge(fromId: 'a', toId: 'b');
      expect(service.isStreaming, false);
    });

    test(
      'removeEdge degrades gracefully when bridge not initialized',
      () async {
        final service = KnowledgeGraphStreamingService.instance;
        await service.removeEdge('a', 'b');
        expect(service.isStreaming, false);
      },
    );

    test('pinNode degrades gracefully when bridge not initialized', () async {
      final service = KnowledgeGraphStreamingService.instance;
      await service.pinNode('node', true);
      expect(service.isStreaming, false);
    });

    test(
      'setNodePosition degrades gracefully when bridge not initialized',
      () async {
        final service = KnowledgeGraphStreamingService.instance;
        await service.setNodePosition('node', 0, 0);
        expect(service.isStreaming, false);
      },
    );

    test(
      'clearGraph degrades gracefully when bridge not initialized',
      () async {
        final service = KnowledgeGraphStreamingService.instance;
        await service.clearGraph();
        expect(service.isStreaming, false);
      },
    );

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
  });

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
