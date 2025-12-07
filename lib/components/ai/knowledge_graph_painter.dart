// Knowledge Graph Custom Painter
//
// High-performance graph visualization using CustomPainter.
// Receives node positions from Rust at 60fps and renders circles.

import 'dart:math' show cos, sin;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Node position data from Rust
class GraphNodePosition {
  final String id;
  final double x;
  final double y;
  final double radius;
  final Color color;
  final String nodeType;

  const GraphNodePosition({
    required this.id,
    required this.x,
    required this.y,
    this.radius = 20.0,
    this.color = Colors.blue,
    this.nodeType = 'node',
  });

  factory GraphNodePosition.fromRust(Map<String, dynamic> data) {
    return GraphNodePosition(
      id: data['id'] as String,
      x: (data['x'] as num).toDouble(),
      y: (data['y'] as num).toDouble(),
      radius: (data['radius'] as num?)?.toDouble() ?? 20.0,
      color: Color(data['color'] as int? ?? 0xFF2196F3),
      nodeType: data['node_type'] as String? ?? 'node',
    );
  }
}

/// Edge position data from Rust
class GraphEdgePosition {
  final double sourceX;
  final double sourceY;
  final double targetX;
  final double targetY;

  const GraphEdgePosition({
    required this.sourceX,
    required this.sourceY,
    required this.targetX,
    required this.targetY,
  });

  factory GraphEdgePosition.fromRust(Map<String, dynamic> data) {
    return GraphEdgePosition(
      sourceX: (data['source_x'] as num).toDouble(),
      sourceY: (data['source_y'] as num).toDouble(),
      targetX: (data['target_x'] as num).toDouble(),
      targetY: (data['target_y'] as num).toDouble(),
    );
  }
}

/// Graph frame data from Rust simulation
class GraphFrame {
  final List<GraphNodePosition> nodes;
  final List<GraphEdgePosition> edges;
  final int frameNumber;
  final bool isRunning;

  const GraphFrame({
    required this.nodes,
    required this.edges,
    required this.frameNumber,
    required this.isRunning,
  });

  factory GraphFrame.empty() {
    return const GraphFrame(
      nodes: [],
      edges: [],
      frameNumber: 0,
      isRunning: false,
    );
  }
}

/// Custom painter for rendering the knowledge graph
class KnowledgeGraphPainter extends CustomPainter {
  final List<GraphNodePosition> nodes;
  final List<GraphEdgePosition> edges;
  final Offset panOffset;
  final double scale;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final bool showLabels;
  final TextStyle? labelStyle;

  // Pre-allocated paints for performance
  static final _edgePaint = Paint()
    ..color = Colors.grey.withValues(alpha: 0.3)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final _nodePaint = Paint()..style = PaintingStyle.fill;

  static final _selectedPaint = Paint()
    ..color = Colors.orange
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

  static final _hoverPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  KnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
    this.panOffset = Offset.zero,
    this.scale = 1.0,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.showLabels = true,
    this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Apply transformations
    canvas.save();
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(scale);

    // Draw edges first (below nodes)
    _drawEdges(canvas);

    // Draw nodes
    _drawNodes(canvas);

    canvas.restore();
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      canvas.drawLine(
        Offset(edge.sourceX, edge.sourceY),
        Offset(edge.targetX, edge.targetY),
        _edgePaint,
      );
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      final offset = Offset(node.x, node.y);

      // Draw hover effect
      if (node.id == hoveredNodeId) {
        canvas.drawCircle(offset, node.radius + 4, _hoverPaint);
      }

      // Draw node
      _nodePaint.color = node.color;
      canvas.drawCircle(offset, node.radius, _nodePaint);

      // Draw selection ring
      if (node.id == selectedNodeId) {
        canvas.drawCircle(offset, node.radius + 3, _selectedPaint);
      }

      // Draw label
      if (showLabels && scale > 0.5) {
        _drawLabel(canvas, node);
      }
    }
  }

  void _drawLabel(Canvas canvas, GraphNodePosition node) {
    final textStyle =
        labelStyle ??
        TextStyle(
          color: Colors.white,
          fontSize: 10 / scale.clamp(0.5, 2.0),
          fontWeight: FontWeight.w500,
        );

    final textSpan = TextSpan(
      text: node.id.length > 15 ? '${node.id.substring(0, 12)}...' : node.id,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Draw background for better readability
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(node.x, node.y + node.radius + 12),
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    textPainter.paint(
      canvas,
      Offset(node.x - textPainter.width / 2, node.y + node.radius + 10),
    );
  }

  @override
  bool shouldRepaint(KnowledgeGraphPainter oldDelegate) {
    return nodes != oldDelegate.nodes ||
        edges != oldDelegate.edges ||
        panOffset != oldDelegate.panOffset ||
        scale != oldDelegate.scale ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        hoveredNodeId != oldDelegate.hoveredNodeId;
  }
}

/// High-performance painter using instanced drawing (drawVertices)
///
/// For graphs with 10,000+ nodes, this uses GPU-accelerated rendering
/// by batching all circles into a single draw call using triangles.
class InstancedKnowledgeGraphPainter extends CustomPainter {
  final List<GraphNodePosition> nodes;
  final List<GraphEdgePosition> edges;
  final Offset panOffset;
  final double scale;
  final String? selectedNodeId;
  final bool showLabels;

  // Cache for vertex data
  Float32List? _vertexCache;
  Int32List? _colorCache;
  var _cachedNodeCount = 0;

  InstancedKnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
    this.panOffset = Offset.zero,
    this.scale = 1.0,
    this.selectedNodeId,
    this.showLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(scale);

    // Draw edges first (still using lines - minimal overhead)
    _drawEdgesBatched(canvas);

    // Draw nodes using instanced rendering
    _drawNodesInstanced(canvas);

    canvas.restore();
  }

  void _drawEdgesBatched(Canvas canvas) {
    if (edges.isEmpty) return;

    final paint = Paint()
      ..color =
          const Color(0x4D9E9E9E) // grey with 0.3 opacity
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (final edge in edges) {
      path.moveTo(edge.sourceX, edge.sourceY);
      path.lineTo(edge.targetX, edge.targetY);
    }
    canvas.drawPath(path, paint);
  }

  void _drawNodesInstanced(Canvas canvas) {
    if (nodes.isEmpty) return;

    // For each node, create a quad (2 triangles = 6 vertices) representing a circle
    // We approximate circles as hexagons for better GPU performance
    const int verticesPerNode = 18; // 6 triangles for hexagon = 18 vertices
    final int totalVertices = nodes.length * verticesPerNode;

    // Check if cache needs rebuild
    if (_vertexCache == null ||
        _cachedNodeCount != nodes.length ||
        _vertexCache!.length != totalVertices * 2) {
      _buildVertexCache();
    }

    if (_vertexCache == null || _colorCache == null) return;

    // Create vertices object
    final vertices = Vertices.raw(
      VertexMode.triangles,
      _vertexCache!,
      colors: _colorCache!,
    );

    canvas.drawVertices(vertices, BlendMode.srcOver, Paint());

    // Draw selection ring separately (rare operation)
    if (selectedNodeId != null) {
      final selectedNode = nodes.cast<GraphNodePosition?>().firstWhere(
        (n) => n?.id == selectedNodeId,
        orElse: () => null,
      );
      if (selectedNode != null) {
        canvas.drawCircle(
          Offset(selectedNode.x, selectedNode.y),
          selectedNode.radius + 3,
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _buildVertexCache() {
    const int verticesPerNode = 18;
    final int totalVertices = nodes.length * verticesPerNode;

    _vertexCache = Float32List(totalVertices * 2); // x, y pairs
    _colorCache = Int32List(totalVertices);
    _cachedNodeCount = nodes.length;

    int vertexIndex = 0;
    int colorIndex = 0;

    for (final node in nodes) {
      final cx = node.x;
      final cy = node.y;
      final r = node.radius;
      final color = node.color.toARGB32();

      // Create hexagon (6 triangles from center)
      for (int i = 0; i < 6; i++) {
        final angle1 = (i * 60) * 3.14159 / 180;
        final angle2 = ((i + 1) * 60) * 3.14159 / 180;

        // Center vertex
        _vertexCache![vertexIndex++] = cx;
        _vertexCache![vertexIndex++] = cy;
        _colorCache![colorIndex++] = color;

        // First edge vertex
        _vertexCache![vertexIndex++] = cx + r * cos(angle1);
        _vertexCache![vertexIndex++] = cy + r * sin(angle1);
        _colorCache![colorIndex++] = color;

        // Second edge vertex
        _vertexCache![vertexIndex++] = cx + r * cos(angle2);
        _vertexCache![vertexIndex++] = cy + r * sin(angle2);
        _colorCache![colorIndex++] = color;
      }
    }
  }

  @override
  bool shouldRepaint(InstancedKnowledgeGraphPainter oldDelegate) {
    return nodes != oldDelegate.nodes ||
        edges != oldDelegate.edges ||
        panOffset != oldDelegate.panOffset ||
        scale != oldDelegate.scale ||
        selectedNodeId != oldDelegate.selectedNodeId;
  }
}

/// Interactive knowledge graph widget
class KnowledgeGraphWidget extends StatefulWidget {
  /// Callback when viewport changes (for Rust viewport culling)
  final void Function(
    double x,
    double y,
    double width,
    double height,
    double scale,
  )?
  onViewportChanged;

  /// Callback when a node is tapped
  final void Function(String nodeId)? onNodeTap;

  /// Callback when a node is double-tapped
  final void Function(String nodeId)? onNodeDoubleTap;

  /// Initial nodes to display
  final List<GraphNodePosition> initialNodes;

  /// Initial edges to display
  final List<GraphEdgePosition> initialEdges;

  /// Whether to show node labels
  final bool showLabels;

  /// Background color
  final Color backgroundColor;

  const KnowledgeGraphWidget({
    super.key,
    this.onViewportChanged,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.initialNodes = const [],
    this.initialEdges = const [],
    this.showLabels = true,
    this.backgroundColor = const Color(0xFF1E1E1E),
  });

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget>
    with SingleTickerProviderStateMixin {
  late List<GraphNodePosition> _nodes;
  late List<GraphEdgePosition> _edges;

  Offset _panOffset = Offset.zero;
  var _scale = 1.0;
  String? _selectedNodeId;
  String? _hoveredNodeId;

  // For gesture handling
  Offset? _lastFocalPoint;
  double? _lastScale;

  // Ticker for 60fps updates
  Ticker? _ticker;
  var _needsRepaint = false;

  @override
  void initState() {
    super.initState();
    _nodes = widget.initialNodes;
    _edges = widget.initialEdges;

    // Start ticker for smooth updates
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_needsRepaint) {
      setState(() {
        _needsRepaint = false;
      });
    }
  }

  /// Update graph data (call this from Rust bridge polling)
  void updateGraph(
    List<GraphNodePosition> nodes,
    List<GraphEdgePosition> edges,
  ) {
    _nodes = nodes;
    _edges = edges;
    _needsRepaint = true;
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

    _notifyViewportChanged();
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _lastScale = null;
  }

  void _notifyViewportChanged() {
    if (widget.onViewportChanged == null) return;

    final size = context.size;
    if (size == null) return;

    // Calculate world-space viewport center
    final centerX = -_panOffset.dx / _scale;
    final centerY = -_panOffset.dy / _scale;

    widget.onViewportChanged!(
      centerX,
      centerY,
      size.width,
      size.height,
      _scale,
    );
  }

  void _onTapUp(TapUpDetails details) {
    final hitNode = _hitTest(details.localPosition);
    if (hitNode != null) {
      setState(() {
        _selectedNodeId = hitNode.id;
      });
      widget.onNodeTap?.call(hitNode.id);
    } else {
      setState(() {
        _selectedNodeId = null;
      });
    }
  }

  void _onDoubleTap() {
    if (_selectedNodeId != null) {
      widget.onNodeDoubleTap?.call(_selectedNodeId!);
    }
  }

  GraphNodePosition? _hitTest(Offset localPosition) {
    final size = context.size;
    if (size == null) return null;

    final center = Offset(size.width / 2, size.height / 2);

    // Transform to world coordinates
    final worldX = (localPosition.dx - center.dx - _panOffset.dx) / _scale;
    final worldY = (localPosition.dy - center.dy - _panOffset.dy) / _scale;

    // Check each node (reverse order for proper z-ordering)
    for (final node in _nodes.reversed) {
      final dx = worldX - node.x;
      final dy = worldY - node.y;
      final distSq = dx * dx + dy * dy;
      if (distSq <= node.radius * node.radius) {
        return node;
      }
    }

    return null;
  }

  void _onHover(PointerHoverEvent event) {
    final hitNode = _hitTest(event.localPosition);
    final newHoveredId = hitNode?.id;

    if (newHoveredId != _hoveredNodeId) {
      setState(() {
        _hoveredNodeId = newHoveredId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Notify viewport on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyViewportChanged();
        });

        return MouseRegion(
          onHover: _onHover,
          onExit: (_) => setState(() => _hoveredNodeId = null),
          cursor: _hoveredNodeId != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onTapUp: _onTapUp,
            onDoubleTap: _onDoubleTap,
            child: ColoredBox(
              color: widget.backgroundColor,
              child: CustomPaint(
                painter: KnowledgeGraphPainter(
                  nodes: _nodes,
                  edges: _edges,
                  panOffset: _panOffset,
                  scale: _scale,
                  selectedNodeId: _selectedNodeId,
                  hoveredNodeId: _hoveredNodeId,
                  showLabels: widget.showLabels,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Controller for the knowledge graph widget
class KnowledgeGraphController {
  _KnowledgeGraphWidgetState? _state;

  void _attach(_KnowledgeGraphWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Update the graph with new node and edge positions
  void updateGraph(
    List<GraphNodePosition> nodes,
    List<GraphEdgePosition> edges,
  ) {
    _state?.updateGraph(nodes, edges);
  }

  /// Check if controller is attached to a widget
  bool get isAttached => _state != null;
}

/// Knowledge graph widget with controller support
class ControlledKnowledgeGraphWidget extends StatefulWidget {
  final KnowledgeGraphController controller;
  final void Function(
    double x,
    double y,
    double width,
    double height,
    double scale,
  )?
  onViewportChanged;
  final void Function(String nodeId)? onNodeTap;
  final void Function(String nodeId)? onNodeDoubleTap;
  final bool showLabels;
  final Color backgroundColor;

  const ControlledKnowledgeGraphWidget({
    super.key,
    required this.controller,
    this.onViewportChanged,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.showLabels = true,
    this.backgroundColor = const Color(0xFF1E1E1E),
  });

  @override
  State<ControlledKnowledgeGraphWidget> createState() =>
      _ControlledKnowledgeGraphWidgetState();
}

class _ControlledKnowledgeGraphWidgetState
    extends State<ControlledKnowledgeGraphWidget> {
  final GlobalKey<_KnowledgeGraphWidgetState> _graphKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _graphKey.currentState;
      if (state != null) {
        widget.controller._attach(state);
      }
    });
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KnowledgeGraphWidget(
      key: _graphKey,
      onViewportChanged: widget.onViewportChanged,
      onNodeTap: widget.onNodeTap,
      onNodeDoubleTap: widget.onNodeDoubleTap,
      showLabels: widget.showLabels,
      backgroundColor: widget.backgroundColor,
    );
  }
}
