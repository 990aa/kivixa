import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';

void main() {
  group('GraphNodePosition', () {
    test('should create with required fields', () {
      const node = GraphNodePosition(id: 'node-1', x: 100.0, y: 200.0);
      expect(node.id, 'node-1');
      expect(node.x, 100.0);
      expect(node.y, 200.0);
      expect(node.radius, 20.0); // default
      expect(node.nodeType, 'node'); // default
    });

    test('should create with all fields', () {
      const node = GraphNodePosition(
        id: 'node-2',
        x: 50.0,
        y: 75.0,
        radius: 30.0,
        nodeType: 'hub',
      );
      expect(node.id, 'node-2');
      expect(node.x, 50.0);
      expect(node.y, 75.0);
      expect(node.radius, 30.0);
      expect(node.nodeType, 'hub');
    });

    test('fromRust should parse map correctly', () {
      final data = {
        'id': 'rust-node',
        'x': 123.0,
        'y': 456.0,
        'radius': 25.0,
        'color': 0xFF00FF00,
        'node_type': 'topic',
      };

      final node = GraphNodePosition.fromRust(data);

      expect(node.id, 'rust-node');
      expect(node.x, 123.0);
      expect(node.y, 456.0);
      expect(node.radius, 25.0);
      expect(node.nodeType, 'topic');
    });

    test('fromRust should handle missing optional fields', () {
      final data = {'id': 'minimal', 'x': 10, 'y': 20};

      final node = GraphNodePosition.fromRust(data);

      expect(node.id, 'minimal');
      expect(node.x, 10.0);
      expect(node.y, 20.0);
      expect(node.radius, 20.0); // default
      expect(node.nodeType, 'node'); // default
    });
  });

  group('GraphEdgePosition', () {
    test('should create with required fields', () {
      const edge = GraphEdgePosition(
        sourceX: 0.0,
        sourceY: 0.0,
        targetX: 100.0,
        targetY: 100.0,
      );
      expect(edge.sourceX, 0.0);
      expect(edge.sourceY, 0.0);
      expect(edge.targetX, 100.0);
      expect(edge.targetY, 100.0);
    });

    test('fromRust should parse map correctly', () {
      final data = {
        'source_x': 10.0,
        'source_y': 20.0,
        'target_x': 30.0,
        'target_y': 40.0,
      };

      final edge = GraphEdgePosition.fromRust(data);

      expect(edge.sourceX, 10.0);
      expect(edge.sourceY, 20.0);
      expect(edge.targetX, 30.0);
      expect(edge.targetY, 40.0);
    });
  });

  group('GraphFrame', () {
    test('should create with nodes and edges', () {
      const nodes = [
        GraphNodePosition(id: 'a', x: 0, y: 0),
        GraphNodePosition(id: 'b', x: 100, y: 100),
      ];
      const edges = [
        GraphEdgePosition(sourceX: 0, sourceY: 0, targetX: 100, targetY: 100),
      ];

      const frame = GraphFrame(
        nodes: nodes,
        edges: edges,
        frameNumber: 1,
        isRunning: true,
      );

      expect(frame.nodes.length, 2);
      expect(frame.edges.length, 1);
      expect(frame.frameNumber, 1);
      expect(frame.isRunning, true);
    });

    test('empty factory should create empty frame', () {
      final frame = GraphFrame.empty();

      expect(frame.nodes, isEmpty);
      expect(frame.edges, isEmpty);
      expect(frame.frameNumber, 0);
      expect(frame.isRunning, false);
    });
  });

  group('KnowledgeGraphController', () {
    test('should start unattached', () {
      final controller = KnowledgeGraphController();
      expect(controller.isAttached, false);
    });

    test('updateGraph should not throw when unattached', () {
      final controller = KnowledgeGraphController();
      expect(() => controller.updateGraph([], []), returnsNormally);
    });
  });
}
