import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/knowledge_graph_service.dart';

void main() {
  group('GraphNode', () {
    test('should create with required fields', () {
      final node = GraphNode(
        id: 'test-1',
        label: 'Test Node',
        nodeType: 'note',
      );
      expect(node.id, 'test-1');
      expect(node.label, 'Test Node');
      expect(node.nodeType, 'note');
      expect(node.x, 0.0);
      expect(node.y, 0.0);
      expect(node.color, isNull);
      expect(node.metadata, isNull);
    });

    test('should create with all fields', () {
      final node = GraphNode(
        id: 'test-2',
        label: 'Full Node',
        nodeType: 'hub',
        x: 100.0,
        y: 200.0,
        color: '#FF0000',
        metadata: {'key': 'value'},
      );
      expect(node.id, 'test-2');
      expect(node.x, 100.0);
      expect(node.y, 200.0);
      expect(node.color, '#FF0000');
      expect(node.metadata, {'key': 'value'});
    });

    test('copyWith should update specified fields', () {
      final node = GraphNode(
        id: 'original',
        label: 'Original',
        nodeType: 'note',
        x: 0.0,
        y: 0.0,
      );

      final updated = node.copyWith(x: 50.0, y: 75.0);

      expect(updated.id, 'original');
      expect(updated.label, 'Original');
      expect(updated.x, 50.0);
      expect(updated.y, 75.0);
    });

    test('copyWith should preserve unchanged fields', () {
      final node = GraphNode(
        id: 'test',
        label: 'Test',
        nodeType: 'note',
        color: '#00FF00',
      );

      final updated = node.copyWith(label: 'New Label');

      expect(updated.id, 'test');
      expect(updated.label, 'New Label');
      expect(updated.nodeType, 'note');
      expect(updated.color, '#00FF00');
    });
  });

  group('GraphEdge', () {
    test('should create with required fields', () {
      const edge = GraphEdge(source: 'node-1', target: 'node-2');
      expect(edge.source, 'node-1');
      expect(edge.target, 'node-2');
      expect(edge.weight, 1.0);
      expect(edge.edgeType, 'link');
    });

    test('should create with custom weight and type', () {
      const edge = GraphEdge(
        source: 'a',
        target: 'b',
        weight: 2.5,
        edgeType: 'topic',
      );
      expect(edge.weight, 2.5);
      expect(edge.edgeType, 'topic');
    });
  });

  group('GraphState', () {
    test('empty should have no nodes or edges', () {
      final state = GraphState.empty();
      expect(state.nodes, isEmpty);
      expect(state.edges, isEmpty);
    });

    test('should hold nodes and edges', () {
      final nodes = [
        GraphNode(id: 'a', label: 'A', nodeType: 'note'),
        GraphNode(id: 'b', label: 'B', nodeType: 'hub'),
      ];
      const edges = [GraphEdge(source: 'a', target: 'b')];

      final state = GraphState(nodes: nodes, edges: edges);

      expect(state.nodes.length, 2);
      expect(state.edges.length, 1);
    });
  });

  group('KnowledgeGraphService', () {
    test('should be a singleton', () {
      final instance1 = KnowledgeGraphService();
      final instance2 = KnowledgeGraphService();
      expect(identical(instance1, instance2), true);
    });

    test('should have stream for state updates', () {
      final service = KnowledgeGraphService();
      expect(service.stateStream, isA<Stream<GraphState>>());
    });

    test('currentState should return GraphState', () {
      final service = KnowledgeGraphService();
      expect(service.currentState, isA<GraphState>());
    });
  });
}
