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
      // Clean up from any previous tests
      service.stopStreaming();
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

    test('startStreaming should enable streaming', () async {
      final service = KnowledgeGraphStreamingService.instance;
      await service.startStreaming();
      expect(service.isStreaming, true);

      // Clean up
      await service.stopStreaming();
    });

    test('stopStreaming should disable streaming', () async {
      final service = KnowledgeGraphStreamingService.instance;
      await service.startStreaming();
      await service.stopStreaming();
      expect(service.isStreaming, false);
    });

    test('addNode should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(
        () =>
            service.addNode(id: 'test-node', x: 100.0, y: 200.0, radius: 20.0),
        returnsNormally,
      );
    });

    test('removeNode should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(() => service.removeNode('test-node'), returnsNormally);
    });

    test('addEdge should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(
        () => service.addEdge(fromId: 'node-a', toId: 'node-b', strength: 1.0),
        returnsNormally,
      );
    });

    test('removeEdge should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(() => service.removeEdge('node-a', 'node-b'), returnsNormally);
    });

    test('pinNode should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(() => service.pinNode('node-a', true), returnsNormally);
    });

    test('setNodePosition should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(
        () => service.setNodePosition('node-a', 50.0, 75.0),
        returnsNormally,
      );
    });

    test('clearGraph should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(() => service.clearGraph(), returnsNormally);
    });

    test('getStats should return GraphStats', () async {
      final service = KnowledgeGraphStreamingService.instance;
      final stats = await service.getStats();
      expect(stats, isA<GraphStats>());
    });

    test('updateViewport should not throw', () async {
      final service = KnowledgeGraphStreamingService.instance;
      expect(
        () => service.updateViewport(0, 0, 1920, 1080, 1.0),
        returnsNormally,
      );
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
