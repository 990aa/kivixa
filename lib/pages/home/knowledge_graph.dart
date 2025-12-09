// Knowledge Graph Page
//
// Interactive visualization of the knowledge graph showing connections
// between notes, topics, and concepts.
//
// Features:
// - Pan and zoom navigation
// - Multiple node shapes (circle, square, diamond, hexagon, star)
// - Node titles and descriptions
// - Link to existing notes from Browse
// - Customizable link styles (thickness, arrows, colors, labels)
// - Clear/delete specific links
// - Recenter to nodes

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';

/// Node shape types for mind mapping
enum NodeShape {
  circle('Circle', Icons.circle_outlined),
  square('Square', Icons.square_outlined),
  diamond('Diamond', Icons.diamond_outlined),
  hexagon('Hexagon', Icons.hexagon_outlined),
  star('Star', Icons.star_outline),
  rectangle('Rectangle', Icons.crop_landscape);

  final String label;
  final IconData icon;
  const NodeShape(this.label, this.icon);
}

/// Link style configuration
enum LinkStyle {
  thin('Thin', 1.0),
  normal('Normal', 2.0),
  thick('Thick', 4.0);

  final String label;
  final double width;
  const LinkStyle(this.label, this.width);
}

/// Arrow style for links
enum ArrowStyle {
  none('None'),
  single('Single Arrow'),
  double('Double Arrow');

  final String label;
  const ArrowStyle(this.label);
}

/// Enhanced graph node with title, description, shape, and linked notes
class GraphNode {
  final String id;
  final String title;
  final String description;
  final double x;
  final double y;
  final double radius;
  final Color color;
  final String nodeType; // 'hub', 'note', 'idea', 'topic'
  final NodeShape shape;
  final List<String> linkedNoteIds; // IDs of notes from Browse section

  const GraphNode({
    required this.id,
    required this.title,
    this.description = '',
    required this.x,
    required this.y,
    this.radius = 25,
    required this.color,
    this.nodeType = 'note',
    this.shape = NodeShape.circle,
    this.linkedNoteIds = const [],
  });

  GraphNode copyWith({
    String? id,
    String? title,
    String? description,
    double? x,
    double? y,
    double? radius,
    Color? color,
    String? nodeType,
    NodeShape? shape,
    List<String>? linkedNoteIds,
  }) {
    return GraphNode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      color: color ?? this.color,
      nodeType: nodeType ?? this.nodeType,
      shape: shape ?? this.shape,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
    );
  }

  // Convert to GraphNodePosition for the painter
  GraphNodePosition toPosition() => GraphNodePosition(
    id: id,
    x: x,
    y: y,
    radius: radius,
    color: color,
    nodeType: nodeType,
  );
}

/// Enhanced graph edge with label, style, and arrow
class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String label;
  final String edgeType; // 'link', 'topic', 'similarity'
  final LinkStyle style;
  final ArrowStyle arrowStyle;
  final Color? color;

  const GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.label = '',
    this.edgeType = 'link',
    this.style = LinkStyle.normal,
    this.arrowStyle = ArrowStyle.none,
    this.color,
  });

  GraphEdge copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    String? label,
    String? edgeType,
    LinkStyle? style,
    ArrowStyle? arrowStyle,
    Color? color,
  }) {
    return GraphEdge(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      label: label ?? this.label,
      edgeType: edgeType ?? this.edgeType,
      style: style ?? this.style,
      arrowStyle: arrowStyle ?? this.arrowStyle,
      color: color ?? this.color,
    );
  }
}

/// Knowledge Graph visualization page
class KnowledgeGraphPage extends StatefulWidget {
  final String? focusNoteId;
  final String? filterTopic;

  const KnowledgeGraphPage({super.key, this.focusNoteId, this.filterTopic});

  @override
  State<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends State<KnowledgeGraphPage>
    with TickerProviderStateMixin {
  // Graph data
  final List<GraphNode> _nodes = [];
  final List<GraphEdge> _edges = [];

  // Physics simulation
  Timer? _physicsTimer;
  final Map<String, Offset> _velocities = {};

  // Interaction state
  GraphNode? _selectedNode;
  String? _linkingFromNode;
  var _isAddingNode = false;

  // Viewport state
  var _panOffset = Offset.zero;
  var _scale = 1.0;
  Offset? _lastFocalPoint;
  double? _lastScale;

  // Counters
  var _nodeCounter = 0;
  var _edgeCounter = 0;

  // Cluster colors
  static const _clusterColors = <Color>[
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFF45B7D1), // Blue
    Color(0xFF96CEB4), // Green
    Color(0xFFFFEAA7), // Yellow
    Color(0xFFDDA0DD), // Purple
    Color(0xFFFF8C42), // Orange
    Color(0xFF98D8C8), // Mint
  ];

  @override
  void initState() {
    super.initState();
    _loadDemoData();
    _startPhysicsSimulation();
  }

  @override
  void dispose() {
    _physicsTimer?.cancel();
    super.dispose();
  }

  void _loadDemoData() {
    final random = Random(42);

    // Create topic hub nodes with different shapes
    final topics = [
      ('Recipes', NodeShape.hexagon),
      ('Code', NodeShape.diamond),
      ('Ideas', NodeShape.star),
      ('Research', NodeShape.square),
      ('Projects', NodeShape.circle),
    ];

    for (var i = 0; i < topics.length; i++) {
      final (name, shape) = topics[i];
      final angle = (i / topics.length) * 2 * pi;
      const radius = 150.0;
      final nodeId = 'hub_${name.toLowerCase()}';

      _nodes.add(
        GraphNode(
          id: nodeId,
          title: name,
          description: 'Topic hub for $name',
          x: cos(angle) * radius,
          y: sin(angle) * radius,
          radius: 35,
          color: _clusterColors[i % _clusterColors.length],
          nodeType: 'hub',
          shape: shape,
        ),
      );
      _velocities[nodeId] = Offset.zero;
    }

    // Create note nodes connected to topics
    final noteTopics = {
      'Pasta Recipe': ('recipes', 'A delicious Italian pasta dish'),
      'Curry Recipe': ('recipes', 'Spicy Indian curry'),
      'Flutter Tips': ('code', 'Best practices for Flutter'),
      'Rust Basics': ('code', 'Getting started with Rust'),
      'App Idea': ('ideas', 'A new app concept'),
      'ML Paper': ('research', 'Machine learning research'),
      'Kivixa': ('projects', 'Note-taking app project'),
    };

    var noteIndex = 0;
    noteTopics.forEach((noteName, topicData) {
      final (topic, description) = topicData;
      final hubNode = _nodes.firstWhere((n) => n.id == 'hub_$topic');
      final angle = random.nextDouble() * 2 * pi;
      final distance = 80 + random.nextDouble() * 60;

      final nodeId = 'note_${noteIndex++}';
      _nodes.add(
        GraphNode(
          id: nodeId,
          title: noteName,
          description: description,
          x: hubNode.x + cos(angle) * distance,
          y: hubNode.y + sin(angle) * distance,
          radius: 22,
          color: hubNode.color.withValues(alpha: 0.8),
          nodeType: 'note',
          shape: NodeShape.circle,
        ),
      );
      _velocities[nodeId] = Offset.zero;

      // Add edge to hub with label
      _edges.add(
        GraphEdge(
          id: 'edge_${_edgeCounter++}',
          sourceId: nodeId,
          targetId: hubNode.id,
          label: 'belongs to',
          edgeType: 'topic',
          style: LinkStyle.normal,
          arrowStyle: ArrowStyle.single,
        ),
      );
    });

    // Add some cross-links
    _edges.add(
      GraphEdge(
        id: 'edge_${_edgeCounter++}',
        sourceId: 'note_0',
        targetId: 'note_1',
        label: 'related',
        edgeType: 'link',
        style: LinkStyle.thin,
        arrowStyle: ArrowStyle.double,
      ),
    );

    _nodeCounter = noteIndex;
  }

  void _startPhysicsSimulation() {
    _physicsTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updatePhysics(),
    );
  }

  void _updatePhysics() {
    if (_nodes.isEmpty) return;

    const repulsion = 5000.0;
    const attraction = 0.01;
    const damping = 0.85;
    const minDistance = 50.0;

    final forces = <String, Offset>{};
    for (final node in _nodes) {
      forces[node.id] = Offset.zero;
    }

    // Repulsion between all nodes
    for (var i = 0; i < _nodes.length; i++) {
      for (var j = i + 1; j < _nodes.length; j++) {
        final a = _nodes[i];
        final b = _nodes[j];

        var dx = a.x - b.x;
        var dy = a.y - b.y;
        final distSq = dx * dx + dy * dy + 1;
        final dist = sqrt(distSq);

        if (dist < minDistance) {
          dx = (dx / dist) * minDistance;
          dy = (dy / dist) * minDistance;
        }

        final force = repulsion / distSq;
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;

        forces[a.id] = forces[a.id]! + Offset(fx, fy);
        forces[b.id] = forces[b.id]! + Offset(-fx, -fy);
      }
    }

    // Attraction along edges
    for (final edge in _edges) {
      final source = _nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.sourceId,
        orElse: () => null,
      );
      final target = _nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.targetId,
        orElse: () => null,
      );

      if (source == null || target == null) continue;

      final dx = target.x - source.x;
      final dy = target.y - source.y;
      final dist = sqrt(dx * dx + dy * dy).clamp(1.0, 1000.0);

      final force = dist * attraction;
      final fx = (dx / dist) * force;
      final fy = (dy / dist) * force;

      forces[source.id] = forces[source.id]! + Offset(fx, fy);
      forces[target.id] = forces[target.id]! + Offset(-fx, -fy);
    }

    // Apply forces
    var needsUpdate = false;
    for (var i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final velocity = (_velocities[node.id] ?? Offset.zero) + forces[node.id]!;
      final dampedVelocity = velocity * damping;

      if (_selectedNode?.id == node.id && _lastFocalPoint != null) continue;

      if (dampedVelocity.distance > 0.1) {
        _nodes[i] = node.copyWith(
          x: node.x + dampedVelocity.dx,
          y: node.y + dampedVelocity.dy,
        );
        _velocities[node.id] = dampedVelocity;
        needsUpdate = true;
      } else {
        _velocities[node.id] = Offset.zero;
      }
    }

    if (needsUpdate) {
      setState(() {});
    }
  }

  GraphNode? _hitTestNode(Offset localPosition) {
    final size = context.size;
    if (size == null) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final worldX = (localPosition.dx - center.dx - _panOffset.dx) / _scale;
    final worldY = (localPosition.dy - center.dy - _panOffset.dy) / _scale;

    for (final node in _nodes.reversed) {
      final dx = worldX - node.x;
      final dy = worldY - node.y;
      final distSq = dx * dx + dy * dy;
      if (distSq <= node.radius * node.radius * 1.5) {
        return node;
      }
    }
    return null;
  }

  Offset _localToWorld(Offset localPosition) {
    final size = context.size!;
    final center = Offset(size.width / 2, size.height / 2);
    return Offset(
      (localPosition.dx - center.dx - _panOffset.dx) / _scale,
      (localPosition.dy - center.dy - _panOffset.dy) / _scale,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.scale != 1.0 && _lastScale != null) {
        _scale = (_lastScale! * details.scale).clamp(0.1, 5.0);
      }
      if (_lastFocalPoint != null) {
        _panOffset += details.focalPoint - _lastFocalPoint!;
        _lastFocalPoint = details.focalPoint;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _lastScale = null;
  }

  void _onTapUp(TapUpDetails details) {
    final hitNode = _hitTestNode(details.localPosition);

    if (_isAddingNode) {
      _showAddNodeDialog(_localToWorld(details.localPosition));
      return;
    }

    if (_linkingFromNode != null) {
      if (hitNode != null && hitNode.id != _linkingFromNode) {
        _showAddLinkDialog(_linkingFromNode!, hitNode.id);
      } else {
        setState(() => _linkingFromNode = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Linking cancelled')));
      }
      return;
    }

    setState(() {
      _selectedNode = hitNode;
    });
  }

  void _recenterToNodes() {
    if (_nodes.isEmpty) return;

    // Calculate center of all nodes
    double sumX = 0, sumY = 0;
    for (final node in _nodes) {
      sumX += node.x;
      sumY += node.y;
    }
    final centerX = sumX / _nodes.length;
    final centerY = sumY / _nodes.length;

    setState(() {
      _panOffset = Offset(-centerX * _scale, -centerY * _scale);
    });
  }

  void _showAddNodeDialog(Offset position) {
    var title = '';
    var description = '';
    var selectedShape = NodeShape.circle;
    var selectedColor = _clusterColors[_nodeCounter % _clusterColors.length];
    var nodeType = 'note';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Node'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter node title',
                  ),
                  onChanged: (v) => title = v,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  onChanged: (v) => description = v,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Node Type'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'note', label: Text('Note')),
                    ButtonSegment(value: 'hub', label: Text('Hub')),
                    ButtonSegment(value: 'idea', label: Text('Idea')),
                  ],
                  selected: {nodeType},
                  onSelectionChanged: (v) {
                    setDialogState(() => nodeType = v.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Shape'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: NodeShape.values.map((shape) {
                    return ChoiceChip(
                      label: Icon(shape.icon, size: 20),
                      selected: selectedShape == shape,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => selectedShape = shape);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _clusterColors.map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selectedColor == color
                              ? [BoxShadow(color: color, blurRadius: 8)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isAddingNode = false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }
                Navigator.pop(context);
                _addNode(
                  position: position,
                  title: title,
                  description: description,
                  shape: selectedShape,
                  color: selectedColor,
                  nodeType: nodeType,
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addNode({
    required Offset position,
    required String title,
    required String description,
    required NodeShape shape,
    required Color color,
    required String nodeType,
  }) {
    final nodeId = '${nodeType}_${_nodeCounter++}';

    setState(() {
      _nodes.add(
        GraphNode(
          id: nodeId,
          title: title,
          description: description,
          x: position.dx,
          y: position.dy,
          radius: nodeType == 'hub' ? 35 : 22,
          color: color,
          nodeType: nodeType,
          shape: shape,
        ),
      );
      _velocities[nodeId] = Offset.zero;
      _isAddingNode = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added: $title')));
  }

  void _showAddLinkDialog(String sourceId, String targetId) {
    var label = '';
    var style = LinkStyle.normal;
    var arrowStyle = ArrowStyle.single;
    Color? color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g., "relates to", "depends on"',
                  ),
                  onChanged: (v) => label = v,
                ),
                const SizedBox(height: 16),
                const Text('Line Thickness'),
                const SizedBox(height: 8),
                SegmentedButton<LinkStyle>(
                  segments: LinkStyle.values.map((s) {
                    return ButtonSegment(value: s, label: Text(s.label));
                  }).toList(),
                  selected: {style},
                  onSelectionChanged: (v) {
                    setDialogState(() => style = v.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Arrow Style'),
                const SizedBox(height: 8),
                SegmentedButton<ArrowStyle>(
                  segments: ArrowStyle.values.map((a) {
                    return ButtonSegment(value: a, label: Text(a.label));
                  }).toList(),
                  selected: {arrowStyle},
                  onSelectionChanged: (v) {
                    setDialogState(() => arrowStyle = v.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Color (optional)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    GestureDetector(
                      onTap: () => setDialogState(() => color = null),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                          border: color == null
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: const Icon(
                          Icons.block,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ..._clusterColors.map((c) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => color = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: color == c
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _linkingFromNode = null);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _addEdge(
                  sourceId: sourceId,
                  targetId: targetId,
                  label: label,
                  style: style,
                  arrowStyle: arrowStyle,
                  color: color,
                );
              },
              child: const Text('Add Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _addEdge({
    required String sourceId,
    required String targetId,
    required String label,
    required LinkStyle style,
    required ArrowStyle arrowStyle,
    Color? color,
  }) {
    // Check if edge already exists
    final exists = _edges.any(
      (e) =>
          (e.sourceId == sourceId && e.targetId == targetId) ||
          (e.sourceId == targetId && e.targetId == sourceId),
    );

    if (exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link already exists')));
      setState(() => _linkingFromNode = null);
      return;
    }

    setState(() {
      _edges.add(
        GraphEdge(
          id: 'edge_${_edgeCounter++}',
          sourceId: sourceId,
          targetId: targetId,
          label: label,
          style: style,
          arrowStyle: arrowStyle,
          color: color,
        ),
      );
      _linkingFromNode = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Linked: ${label.isNotEmpty ? label : "connected"}'),
      ),
    );
  }

  void _showEditNodeDialog(GraphNode node) {
    var title = node.title;
    var description = node.description;
    var selectedShape = node.shape;
    var selectedColor = node.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Node'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (v) => title = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (v) => description = v,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Shape'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: NodeShape.values.map((shape) {
                    return ChoiceChip(
                      label: Icon(shape.icon, size: 20),
                      selected: selectedShape == shape,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => selectedShape = shape);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _clusterColors.map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (node.linkedNoteIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Linked Notes: ${node.linkedNoteIds.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                final index = _nodes.indexWhere((n) => n.id == node.id);
                if (index != -1) {
                  setState(() {
                    _nodes[index] = node.copyWith(
                      title: title,
                      description: description,
                      shape: selectedShape,
                      color: selectedColor,
                    );
                    _selectedNode = _nodes[index];
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Links'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: _edges.isEmpty
                ? const Center(child: Text('No links in the graph'))
                : ListView.builder(
                    itemCount: _edges.length,
                    itemBuilder: (context, index) {
                      final edge = _edges[index];
                      final source = _nodes.cast<GraphNode?>().firstWhere(
                        (n) => n?.id == edge.sourceId,
                        orElse: () => null,
                      );
                      final target = _nodes.cast<GraphNode?>().firstWhere(
                        (n) => n?.id == edge.targetId,
                        orElse: () => null,
                      );

                      return ListTile(
                        leading: Icon(
                          edge.arrowStyle == ArrowStyle.double
                              ? Icons.swap_horiz
                              : edge.arrowStyle == ArrowStyle.single
                              ? Icons.arrow_forward
                              : Icons.remove,
                          color: edge.color ?? Colors.grey,
                        ),
                        title: Text(
                          '${source?.title ?? edge.sourceId} → ${target?.title ?? edge.targetId}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: edge.label.isNotEmpty
                            ? Text(edge.label)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _edges.removeAt(index);
                            });
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link deleted')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (_edges.isNotEmpty)
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showClearLinksConfirmation();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Clear All Links'),
              ),
          ],
        ),
      ),
    );
  }

  void _showClearLinksConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Links?'),
        content: Text(
          'This will remove all ${_edges.length} links. Nodes will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _edges.clear();
                _edgeCounter = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All links cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _removeNode(String nodeId) {
    setState(() {
      _nodes.removeWhere((n) => n.id == nodeId);
      _edges.removeWhere((e) => e.sourceId == nodeId || e.targetId == nodeId);
      _velocities.remove(nodeId);
      if (_selectedNode?.id == nodeId) _selectedNode = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Node removed')));
  }

  void _clearGraph() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Graph?'),
        content: const Text('This will remove all nodes and links.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _nodes.clear();
                _edges.clear();
                _velocities.clear();
                _selectedNode = null;
                _nodeCounter = 0;
                _edgeCounter = 0;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Graph'),
        actions: [
          // Stats badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_nodes.length} nodes · ${_edges.length} links',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: _isAddingNode ? colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() => _isAddingNode = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap anywhere to add a node'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            tooltip: 'Add node',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showLinkManagementDialog,
            tooltip: 'Manage links',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => setState(() => _scale *= 1.2),
            tooltip: 'Zoom in',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => setState(() => _scale /= 1.2),
            tooltip: 'Zoom out',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _recenterToNodes,
            tooltip: 'Recenter to nodes',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reload_demo',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reload Demo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Clear All'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'reload_demo') {
                setState(() {
                  _nodes.clear();
                  _edges.clear();
                  _velocities.clear();
                  _nodeCounter = 0;
                  _edgeCounter = 0;
                });
                _loadDemoData();
              } else if (value == 'clear') {
                _clearGraph();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onTapUp: _onTapUp,
            child: Container(
              color: colorScheme.surface,
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: _EnhancedGraphPainter(
                  nodes: _nodes,
                  edges: _edges,
                  panOffset: _panOffset,
                  scale: _scale,
                  selectedNodeId: _selectedNode?.id,
                  linkingFromId: _linkingFromNode,
                ),
              ),
            ),
          ),

          // Adding node overlay
          if (_isAddingNode)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to place node',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        onPressed: () => setState(() => _isAddingNode = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Linking mode overlay
          if (_linkingFromNode != null)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Tap another node to link',
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        onPressed: () =>
                            setState(() => _linkingFromNode = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Empty state
          if (_nodes.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hub,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text('No nodes yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Add nodes using the + button or reload demo data',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      _loadDemoData();
                      setState(() {});
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Load Demo'),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomSheet: _selectedNode != null ? _buildNodeDetails() : null,
    );
  }

  Widget _buildNodeDetails() {
    if (_selectedNode == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = _selectedNode!;

    final connectionCount = _edges
        .where((e) => e.sourceId == node.id || e.targetId == node.id)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape:
                        node.shape == NodeShape.square ||
                            node.shape == NodeShape.rectangle
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius:
                        node.shape == NodeShape.square ||
                            node.shape == NodeShape.rectangle
                        ? BorderRadius.circular(4)
                        : null,
                  ),
                  child: Icon(node.shape.icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${node.nodeType.toUpperCase()} · ${node.shape.label} · $connectionCount links',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedNode = null),
                ),
              ],
            ),
            if (node.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (node.linkedNoteIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: node.linkedNoteIds.map((id) {
                  return Chip(
                    label: Text(id, style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditNodeDialog(node),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _linkingFromNode = node.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tap another node to create a link'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Link'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _panOffset = Offset(-node.x * _scale, -node.y * _scale);
                      });
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Focus'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _removeNode(node.id),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced graph painter with shapes and styled edges
class _EnhancedGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Offset panOffset;
  final double scale;
  final String? selectedNodeId;
  final String? linkingFromId;

  _EnhancedGraphPainter({
    required this.nodes,
    required this.edges,
    this.panOffset = Offset.zero,
    this.scale = 1.0,
    this.selectedNodeId,
    this.linkingFromId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(scale);

    _drawEdges(canvas);
    _drawNodes(canvas);

    canvas.restore();
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      final source = nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.sourceId,
        orElse: () => null,
      );
      final target = nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.targetId,
        orElse: () => null,
      );

      if (source == null || target == null) continue;

      final paint = Paint()
        ..strokeWidth = edge.style.width
        ..style = PaintingStyle.stroke
        ..color = edge.color ?? Colors.grey.withValues(alpha: 0.6);

      final startOffset = Offset(source.x, source.y);
      final endOffset = Offset(target.x, target.y);

      canvas.drawLine(startOffset, endOffset, paint);

      // Draw arrows
      if (edge.arrowStyle != ArrowStyle.none) {
        _drawArrow(
          canvas,
          startOffset,
          endOffset,
          source.radius,
          target.radius,
          paint.color,
          edge.arrowStyle,
        );
      }

      // Draw label
      if (edge.label.isNotEmpty && scale > 0.5) {
        final midPoint = Offset(
          (startOffset.dx + endOffset.dx) / 2,
          (startOffset.dy + endOffset.dy) / 2,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: edge.label,
            style: TextStyle(
              color: paint.color,
              fontSize: 10 / scale.clamp(0.5, 2.0),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Background for label
        final bgRect = Rect.fromCenter(
          center: midPoint,
          width: textPainter.width + 8,
          height: textPainter.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );

        textPainter.paint(
          canvas,
          Offset(
            midPoint.dx - textPainter.width / 2,
            midPoint.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    double sourceRadius,
    double targetRadius,
    Color color,
    ArrowStyle style,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final unitX = dx / dist;
    final unitY = dy / dist;

    // Adjust end point to not overlap with node
    final adjustedEnd = Offset(
      end.dx - unitX * (targetRadius + 5),
      end.dy - unitY * (targetRadius + 5),
    );

    const arrowSize = 10.0;
    final angle = atan2(unitY, unitX);

    final arrowPath = Path();
    arrowPath.moveTo(adjustedEnd.dx, adjustedEnd.dy);
    arrowPath.lineTo(
      adjustedEnd.dx - arrowSize * cos(angle - 0.5),
      adjustedEnd.dy - arrowSize * sin(angle - 0.5),
    );
    arrowPath.moveTo(adjustedEnd.dx, adjustedEnd.dy);
    arrowPath.lineTo(
      adjustedEnd.dx - arrowSize * cos(angle + 0.5),
      adjustedEnd.dy - arrowSize * sin(angle + 0.5),
    );

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw arrow on source side for double arrow
    if (style == ArrowStyle.double) {
      final adjustedStart = Offset(
        start.dx + unitX * (sourceRadius + 5),
        start.dy + unitY * (sourceRadius + 5),
      );
      final reverseAngle = atan2(-unitY, -unitX);

      final reversePath = Path();
      reversePath.moveTo(adjustedStart.dx, adjustedStart.dy);
      reversePath.lineTo(
        adjustedStart.dx - arrowSize * cos(reverseAngle - 0.5),
        adjustedStart.dy - arrowSize * sin(reverseAngle - 0.5),
      );
      reversePath.moveTo(adjustedStart.dx, adjustedStart.dy);
      reversePath.lineTo(
        adjustedStart.dx - arrowSize * cos(reverseAngle + 0.5),
        adjustedStart.dy - arrowSize * sin(reverseAngle + 0.5),
      );

      canvas.drawPath(
        reversePath,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      final offset = Offset(node.x, node.y);

      // Draw glow for selected node
      if (node.id == selectedNodeId) {
        _drawShape(
          canvas,
          offset,
          node.radius + 8,
          node.shape,
          Paint()
            ..color = Colors.orange.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Draw glow for linking source
      if (node.id == linkingFromId) {
        _drawShape(
          canvas,
          offset,
          node.radius + 6,
          node.shape,
          Paint()
            ..color = Colors.green.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Draw node shape
      _drawShape(
        canvas,
        offset,
        node.radius,
        node.shape,
        Paint()..color = node.color,
      );

      // Draw selection ring
      if (node.id == selectedNodeId) {
        _drawShape(
          canvas,
          offset,
          node.radius + 3,
          node.shape,
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke,
        );
      }

      // Draw label
      if (scale > 0.4) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11 / scale.clamp(0.5, 2.0),
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout(maxWidth: node.radius * 2.5);
        textPainter.paint(
          canvas,
          Offset(
            node.x - textPainter.width / 2,
            node.y - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawShape(
    Canvas canvas,
    Offset center,
    double radius,
    NodeShape shape,
    Paint paint,
  ) {
    switch (shape) {
      case NodeShape.circle:
        canvas.drawCircle(center, radius, paint);
      case NodeShape.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: radius * 2,
            height: radius * 2,
          ),
          paint,
        );
      case NodeShape.diamond:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius, center.dy);
        path.lineTo(center.dx, center.dy + radius);
        path.lineTo(center.dx - radius, center.dy);
        path.close();
        canvas.drawPath(path, paint);
      case NodeShape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (i * 60 - 30) * pi / 180;
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      case NodeShape.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? radius : radius * 0.5;
          final angle = (i * 36 - 90) * pi / 180;
          final x = center.dx + r * cos(angle);
          final y = center.dy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      case NodeShape.rectangle:
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: radius * 2.5,
            height: radius * 1.5,
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_EnhancedGraphPainter oldDelegate) {
    return nodes != oldDelegate.nodes ||
        edges != oldDelegate.edges ||
        panOffset != oldDelegate.panOffset ||
        scale != oldDelegate.scale ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        linkingFromId != oldDelegate.linkingFromId;
  }
}
