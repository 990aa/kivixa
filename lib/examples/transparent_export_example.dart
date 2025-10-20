import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';
import '../services/layer_renderer.dart';

/// Demonstrates transparent background export and proper eraser implementation
///
/// Key concepts:
/// 1. Canvas background is visual aid only - never exported
/// 2. Eraser creates TRUE transparency (not white pixels)
/// 3. Layers render with proper alpha compositing
class TransparentExportExample extends StatefulWidget {
  const TransparentExportExample({super.key});

  @override
  State<TransparentExportExample> createState() =>
      _TransparentExportExampleState();
}

class _TransparentExportExampleState extends State<TransparentExportExample> {
  final List<DrawingLayer> _layers = [];
  final Size _canvasSize = const Size(400, 400);
  ui.Image? _exportedImage;
  bool _showCheckeredBackground = true;
  String _statusText = 'Ready to export';

  @override
  void initState() {
    super.initState();
    _createSampleArtwork();
  }

  /// Create sample artwork with various colors and transparency
  void _createSampleArtwork() {
    final layer = DrawingLayer(name: 'Sample Artwork');

    // Red circle
    layer.addStroke(
      _createCircleStroke(
        center: const Offset(100, 100),
        radius: 40,
        color: Colors.red.withValues(alpha: 0.8),
        width: 10,
      ),
    );

    // Green circle (overlapping)
    layer.addStroke(
      _createCircleStroke(
        center: const Offset(140, 100),
        radius: 40,
        color: Colors.green.withValues(alpha: 0.6),
        width: 10,
      ),
    );

    // Blue circle (overlapping)
    layer.addStroke(
      _createCircleStroke(
        center: const Offset(120, 140),
        radius: 40,
        color: Colors.blue.withValues(alpha: 0.7),
        width: 10,
      ),
    );

    // Yellow star with transparency
    layer.addStroke(
      _createStarStroke(
        center: const Offset(300, 300),
        radius: 50,
        color: Colors.yellow.withValues(alpha: 0.9),
        width: 8,
      ),
    );

    // Purple line with varying pressure
    layer.addStroke(
      _createPressureStroke(
        start: const Offset(50, 300),
        end: const Offset(350, 320),
        color: Colors.purple.withValues(alpha: 0.75),
        baseWidth: 15,
      ),
    );

    _layers.add(layer);
  }

  LayerStroke _createCircleStroke({
    required Offset center,
    required double radius,
    required Color color,
    required double width,
  }) {
    final points = <StrokePoint>[];
    for (int i = 0; i <= 360; i += 10) {
      final angle = i * 3.14159 / 180;
      points.add(
        StrokePoint(
          position: Offset(
            center.dx + radius * (angle / 6.28).abs(),
            center.dy + radius * (1 - angle / 6.28).abs(),
          ),
          pressure: 1.0,
        ),
      );
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    return LayerStroke(points: points, brushProperties: paint);
  }

  LayerStroke _createStarStroke({
    required Offset center,
    required double radius,
    required Color color,
    required double width,
  }) {
    final points = <StrokePoint>[];
    for (int i = 0; i < 10; i++) {
      final angle = i * 3.14159 / 5;
      final r = i % 2 == 0 ? radius : radius / 2;
      points.add(
        StrokePoint(
          position: Offset(
            center.dx + r * (angle / 6.28),
            center.dy + r * (1 - angle / 6.28),
          ),
          pressure: 1.0,
        ),
      );
    }
    points.add(points.first); // Close the star

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    return LayerStroke(points: points, brushProperties: paint);
  }

  LayerStroke _createPressureStroke({
    required Offset start,
    required Offset end,
    required Color color,
    required double baseWidth,
  }) {
    final points = <StrokePoint>[];
    const steps = 20;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final pressure =
          0.3 + 0.7 * (1 - (2 * t - 1).abs()); // Varies from 0.3 to 1.0

      points.add(
        StrokePoint(position: Offset.lerp(start, end, t)!, pressure: pressure),
      );
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = baseWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    return LayerStroke(points: points, brushProperties: paint);
  }

  Future<void> _exportWithTransparency() async {
    setState(() => _statusText = 'Exporting with transparency...');

    try {
      final image = await LayerRenderer.renderLayersToImage(
        _layers,
        _canvasSize,
      );

      setState(() {
        _exportedImage = image;
        _statusText = 'Export successful! Image has transparent background.';
      });
    } catch (e) {
      setState(() => _statusText = 'Export failed: $e');
    }
  }

  Future<void> _exportAsPNG() async {
    setState(() => _statusText = 'Exporting as PNG...');

    try {
      final pngBytes = await LayerRenderer.exportLayersAsPNG(
        _layers,
        _canvasSize,
      );

      setState(() {
        _statusText =
            'PNG exported successfully! Size: ${pngBytes.length} bytes with transparency.';
      });
    } catch (e) {
      setState(() => _statusText = 'PNG export failed: $e');
    }
  }

  void _demonstrateEraser() {
    setState(() => _statusText = 'Demonstrating transparent eraser...');

    final layer = DrawingLayer(name: 'Eraser Demo');

    // Draw a red rectangle
    layer.addStroke(
      _createRectStroke(
        rect: const Rect.fromLTWH(200, 200, 150, 100),
        color: Colors.red.withValues(alpha: 0.8),
        width: 20,
      ),
    );

    _layers.add(layer);
    setState(() => _statusText = 'Draw complete. Now erasing center...');

    // Simulate eraser by creating a transparent stroke
    // In real implementation, this would use TransparentEraser.eraseWithTransparency
  }

  LayerStroke _createRectStroke({
    required Rect rect,
    required Color color,
    required double width,
  }) {
    final points = [
      StrokePoint(position: rect.topLeft, pressure: 1.0),
      StrokePoint(position: rect.topRight, pressure: 1.0),
      StrokePoint(position: rect.bottomRight, pressure: 1.0),
      StrokePoint(position: rect.bottomLeft, pressure: 1.0),
      StrokePoint(position: rect.topLeft, pressure: 1.0),
    ];

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    return LayerStroke(points: points, brushProperties: paint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transparent Export Example')),
      body: Column(
        children: [
          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transparent Background Export',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_statusText, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _exportWithTransparency,
                      icon: const Icon(Icons.image),
                      label: const Text('Export to Image'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportAsPNG,
                      icon: const Icon(Icons.download),
                      label: const Text('Export PNG'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _demonstrateEraser,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Demo Eraser'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _layers.clear();
                          _exportedImage = null;
                          _createSampleArtwork();
                          _statusText = 'Reset complete';
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Show Checkered Background'),
                  subtitle: const Text(
                    'Visualize transparency (not part of export)',
                  ),
                  value: _showCheckeredBackground,
                  onChanged: (value) {
                    setState(() => _showCheckeredBackground = value);
                  },
                ),
              ],
            ),
          ),

          // Canvas display
          Expanded(
            child: Row(
              children: [
                // Original artwork
                Expanded(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Original Artwork',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: _canvasSize.width,
                            height: _canvasSize.height,
                            decoration: BoxDecoration(
                              color: _showCheckeredBackground
                                  ? null
                                  : Colors.white,
                              border: Border.all(color: Colors.black),
                            ),
                            child: _showCheckeredBackground
                                ? Stack(
                                    children: [
                                      CustomPaint(
                                        painter: _CheckeredBackgroundPainter(),
                                        size: _canvasSize,
                                      ),
                                      CustomPaint(
                                        painter: _ArtworkPainter(_layers),
                                        size: _canvasSize,
                                      ),
                                    ],
                                  )
                                : CustomPaint(
                                    painter: _ArtworkPainter(_layers),
                                    size: _canvasSize,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Exported image
                Expanded(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Exported (Transparent)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _exportedImage != null
                              ? Container(
                                  width: _canvasSize.width,
                                  height: _canvasSize.height,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: _showCheckeredBackground
                                      ? Stack(
                                          children: [
                                            CustomPaint(
                                              painter:
                                                  _CheckeredBackgroundPainter(),
                                              size: _canvasSize,
                                            ),
                                            RawImage(image: _exportedImage),
                                          ],
                                        )
                                      : RawImage(image: _exportedImage),
                                )
                              : const Text('Export to see result'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Technical info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 Technical Implementation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ Canvas background (white) is NOT rendered during export',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '✓ Layers render with proper alpha compositing',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '✓ Eraser uses BlendMode.clear + saveLayer for transparency',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '✓ PNG export preserves full alpha channel',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '💡 Checkered background is only for visualization',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
}

/// Painter for checkered transparency background
class _CheckeredBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const checkSize = 10.0;
    final lightPaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = Colors.grey.shade300;

    for (double y = 0; y < size.height; y += checkSize) {
      for (double x = 0; x < size.width; x += checkSize) {
        final isEven =
            ((x / checkSize).floor() + (y / checkSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? lightPaint : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckeredBackgroundPainter oldDelegate) => false;
}

/// Painter for artwork
class _ArtworkPainter extends CustomPainter {
  final List<DrawingLayer> layers;

  _ArtworkPainter(this.layers);

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;

        for (int i = 1; i < stroke.points.length; i++) {
          canvas.drawLine(
            stroke.points[i - 1].position,
            stroke.points[i].position,
            stroke.brushProperties,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ArtworkPainter oldDelegate) => true;
}
