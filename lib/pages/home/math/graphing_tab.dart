import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/services/math/math_service.dart';

/// Graphing tab - Function plotting and analysis
class MathGraphingTab extends StatefulWidget {
  const MathGraphingTab({super.key});

  @override
  State<MathGraphingTab> createState() => _MathGraphingTabState();
}

class _MathGraphingTabState extends State<MathGraphingTab> {
  final _functions = <_FunctionEntry>[
    _FunctionEntry(expression: 'sin(x)', color: Colors.blue, visible: true),
  ];
  double _xMin = -10;
  double _xMax = 10;
  double _yMin = -5;
  double _yMax = 5;
  var _resolution = 200;
  List<List<Offset>> _graphData = [];
  var _isComputing = false;
  var _extremaInfo = '';

  // Pan and zoom state
  Offset? _lastPanPosition;
  Offset? _cursorPosition; // In graph coordinates
  Size? _graphSize;
  final _graphKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _computeGraphs();
  }

  Future<void> _computeGraphs() async {
    setState(() => _isComputing = true);

    // Generate x values using Rust
    final xValues = MathService.instance.generateXRange(
      _xMin,
      _xMax,
      _resolution + 1,
    );

    // Compute graphs using Rust backend for parallel evaluation
    final List<List<Offset>> data = [];
    for (final fn in _functions) {
      if (!fn.visible) {
        data.add([]);
        continue;
      }
      try {
        final result = await MathService.instance.evaluateGraphPoints(
          fn.expression,
          'x',
          xValues.toList(),
        );

        final points = <Offset>[];
        for (final point in result.points) {
          if (point.valid && point.y.isFinite) {
            points.add(Offset(point.x, point.y));
          }
        }
        data.add(points);
      } catch (e) {
        // Fallback to placeholder evaluation on error
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
    final buffer = StringBuffer();

    for (int i = 0; i < _functions.length; i++) {
      final fn = _functions[i];
      if (!fn.visible || fn.expression.isEmpty) continue;

      try {
        // Use Rust backend to find extrema
        final (maxima, minima) = await MathService.instance.findExtrema(
          fn.expression,
          'x',
          _xMin,
          _xMax,
          _resolution,
        );

        if (maxima.isNotEmpty || minima.isNotEmpty) {
          buffer.writeln('f${i + 1}(x) = ${fn.expression}:');

          for (final e in maxima.take(5)) {
            buffer.writeln(
              '  Local max at x ≈ ${e.$1.toStringAsFixed(2)}, y ≈ ${e.$2.toStringAsFixed(4)}',
            );
          }
          if (maxima.length > 5) {
            buffer.writeln('  ... and ${maxima.length - 5} more maxima');
          }

          for (final e in minima.take(5)) {
            buffer.writeln(
              '  Local min at x ≈ ${e.$1.toStringAsFixed(2)}, y ≈ ${e.$2.toStringAsFixed(4)}',
            );
          }
          if (minima.length > 5) {
            buffer.writeln('  ... and ${minima.length - 5} more minima');
          }
          buffer.writeln();
        }
      } catch (e) {
        // Fallback to local computation on error
        final extrema = <(double, double, String)>[];
        double? prevDerivative;

        for (int j = 1; j < _resolution - 1; j++) {
          final x = _xMin + (_xMax - _xMin) * j / _resolution;
          final h = (_xMax - _xMin) / _resolution / 2;

          final y = _evaluatePlaceholder(fn.expression, x);
          final yPlus = _evaluatePlaceholder(fn.expression, x + h);
          final yMinus = _evaluatePlaceholder(fn.expression, x - h);

          if (!y.isFinite || !yPlus.isFinite || !yMinus.isFinite) continue;

          final derivative = (yPlus - yMinus) / (2 * h);

          if (prevDerivative != null) {
            if (prevDerivative > 0 && derivative < 0) {
              extrema.add((x, y, 'max'));
            } else if (prevDerivative < 0 && derivative > 0) {
              extrema.add((x, y, 'min'));
            }
          }
          prevDerivative = derivative;
        }

        if (extrema.isNotEmpty) {
          buffer.writeln('f${i + 1}(x) = ${fn.expression}:');
          for (final e in extrema.take(5)) {
            final typeStr = e.$3 == 'max' ? 'Local max' : 'Local min';
            buffer.writeln(
              '  $typeStr at x ≈ ${e.$1.toStringAsFixed(2)}, y ≈ ${e.$2.toStringAsFixed(4)}',
            );
          }
          if (extrema.length > 5) {
            buffer.writeln('  ... and ${extrema.length - 5} more');
          }
          buffer.writeln();
        }
      }
    }

    setState(() {
      _extremaInfo = buffer.isEmpty
          ? 'No extrema found in the visible range'
          : buffer.toString().trim();
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null || _graphSize == null) return;

    final delta = details.localPosition - _lastPanPosition!;
    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;

    final dx = -delta.dx / _graphSize!.width * xRange;
    final dy = delta.dy / _graphSize!.height * yRange;

    setState(() {
      _xMin += dx;
      _xMax += dx;
      _yMin += dy;
      _yMax += dy;
      _lastPanPosition = details.localPosition;
    });
    _computeGraphs();
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _graphSize != null) {
      final zoomFactor = event.scrollDelta.dy > 0 ? 1.1 : 0.9;
      _zoomAt(event.localPosition, zoomFactor);
    }
  }

  void _zoomAt(Offset position, double factor) {
    if (_graphSize == null) return;

    // Convert screen position to graph coordinates
    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;
    final graphX = _xMin + position.dx / _graphSize!.width * xRange;
    final graphY = _yMax - position.dy / _graphSize!.height * yRange;

    // Zoom around the cursor position
    final newXRange = xRange * factor;
    final newYRange = yRange * factor;

    final xRatio = (graphX - _xMin) / xRange;
    final yRatio = (_yMax - graphY) / yRange;

    setState(() {
      _xMin = graphX - xRatio * newXRange;
      _xMax = graphX + (1 - xRatio) * newXRange;
      _yMin = graphY - (1 - yRatio) * newYRange;
      _yMax = graphY + yRatio * newYRange;
    });
    _computeGraphs();
  }

  void _zoom(double factor) {
    final centerX = (_xMin + _xMax) / 2;
    final centerY = (_yMin + _yMax) / 2;
    final xHalf = (_xMax - _xMin) / 2 * factor;
    final yHalf = (_yMax - _yMin) / 2 * factor;

    setState(() {
      _xMin = centerX - xHalf;
      _xMax = centerX + xHalf;
      _yMin = centerY - yHalf;
      _yMax = centerY + yHalf;
    });
    _computeGraphs();
  }

  void _resetView() {
    setState(() {
      _xMin = -10;
      _xMax = 10;
      _yMin = -5;
      _yMax = 5;
    });
    _computeGraphs();
  }

  void _handleMouseMove(PointerHoverEvent event) {
    if (_graphSize == null) return;

    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;
    final graphX = _xMin + event.localPosition.dx / _graphSize!.width * xRange;
    final graphY = _yMax - event.localPosition.dy / _graphSize!.height * yRange;

    setState(() {
      _cursorPosition = Offset(graphX, graphY);
    });
  }

  void _handleMouseExit(PointerExitEvent event) {
    setState(() {
      _cursorPosition = null;
    });
  }

  void _addFunction() {
    setState(() {
      _functions.add(
        _FunctionEntry(
          expression: '',
          color: Colors.primaries[_functions.length % Colors.primaries.length],
          visible: true,
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
          child: Column(
            children: [
              // Zoom controls and coordinates
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () => _zoom(0.8),
                      tooltip: 'Zoom In',
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () => _zoom(1.25),
                      tooltip: 'Zoom Out',
                    ),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong),
                      onPressed: _resetView,
                      tooltip: 'Reset View',
                    ),
                    const SizedBox(width: 16),
                    if (_cursorPosition != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'x: ${_cursorPosition!.dx.toStringAsFixed(3)}, '
                          'y: ${_cursorPosition!.dy.toStringAsFixed(3)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Scroll to zoom, drag to pan',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _graphSize = constraints.biggest;
                        return Listener(
                          onPointerSignal: _handleScroll,
                          child: MouseRegion(
                            onHover: _handleMouseMove,
                            onExit: _handleMouseExit,
                            cursor: SystemMouseCursors.move,
                            child: GestureDetector(
                              onPanStart: _handlePanStart,
                              onPanUpdate: _handlePanUpdate,
                              onPanEnd: _handlePanEnd,
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    key: _graphKey,
                                    painter: _GraphPainter(
                                      functions: _functions,
                                      graphData: _graphData,
                                      xMin: _xMin,
                                      xMax: _xMax,
                                      yMin: _yMin,
                                      yMax: _yMax,
                                      cursorPosition: _cursorPosition,
                                      axisColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                      gridColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.1),
                                      cursorColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                    ),
                                    size: Size.infinite,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
    required this.visible,
  });
}

class _GraphPainter extends CustomPainter {
  final List<_FunctionEntry> functions;
  final List<List<Offset>> graphData;
  final double xMin, xMax, yMin, yMax;
  final Color axisColor, gridColor, cursorColor;
  final Offset? cursorPosition;

  _GraphPainter({
    required this.functions,
    required this.graphData,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.axisColor,
    required this.gridColor,
    required this.cursorColor,
    this.cursorPosition,
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

    // Draw cursor crosshairs
    if (cursorPosition != null) {
      paint.color = cursorColor;
      paint.strokeWidth = 1;
      paint.style = PaintingStyle.stroke;

      final sx = (cursorPosition!.dx - xMin) / xRange * size.width;
      final sy =
          size.height - (cursorPosition!.dy - yMin) / yRange * size.height;

      // Vertical line
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), paint);
      // Horizontal line
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), paint);

      // Draw a small circle at cursor position
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sx, sy), 4, paint);
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
        yMax != oldDelegate.yMax ||
        cursorPosition != oldDelegate.cursorPosition;
  }
}
