import 'package:flutter/material.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/models/brush_settings.dart';
import 'package:kivixa/services/brush_stroke_renderer.dart';
import 'package:kivixa/services/stroke_stabilizer.dart';

/// Example: Comprehensive stroke stabilization demonstration
/// Shows all stabilization algorithms with side-by-side comparison

class StrokeStabilizationExample extends StatefulWidget {
  const StrokeStabilizationExample({super.key});

  @override
  State<StrokeStabilizationExample> createState() =>
      _StrokeStabilizationExampleState();
}

class _StrokeStabilizationExampleState
    extends State<StrokeStabilizationExample> {
  final _renderer = BrushStrokeRenderer();
  final _stabilizer = StrokeStabilizer(windowSize: 5);

  List<StrokePoint> _rawStroke = [];
  List<StrokePoint> _currentPoints = [];
  var _isDrawing = false;

  // Stabilization settings
  var _selectedMode = 'streamline';
  var _stabilizationAmount = 0.5;
  var _brushSettings = BrushSettings.pen();

  final _modes = <String>[
    'none',
    'streamline',
    'moving',
    'weighted',
    'catmull',
    'bezier',
    'chaikin',
    'pull',
    'adaptive',
    'combined',
  ];

  final _modeDescriptions = <String, String>{
    'none': 'No stabilization - raw input',
    'streamline': 'Real-time jitter reduction with exponential smoothing',
    'moving': 'Simple moving average filter',
    'weighted': 'Weighted moving average with Gaussian weights',
    'catmull': 'Catmull-Rom spline interpolation',
    'bezier': 'Cubic Bezier spline curves',
    'chaikin': 'Chaikin corner cutting algorithm',
    'pull': 'Pull string algorithm for straightening',
    'adaptive': 'Adaptive smoothing based on curvature',
    'combined': 'Multi-stage smoothing (highest quality)',
  };

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Stabilization Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _rawStroke.clear();
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
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Draw here to test stabilization',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomPaint(
                        painter: _StabilizationCanvasPainter(
                          rawStroke: _rawStroke,
                          currentPoints: _currentPoints,
                          brushSettings: _brushSettings,
                          renderer: _renderer,
                          stabilizer: _stabilizer,
                          mode: _selectedMode,
                          amount: _stabilizationAmount,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ],
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
          const Text(
            'Stabilization Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Mode selector
          RadioGroup<String>(
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            child: Column(
              children: _modes.map((mode) {
                return RadioListTile<String>(
                  title: Text(mode.toUpperCase()),
                  subtitle: Text(
                    _modeDescriptions[mode] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: mode,
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // Stabilization amount slider
          const Text(
            'Stabilization Amount',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _stabilizationAmount,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: _stabilizationAmount.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _stabilizationAmount = value;
                    });
                  },
                ),
              ),
              Text(_stabilizationAmount.toStringAsFixed(2)),
            ],
          ),

          const Divider(),

          // Brush size
          const Text(
            'Brush Size',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _brushSettings.size,
                  min: 1.0,
                  max: 20.0,
                  onChanged: (value) {
                    setState(() {
                      _brushSettings = _brushSettings.copyWith(size: value);
                    });
                  },
                ),
              ),
              Text(_brushSettings.size.toStringAsFixed(1)),
            ],
          ),

          const Divider(),

          // Statistics
          if (_rawStroke.isNotEmpty) ...[
            const Text(
              'Stroke Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatistics(),
          ],

          const SizedBox(height: 16),

          // Help text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '• Draw wobbly lines to see stabilization',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Try different modes for different effects',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Higher amounts = more smoothing',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Combined mode gives best quality',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stabilizedPoints = _applyStabilization(_rawStroke);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Raw Points: ${_rawStroke.length}'),
          Text('Stabilized Points: ${stabilizedPoints.length}'),
          Text(
            'Change: ${(stabilizedPoints.length - _rawStroke.length >= 0 ? "+" : "")}${stabilizedPoints.length - _rawStroke.length}',
          ),
          const SizedBox(height: 8),
          Text(
            'Mode: ${_selectedMode.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<StrokePoint> _applyStabilization(List<StrokePoint> points) {
    if (_selectedMode == 'none' || points.isEmpty) return points;

    switch (_selectedMode) {
      case 'streamline':
        return _stabilizer.streamLine(points, _stabilizationAmount);
      case 'moving':
        return _stabilizer.movingAverage(points);
      case 'weighted':
        return _stabilizer.weightedMovingAverage(
          points,
          sigma: _stabilizationAmount * 2,
        );
      case 'catmull':
        return _stabilizer.catmullRomSpline(
          points,
          (_stabilizationAmount * 5).round().clamp(1, 5),
        );
      case 'bezier':
        return _stabilizer.bezierSpline(
          points,
          (_stabilizationAmount * 5).round().clamp(1, 5),
        );
      case 'chaikin':
        return _stabilizer.chaikinSmooth(
          points,
          (_stabilizationAmount * 3).round().clamp(1, 3),
        );
      case 'pull':
        return _stabilizer.pullString(
          points,
          iterations: 3,
          strength: _stabilizationAmount,
        );
      case 'adaptive':
        return _stabilizer.adaptiveSmooth(
          points,
          threshold: _stabilizationAmount,
        );
      case 'combined':
        return _stabilizer.combinedSmooth(
          points,
          streamLineAmount: _stabilizationAmount,
        );
      default:
        return points;
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _rawStroke = [];
      _currentPoints = [
        StrokePoint(position: details.localPosition, pressure: 0.5),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _currentPoints.add(
        StrokePoint(position: details.localPosition, pressure: 0.7),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;
      _rawStroke = List.from(_currentPoints);
      _currentPoints = [];
    });
  }
}

class _StabilizationCanvasPainter extends CustomPainter {
  final List<StrokePoint> rawStroke;
  final List<StrokePoint> currentPoints;
  final BrushSettings brushSettings;
  final BrushStrokeRenderer renderer;
  final StrokeStabilizer stabilizer;
  final String mode;
  final double amount;

  _StabilizationCanvasPainter({
    required this.rawStroke,
    required this.currentPoints,
    required this.brushSettings,
    required this.renderer,
    required this.stabilizer,
    required this.mode,
    required this.amount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Draw completed stroke with stabilization
    if (rawStroke.isNotEmpty) {
      // Draw raw stroke in light gray
      final rawSettings = brushSettings.copyWith(
        color: Colors.grey.shade300,
        size: brushSettings.size * 0.8,
      );
      renderer.renderStroke(canvas, rawStroke, rawSettings);

      // Draw stabilized stroke in black
      final stabilizedPoints = _applyStabilization(rawStroke);
      renderer.renderStroke(canvas, stabilizedPoints, brushSettings);

      // Draw points for visualization
      _drawPoints(canvas, rawStroke, Colors.red.withValues(alpha: 0.3), 2);
      _drawPoints(
        canvas,
        stabilizedPoints,
        Colors.blue.withValues(alpha: 0.5),
        3,
      );
    }

    // Draw current stroke being drawn
    if (currentPoints.isNotEmpty) {
      // Raw stroke in light gray
      final rawSettings = brushSettings.copyWith(
        color: Colors.grey.shade300,
        size: brushSettings.size * 0.8,
      );
      renderer.renderStroke(canvas, currentPoints, rawSettings);

      // Stabilized stroke in black
      final stabilizedPoints = _applyStabilization(currentPoints);
      renderer.renderStroke(canvas, stabilizedPoints, brushSettings);
    }
  }

  void _drawPoints(
    Canvas canvas,
    List<StrokePoint> points,
    Color color,
    double radius,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point.position, radius, paint);
    }
  }

  List<StrokePoint> _applyStabilization(List<StrokePoint> points) {
    if (mode == 'none' || points.isEmpty) return points;

    switch (mode) {
      case 'streamline':
        return stabilizer.streamLine(points, amount);
      case 'moving':
        return stabilizer.movingAverage(points);
      case 'weighted':
        return stabilizer.weightedMovingAverage(points, sigma: amount * 2);
      case 'catmull':
        return stabilizer.catmullRomSpline(
          points,
          (amount * 5).round().clamp(1, 5),
        );
      case 'bezier':
        return stabilizer.bezierSpline(
          points,
          (amount * 5).round().clamp(1, 5),
        );
      case 'chaikin':
        return stabilizer.chaikinSmooth(
          points,
          (amount * 3).round().clamp(1, 3),
        );
      case 'pull':
        return stabilizer.pullString(points, iterations: 3, strength: amount);
      case 'adaptive':
        return stabilizer.adaptiveSmooth(points, threshold: amount);
      case 'combined':
        return stabilizer.combinedSmooth(points, streamLineAmount: amount);
      default:
        return points;
    }
  }

  @override
  bool shouldRepaint(_StabilizationCanvasPainter oldDelegate) {
    return rawStroke != oldDelegate.rawStroke ||
        currentPoints != oldDelegate.currentPoints ||
        mode != oldDelegate.mode ||
        amount != oldDelegate.amount;
  }
}
