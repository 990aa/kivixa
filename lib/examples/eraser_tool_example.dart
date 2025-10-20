import 'package:flutter/material.dart';
import '../models/stroke_point.dart';
import '../models/eraser_mode.dart';
import '../models/brush_settings.dart';
import '../tools/eraser_tool.dart';
import '../services/brush_stroke_renderer.dart';

/// Example: Comprehensive eraser tool demonstration
/// Shows all eraser modes with interactive controls

class EraserToolExample extends StatefulWidget {
  const EraserToolExample({super.key});

  @override
  State<EraserToolExample> createState() => _EraserToolExampleState();
}

class _EraserToolExampleState extends State<EraserToolExample> {
  final BrushStrokeRenderer _renderer = BrushStrokeRenderer();
  final EraserTool _eraserTool = EraserTool();

  final List<_DrawingStroke> _strokes = [];
  final List<_EraserStroke> _eraserStrokes = [];

  List<StrokePoint> _currentDrawPoints = [];
  List<StrokePoint> _currentErasePoints = [];

  bool _isDrawing = false;
  bool _isErasing = false;

  // Tool modes
  bool _eraserMode = false;

  // Drawing settings
  BrushSettings _brushSettings = BrushSettings.pen(
    color: Colors.black,
    size: 8.0,
  );

  // Eraser settings
  EraserSettings _eraserSettings = const EraserSettings(
    mode: EraserMode.standard,
    size: 20.0,
  );

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eraser Tool Demo'),
        actions: [
          IconButton(
            icon: Icon(_eraserMode ? Icons.brush : Icons.auto_fix_high),
            onPressed: () {
              setState(() {
                _eraserMode = !_eraserMode;
              });
            },
            tooltip: _eraserMode ? 'Switch to Brush' : 'Switch to Eraser',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _strokes.clear();
                _eraserStrokes.clear();
              });
            },
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: Row(
        children: [
          // Drawing canvas
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: Colors.grey[200],
                child: CustomPaint(
                  painter: _EraserCanvasPainter(
                    strokes: _strokes,
                    eraserStrokes: _eraserStrokes,
                    currentDrawPoints: _currentDrawPoints,
                    currentErasePoints: _currentErasePoints,
                    brushSettings: _brushSettings,
                    eraserSettings: _eraserSettings,
                    renderer: _renderer,
                    eraserTool: _eraserTool,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // Controls panel
          SizedBox(width: 320, child: _buildControlsPanel()),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Mode toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Brush'),
                icon: Icon(Icons.brush),
              ),
              ButtonSegment(
                value: true,
                label: Text('Eraser'),
                icon: Icon(Icons.auto_fix_high),
              ),
            ],
            selected: {_eraserMode},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _eraserMode = newSelection.first;
              });
            },
          ),

          const SizedBox(height: 24),

          if (_eraserMode) ...[
            const Text(
              'Eraser Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<EraserMode>(
              value: _eraserSettings.mode,
              onChanged: (value) {
                setState(() {
                  _eraserSettings = _eraserSettings.copyWith(mode: value);
                });
              },
              children: EraserMode.values.map((mode) {
                return RadioListTile<EraserMode>(
                  title: Text(mode.name.toUpperCase()),
                  subtitle: Text(
                    EraserSettings.getModeDescription(mode),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: mode,
                );
              }).toList(),
            ),

            const Divider(),

            const Text(
              'Eraser Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _eraserSettings.size,
                    min: 5.0,
                    max: 100.0,
                    onChanged: (value) {
                      setState(() {
                        _eraserSettings = _eraserSettings.copyWith(size: value);
                      });
                    },
                  ),
                ),
                Text(_eraserSettings.size.toStringAsFixed(0)),
              ],
            ),

            const Text(
              'Hardness',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _eraserSettings.hardness,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _eraserSettings = _eraserSettings.copyWith(
                          hardness: value,
                        );
                      });
                    },
                  ),
                ),
                Text(_eraserSettings.hardness.toStringAsFixed(2)),
              ],
            ),

            const Text(
              'Opacity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _eraserSettings.opacity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _eraserSettings = _eraserSettings.copyWith(
                          opacity: value,
                        );
                      });
                    },
                  ),
                ),
                Text(_eraserSettings.opacity.toStringAsFixed(2)),
              ],
            ),

            SwitchListTile(
              title: const Text('Pressure Sensitivity'),
              value: _eraserSettings.usePressure,
              onChanged: (value) {
                setState(() {
                  _eraserSettings = _eraserSettings.copyWith(
                    usePressure: value,
                  );
                });
              },
            ),
          ] else ...[
            const Text(
              'Brush Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const Text('Brush Size'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _brushSettings.size,
                    min: 1.0,
                    max: 50.0,
                    onChanged: (value) {
                      setState(() {
                        _brushSettings = _brushSettings.copyWith(size: value);
                      });
                    },
                  ),
                ),
                Text(_brushSettings.size.toStringAsFixed(0)),
              ],
            ),

            const Text('Color'),
            Wrap(
              spacing: 8.0,
              children:
                  [
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.orange,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _brushSettings = _brushSettings.copyWith(
                            color: color,
                          );
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _brushSettings.color == color
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Statistics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Drawing Strokes: ${_strokes.length}'),
                Text('Eraser Strokes: ${_eraserStrokes.length}'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Draw strokes in brush mode',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• Switch to eraser to remove',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• Try different eraser modes',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• Adjust size and hardness',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      if (_eraserMode) {
        _isErasing = true;
        _currentErasePoints = [
          StrokePoint(position: details.localPosition, pressure: 0.5),
        ];
      } else {
        _isDrawing = true;
        _currentDrawPoints = [
          StrokePoint(position: details.localPosition, pressure: 0.5),
        ];
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_eraserMode && _isErasing) {
        _currentErasePoints.add(
          StrokePoint(position: details.localPosition, pressure: 0.7),
        );
      } else if (!_eraserMode && _isDrawing) {
        _currentDrawPoints.add(
          StrokePoint(position: details.localPosition, pressure: 0.7),
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (_eraserMode && _isErasing) {
        _isErasing = false;
        if (_currentErasePoints.isNotEmpty) {
          _eraserStrokes.add(
            _EraserStroke(
              points: List.from(_currentErasePoints),
              settings: _eraserSettings,
            ),
          );
          _currentErasePoints = [];
        }
      } else if (!_eraserMode && _isDrawing) {
        _isDrawing = false;
        if (_currentDrawPoints.isNotEmpty) {
          _strokes.add(
            _DrawingStroke(
              points: List.from(_currentDrawPoints),
              settings: _brushSettings,
            ),
          );
          _currentDrawPoints = [];
        }
      }
    });
  }
}

class _DrawingStroke {
  final List<StrokePoint> points;
  final BrushSettings settings;

  _DrawingStroke({required this.points, required this.settings});
}

class _EraserStroke {
  final List<StrokePoint> points;
  final EraserSettings settings;

  _EraserStroke({required this.points, required this.settings});
}

class _EraserCanvasPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final List<_EraserStroke> eraserStrokes;
  final List<StrokePoint> currentDrawPoints;
  final List<StrokePoint> currentErasePoints;
  final BrushSettings brushSettings;
  final EraserSettings eraserSettings;
  final BrushStrokeRenderer renderer;
  final EraserTool eraserTool;

  _EraserCanvasPainter({
    required this.strokes,
    required this.eraserStrokes,
    required this.currentDrawPoints,
    required this.currentErasePoints,
    required this.brushSettings,
    required this.eraserSettings,
    required this.renderer,
    required this.eraserTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Save layer for proper blending
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw all drawing strokes
    for (final stroke in strokes) {
      renderer.renderStroke(canvas, stroke.points, stroke.settings);
    }

    // Draw current drawing stroke
    if (currentDrawPoints.isNotEmpty) {
      renderer.renderStroke(canvas, currentDrawPoints, brushSettings);
    }

    // Apply eraser strokes
    for (final eraseStroke in eraserStrokes) {
      eraserTool.erase(canvas, eraseStroke.points, eraseStroke.settings);
    }

    // Apply current eraser stroke
    if (currentErasePoints.isNotEmpty) {
      eraserTool.erase(canvas, currentErasePoints, eraserSettings);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EraserCanvasPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        eraserStrokes != oldDelegate.eraserStrokes ||
        currentDrawPoints != oldDelegate.currentDrawPoints ||
        currentErasePoints != oldDelegate.currentErasePoints;
  }
}
