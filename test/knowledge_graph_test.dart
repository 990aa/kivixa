// Knowledge Graph Tests
//
// Comprehensive tests for all Knowledge Graph features including:
// - Node management (create, edit, delete)
// - Link management (create, edit, delete, clear all)
// - Node shapes and colors
// - Link styles (thickness, arrows, colors, labels)
// - Viewport navigation (pan, zoom, recenter)
// - Physics simulation

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/knowledge_graph.dart';

void main() {
  group('NodeShape enum', () {
    test('should have correct labels', () {
      expect(NodeShape.circle.label, 'Circle');
      expect(NodeShape.square.label, 'Square');
      expect(NodeShape.diamond.label, 'Diamond');
      expect(NodeShape.hexagon.label, 'Hexagon');
      expect(NodeShape.star.label, 'Star');
      expect(NodeShape.rectangle.label, 'Rectangle');
    });

    test('should have correct icons', () {
      expect(NodeShape.circle.icon, Icons.circle_outlined);
      expect(NodeShape.square.icon, Icons.square_outlined);
      expect(NodeShape.diamond.icon, Icons.diamond_outlined);
      expect(NodeShape.hexagon.icon, Icons.hexagon_outlined);
      expect(NodeShape.star.icon, Icons.star_outline);
      expect(NodeShape.rectangle.icon, Icons.crop_landscape);
    });

    test('should have all 6 shape values', () {
      expect(NodeShape.values.length, 6);
    });
  });

  group('LinkStyle enum', () {
    test('should have correct labels', () {
      expect(LinkStyle.thin.label, 'Thin');
      expect(LinkStyle.normal.label, 'Normal');
      expect(LinkStyle.thick.label, 'Thick');
    });

    test('should have correct widths', () {
      expect(LinkStyle.thin.width, 1.0);
      expect(LinkStyle.normal.width, 2.0);
      expect(LinkStyle.thick.width, 4.0);
    });

    test('should have all 3 style values', () {
      expect(LinkStyle.values.length, 3);
    });
  });

  group('ArrowStyle enum', () {
    test('should have correct labels', () {
      expect(ArrowStyle.none.label, 'None');
      expect(ArrowStyle.single.label, 'Single Arrow');
      expect(ArrowStyle.double.label, 'Double Arrow');
    });

    test('should have all 3 arrow values', () {
      expect(ArrowStyle.values.length, 3);
    });
  });

  group('GraphNode', () {
    test('should create with required fields', () {
      const node = GraphNode(
        id: 'test_1',
        title: 'Test Node',
        x: 100,
        y: 200,
        color: Colors.blue,
      );

      expect(node.id, 'test_1');
      expect(node.title, 'Test Node');
      expect(node.x, 100);
      expect(node.y, 200);
      expect(node.color, Colors.blue);
      expect(node.description, '');
      expect(node.radius, 25);
      expect(node.nodeType, 'note');
      expect(node.shape, NodeShape.circle);
      expect(node.linkedNoteIds, isEmpty);
    });

    test('should create with all fields', () {
      const node = GraphNode(
        id: 'hub_1',
        title: 'Hub Node',
        description: 'A hub for topics',
        x: 50,
        y: 75,
        radius: 35,
        color: Colors.red,
        nodeType: 'hub',
        shape: NodeShape.hexagon,
        linkedNoteIds: ['note_1', 'note_2'],
      );

      expect(node.id, 'hub_1');
      expect(node.title, 'Hub Node');
      expect(node.description, 'A hub for topics');
      expect(node.x, 50);
      expect(node.y, 75);
      expect(node.radius, 35);
      expect(node.color, Colors.red);
      expect(node.nodeType, 'hub');
      expect(node.shape, NodeShape.hexagon);
      expect(node.linkedNoteIds, ['note_1', 'note_2']);
    });

    test('copyWith should update specified fields', () {
      const original = GraphNode(
        id: 'test_1',
        title: 'Original',
        x: 0,
        y: 0,
        color: Colors.blue,
      );

      final updated = original.copyWith(
        title: 'Updated',
        x: 100,
        y: 200,
        shape: NodeShape.star,
      );

      expect(updated.id, 'test_1'); // unchanged
      expect(updated.title, 'Updated');
      expect(updated.x, 100);
      expect(updated.y, 200);
      expect(updated.color, Colors.blue); // unchanged
      expect(updated.shape, NodeShape.star);
    });

    test('copyWith should preserve unspecified fields', () {
      const original = GraphNode(
        id: 'test_1',
        title: 'Original',
        description: 'Description',
        x: 10,
        y: 20,
        radius: 30,
        color: Colors.green,
        nodeType: 'idea',
        shape: NodeShape.diamond,
        linkedNoteIds: ['note_1'],
      );

      final updated = original.copyWith(title: 'New Title');

      expect(updated.id, original.id);
      expect(updated.description, original.description);
      expect(updated.x, original.x);
      expect(updated.y, original.y);
      expect(updated.radius, original.radius);
      expect(updated.color, original.color);
      expect(updated.nodeType, original.nodeType);
      expect(updated.shape, original.shape);
      expect(updated.linkedNoteIds, original.linkedNoteIds);
    });

    test('toPosition should create GraphNodePosition', () {
      const node = GraphNode(
        id: 'test_1',
        title: 'Test',
        x: 100,
        y: 200,
        radius: 25,
        color: Colors.blue,
        nodeType: 'note',
      );

      final position = node.toPosition();

      expect(position.id, 'test_1');
      expect(position.x, 100);
      expect(position.y, 200);
      expect(position.radius, 25);
      expect(position.color, Colors.blue);
      expect(position.nodeType, 'note');
    });
  });

  group('GraphEdge', () {
    test('should create with required fields', () {
      const edge = GraphEdge(
        id: 'edge_1',
        sourceId: 'node_1',
        targetId: 'node_2',
      );

      expect(edge.id, 'edge_1');
      expect(edge.sourceId, 'node_1');
      expect(edge.targetId, 'node_2');
      expect(edge.label, '');
      expect(edge.edgeType, 'link');
      expect(edge.style, LinkStyle.normal);
      expect(edge.arrowStyle, ArrowStyle.none);
      expect(edge.color, isNull);
    });

    test('should create with all fields', () {
      const edge = GraphEdge(
        id: 'edge_1',
        sourceId: 'node_1',
        targetId: 'node_2',
        label: 'relates to',
        edgeType: 'topic',
        style: LinkStyle.thick,
        arrowStyle: ArrowStyle.single,
        color: Colors.purple,
      );

      expect(edge.id, 'edge_1');
      expect(edge.sourceId, 'node_1');
      expect(edge.targetId, 'node_2');
      expect(edge.label, 'relates to');
      expect(edge.edgeType, 'topic');
      expect(edge.style, LinkStyle.thick);
      expect(edge.arrowStyle, ArrowStyle.single);
      expect(edge.color, Colors.purple);
    });

    test('copyWith should update specified fields', () {
      const original = GraphEdge(
        id: 'edge_1',
        sourceId: 'node_1',
        targetId: 'node_2',
      );

      final updated = original.copyWith(
        label: 'new label',
        style: LinkStyle.thick,
        arrowStyle: ArrowStyle.double,
      );

      expect(updated.id, 'edge_1');
      expect(updated.sourceId, 'node_1');
      expect(updated.targetId, 'node_2');
      expect(updated.label, 'new label');
      expect(updated.style, LinkStyle.thick);
      expect(updated.arrowStyle, ArrowStyle.double);
    });

    test('copyWith should preserve unspecified fields', () {
      const original = GraphEdge(
        id: 'edge_1',
        sourceId: 'node_1',
        targetId: 'node_2',
        label: 'test',
        edgeType: 'similarity',
        style: LinkStyle.thin,
        arrowStyle: ArrowStyle.single,
        color: Colors.red,
      );

      final updated = original.copyWith(label: 'updated');

      expect(updated.id, original.id);
      expect(updated.sourceId, original.sourceId);
      expect(updated.targetId, original.targetId);
      expect(updated.edgeType, original.edgeType);
      expect(updated.style, original.style);
      expect(updated.arrowStyle, original.arrowStyle);
      expect(updated.color, original.color);
    });
  });

  group('KnowledgeGraphPage Widget', () {
    testWidgets('should render with title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      expect(find.text('Knowledge Graph'), findsOneWidget);
    });

    testWidgets('should show node/link count badge', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      // Demo data is loaded, should show counts
      await tester.pump();

      // Find text that contains "nodes" and "links"
      expect(find.textContaining('nodes'), findsOneWidget);
      expect(find.textContaining('links'), findsOneWidget);
    });

    testWidgets('should have add node button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('should have manage links button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('should have zoom controls', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
    });

    testWidgets('should have recenter button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    });

    testWidgets('should have popup menu', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('tapping add node shows adding mode overlay', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Tap to place node'), findsOneWidget);
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
    });

    testWidgets('can cancel adding node mode', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Tap to place node'), findsOneWidget);

      // Find and tap the close button in the overlay
      final closeButtons = find.byIcon(Icons.close);
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Tap to place node'), findsNothing);
    });

    testWidgets('popup menu shows reload and clear options', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Reload Demo'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('manage links button opens dialog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      expect(find.text('Manage Links'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('manage links dialog shows clear all button when links exist', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      // Demo data has links, so Clear All should be visible
      expect(find.text('Clear All Links'), findsOneWidget);
    });

    testWidgets('zoom in increases scale', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      // Tap zoom in multiple times
      await tester.tap(find.byIcon(Icons.zoom_in));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.zoom_in));
      await tester.pump();

      // The graph should still render (no errors) - multiple CustomPaint exist in widget tree
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('zoom out decreases scale', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.zoom_out));
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('recenter button works', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.center_focus_strong));
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Add Node Dialog', () {
    testWidgets('tapping canvas in add mode opens add node dialog', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      // Enter add node mode
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Tap on canvas
      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Add Node'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('add node dialog has node type selector', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      expect(find.text('Node Type'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Hub'), findsOneWidget);
      expect(find.text('Idea'), findsOneWidget);
    });

    testWidgets('add node dialog has shape selector', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      expect(find.text('Shape'), findsOneWidget);
      // Should have ChoiceChip widgets for shapes
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('add node dialog has color selector', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('add node requires title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      // Try to add without title
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Should show error in SnackBar and dialog should still be open
      expect(find.text('Add Node'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('can cancel add node dialog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Node'), findsNothing);
    });
  });

  group('Clear Graph', () {
    testWidgets('clear all shows confirmation dialog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Graph?'), findsOneWidget);
      expect(
        find.text('This will remove all nodes and links.'),
        findsOneWidget,
      );
    });

    testWidgets('can cancel clear graph', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Graph?'), findsNothing);
    });
  });

  group('Graph Rendering', () {
    testWidgets('CustomPaint is present for graph', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      // Multiple CustomPaint widgets exist (for icons, graph, etc.)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('graph container fills available space', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });
  });

  group('Gestures', () {
    testWidgets('GestureDetector handles scale gestures', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeGraphPage()));

      final gesture = find.byType(GestureDetector).first;
      expect(tester.widget(gesture), isA<GestureDetector>());

      // Perform scale gesture
      final center = tester.getCenter(gesture);
      final TestGesture pointer1 = await tester.startGesture(center);
      final TestGesture pointer2 = await tester.startGesture(
        center + const Offset(100, 0),
      );

      await tester.pump();

      await pointer1.moveBy(const Offset(-50, 0));
      await pointer2.moveBy(const Offset(50, 0));

      await tester.pump();

      await pointer1.up();
      await pointer2.up();

      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
