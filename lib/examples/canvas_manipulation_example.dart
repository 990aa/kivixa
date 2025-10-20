import 'package:flutter/material.dart';
import '../models/canvas_settings.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';
import '../widgets/canvas_view.dart';
import 'dart:math' as math;

/// Example demonstrating canvas manipulation features
class CanvasManipulationExample extends StatefulWidget {
  const CanvasManipulationExample({Key? key}) : super(key: key);

  @override
  State<CanvasManipulationExample> createState() =>
      _CanvasManipulationExampleState();
}

class _CanvasManipulationExampleState extends State<CanvasManipulationExample> {
  final GlobalKey<CanvasViewState> _canvasKey = GlobalKey();
  CanvasSettings _settings = const CanvasSettings(
    preset: CanvasPreset.square2048,
    showGrid: true,
    gridSize: 50.0,
    showRulers: true,
  );

  // Sample drawing layers
  final List<DrawingLayer> _layers = [];
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _createSampleDrawing();
  }

  void _createSampleDrawing() {
    // Create a sample layer with some shapes
    final layer = DrawingLayer(
      id: 'sample_layer',
      name: 'Sample Layer',
      isVisible: true,
    );

    // Add some sample strokes
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    final random = math.Random(42);

    for (int i = 0; i < 5; i++) {
      final color = colors[i % colors.length];
      final centerX = 500.0 + random.nextDouble() * 1000;
      final centerY = 500.0 + random.nextDouble() * 1000;
      final radius = 50.0 + random.nextDouble() * 100;

      // Create circular stroke
      final points = <StrokePoint>[];
      for (double angle = 0; angle <= 2 * math.pi; angle += 0.1) {
        points.add(
          StrokePoint(
            position: Offset(
              centerX + math.cos(angle) * radius,
              centerY + math.sin(angle) * radius,
            ),
            pressure: 1.0,
          ),
        );
      }

      // Create paint properties
      final paint = Paint()
        ..color = color
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      layer.addStroke(LayerStroke(points: points, brushProperties: paint));
    }

    setState(() {
      _layers.add(layer);
    });
  }

  void _onCanvasTap(Offset point) {
    // Handle canvas tap
    debugPrint('Canvas tapped at: $point');
  }

  void _onCanvasDrag(Offset start, Offset end) {
    setState(() {
      _currentStroke.add(end);
    });
  }

  void _changePreset(CanvasPreset preset) {
    setState(() {
      _settings = _settings.copyWith(preset: preset);
    });

    // Fit to view after changing preset
    Future.delayed(const Duration(milliseconds: 100), () {
      _canvasKey.currentState?.fitToView();
    });
  }

  void _toggleGrid() {
    setState(() {
      _settings = _settings.copyWith(showGrid: !_settings.showGrid);
    });
  }

  void _toggleRulers() {
    setState(() {
      _settings = _settings.copyWith(showRulers: !_settings.showRulers);
    });
  }

  void _changeGridSize(double size) {
    setState(() {
      _settings = _settings.copyWith(gridSize: size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Manipulation'),
        actions: [
          // Preset selector
          PopupMenuButton<CanvasPreset>(
            icon: Icon(_settings.getPresetIcon()),
            tooltip: 'Canvas Preset',
            onSelected: _changePreset,
            itemBuilder: (context) => CanvasPreset.values.map((preset) {
              final settings = CanvasSettings(preset: preset);
              return PopupMenuItem(
                value: preset,
                child: Row(
                  children: [
                    Icon(settings.getPresetIcon(), size: 20),
                    const SizedBox(width: 8),
                    Text(settings.getPresetName()),
                  ],
                ),
              );
            }).toList(),
          ),

          // Grid toggle
          IconButton(
            icon: Icon(_settings.showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Toggle Grid',
            onPressed: _toggleGrid,
          ),

          // Rulers toggle
          IconButton(
            icon: Icon(
              _settings.showRulers
                  ? Icons.straighten
                  : Icons.straighten_outlined,
            ),
            tooltip: 'Toggle Rulers',
            onPressed: _toggleRulers,
          ),

          // Fit to view
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit to View',
            onPressed: () => _canvasKey.currentState?.fitToView(),
          ),

          // Reset view
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset View',
            onPressed: () => _canvasKey.currentState?.resetView(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas info bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Text(
                  'Canvas: ${_settings.getPresetName()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                if (!_settings.isInfinite) ...[
                  Text(
                    'Size: ${_settings.canvasWidth?.toInt()} × ${_settings.canvasHeight?.toInt()}',
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  'Zoom: ${(_canvasKey.currentState?.zoomLevel ?? 1.0) * 100}%',
                ),
                const SizedBox(width: 16),
                Text(
                  'Rotation: ${((_canvasKey.currentState?.rotation ?? 0.0) * 180 / math.pi).toStringAsFixed(0)}°',
                ),
              ],
            ),
          ),

          // Main canvas
          Expanded(
            child: CanvasView(
              key: _canvasKey,
              settings: _settings,
              layers: _layers,
              onCanvasPointTap: _onCanvasTap,
              onCanvasDrag: _onCanvasDrag,
              child: CustomPaint(
                painter: _SampleCanvasPainter(
                  layers: _layers,
                  currentStroke: _currentStroke,
                ),
              ),
            ),
          ),

          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Canvas Controls',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Zoom controls
                Row(
                  children: [
                    const Text('Zoom:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () => _canvasKey.currentState?.zoomOut(),
                      tooltip: 'Zoom Out',
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () => _canvasKey.currentState?.zoomIn(),
                      tooltip: 'Zoom In',
                    ),
                    TextButton(
                      onPressed: () =>
                          _canvasKey.currentState?.zoomToLevel(1.0),
                      child: const Text('100%'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _canvasKey.currentState?.zoomToLevel(2.0),
                      child: const Text('200%'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _canvasKey.currentState?.zoomToLevel(0.5),
                      child: const Text('50%'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Rotation controls
                Row(
                  children: [
                    const Text('Rotate:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.rotate_left),
                      onPressed: () =>
                          _canvasKey.currentState?.rotateCanvas(-math.pi / 4),
                      tooltip: 'Rotate Left 45°',
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right),
                      onPressed: () =>
                          _canvasKey.currentState?.rotateCanvas(math.pi / 4),
                      tooltip: 'Rotate Right 45°',
                    ),
                    TextButton(
                      onPressed: () =>
                          _canvasKey.currentState?.rotateCanvas(math.pi / 2),
                      child: const Text('90°'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _canvasKey.currentState?.rotateCanvas(math.pi),
                      child: const Text('180°'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Grid size control
                if (_settings.showGrid)
                  Row(
                    children: [
                      const Text('Grid Size:', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _settings.gridSize,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          label: '${_settings.gridSize.toInt()}px',
                          onChanged: _changeGridSize,
                        ),
                      ),
                      Text('${_settings.gridSize.toInt()}px'),
                    ],
                  ),

                const SizedBox(height: 8),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Controls:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Pinch to zoom'),
                      Text('• Drag with one finger to pan'),
                      Text('• Use toolbar buttons for precise control'),
                      Text('• Try different canvas presets'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sample canvas painter
class _SampleCanvasPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final List<Offset> currentStroke;

  _SampleCanvasPainter({required this.layers, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw layers
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        final paint = Paint()
          ..color = stroke.brushProperties.color
          ..strokeWidth = stroke.brushProperties.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path();
        for (int i = 0; i < stroke.points.length; i++) {
          final point = stroke.points[i];
          if (i == 0) {
            path.moveTo(point.position.dx, point.position.dy);
          } else {
            path.lineTo(point.position.dx, point.position.dy);
          }
        }

        canvas.drawPath(path, paint);
      }
    }

    // Draw current stroke
    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < currentStroke.length; i++) {
        if (i == 0) {
          path.moveTo(currentStroke[i].dx, currentStroke[i].dy);
        } else {
          path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SampleCanvasPainter oldDelegate) {
    return oldDelegate.layers != layers ||
        oldDelegate.currentStroke != currentStroke;
  }
}
