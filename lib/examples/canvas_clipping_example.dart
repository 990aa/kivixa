import 'package:flutter/material.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';
import '../widgets/clipped_drawing_canvas.dart';
import 'dart:math' as math;

/// Demonstrates Canvas Clipping System to prevent drawing outside bounds
///
/// Features:
/// - ClipRect with Clip.hardEdge for widget-level clipping
/// - canvas.clipRect() for hardware-level GPU clipping
/// - Visual demonstration of boundary enforcement
/// - Comparison between clipped and unclipped rendering
class CanvasClippingExample extends StatefulWidget {
  const CanvasClippingExample({super.key});

  @override
  State<CanvasClippingExample> createState() => _CanvasClippingExampleState();
}

class _CanvasClippingExampleState extends State<CanvasClippingExample> {
  final List<DrawingLayer> _layers = [];
  final Size _canvasSize = const Size(400, 300);
  bool _useClipping = true;
  bool _showBoundary = true;

  @override
  void initState() {
    super.initState();
    _generateTestStrokes();
  }

  /// Generate strokes that intentionally go outside canvas bounds
  void _generateTestStrokes() {
    final layer = DrawingLayer(name: 'Test Layer');

    // Stroke 1: Crosses left boundary
    layer.addStroke(
      _createStroke(
        points: [const Offset(-50, 50), const Offset(100, 50)],
        color: Colors.red,
        width: 10,
      ),
    );

    // Stroke 2: Crosses right boundary
    layer.addStroke(
      _createStroke(
        points: [const Offset(300, 100), const Offset(450, 100)],
        color: Colors.blue,
        width: 10,
      ),
    );

    // Stroke 3: Crosses top boundary
    layer.addStroke(
      _createStroke(
        points: [const Offset(200, -30), const Offset(200, 80)],
        color: Colors.green,
        width: 10,
      ),
    );

    // Stroke 4: Crosses bottom boundary
    layer.addStroke(
      _createStroke(
        points: [const Offset(300, 250), const Offset(300, 350)],
        color: Colors.orange,
        width: 10,
      ),
    );

    // Stroke 5: Diagonal crossing multiple boundaries
    layer.addStroke(
      _createStroke(
        points: [const Offset(-20, -20), const Offset(420, 320)],
        color: Colors.purple,
        width: 15,
      ),
    );

    // Stroke 6: Large circle that extends beyond all boundaries
    final circlePoints = <Offset>[];
    for (int i = 0; i <= 360; i += 10) {
      final angle = i * math.pi / 180;
      circlePoints.add(
        Offset(200 + 250 * math.cos(angle), 150 + 250 * math.sin(angle)),
      );
    }
    layer.addStroke(
      _createStroke(points: circlePoints, color: Colors.pink, width: 8),
    );

    _layers.add(layer);
  }

  LayerStroke _createStroke({
    required List<Offset> points,
    required Color color,
    required double width,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    return LayerStroke(
      points: points
          .map((p) => StrokePoint(position: p, pressure: 1.0))
          .toList(),
      brushProperties: paint,
    );
  }

  void _clearAndRegenerate() {
    setState(() {
      _layers.clear();
      _generateTestStrokes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Clipping Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearAndRegenerate,
            tooltip: 'Regenerate strokes',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Canvas Boundary Enforcement',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Demonstrates how ClipRect prevents strokes from bleeding outside canvas bounds.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Enable Clipping'),
                        subtitle: Text(
                          _useClipping
                              ? 'Strokes cannot go outside canvas'
                              : 'Strokes can bleed onto workspace',
                        ),
                        value: _useClipping,
                        onChanged: (value) {
                          setState(() => _useClipping = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Show Boundary'),
                        subtitle: const Text('Visual canvas border'),
                        value: _showBoundary,
                        onChanged: (value) {
                          setState(() => _showBoundary = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Canvas display
          Expanded(
            child: Center(
              child: Container(
                width: 600,
                height: 450,
                color: Colors.grey[200],
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background workspace
                    Container(color: Colors.grey[300]),

                    // Canvas with or without clipping
                    if (_useClipping)
                      ClippedDrawingCanvas(
                        canvasSize: _canvasSize,
                        layers: _layers,
                        transform: Matrix4.identity(),
                        backgroundColor: Colors.white,
                        showShadow: _showBoundary,
                      )
                    else
                      _UnclippedCanvas(
                        canvasSize: _canvasSize,
                        layers: _layers,
                        showBoundary: _showBoundary,
                      ),

                    // Overlay info
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _useClipping
                                  ? '✓ Clipping: ENABLED'
                                  : '✗ Clipping: DISABLED',
                              style: TextStyle(
                                color: _useClipping
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Canvas: ${_canvasSize.width.toInt()}×${_canvasSize.height.toInt()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Strokes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.red, 'Left boundary crossing'),
                    _buildLegendItem(Colors.blue, 'Right boundary crossing'),
                    _buildLegendItem(Colors.green, 'Top boundary crossing'),
                    _buildLegendItem(Colors.orange, 'Bottom boundary crossing'),
                    _buildLegendItem(
                      Colors.purple,
                      'Diagonal multi-boundary crossing',
                    ),
                    _buildLegendItem(
                      Colors.pink,
                      'Large circle extending beyond all edges',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _useClipping
                          ? '✓ All strokes are clipped at canvas boundaries'
                          : '✗ Strokes extend beyond canvas into workspace',
                      style: TextStyle(
                        color: _useClipping ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Technical details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 Implementation Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Widget-level: ClipRect with Clip.hardEdge wraps CustomPaint',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '2. GPU-level: canvas.clipRect() in paint() method',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '3. Hardware acceleration: Clipping happens at GPU level',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '4. Performance: Zero overhead, native GPU operation',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Unclipped canvas for comparison
class _UnclippedCanvas extends StatelessWidget {
  final Size canvasSize;
  final List<DrawingLayer> layers;
  final bool showBoundary;

  const _UnclippedCanvas({
    required this.canvasSize,
    required this.layers,
    required this.showBoundary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: showBoundary
            ? Border.all(color: Colors.black.withValues(alpha: 0.5), width: 2)
            : null,
        boxShadow: showBoundary
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      // NO ClipRect - strokes will bleed outside
      child: CustomPaint(
        painter: _UnclippedPainter(layers: layers),
        size: canvasSize,
      ),
    );
  }
}

/// Painter without clipping - for comparison
class _UnclippedPainter extends CustomPainter {
  final List<DrawingLayer> layers;

  _UnclippedPainter({required this.layers});

  @override
  void paint(Canvas canvas, Size size) {
    // NO canvas.clipRect() call - strokes can draw anywhere
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        _renderStroke(canvas, stroke);
      }
    }
  }

  void _renderStroke(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].position.dx, stroke.points[i].position.dy);
    }

    canvas.drawPath(path, stroke.brushProperties);
  }

  @override
  bool shouldRepaint(covariant _UnclippedPainter oldDelegate) => true;
}
