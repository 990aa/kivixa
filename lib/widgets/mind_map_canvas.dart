import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/mind_map_node.dart' as model;

/// Widget for displaying and interacting with mind maps
class MindMapCanvas extends StatefulWidget {
  final List<model.MindMapNode> nodes;
  final List<model.MindMapEdge> edges;
  final Function(model.MindMapNode)? onNodeTap;
  final Function(model.MindMapNode)? onNodeLongPress;
  final Function(model.MindMapNode, Offset)? onNodeDrag;
  final bool enableEdit;

  const MindMapCanvas({
    Key? key,
    required this.nodes,
    required this.edges,
    this.onNodeTap,
    this.onNodeLongPress,
    this.onNodeDrag,
    this.enableEdit = true,
  }) : super(key: key);

  @override
  State<MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends State<MindMapCanvas> {
  final Graph graph = Graph();
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  TransformationController transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _configureLayout();
    _buildGraph();
  }

  @override
  void didUpdateWidget(MindMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes != widget.nodes || oldWidget.edges != widget.edges) {
      _buildGraph();
    }
  }

  void _configureLayout() {
    builder
      ..siblingSeparation = 100
      ..levelSeparation = 150
      ..subtreeSeparation = 150
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();

    // Create GraphView nodes
    final nodeMap = <String, Node>{};
    for (var mindMapNode in widget.nodes) {
      final graphNode = Node.Id(mindMapNode.id);
      nodeMap[mindMapNode.id] = graphNode;
      graph.addNode(graphNode);
    }

    // Create GraphView edges
    for (var edge in widget.edges) {
      final fromNode = nodeMap[edge.fromNodeId];
      final toNode = nodeMap[edge.toNodeId];
      if (fromNode != null && toNode != null) {
        graph.addEdge(fromNode, toNode);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: transformationController,
      minScale: 0.1,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(1000),
      constrained: false,
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
        paint: Paint()
          ..color = Colors.grey
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final mindMapNode = widget.nodes.firstWhere(
            (n) => n.id == node.key!.value,
            orElse: () => model.MindMapNode(text: 'Unknown'),
          );
          return _buildNodeWidget(mindMapNode);
        },
      ),
    );
  }

  Widget _buildNodeWidget(model.MindMapNode node) {
    return GestureDetector(
      onTap: widget.enableEdit ? () => widget.onNodeTap?.call(node) : null,
      onLongPress: widget.enableEdit
          ? () => widget.onNodeLongPress?.call(node)
          : null,
      onPanUpdate: widget.enableEdit
          ? (details) => widget.onNodeDrag?.call(node, details.delta)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: node.color.withValues(alpha: 0.2),
          border: Border.all(color: node.color, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.childIds.isNotEmpty)
              Icon(
                node.isCollapsed
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                size: 16,
                color: node.color,
              ),
            if (node.childIds.isNotEmpty) const SizedBox(width: 8),
            Flexible(
              child: Text(
                node.text,
                style: TextStyle(
                  fontSize: node.fontSize,
                  color: node.color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }
}

/// Simple mind map viewer without edit capabilities
class MindMapViewer extends StatelessWidget {
  final List<model.MindMapNode> nodes;
  final List<model.MindMapEdge> edges;

  const MindMapViewer({Key? key, required this.nodes, required this.edges})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MindMapCanvas(nodes: nodes, edges: edges, enableEdit: false);
  }
}
