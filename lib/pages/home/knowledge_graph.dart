// Knowledge Graph Page
//
// Interactive visualization of the knowledge graph showing connections
// between notes, topics, and concepts.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';

/// Knowledge Graph visualization page
///
/// Displays an interactive graph of notes and their relationships.
/// Features:
/// - Pan and zoom navigation
/// - Node selection and details
/// - Add/remove nodes and edges
/// - Demo mode with sample data
class KnowledgeGraphPage extends StatefulWidget {
  /// Optional note ID to focus on initially
  final String? focusNoteId;

  /// Optional topic to filter by
  final String? filterTopic;

  const KnowledgeGraphPage({super.key, this.focusNoteId, this.filterTopic});

  @override
  State<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends State<KnowledgeGraphPage>
    with TickerProviderStateMixin {
  // Graph data
  final List<GraphNodePosition> _nodes = [];
  final List<_GraphEdge> _edges = [];

  // Physics simulation
  Timer? _physicsTimer;
  final Map<String, Offset> _velocities = {};

  // Interaction state
  GraphNodePosition? _selectedNode;
  String? _linkingFromNode;
  var _isAddingNode = false;

  // Viewport state
  var _panOffset = Offset.zero;
  var _scale = 1.0;
  Offset? _lastFocalPoint;
  double? _lastScale;

  // Node counter for generating IDs
  var _nodeCounter = 0;

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

  /// Load demo data for testing
  void _loadDemoData() {
    final random = Random(42);

    // Create topic hub nodes
    final topics = ['Recipes', 'Code', 'Ideas', 'Research', 'Projects'];
    for (var i = 0; i < topics.length; i++) {
      final angle = (i / topics.length) * 2 * pi;
      final radius = 150.0;
      _nodes.add(
        GraphNodePosition(
          id: 'hub_${topics[i].toLowerCase()}',
          x: cos(angle) * radius,
          y: sin(angle) * radius,
          radius: 30,
          color: _clusterColors[i % _clusterColors.length],
          nodeType: 'hub',
        ),
      );
      _velocities['hub_${topics[i].toLowerCase()}'] = Offset.zero;
    }

    // Create note nodes connected to topics
    final noteTopics = {
      'Pasta Recipe': 'recipes',
      'Curry Recipe': 'recipes',
      'Flutter Tips': 'code',
      'Rust Basics': 'code',
      'App Idea 1': 'ideas',
      'App Idea 2': 'ideas',
      'ML Paper': 'research',
      'Kivixa': 'projects',
    };

    var noteIndex = 0;
    noteTopics.forEach((noteName, topic) {
      final hubNode = _nodes.firstWhere((n) => n.id == 'hub_$topic');
      final angle = random.nextDouble() * 2 * pi;
      final distance = 80 + random.nextDouble() * 60;

      final nodeId = 'note_${noteIndex++}';
      _nodes.add(
        GraphNodePosition(
          id: nodeId,
          x: hubNode.x + cos(angle) * distance,
          y: hubNode.y + sin(angle) * distance,
          radius: 20,
          color: hubNode.color.withValues(alpha: 0.8),
          nodeType: 'note',
        ),
      );
      _velocities[nodeId] = Offset.zero;

      // Add edge to hub
      _edges.add(
        _GraphEdge(sourceId: nodeId, targetId: hubNode.id, edgeType: 'topic'),
      );
    });

    // Add some cross-links between related notes
    _edges.add(
      const _GraphEdge(sourceId: 'note_0', targetId: 'note_1', edgeType: 'link'),
    );
    _edges.add(
      const _GraphEdge(sourceId: 'note_2', targetId: 'note_3', edgeType: 'link'),
    );

    _nodeCounter = noteIndex;
  }

  /// Start physics simulation for force-directed layout
  void _startPhysicsSimulation() {
    _physicsTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (_) => _updatePhysics(),
    );
  }

  /// Update physics simulation
  void _updatePhysics() {
    if (_nodes.isEmpty) return;

    const repulsion = 5000.0;
    const attraction = 0.01;
    const damping = 0.85;
    const minDistance = 50.0;

    // Calculate forces
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
      final source = _nodes.cast<GraphNodePosition?>().firstWhere(
        (n) => n?.id == edge.sourceId,
        orElse: () => null,
      );
      final target = _nodes.cast<GraphNodePosition?>().firstWhere(
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

    // Apply forces and update positions
    var needsUpdate = false;
    for (var i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final velocity = (_velocities[node.id] ?? Offset.zero) + forces[node.id]!;
      final dampedVelocity = velocity * damping;

      // Skip if node is being dragged
      if (_selectedNode?.id == node.id && _lastFocalPoint != null) continue;

      // Only update if velocity is significant
      if (dampedVelocity.distance > 0.1) {
        _nodes[i] = GraphNodePosition(
          id: node.id,
          x: node.x + dampedVelocity.dx,
          y: node.y + dampedVelocity.dy,
          radius: node.radius,
          color: node.color,
          nodeType: node.nodeType,
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

  /// Add a new node at the given position
  void _addNode(Offset worldPosition, String type) {
    final nodeId = '${type}_${_nodeCounter++}';
    final color = _clusterColors[_nodeCounter % _clusterColors.length];

    setState(() {
      _nodes.add(
        GraphNodePosition(
          id: nodeId,
          x: worldPosition.dx,
          y: worldPosition.dy,
          radius: type == 'hub' ? 30 : 20,
          color: color,
          nodeType: type,
        ),
      );
      _velocities[nodeId] = Offset.zero;
      _isAddingNode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${type == "hub" ? "topic hub" : "note"}: $nodeId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Add an edge between two nodes
  void _addEdge(String sourceId, String targetId) {
    // Check if edge already exists
    final exists = _edges.any(
      (e) =>
          (e.sourceId == sourceId && e.targetId == targetId) ||
          (e.sourceId == targetId && e.targetId == sourceId),
    );

    if (exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Edge already exists')));
      return;
    }

    setState(() {
      _edges.add(
        _GraphEdge(sourceId: sourceId, targetId: targetId, edgeType: 'link'),
      );
      _linkingFromNode = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Linked: $sourceId → $targetId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Remove a node and its edges
  void _removeNode(String nodeId) {
    setState(() {
      _nodes.removeWhere((n) => n.id == nodeId);
      _edges.removeWhere((e) => e.sourceId == nodeId || e.targetId == nodeId);
      _velocities.remove(nodeId);
      if (_selectedNode?.id == nodeId) _selectedNode = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed node: $nodeId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Hit test for node selection
  GraphNodePosition? _hitTest(Offset localPosition) {
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

  /// Convert local position to world position
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
      // Handle zoom
      if (details.scale != 1.0 && _lastScale != null) {
        _scale = (_lastScale! * details.scale).clamp(0.1, 5.0);
      }

      // Handle pan
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
    final hitNode = _hitTest(details.localPosition);

    if (_isAddingNode) {
      // Add node at tap position
      _addNode(_localToWorld(details.localPosition), 'note');
      return;
    }

    if (_linkingFromNode != null) {
      // Complete linking
      if (hitNode != null && hitNode.id != _linkingFromNode) {
        _addEdge(_linkingFromNode!, hitNode.id);
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

  void _resetViewport() {
    setState(() {
      _panOffset = Offset.zero;
      _scale = 1.0;
    });
  }

  void _clearGraph() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Graph?'),
        content: const Text(
          'This will remove all nodes and edges. This cannot be undone.',
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
                _nodes.clear();
                _edges.clear();
                _velocities.clear();
                _selectedNode = null;
                _nodeCounter = 0;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAddNodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Node'),
        content: const Text('Choose the type of node to add:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isAddingNode = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap anywhere to add a note node'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Note'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _addNode(Offset.zero, 'hub');
            },
            child: const Text('Topic Hub'),
          ),
        ],
      ),
    );
  }

  // Note: _getEdgePositions was removed as it's handled by the painter

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GraphEdgePosition(
        sourceX: source.x,
        sourceY: source.y,
        targetX: target.x,
        targetY: target.y,
      );
    }).toList();
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
                  '${_nodes.length} nodes · ${_edges.length} edges',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          // Add node
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: _isAddingNode ? colorScheme.primary : null,
            ),
            onPressed: _showAddNodeDialog,
            tooltip: 'Add node',
          ),
          // Zoom controls
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
            onPressed: _resetViewport,
            tooltip: 'Reset view',
          ),
          // More options
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reload_demo',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reload Demo Data'),
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
          // Graph canvas
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
                painter: _KnowledgeGraphPainterWithEdgeTypes(
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

          // Instructions overlay
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
      // Node details bottom sheet
      bottomSheet: _selectedNode != null ? _buildNodeDetails() : null,
    );
  }

  Widget _buildNodeDetails() {
    if (_selectedNode == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = _selectedNode!;

    // Count connections
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
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.id,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${node.nodeType.toUpperCase()} · $connectionCount connections',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _linkingFromNode = node.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tap another node to create a link'),
                          duration: Duration(seconds: 3),
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
                      // Focus on this node
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

/// Internal edge representation
class _GraphEdge {
  final String sourceId;
  final String targetId;
  final String edgeType; // 'link', 'topic', 'similarity'

  const _GraphEdge({
    required this.sourceId,
    required this.targetId,
    this.edgeType = 'link',
  });
}

/// Custom painter that handles edge types (solid vs dotted)
class _KnowledgeGraphPainterWithEdgeTypes extends CustomPainter {
  final List<GraphNodePosition> nodes;
  final List<_GraphEdge> edges;
  final Offset panOffset;
  final double scale;
  final String? selectedNodeId;
  final String? linkingFromId;

  _KnowledgeGraphPainterWithEdgeTypes({
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

    // Draw edges
    _drawEdges(canvas);

    // Draw nodes
    _drawNodes(canvas);

    canvas.restore();
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      final source = nodes.cast<GraphNodePosition?>().firstWhere(
        (n) => n?.id == edge.sourceId,
        orElse: () => null,
      );
      final target = nodes.cast<GraphNodePosition?>().firstWhere(
        (n) => n?.id == edge.targetId,
        orElse: () => null,
      );

      if (source == null || target == null) continue;

      final paint = Paint()
        ..strokeWidth = edge.edgeType == 'topic' ? 2.0 : 1.5
        ..style = PaintingStyle.stroke;

      // Set color and style based on edge type
      switch (edge.edgeType) {
        case 'topic':
          paint.color = Colors.grey.withValues(alpha: 0.4);
        case 'similarity':
          paint.color = Colors.purple.withValues(alpha: 0.2);
        default:
          paint.color = Colors.grey.withValues(alpha: 0.6);
      }

      canvas.drawLine(
        Offset(source.x, source.y),
        Offset(target.x, target.y),
        paint,
      );
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      final offset = Offset(node.x, node.y);

      // Draw glow for selected node
      if (node.id == selectedNodeId) {
        canvas.drawCircle(
          offset,
          node.radius + 8,
          Paint()
            ..color = Colors.orange.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Draw glow for linking source
      if (node.id == linkingFromId) {
        canvas.drawCircle(
          offset,
          node.radius + 6,
          Paint()
            ..color = Colors.green.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Draw node
      canvas.drawCircle(offset, node.radius, Paint()..color = node.color);

      // Draw selection ring
      if (node.id == selectedNodeId) {
        canvas.drawCircle(
          offset,
          node.radius + 3,
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke,
        );
      }

      // Draw label for hubs
      if (node.nodeType == 'hub' && scale > 0.5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.id.replaceFirst('hub_', '').replaceAll('_', ' '),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 / scale.clamp(0.5, 2.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
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

  @override
  bool shouldRepaint(_KnowledgeGraphPainterWithEdgeTypes oldDelegate) {
    return nodes != oldDelegate.nodes ||
        edges != oldDelegate.edges ||
        panOffset != oldDelegate.panOffset ||
        scale != oldDelegate.scale ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        linkingFromId != oldDelegate.linkingFromId;
  }
}
