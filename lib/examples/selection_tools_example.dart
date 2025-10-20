import 'package:flutter/material.dart';
import '../models/selection_mode.dart';
import '../tools/selection_tools.dart';

/// Example: Comprehensive selection tools demonstration
/// Shows all selection modes with interactive controls

class SelectionToolsExample extends StatefulWidget {
  const SelectionToolsExample({super.key});

  @override
  State<SelectionToolsExample> createState() => _SelectionToolsExampleState();
}

class _SelectionToolsExampleState extends State<SelectionToolsExample>
    with SingleTickerProviderStateMixin {
  SelectionTool? _currentTool;
  SelectionSettings _settings = const SelectionSettings();

  late AnimationController _marchingAntsController;

  @override
  void initState() {
    super.initState();
    _marchingAntsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();

    _initializeTool();
  }

  @override
  void dispose() {
    _marchingAntsController.dispose();
    super.dispose();
  }

  void _initializeTool() {
    switch (_settings.mode) {
      case SelectionMode.rectangular:
        _currentTool = RectangularSelection();
        break;
      case SelectionMode.ellipse:
        _currentTool = EllipseSelection();
        break;
      case SelectionMode.lasso:
        _currentTool = LassoSelection();
        break;
      case SelectionMode.polygonal:
        _currentTool = PolygonalSelection();
        break;
      case SelectionMode.magicWand:
        _currentTool = MagicWandSelection();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selection Tools Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _currentTool?.clearSelection();
              });
            },
            tooltip: 'Clear Selection',
          ),
        ],
      ),
      body: Row(
        children: [
          // Canvas area
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTapDown: _settings.mode == SelectionMode.polygonal
                  ? _onTapDown
                  : null,
              child: Container(
                color: Colors.grey[200],
                child: AnimatedBuilder(
                  animation: _marchingAntsController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _SelectionCanvasPainter(
                        tool: _currentTool,
                        settings: _settings,
                        animationValue: _marchingAntsController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
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
          const Text(
            'Selection Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Mode selector
          ...SelectionMode.values.map((mode) {
            return RadioListTile<SelectionMode>(
              title: Row(
                children: [
                  Icon(SelectionSettings.getModeIcon(mode), size: 20),
                  const SizedBox(width: 8),
                  Text(mode.name.toUpperCase()),
                ],
              ),
              subtitle: Text(
                SelectionSettings.getModeDescription(mode),
                style: const TextStyle(fontSize: 12),
              ),
              value: mode,
              groupValue: _settings.mode,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(mode: value);
                  _initializeTool();
                });
              },
            );
          }).toList(),

          const Divider(),

          // Operation mode
          const Text(
            'Operation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8.0,
            children: SelectionOperation.values.map((op) {
              return ChoiceChip(
                label: Text(op.name.toUpperCase()),
                selected: _settings.operation == op,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _settings = _settings.copyWith(operation: op);
                    });
                  }
                },
              );
            }).toList(),
          ),

          const Divider(),

          // Magic Wand tolerance
          if (_settings.mode == SelectionMode.magicWand) ...[
            const Text(
              'Tolerance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _settings.tolerance,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(tolerance: value);
                      });
                    },
                  ),
                ),
                Text(_settings.tolerance.toStringAsFixed(2)),
              ],
            ),
          ],

          // Feather
          const Text(
            'Feather',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _settings.feather,
                  min: 0.0,
                  max: 50.0,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(feather: value);
                    });
                  },
                ),
              ),
              Text(_settings.feather.toStringAsFixed(0)),
            ],
          ),

          // Options
          SwitchListTile(
            title: const Text('Marching Ants'),
            subtitle: const Text('Animated selection border'),
            value: _settings.showMarchingAnts,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showMarchingAnts: value);
              });
            },
          ),

          SwitchListTile(
            title: const Text('Anti-Aliasing'),
            subtitle: const Text('Smooth selection edges'),
            value: _settings.antiAlias,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(antiAlias: value);
              });
            },
          ),

          const Divider(),

          // Selection info
          if (_currentTool?.hasSelection ?? false) ...[
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
                    'Selection Info',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_currentTool?.selectionBounds != null) ...[
                    Text(
                      'Bounds: ${_currentTool!.selectionBounds!.width.toInt()} × ${_currentTool!.selectionBounds!.height.toInt()}',
                    ),
                  ],
                  if (_currentTool is MagicWandSelection) ...[
                    Text(
                      'Pixels: ${(_currentTool as MagicWandSelection).selectionSize}',
                    ),
                  ],
                  if (_currentTool is PolygonalSelection) ...[
                    Text(
                      'Points: ${(_currentTool as PolygonalSelection).points.length}',
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Instructions
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
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ..._getInstructions().map((instruction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      instruction,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getInstructions() {
    switch (_settings.mode) {
      case SelectionMode.rectangular:
        return [
          '• Drag to create rectangle',
          '• Selection shows in blue',
          '• Release to finish',
        ];
      case SelectionMode.ellipse:
        return [
          '• Drag to create ellipse',
          '• Constrain bounds with drag',
          '• Release to finish',
        ];
      case SelectionMode.lasso:
        return [
          '• Draw freeform selection',
          '• Path closes automatically',
          '• Release to finish',
        ];
      case SelectionMode.polygonal:
        return [
          '• Click to add points',
          '• Creates straight segments',
          '• Double-click to finish',
        ];
      case SelectionMode.magicWand:
        return [
          '• Click on color to select',
          '• Adjust tolerance for range',
          '• Selects similar pixels',
        ];
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_settings.mode == SelectionMode.polygonal) return;

    setState(() {
      _currentTool?.startSelection(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_settings.mode == SelectionMode.polygonal) return;

    setState(() {
      _currentTool?.updateSelection(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_settings.mode == SelectionMode.polygonal) return;

    setState(() {
      _currentTool?.finishSelection();
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (_settings.mode != SelectionMode.polygonal) return;

    setState(() {
      final polygonTool = _currentTool as PolygonalSelection;
      if (polygonTool.points.isEmpty) {
        polygonTool.startSelection(details.localPosition);
      } else {
        polygonTool.addPoint(details.localPosition);
      }
    });
  }
}

class _SelectionCanvasPainter extends CustomPainter {
  final SelectionTool? tool;
  final SelectionSettings settings;
  final double animationValue;

  _SelectionCanvasPainter({
    required this.tool,
    required this.settings,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Draw grid for reference
    _drawGrid(canvas, size);

    // Draw selection if exists
    tool?.drawSelection(canvas, settings, animationValue: animationValue);

    // Draw instructions text
    _drawInstructions(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    const gridSize = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawInstructions(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Draw selection on canvas',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 24,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_SelectionCanvasPainter oldDelegate) {
    return tool != oldDelegate.tool ||
        settings != oldDelegate.settings ||
        animationValue != oldDelegate.animationValue;
  }
}
