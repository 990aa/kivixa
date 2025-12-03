// Knowledge Graph Streaming Service
//
// Bridges Rust streaming graph simulation to Flutter.
// Polls visible nodes at 60fps and updates the CustomPainter.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/ai/knowledge_graph_painter.dart';

/// Service for managing the knowledge graph streaming simulation
class KnowledgeGraphStreamingService {
  static KnowledgeGraphStreamingService? _instance;

  KnowledgeGraphStreamingService._();

  static KnowledgeGraphStreamingService get instance {
    _instance ??= KnowledgeGraphStreamingService._();
    return _instance!;
  }

  // Stream controller for graph frames
  final _frameController = StreamController<GraphFrame>.broadcast();

  // Timer for polling Rust
  Timer? _pollTimer;

  // Current viewport state (used when Rust bridge is connected)
  // ignore: unused_field
  double _viewportX = 0;
  // ignore: unused_field
  double _viewportY = 0;
  // ignore: unused_field
  double _viewportWidth = 1920;
  // ignore: unused_field
  double _viewportHeight = 1080;
  // ignore: unused_field
  double _viewportScale = 1.0;

  // Stats
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _currentFps = 0;

  /// Stream of graph frames
  Stream<GraphFrame> get frameStream => _frameController.stream;

  /// Current FPS
  double get currentFps => _currentFps;

  /// Whether streaming is active
  bool get isStreaming => _pollTimer?.isActive ?? false;

  /// Start the streaming simulation
  Future<void> startStreaming() async {
    if (isStreaming) return;

    try {
      // Start Rust simulation
      // TODO: Call native.startGraphStream() when flutter_rust_bridge is set up
      debugPrint('[KnowledgeGraph] Starting streaming simulation');

      // Start polling for visible nodes at 60fps
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 16), // ~60fps
        _pollVisibleNodes,
      );

      _lastFrameTime = DateTime.now();
      _frameCount = 0;
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to start streaming: $e');
      rethrow;
    }
  }

  /// Stop the streaming simulation
  Future<void> stopStreaming() async {
    _pollTimer?.cancel();
    _pollTimer = null;

    try {
      // Stop Rust simulation
      // TODO: Call native.stopGraphStream() when flutter_rust_bridge is set up
      debugPrint('[KnowledgeGraph] Stopped streaming simulation');
    } catch (e) {
      debugPrint('[KnowledgeGraph] Error stopping stream: $e');
    }
  }

  /// Update the viewport (called when user pans/zooms)
  Future<void> updateViewport(
    double x,
    double y,
    double width,
    double height,
    double scale,
  ) async {
    _viewportX = x;
    _viewportY = y;
    _viewportWidth = width;
    _viewportHeight = height;
    _viewportScale = scale;

    try {
      // Update Rust viewport
      // TODO: Call native.updateGraphViewport(x, y, width, height, scale)
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to update viewport: $e');
    }
  }

  /// Add a node to the graph
  Future<void> addNode({
    required String id,
    required double x,
    required double y,
    double radius = 20.0,
    int color = 0xFF2196F3,
  }) async {
    try {
      // TODO: Call native.addStreamNode(id, x, y, radius, color)
      debugPrint('[KnowledgeGraph] Added node: $id');
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to add node: $e');
      rethrow;
    }
  }

  /// Remove a node from the graph
  Future<void> removeNode(String id) async {
    try {
      // TODO: Call native.removeStreamNode(id)
      debugPrint('[KnowledgeGraph] Removed node: $id');
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to remove node: $e');
      rethrow;
    }
  }

  /// Add an edge between two nodes
  Future<void> addEdge({
    required String fromId,
    required String toId,
    double strength = 1.0,
  }) async {
    try {
      // TODO: Call native.addStreamEdge(fromId, toId, strength)
      debugPrint('[KnowledgeGraph] Added edge: $fromId -> $toId');
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to add edge: $e');
      rethrow;
    }
  }

  /// Remove an edge between two nodes
  Future<void> removeEdge(String fromId, String toId) async {
    try {
      // TODO: Call native.removeStreamEdge(fromId, toId)
      debugPrint('[KnowledgeGraph] Removed edge: $fromId -> $toId');
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to remove edge: $e');
      rethrow;
    }
  }

  /// Pin a node at its current position
  Future<void> pinNode(String id, bool pinned) async {
    try {
      // TODO: Call native.pinStreamNode(id, pinned)
      debugPrint(
        '[KnowledgeGraph] ${pinned ? 'Pinned' : 'Unpinned'} node: $id',
      );
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to pin node: $e');
      rethrow;
    }
  }

  /// Set node position (for dragging)
  Future<void> setNodePosition(String id, double x, double y) async {
    try {
      // TODO: Call native.setStreamNodePosition(id, x, y)
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to set node position: $e');
      rethrow;
    }
  }

  /// Clear all nodes and edges
  Future<void> clearGraph() async {
    try {
      // TODO: Call native.clearStreamGraph()
      debugPrint('[KnowledgeGraph] Cleared graph');
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to clear graph: $e');
      rethrow;
    }
  }

  /// Get graph statistics
  Future<GraphStats> getStats() async {
    try {
      // TODO: Call native.getStreamGraphStats()
      return GraphStats(
        nodeCount: 0,
        edgeCount: 0,
        visibleCount: 0,
        fps: _currentFps,
      );
    } catch (e) {
      debugPrint('[KnowledgeGraph] Failed to get stats: $e');
      return GraphStats(nodeCount: 0, edgeCount: 0, visibleCount: 0, fps: 0);
    }
  }

  void _pollVisibleNodes(Timer timer) {
    try {
      // TODO: Get visible nodes from Rust
      // final nodes = native.getVisibleGraphNodes();

      // For now, create an empty frame (will be populated when Rust bridge is ready)
      final frame = GraphFrame(
        nodes: [],
        edges: [],
        frameNumber: _frameCount,
        isRunning: true,
      );

      _frameController.add(frame);

      // Update FPS counter
      _frameCount++;
      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final elapsed = now.difference(_lastFrameTime!).inMilliseconds;
        if (elapsed >= 1000) {
          _currentFps = _frameCount / (elapsed / 1000);
          _frameCount = 0;
          _lastFrameTime = now;
        }
      }
    } catch (e) {
      debugPrint('[KnowledgeGraph] Error polling visible nodes: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    stopStreaming();
    _frameController.close();
    _instance = null;
  }
}

/// Graph statistics
class GraphStats {
  final int nodeCount;
  final int edgeCount;
  final int visibleCount;
  final double fps;

  const GraphStats({
    required this.nodeCount,
    required this.edgeCount,
    required this.visibleCount,
    required this.fps,
  });

  @override
  String toString() {
    return 'GraphStats(nodes: $nodeCount, edges: $edgeCount, visible: $visibleCount, fps: ${fps.toStringAsFixed(1)})';
  }
}

/// Widget for displaying the streaming knowledge graph
class StreamingKnowledgeGraph extends StatefulWidget {
  final void Function(String nodeId)? onNodeTap;
  final void Function(String nodeId)? onNodeDoubleTap;
  final bool showLabels;
  final bool showStats;

  const StreamingKnowledgeGraph({
    super.key,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.showLabels = true,
    this.showStats = false,
  });

  @override
  State<StreamingKnowledgeGraph> createState() =>
      _StreamingKnowledgeGraphState();
}

class _StreamingKnowledgeGraphState extends State<StreamingKnowledgeGraph> {
  final _graphController = KnowledgeGraphController();
  late StreamSubscription<GraphFrame> _frameSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to frame stream
    _frameSubscription = KnowledgeGraphStreamingService.instance.frameStream
        .listen((frame) {
          _graphController.updateGraph(frame.nodes, frame.edges);
        });

    // Start streaming
    KnowledgeGraphStreamingService.instance.startStreaming();
  }

  @override
  void dispose() {
    _frameSubscription.cancel();
    super.dispose();
  }

  void _onViewportChanged(
    double x,
    double y,
    double width,
    double height,
    double scale,
  ) {
    KnowledgeGraphStreamingService.instance.updateViewport(
      x,
      y,
      width,
      height,
      scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ControlledKnowledgeGraphWidget(
          controller: _graphController,
          onViewportChanged: _onViewportChanged,
          onNodeTap: widget.onNodeTap,
          onNodeDoubleTap: widget.onNodeDoubleTap,
          showLabels: widget.showLabels,
        ),
        if (widget.showStats)
          Positioned(
            top: 8,
            right: 8,
            child: StreamBuilder<GraphFrame>(
              stream: KnowledgeGraphStreamingService.instance.frameStream,
              builder: (context, snapshot) {
                final fps = KnowledgeGraphStreamingService.instance.currentFps;
                final frame = snapshot.data;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FPS: ${fps.toStringAsFixed(1)} | '
                    'Nodes: ${frame?.nodes.length ?? 0} | '
                    'Frame: ${frame?.frameNumber ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
