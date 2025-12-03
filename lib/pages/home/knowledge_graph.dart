// Knowledge Graph Page
//
// Interactive visualization of the knowledge graph showing connections
// between notes, topics, and concepts.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/ai/knowledge_graph_painter.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/services/ai/knowledge_graph_service.dart';
import 'package:kivixa/services/ai/knowledge_graph_streaming.dart';

/// Knowledge Graph visualization page
///
/// Displays an interactive graph of notes and their relationships.
/// Features:
/// - Pan and zoom navigation
/// - Node selection and details
/// - Topic filtering
/// - Real-time updates from the streaming service
class KnowledgeGraphPage extends StatefulWidget {
  /// Optional note ID to focus on initially
  final String? focusNoteId;

  /// Optional topic to filter by
  final String? filterTopic;

  const KnowledgeGraphPage({super.key, this.focusNoteId, this.filterTopic});

  @override
  State<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends State<KnowledgeGraphPage> {
  final KnowledgeGraphStreamingService _streamingService =
      KnowledgeGraphStreamingService.instance;
  final KnowledgeGraphService _graphService = KnowledgeGraphService();
  final KnowledgeGraphController _graphController = KnowledgeGraphController();

  StreamSubscription<GraphFrame>? _frameSubscription;
  GraphFrame? _currentFrame;
  GraphNodePosition? _selectedNode;

  // Viewport state (used for zoom controls)
  // ignore: unused_field
  Offset _offset = Offset.zero;
  double _scale = 1.0;

  // Filter state
  String? _selectedTopic;
  List<String> _availableTopics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }

  Future<void> _initializeGraph() async {
    setState(() => _isLoading = true);

    try {
      // Initialize services
      await _graphService.initialize();

      // Extract topics from current graph state
      _availableTopics = _graphService.currentState.nodes
          .where((n) => n.nodeType == 'hub')
          .map((n) => n.label)
          .toList();

      // Set initial filter if provided
      if (widget.filterTopic != null) {
        _selectedTopic = widget.filterTopic;
      }

      // Start streaming
      _streamingService.startStreaming();
      _frameSubscription = _streamingService.frameStream.listen(_onFrame);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize graph: $e')),
        );
      }
    }
  }

  void _onFrame(GraphFrame frame) {
    _graphController.updateGraph(frame.nodes, frame.edges);
    setState(() {
      _currentFrame = frame;
    });
  }

  void _onNodeSelected(GraphNodePosition node) {
    setState(() {
      _selectedNode = node;
    });
  }

  /// Navigate to a note by its ID
  void _navigateToNote(String nodeId) {
    // Node IDs for notes are typically the file path
    // If it's a hub node (starts with 'hub_'), we shouldn't navigate
    if (nodeId.startsWith('hub_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Topic: ${nodeId.substring(4).replaceAll('_', ' ')}'),
        ),
      );
      return;
    }

    // Navigate to the note editor
    context.push(RoutePaths.editFilePath(nodeId));
  }

  void _onViewportChangedCallback(
    double x,
    double y,
    double width,
    double height,
    double scale,
  ) {
    setState(() {
      _offset = Offset(x, y);
      _scale = scale;
    });
    _streamingService.updateViewport(x, y, width, height, scale);
  }

  void _resetViewport() {
    setState(() {
      _offset = Offset.zero;
      _scale = 1.0;
    });
    final size = MediaQuery.of(context).size;
    _streamingService.updateViewport(0, 0, size.width, size.height, 1.0);
  }

  Future<void> _onTopicFilterChanged(String? topic) async {
    setState(() {
      _selectedTopic = topic;
    });
    // Re-initialize to apply filter
    await _initializeGraph();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _streamingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Graph'),
        actions: [
          // Topic filter dropdown
          if (_availableTopics.isNotEmpty)
            PopupMenuButton<String?>(
              icon: Icon(
                Icons.filter_list,
                color: _selectedTopic != null ? colorScheme.primary : null,
              ),
              tooltip: 'Filter by topic',
              onSelected: _onTopicFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('All Topics')),
                const PopupMenuDivider(),
                ..._availableTopics.map(
                  (topic) => PopupMenuItem(
                    value: topic,
                    child: Row(
                      children: [
                        if (topic == _selectedTopic)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        if (topic == _selectedTopic) const SizedBox(width: 8),
                        Text(topic),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGraph,
            tooltip: 'Refresh graph',
          ),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() => _scale *= 1.2);
            },
            tooltip: 'Zoom in',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() => _scale /= 1.2);
            },
            tooltip: 'Zoom out',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _resetViewport,
            tooltip: 'Reset view',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildGraphView(),
      bottomSheet: _selectedNode != null ? _buildNodeDetails() : null,
    );
  }

  Widget _buildGraphView() {
    if (_currentFrame == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No graph data available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some notes to see the knowledge graph',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ControlledKnowledgeGraphWidget(
      controller: _graphController,
      onViewportChanged: _onViewportChangedCallback,
      onNodeTap: (nodeId) {
        final node = _currentFrame?.nodes.firstWhere(
          (n) => n.id == nodeId,
          orElse: () => GraphNodePosition(id: nodeId, x: 0, y: 0),
        );
        if (node != null) {
          _onNodeSelected(node);
        }
      },
      onNodeDoubleTap: (nodeId) {
        _navigateToNote(nodeId);
      },
    );
  }

  Widget _buildNodeDetails() {
    if (_selectedNode == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = _selectedNode!;

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
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedNode = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${node.nodeType}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _navigateToNote(node.id);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Note'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // Focus on this node - update viewport
                      final size = MediaQuery.of(context).size;
                      final centerX = -node.x + size.width / 2;
                      final centerY = -node.y + size.height / 2;
                      _streamingService.updateViewport(
                        centerX,
                        centerY,
                        size.width,
                        size.height,
                        1.5,
                      );
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Focus'),
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

/// Compact knowledge graph widget for embedding in other views
class CompactKnowledgeGraph extends StatefulWidget {
  final String? noteId;
  final double height;
  final VoidCallback? onExpand;

  const CompactKnowledgeGraph({
    super.key,
    this.noteId,
    this.height = 200,
    this.onExpand,
  });

  @override
  State<CompactKnowledgeGraph> createState() => _CompactKnowledgeGraphState();
}

class _CompactKnowledgeGraphState extends State<CompactKnowledgeGraph> {
  final KnowledgeGraphStreamingService _streamingService =
      KnowledgeGraphStreamingService.instance;
  StreamSubscription<GraphFrame>? _subscription;
  GraphFrame? _frame;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    _streamingService.startStreaming();
    _subscription = _streamingService.frameStream.listen((frame) {
      if (mounted) {
        setState(() => _frame = frame);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (_frame != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const StreamingKnowledgeGraph(),
            )
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: widget.onExpand,
              icon: const Icon(Icons.open_in_full),
              tooltip: 'Expand',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
