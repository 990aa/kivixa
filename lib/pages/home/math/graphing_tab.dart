import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Graphing tab - Function plotting and analysis
class MathGraphingTab extends StatefulWidget {
  const MathGraphingTab({super.key});

  @override
  State<MathGraphingTab> createState() => _MathGraphingTabState();
}

class _MathGraphingTabState extends State<MathGraphingTab> {
  final _functions = <_FunctionEntry>[
    _FunctionEntry(expression: 'sin(x)', color: Colors.blue),
  ];
  double _xMin = -10;
  double _xMax = 10;
  double _yMin = -5;
  double _yMax = 5;
  int _resolution = 200;
  List<List<Offset>> _graphData = [];
  bool _isComputing = false;
  String _extremaInfo = '';

  @override
  void initState() {
    super.initState();
    _computeGraphs();
  }

  Future<void> _computeGraphs() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend api.evaluate_graph_points for parallel evaluation
    await Future.delayed(const Duration(milliseconds: 300));

    // Placeholder: compute simple graphs locally for demo
    final List<List<Offset>> data = [];
    for (final fn in _functions) {
      if (!fn.visible) {
        data.add([]);
        continue;
      }
      final points = <Offset>[];
      for (int i = 0; i <= _resolution; i++) {
        final x = _xMin + (_xMax - _xMin) * i / _resolution;
        final y = _evaluatePlaceholder(fn.expression, x);
        if (y.isFinite) {
          points.add(Offset(x, y));
        }
      }
      data.add(points);
    }

    setState(() {
      _graphData = data;
      _isComputing = false;
    });
  }

  double _evaluatePlaceholder(String expr, double x) {
    // Simple placeholder evaluation for demo
    if (expr.contains('sin')) return math.sin(x);
    if (expr.contains('cos')) return math.cos(x);
    if (expr.contains('tan')) return math.tan(x);
    if (expr.contains('x^2')) return x * x;
    if (expr.contains('x^3')) return x * x * x;
    if (expr.contains('exp')) return math.exp(x);
    if (expr.contains('sqrt')) return x >= 0 ? math.sqrt(x) : double.nan;
    return x;
  }

  Future<void> _findExtrema() async {
    // TODO: Call Rust backend api.find_extrema
    setState(() {
      _extremaInfo =
          'sin(x) on [-10, 10]:\nLocal max at x ≈ 1.57, y = 1.0\nLocal min at x ≈ -1.57, y = -1.0\n(placeholder)';
    });
  }

  void _addFunction() {
    setState(() {
      _functions.add(
        _FunctionEntry(
          expression: '',
          color: Colors.primaries[_functions.length % Colors.primaries.length],
        ),
      );
    });
  }

  void _removeFunction(int index) {
    setState(() {
      _functions.removeAt(index);
      _computeGraphs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel: controls
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Functions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                ..._functions.asMap().entries.map((e) {
                  final index = e.key;
                  final fn = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: fn.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'f${index + 1}(x)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: fn.expression,
                                  ),
                                  onChanged: (v) => fn.expression = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: fn.visible,
                                    onChanged: (v) {
                                      setState(() => fn.visible = v ?? true);
                                      _computeGraphs();
                                    },
                                  ),
                                  const Text('Visible'),
                                ],
                              ),
                              if (_functions.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => _removeFunction(index),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                TextButton.icon(
                  onPressed: _addFunction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add function'),
                ),
                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: _isComputing ? null : _computeGraphs,
                  icon: _isComputing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Plot'),
                ),
                const Divider(height: 32),

                Text(
                  'View Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'X min',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        controller: TextEditingController(text: '$_xMin'),
                        onChanged: (v) => _xMin = double.tryParse(v) ?? _xMin,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'X max',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        controller: TextEditingController(text: '$_xMax'),
                        onChanged: (v) => _xMax = double.tryParse(v) ?? _xMax,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Y min',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        controller: TextEditingController(text: '$_yMin'),
                        onChanged: (v) => _yMin = double.tryParse(v) ?? _yMin,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Y max',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        controller: TextEditingController(text: '$_yMax'),
                        onChanged: (v) => _yMax = double.tryParse(v) ?? _yMax,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Resolution: '),
                    Expanded(
                      child: Slider(
                        value: _resolution.toDouble(),
                        min: 50,
                        max: 500,
                        divisions: 9,
                        label: '$_resolution',
                        onChanged: (v) =>
                            setState(() => _resolution = v.round()),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                Text(
                  'Analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _findExtrema,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Find Extrema'),
                ),
                const SizedBox(height: 8),

                if (_extremaInfo.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _extremaInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Right panel: graph
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _GraphPainter(
                  functions: _functions,
                  graphData: _graphData,
                  xMin: _xMin,
                  xMax: _xMax,
                  yMin: _yMin,
                  yMax: _yMax,
                  axisColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  gridColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FunctionEntry {
  String expression;
  Color color;
  bool visible;

  _FunctionEntry({
    required this.expression,
    required this.color,
    this.visible = true,
  });
}

class _GraphPainter extends CustomPainter {
  final List<_FunctionEntry> functions;
  final List<List<Offset>> graphData;
  final double xMin, xMax, yMin, yMax;
  final Color axisColor, gridColor;

  _GraphPainter({
    required this.functions,
    required this.graphData,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.axisColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;

    // Draw grid
    paint.color = gridColor;
    final xRange = xMax - xMin;
    final yRange = yMax - yMin;

    // Vertical grid lines
    final xStep = _niceStep(xRange / 10);
    for (var x = (xMin / xStep).ceil() * xStep; x <= xMax; x += xStep) {
      final sx = (x - xMin) / xRange * size.width;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), paint);
    }

    // Horizontal grid lines
    final yStep = _niceStep(yRange / 10);
    for (var y = (yMin / yStep).ceil() * yStep; y <= yMax; y += yStep) {
      final sy = size.height - (y - yMin) / yRange * size.height;
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), paint);
    }

    // Draw axes
    paint.color = axisColor;
    paint.strokeWidth = 2;

    // X axis
    if (yMin <= 0 && yMax >= 0) {
      final sy = size.height - (0 - yMin) / yRange * size.height;
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), paint);
    }

    // Y axis
    if (xMin <= 0 && xMax >= 0) {
      final sx = (0 - xMin) / xRange * size.width;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), paint);
    }

    // Draw functions
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < graphData.length && i < functions.length; i++) {
      if (!functions[i].visible) continue;

      paint.color = functions[i].color;
      final points = graphData[i];

      if (points.isEmpty) continue;

      final path = Path();
      bool started = false;

      for (final p in points) {
        final sx = (p.dx - xMin) / xRange * size.width;
        final sy = size.height - (p.dy - yMin) / yRange * size.height;

        if (sy < -1000 || sy > size.height + 1000) {
          started = false;
          continue;
        }

        if (!started) {
          path.moveTo(sx, sy);
          started = true;
        } else {
          path.lineTo(sx, sy);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  double _niceStep(double rough) {
    final exp = (math.log(rough) / math.ln10).floor();
    final f = rough / math.pow(10, exp);
    double nice;
    if (f < 1.5) {
      nice = 1;
    } else if (f < 3) {
      nice = 2;
    } else if (f < 7) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * math.pow(10, exp);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return graphData != oldDelegate.graphData ||
        xMin != oldDelegate.xMin ||
        xMax != oldDelegate.xMax ||
        yMin != oldDelegate.yMin ||
        yMax != oldDelegate.yMax;
  }
}
