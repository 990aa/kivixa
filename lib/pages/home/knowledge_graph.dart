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
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Enhanced graph edge with label, style, arrow, and branching support
class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String label;
  final String edgeType; // 'link', 'topic', 'similarity'
  final LinkStyle style;
  final ArrowStyle arrowStyle;
  final Color? color;
  final List<String> branchTargetIds; // Additional targets for branching

  const GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.label = '',
    this.edgeType = 'link',
    this.style = LinkStyle.normal,
    this.arrowStyle = ArrowStyle.none,
    this.color,
    this.branchTargetIds = const [],
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
    List<String>? branchTargetIds,
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
      branchTargetIds: branchTargetIds ?? this.branchTargetIds,
    );
  }

  /// Get all target node IDs (primary + branches)
  List<String> get allTargetIds => [targetId, ...branchTargetIds];
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

  // Dragging state
  GraphNode? _draggingNode;
  Offset? _dragStartPosition;

  // Interaction state
  GraphNode? _selectedNode;
  GraphEdge? _selectedEdge;
  String? _linkingFromNode;
  var _isAddingNode = false;

  // Viewport state
  var _panOffset = Offset.zero;
  var _scale = 1.0;
  Offset? _lastFocalPoint;
  double? _lastScale;

  // Grid toggle
  var _showGrid = false;

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

  static const _storageKey = 'knowledge_graph_data';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// Load saved graph data from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final nodesList = data['nodes'] as List<dynamic>? ?? [];
        final edgesList = data['edges'] as List<dynamic>? ?? [];

        setState(() {
          _nodes.clear();
          _edges.clear();
          _nodeCounter = data['nodeCounter'] as int? ?? 0;
          _edgeCounter = data['edgeCounter'] as int? ?? 0;
          _showGrid = data['showGrid'] as bool? ?? false;

          for (final nodeJson in nodesList) {
            _nodes.add(_nodeFromJson(nodeJson as Map<String, dynamic>));
          }
          for (final edgeJson in edgesList) {
            _edges.add(_edgeFromJson(edgeJson as Map<String, dynamic>));
          }
        });
      } catch (e) {
        // If parsing fails, start with empty graph
        debugPrint('Error loading graph data: $e');
      }
    }
    // If no saved data, start with empty graph (not demo)
  }

  /// Save current graph data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'nodes': _nodes.map(_nodeToJson).toList(),
      'edges': _edges.map(_edgeToJson).toList(),
      'nodeCounter': _nodeCounter,
      'edgeCounter': _edgeCounter,
      'showGrid': _showGrid,
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Map<String, dynamic> _nodeToJson(GraphNode node) => {
    'id': node.id,
    'title': node.title,
    'description': node.description,
    'x': node.x,
    'y': node.y,
    'radius': node.radius,
    'color': node.color.toARGB32(),
    'nodeType': node.nodeType,
    'shape': node.shape.index,
    'linkedNoteIds': node.linkedNoteIds,
  };

  GraphNode _nodeFromJson(Map<String, dynamic> json) => GraphNode(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    radius: (json['radius'] as num?)?.toDouble() ?? 22,
    color: Color(json['color'] as int),
    nodeType: json['nodeType'] as String? ?? 'note',
    shape: NodeShape.values[json['shape'] as int? ?? 0],
    linkedNoteIds:
        (json['linkedNoteIds'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> _edgeToJson(GraphEdge edge) => {
    'id': edge.id,
    'sourceId': edge.sourceId,
    'targetId': edge.targetId,
    'label': edge.label,
    'edgeType': edge.edgeType,
    'style': edge.style.index,
    'arrowStyle': edge.arrowStyle.index,
    'color': edge.color?.toARGB32(),
    'branchTargetIds': edge.branchTargetIds,
  };

  GraphEdge _edgeFromJson(Map<String, dynamic> json) => GraphEdge(
    id: json['id'] as String,
    sourceId: json['sourceId'] as String,
    targetId: json['targetId'] as String,
    label: json['label'] as String? ?? '',
    edgeType: json['edgeType'] as String? ?? 'link',
    style: LinkStyle.values[json['style'] as int? ?? 1],
    arrowStyle: ArrowStyle.values[json['arrowStyle'] as int? ?? 0],
    color: json['color'] != null ? Color(json['color'] as int) : null,
    branchTargetIds:
        (json['branchTargetIds'] as List<dynamic>?)?.cast<String>() ?? [],
  );

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
    _saveData(); // Save the demo data
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

  /// Hit test for edges - returns the closest edge within threshold distance
  GraphEdge? _hitTestEdge(Offset localPosition) {
    final worldPos = _localToWorld(localPosition);
    const threshold = 15.0; // Distance threshold for edge selection

    GraphEdge? closestEdge;
    double minDistance = double.infinity;

    for (final edge in _edges) {
      final sourceNode = _nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.sourceId,
        orElse: () => null,
      );
      final targetNode = _nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.targetId,
        orElse: () => null,
      );

      if (sourceNode == null || targetNode == null) continue;

      // Calculate distance from point to line segment
      final dist = _pointToLineDistance(
        worldPos,
        Offset(sourceNode.x, sourceNode.y),
        Offset(targetNode.x, targetNode.y),
      );

      if (dist < threshold && dist < minDistance) {
        minDistance = dist;
        closestEdge = edge;
      }

      // Also check branch target edges (branched links)
      for (final branchTargetId in edge.branchTargetIds) {
        final branchTargetNode = _nodes.cast<GraphNode?>().firstWhere(
          (n) => n?.id == branchTargetId,
          orElse: () => null,
        );
        if (branchTargetNode == null) continue;

        final branchDist = _pointToLineDistance(
          worldPos,
          Offset(sourceNode.x, sourceNode.y),
          Offset(branchTargetNode.x, branchTargetNode.y),
        );

        if (branchDist < threshold && branchDist < minDistance) {
          minDistance = branchDist;
          closestEdge = edge;
        }
      }
    }

    return closestEdge;
  }

  /// Calculate distance from a point to a line segment
  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSq = dx * dx + dy * dy;

    if (lengthSq == 0) {
      // Line segment is a point
      return (point - lineStart).distance;
    }

    // Calculate projection of point onto line
    var t =
        ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        lengthSq;
    t = t.clamp(0.0, 1.0);

    final projection = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);

    return (point - projection).distance;
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Check if starting on a node for dragging
    final hitNode = _hitTestNode(details.localFocalPoint);
    if (hitNode != null && details.pointerCount == 1) {
      _draggingNode = hitNode;
      _dragStartPosition = details.localFocalPoint;
    } else {
      _lastFocalPoint = details.focalPoint;
      _lastScale = _scale;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_draggingNode != null && _dragStartPosition != null) {
        // Dragging a node
        final worldPos = _localToWorld(details.localFocalPoint);
        final nodeIndex = _nodes.indexWhere((n) => n.id == _draggingNode!.id);
        if (nodeIndex >= 0) {
          _nodes[nodeIndex] = _nodes[nodeIndex].copyWith(
            x: worldPos.dx,
            y: worldPos.dy,
          );
        }
      } else {
        // Pan/zoom the canvas
        if (details.scale != 1.0 && _lastScale != null) {
          _scale = (_lastScale! * details.scale).clamp(0.1, 5.0);
        }
        if (_lastFocalPoint != null) {
          _panOffset += details.focalPoint - _lastFocalPoint!;
          _lastFocalPoint = details.focalPoint;
        }
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_draggingNode != null) {
      // Save after dragging a node
      _saveData();
    }
    _draggingNode = null;
    _dragStartPosition = null;
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

    if (hitNode != null) {
      setState(() {
        _selectedNode = hitNode;
        _selectedEdge = null;
      });
    } else {
      // Check if we hit an edge
      final hitEdge = _hitTestEdge(details.localPosition);
      setState(() {
        _selectedNode = null;
        _selectedEdge = hitEdge;
      });
    }
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
      _isAddingNode = false;
    });

    _saveData(); // Persist after adding node

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

    _saveData(); // Persist after adding link

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
                  _saveData(); // Persist after editing node
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to link notes from Browse section to a node
  Future<void> _showLinkNotesDialog(GraphNode node) async {
    // Get all notes from the file system
    final allNotes = await FileManager.getAllFiles(includeExtensions: true);
    final notes = allNotes.where((f) {
      return f.endsWith(Editor.extension) ||
          f.endsWith('.md') ||
          f.endsWith(TextFileEditor.internalExtension);
    }).toList();

    if (!mounted) return;

    // Current linked notes for this node
    final linkedNotes = List<String>.from(node.linkedNoteIds);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final searchQuery = ValueNotifier<String>('');

          return AlertDialog(
            title: const Text('Link Notes'),
            content: SizedBox(
              width: 450,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search notes',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => searchQuery.value = v,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: searchQuery,
                      builder: (context, query, _) {
                        final filteredNotes = notes.where((note) {
                          return note.toLowerCase().contains(
                            query.toLowerCase(),
                          );
                        }).toList();

                        if (filteredNotes.isEmpty) {
                          return const Center(child: Text('No notes found'));
                        }

                        return ListView.builder(
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final notePath = filteredNotes[index];
                            final isLinked = linkedNotes.contains(notePath);
                            final noteName = _getNoteName(notePath);
                            final noteType = _getNoteType(notePath);

                            return CheckboxListTile(
                              value: isLinked,
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked ?? false) {
                                    linkedNotes.add(notePath);
                                  } else {
                                    linkedNotes.remove(notePath);
                                  }
                                });
                              },
                              title: Text(noteName),
                              subtitle: Text('$noteType · $notePath'),
                              secondary: Icon(_getNoteIcon(notePath)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (linkedNotes.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      '${linkedNotes.length} note(s) linked',
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
                  final nodeIndex = _nodes.indexWhere((n) => n.id == node.id);
                  if (nodeIndex != -1) {
                    setState(() {
                      _nodes[nodeIndex] = node.copyWith(
                        linkedNoteIds: linkedNotes,
                      );
                      _selectedNode = _nodes[nodeIndex];
                    });
                    _saveData();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show dialog to view and open linked notes
  void _showLinkedNotesDialog(GraphNode node) {
    if (node.linkedNoteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes linked to this node')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.note, color: node.color),
            const SizedBox(width: 8),
            Expanded(child: Text('Notes in "${node.title}"')),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: node.linkedNoteIds.length,
            itemBuilder: (context, index) {
              final notePath = node.linkedNoteIds[index];
              final noteName = _getNoteName(notePath);
              final noteType = _getNoteType(notePath);

              return ListTile(
                leading: Icon(_getNoteIcon(notePath)),
                title: Text(noteName),
                subtitle: Text(noteType),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  Navigator.pop(context);
                  _openNote(notePath);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Open a note in its appropriate editor
  void _openNote(String notePath) {
    // Remove extension for path
    String pathWithoutExt;
    if (notePath.endsWith(Editor.extension)) {
      pathWithoutExt = notePath.substring(
        0,
        notePath.length - Editor.extension.length,
      );
      context.push(RoutePaths.editFilePath(pathWithoutExt));
    } else if (notePath.endsWith('.md')) {
      pathWithoutExt = notePath.substring(0, notePath.length - '.md'.length);
      context.push(RoutePaths.markdownFilePath(pathWithoutExt));
    } else if (notePath.endsWith(TextFileEditor.internalExtension)) {
      pathWithoutExt = notePath.substring(
        0,
        notePath.length - TextFileEditor.internalExtension.length,
      );
      context.push(RoutePaths.textFilePath(pathWithoutExt));
    }
  }

  /// Get display name from note path
  String _getNoteName(String path) {
    final segments = path.split('/');
    var name = segments.last;
    // Remove extension
    if (name.endsWith(Editor.extension)) {
      name = name.substring(0, name.length - Editor.extension.length);
    } else if (name.endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    } else if (name.endsWith(TextFileEditor.internalExtension)) {
      name = name.substring(
        0,
        name.length - TextFileEditor.internalExtension.length,
      );
    }
    return name;
  }

  /// Get note type label from path
  String _getNoteType(String path) {
    if (path.endsWith(Editor.extension)) return 'Handwritten';
    if (path.endsWith('.md')) return 'Markdown';
    if (path.endsWith(TextFileEditor.internalExtension)) return 'Text';
    return 'Unknown';
  }

  /// Get icon for note type
  IconData _getNoteIcon(String path) {
    if (path.endsWith(Editor.extension)) return Icons.draw;
    if (path.endsWith('.md')) return Icons.description;
    if (path.endsWith(TextFileEditor.internalExtension))
      return Icons.text_snippet;
    return Icons.note;
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
                            _saveData(); // Persist after deleting link
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
              _saveData(); // Persist after clearing links
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
      if (_selectedNode?.id == nodeId) _selectedNode = null;
    });

    _saveData(); // Persist after removing node

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
                _selectedNode = null;
                _nodeCounter = 0;
                _edgeCounter = 0;
              });
              _saveData(); // Persist after clearing
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
          IconButton(
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () {
              setState(() => _showGrid = !_showGrid);
              _saveData(); // Persist grid preference
            },
            tooltip: _showGrid ? 'Hide grid' : 'Show grid',
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'reload_demo',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Load Demo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
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
              // PERFORMANCE FIX: RepaintBoundary isolates graph repaints from parent tree
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _EnhancedGraphPainter(
                    nodes: _nodes,
                    edges: _edges,
                    panOffset: _panOffset,
                    scale: _scale,
                    selectedNodeId: _selectedNode?.id,
                    selectedEdgeId: _selectedEdge?.id,
                    linkingFromId: _linkingFromNode,
                    showGrid: _showGrid,
                  ),
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
      bottomSheet: _selectedNode != null
          ? _buildNodeDetails()
          : _selectedEdge != null
          ? _buildEdgeDetails()
          : null,
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
              InkWell(
                onTap: () => _showLinkedNotesDialog(node),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${node.linkedNoteIds.length} linked note(s) - tap to view',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // First row of action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditNodeDialog(node),
                    icon: const Icon(Icons.edit, size: 18),
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
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Link Node'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row of action buttons
            Row(
              children: [
                if (node.nodeType == 'note')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showLinkNotesDialog(node),
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(
                        node.linkedNoteIds.isEmpty
                            ? 'Link Notes'
                            : 'Edit Notes',
                      ),
                    ),
                  ),
                if (node.nodeType == 'note') const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _panOffset = Offset(-node.x * _scale, -node.y * _scale);
                      });
                    },
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text('Focus'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _removeNode(node.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
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

  Widget _buildEdgeDetails() {
    if (_selectedEdge == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final edge = _selectedEdge!;

    // Find source and target nodes
    final sourceNode = _nodes.cast<GraphNode?>().firstWhere(
      (n) => n?.id == edge.sourceId,
      orElse: () => null,
    );
    final targetNode = _nodes.cast<GraphNode?>().firstWhere(
      (n) => n?.id == edge.targetId,
      orElse: () => null,
    );

    final branchTargetNodes = edge.branchTargetIds
        .map(
          (id) => _nodes.cast<GraphNode?>().firstWhere(
            (n) => n?.id == id,
            orElse: () => null,
          ),
        )
        .whereType<GraphNode>()
        .toList();

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
                    color: edge.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edge.label.isNotEmpty ? edge.label : 'Untitled Link',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${edge.edgeType.toUpperCase()} · ${edge.style.name} · ${edge.arrowStyle.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedEdge = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Connection info
            Text(
              '${sourceNode?.title ?? "Unknown"} → ${targetNode?.title ?? "Unknown"}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            // Show branch targets if any
            if (branchTargetNodes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Branches to ${branchTargetNodes.length} additional node(s):',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: branchTargetNodes
                          .map(
                            (n) => Chip(
                              label: Text(
                                n.title,
                                style: theme.textTheme.labelSmall,
                              ),
                              avatar: Icon(
                                n.shape.icon,
                                size: 14,
                                color: n.color,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditEdgeDialog(edge),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddBranchDialog(edge),
                    icon: const Icon(Icons.call_split, size: 18),
                    label: const Text('Branch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _removeEdge(edge.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
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

  void _showEditEdgeDialog(GraphEdge edge) {
    final labelController = TextEditingController(text: edge.label);
    var selectedStyle = edge.style;
    var selectedArrowStyle = edge.arrowStyle;
    var selectedColor = edge.color;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Link'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Style'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: LinkStyle.values
                          .map(
                            (style) => ChoiceChip(
                              label: Text(style.name),
                              selected: selectedStyle == style,
                              onSelected: (sel) {
                                if (sel) {
                                  setDialogState(() => selectedStyle = style);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Arrow'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ArrowStyle.values
                          .map(
                            (style) => ChoiceChip(
                              label: Text(style.name),
                              selected: selectedArrowStyle == style,
                              onSelected: (sel) {
                                if (sel) {
                                  setDialogState(
                                    () => selectedArrowStyle = style,
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                                Colors.grey,
                                Colors.red,
                                Colors.orange,
                                Colors.amber,
                                Colors.green,
                                Colors.teal,
                                Colors.blue,
                                Colors.purple,
                              ]
                              .map(
                                (c) => GestureDetector(
                                  onTap: () =>
                                      setDialogState(() => selectedColor = c),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border:
                                          selectedColor?.toARGB32() ==
                                              c.toARGB32()
                                          ? Border.all(
                                              color: Colors.black,
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
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
                    final index = _edges.indexWhere((e) => e.id == edge.id);
                    if (index >= 0) {
                      setState(() {
                        _edges[index] = _edges[index].copyWith(
                          label: labelController.text,
                          style: selectedStyle,
                          arrowStyle: selectedArrowStyle,
                          color: selectedColor,
                        );
                        _selectedEdge = _edges[index];
                      });
                      _saveData();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddBranchDialog(GraphEdge edge) {
    // Get nodes that are not already connected to this edge
    final sourceNode = _nodes.cast<GraphNode?>().firstWhere(
      (n) => n?.id == edge.sourceId,
      orElse: () => null,
    );
    if (sourceNode == null) return;

    final excludedIds = {edge.sourceId, edge.targetId, ...edge.branchTargetIds};
    final availableNodes = _nodes
        .where((n) => !excludedIds.contains(n.id))
        .toList();

    if (availableNodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available nodes to branch to')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Branch'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a node to branch "${edge.label.isNotEmpty ? edge.label : "this link"}" to:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableNodes.length,
                    itemBuilder: (context, index) {
                      final node = availableNodes[index];
                      return ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: node.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            node.shape.icon,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(node.title),
                        subtitle: Text(node.nodeType),
                        onTap: () {
                          final edgeIndex = _edges.indexWhere(
                            (e) => e.id == edge.id,
                          );
                          if (edgeIndex >= 0) {
                            setState(() {
                              final newBranchTargets = [
                                ...edge.branchTargetIds,
                                node.id,
                              ];
                              _edges[edgeIndex] = _edges[edgeIndex].copyWith(
                                branchTargetIds: newBranchTargets,
                              );
                              _selectedEdge = _edges[edgeIndex];
                            });
                            _saveData();
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Branched to "${node.title}"'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _removeEdge(String edgeId) {
    setState(() {
      _edges.removeWhere((e) => e.id == edgeId);
      _selectedEdge = null;
    });
    _saveData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link deleted')));
  }
}

/// Enhanced graph painter with shapes and styled edges
class _EnhancedGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Offset panOffset;
  final double scale;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final String? linkingFromId;
  final bool showGrid;

  _EnhancedGraphPainter({
    required this.nodes,
    required this.edges,
    this.panOffset = Offset.zero,
    this.scale = 1.0,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.linkingFromId,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw grid before transformations for screen-space grid
    if (showGrid) {
      _drawGrid(canvas, size, center);
    }

    canvas.save();
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(scale);

    _drawEdges(canvas);
    _drawNodes(canvas);

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size, Offset center) {
    const gridSize = 50.0;
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Calculate grid offset based on pan
    final offsetX = (panOffset.dx % (gridSize * scale)) - gridSize * scale;
    final offsetY = (panOffset.dy % (gridSize * scale)) - gridSize * scale;

    // Draw vertical lines
    for (
      var x = offsetX;
      x < size.width + gridSize * scale;
      x += gridSize * scale
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (
      var y = offsetY;
      y < size.height + gridSize * scale;
      y += gridSize * scale
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw origin crosshair
    final originX = center.dx + panOffset.dx;
    final originY = center.dy + panOffset.dy;
    final originPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(originX, 0),
      Offset(originX, size.height),
      originPaint,
    );
    canvas.drawLine(
      Offset(0, originY),
      Offset(size.width, originY),
      originPaint,
    );
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

      final isSelected = edge.id == selectedEdgeId;
      final baseColor = edge.color ?? Colors.grey.withValues(alpha: 0.6);

      final paint = Paint()
        ..strokeWidth = isSelected ? edge.style.width + 2 : edge.style.width
        ..style = PaintingStyle.stroke
        ..color = isSelected ? baseColor.withValues(alpha: 1.0) : baseColor;

      final startOffset = Offset(source.x, source.y);
      final endOffset = Offset(target.x, target.y);

      // Draw selection highlight glow
      if (isSelected) {
        final glowPaint = Paint()
          ..strokeWidth = edge.style.width + 6
          ..style = PaintingStyle.stroke
          ..color = baseColor.withValues(alpha: 0.3);
        canvas.drawLine(startOffset, endOffset, glowPaint);
      }

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

      // Draw branch lines to additional targets
      for (final branchTargetId in edge.branchTargetIds) {
        final branchTarget = nodes.cast<GraphNode?>().firstWhere(
          (n) => n?.id == branchTargetId,
          orElse: () => null,
        );
        if (branchTarget == null) continue;

        final branchEndOffset = Offset(branchTarget.x, branchTarget.y);

        // Branch paint - dashed style
        final branchPaint = Paint()
          ..strokeWidth = isSelected
              ? edge.style.width + 1
              : edge.style.width * 0.8
          ..style = PaintingStyle.stroke
          ..color = (edge.color ?? Colors.grey).withValues(alpha: 0.7);

        // Draw selection highlight for branch
        if (isSelected) {
          final glowPaint = Paint()
            ..strokeWidth = edge.style.width + 4
            ..style = PaintingStyle.stroke
            ..color = baseColor.withValues(alpha: 0.2);
          canvas.drawLine(startOffset, branchEndOffset, glowPaint);
        }

        // Draw branch as dashed line
        _drawDashedLine(canvas, startOffset, branchEndOffset, branchPaint);

        // Draw arrow for branch if main edge has arrows
        if (edge.arrowStyle != ArrowStyle.none) {
          _drawArrow(
            canvas,
            startOffset,
            branchEndOffset,
            source.radius,
            branchTarget.radius,
            branchPaint.color,
            ArrowStyle.single,
          );
        }
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
              color: isSelected ? paint.color : baseColor,
              fontSize: 10 / scale.clamp(0.5, 2.0),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          Paint()
            ..color = isSelected
                ? baseColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.8),
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

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    var currentDist = 0.0;
    while (currentDist < distance) {
      final segmentEnd = (currentDist + dashLength).clamp(0.0, distance);
      canvas.drawLine(
        Offset(start.dx + unitX * currentDist, start.dy + unitY * currentDist),
        Offset(start.dx + unitX * segmentEnd, start.dy + unitY * segmentEnd),
        paint,
      );
      currentDist += dashLength + gapLength;
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
        linkingFromId != oldDelegate.linkingFromId ||
        showGrid != oldDelegate.showGrid;
  }
}
