import 'package:flutter/material.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/models/brush_settings.dart';
import 'package:kivixa/services/brush_stroke_renderer.dart';

/// Example: Comprehensive brush engine demonstration
/// Shows all brush types with interactive controls

class BrushEngineExample extends StatefulWidget {
  const BrushEngineExample({super.key});

  @override
  State<BrushEngineExample> createState() => _BrushEngineExampleState();
}

class _BrushEngineExampleState extends State<BrushEngineExample> {
  final _renderer = BrushStrokeRenderer();
  final List<_StrokeData> _strokes = [];
  List<StrokePoint> _currentPoints = [];
  var _isDrawing = false;

  // Current brush settings
  var _brushSettings = BrushSettings.pen();
  var _selectedBrushType = 'pen';

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brush Engine Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _strokes.clear();
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
              child: CustomPaint(
                painter: _BrushCanvasPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentSettings: _brushSettings,
                  renderer: _renderer,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Brush controls panel
          SizedBox(width: 280, child: _buildControlsPanel()),
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
            'Brush Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildBrushTypeSelector(),

          const SizedBox(height: 24),
          const Text(
            'Brush Properties',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildSlider('Size', _brushSettings.size, 1.0, 50.0, (value) {
            setState(() {
              _brushSettings = _brushSettings.copyWith(size: value);
            });
          }),

          _buildSlider('Opacity', _brushSettings.opacity, 0.0, 1.0, (value) {
            setState(() {
              _brushSettings = _brushSettings.copyWith(opacity: value);
            });
          }),

          _buildSlider('Hardness', _brushSettings.hardness, 0.0, 1.0, (value) {
            setState(() {
              _brushSettings = _brushSettings.copyWith(hardness: value);
            });
          }),

          _buildSlider('Spacing', _brushSettings.spacing, 0.01, 0.5, (value) {
            setState(() {
              _brushSettings = _brushSettings.copyWith(spacing: value);
            });
          }),

          if (_brushSettings.brushType == 'airbrush' ||
              _brushSettings.brushType == 'watercolor')
            _buildSlider('Flow', _brushSettings.flow, 0.1, 1.0, (value) {
              setState(() {
                _brushSettings = _brushSettings.copyWith(flow: value);
              });
            }),

          if (_brushSettings.brushType == 'watercolor' ||
              _brushSettings.brushType == 'chalk')
            _buildSlider('Scatter', _brushSettings.scatter, 0.0, 0.5, (value) {
              setState(() {
                _brushSettings = _brushSettings.copyWith(scatter: value);
              });
            }),

          const SizedBox(height: 16),
          _buildColorPicker(),

          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Pressure Sensitivity'),
            value: _brushSettings.usePressure,
            onChanged: (value) {
              setState(() {
                _brushSettings = _brushSettings.copyWith(usePressure: value);
              });
            },
          ),

          const SizedBox(height: 16),
          _buildBrushPreview(),
        ],
      ),
    );
  }

  Widget _buildBrushTypeSelector() {
    final brushTypes = [
      ('pen', 'Pen', Icons.create),
      ('airbrush', 'Airbrush', Icons.brush),
      ('pencil', 'Pencil', Icons.edit),
      ('marker', 'Marker', Icons.highlight),
      ('watercolor', 'Watercolor', Icons.water_drop),
      ('chalk', 'Chalk', Icons.gradient),
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: brushTypes.map((type) {
        final isSelected = _selectedBrushType == type.$1;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.$3, size: 16),
              const SizedBox(width: 4),
              Text(type.$2),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedBrushType = type.$1;
                _brushSettings = _getPresetForType(type.$1);
              });
            }
          },
        );
      }).toList(),
    );
  }

  BrushSettings _getPresetForType(String type) {
    switch (type) {
      case 'pen':
        return BrushSettings.pen(color: _brushSettings.color);
      case 'airbrush':
        return BrushSettings.airbrush(color: _brushSettings.color);
      case 'watercolor':
        return BrushSettings.watercolor(color: _brushSettings.color);
      case 'pencil':
        return BrushSettings.pencil(color: _brushSettings.color);
      case 'marker':
        return BrushSettings.marker(color: _brushSettings.color);
      case 'chalk':
        return BrushSettings.chalk(color: _brushSettings.color);
      default:
        return BrushSettings.pen(color: _brushSettings.color);
    }
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value.toStringAsFixed(2))],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: colors.map((color) {
            final isSelected = _brushSettings.color == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _brushSettings = _brushSettings.copyWith(color: color);
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrushPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Brush Preview'),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _BrushPreviewPainter(_brushSettings, _renderer),
            size: const Size(double.infinity, 60),
          ),
        ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentPoints = [
        StrokePoint(position: details.localPosition, pressure: 0.5),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _currentPoints.add(
        StrokePoint(
          position: details.localPosition,
          pressure: 0.7, // Would come from stylus in real app
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;
      if (_currentPoints.isNotEmpty) {
        _strokes.add(
          _StrokeData(
            points: List.from(_currentPoints),
            settings: _brushSettings,
          ),
        );
        _currentPoints = [];
      }
    });
  }
}

class _StrokeData {
  final List<StrokePoint> points;
  final BrushSettings settings;

  _StrokeData({required this.points, required this.settings});
}

class _BrushCanvasPainter extends CustomPainter {
  final List<_StrokeData> strokes;
  final List<StrokePoint> currentPoints;
  final BrushSettings currentSettings;
  final BrushStrokeRenderer renderer;

  _BrushCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentSettings,
    required this.renderer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Draw completed strokes
    for (final stroke in strokes) {
      renderer.renderStroke(canvas, stroke.points, stroke.settings);
    }

    // Draw current stroke
    if (currentPoints.isNotEmpty) {
      renderer.renderStroke(canvas, currentPoints, currentSettings);
    }
  }

  @override
  bool shouldRepaint(_BrushCanvasPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentPoints != oldDelegate.currentPoints ||
        currentSettings != oldDelegate.currentSettings;
  }
}

class _BrushPreviewPainter extends CustomPainter {
  final BrushSettings settings;
  final BrushStrokeRenderer renderer;

  _BrushPreviewPainter(this.settings, this.renderer);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a sample stroke showing the brush
    final points = <StrokePoint>[];
    for (int i = 0; i <= 20; i++) {
      final t = i / 20.0;
      final x = size.width * 0.1 + size.width * 0.8 * t;
      final y =
          size.height / 2 +
          10 * (t < 0.5 ? t * 2 : (1 - t) * 2); // Slight curve
      final pressure = 0.3 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);

      points.add(StrokePoint(position: Offset(x, y), pressure: pressure));
    }

    renderer.renderStroke(canvas, points, settings);
  }

  @override
  bool shouldRepaint(_BrushPreviewPainter oldDelegate) {
    return settings != oldDelegate.settings;
  }
}
