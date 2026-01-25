import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kivixa/services/math/math_service.dart';

/// Calculus tab - Derivatives, integrals, limits, series, partial derivatives, multiple integrals
class MathCalculusTab extends StatefulWidget {
  const MathCalculusTab({super.key});

  @override
  State<MathCalculusTab> createState() => _MathCalculusTabState();
}

class _MathCalculusTabState extends State<MathCalculusTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Derivative'),
            Tab(text: 'Partial'),
            Tab(text: 'Integral'),
            Tab(text: 'Multiple Int'),
            Tab(text: 'Limits'),
            Tab(text: 'Series'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _DerivativeCalculator(),
              _PartialDerivativeCalculator(),
              _IntegralCalculator(),
              _MultipleIntegralCalculator(),
              _LimitCalculator(),
              _SeriesCalculator(),
            ],
          ),
        ),
      ],
    );
  }
}

// Expression evaluator helper
double _evaluateExpr(String expr, String variable, double value) {
  expr = expr.replaceAll(' ', '').toLowerCase();
  expr = expr.replaceAll(variable.toLowerCase(), '($value)');
  expr = expr.replaceAll('pi', '(${math.pi})');
  expr = expr.replaceAllMapped(
    RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z])'),
    (m) => '(${math.e})',
  );

  // Handle functions
  expr = _processFunctions(expr);
  return _calculate(expr);
}

String _processFunctions(String expr) {
  var changed = true;
  var iterations = 0;
  while (changed && iterations < 50) {
    changed = false;
    iterations++;

    for (final fn in ['sqrt', 'sin', 'cos', 'tan', 'ln', 'log', 'abs', 'exp']) {
      final match = RegExp('$fn\\(([^()]+)\\)').firstMatch(expr);
      if (match != null) {
        final inner = _calculate(match.group(1)!);
        double result;
        switch (fn) {
          case 'sqrt':
            result = math.sqrt(inner);
          case 'sin':
            result = math.sin(inner);
          case 'cos':
            result = math.cos(inner);
          case 'tan':
            result = math.tan(inner);
          case 'ln':
            result = math.log(inner);
          case 'log':
            result = math.log(inner) / math.ln10;
          case 'abs':
            result = inner.abs();
          case 'exp':
            result = math.exp(inner);
          default:
            result = inner;
        }
        expr = expr.replaceFirst(match.group(0)!, '($result)');
        changed = true;
        break;
      }
    }
  }
  return expr;
}

double _calculate(String expr) {
  expr = expr.trim();

  // Handle parentheses
  while (expr.contains('(')) {
    final match = RegExp(r'\(([^()]+)\)').firstMatch(expr);
    if (match == null) break;
    final inner = _calculate(match.group(1)!);
    expr = expr.replaceFirst(match.group(0)!, inner.toString());
  }

  // Handle power (^)
  final powerIdx = expr.lastIndexOf('^');
  if (powerIdx > 0) {
    final base = _calculate(expr.substring(0, powerIdx));
    final exp = _calculate(expr.substring(powerIdx + 1));
    return math.pow(base, exp).toDouble();
  }

  // Handle +/- (right to left)
  for (var i = expr.length - 1; i >= 0; i--) {
    if ((expr[i] == '+' || expr[i] == '-') && i > 0) {
      if (i > 0 && (expr[i - 1] == 'e' || expr[i - 1] == 'E')) continue;
      final left = expr.substring(0, i);
      final right = expr.substring(i + 1);
      if (left.isNotEmpty && right.isNotEmpty) {
        return expr[i] == '+'
            ? _calculate(left) + _calculate(right)
            : _calculate(left) - _calculate(right);
      }
    }
  }

  // Handle */
  for (var i = expr.length - 1; i >= 0; i--) {
    if (expr[i] == '*' || expr[i] == '/') {
      final left = expr.substring(0, i);
      final right = expr.substring(i + 1);
      if (left.isNotEmpty && right.isNotEmpty) {
        final r = _calculate(right);
        return expr[i] == '*' ? _calculate(left) * r : _calculate(left) / r;
      }
    }
  }

  return double.parse(expr);
}

String _formatNumber(double n) {
  if (n.isNaN) return 'undefined';
  if (n.isInfinite) return n > 0 ? '∞' : '-∞';
  if (n == n.toInt().toDouble() && n.abs() < 1e10) return n.toInt().toString();
  return n
      .toStringAsFixed(8)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

// ============================================================================
// DERIVATIVE CALCULATOR
// ============================================================================

class _DerivativeCalculator extends StatefulWidget {
  const _DerivativeCalculator();

  @override
  State<_DerivativeCalculator> createState() => _DerivativeCalculatorState();
}

class _DerivativeCalculatorState extends State<_DerivativeCalculator> {
  final _expressionCtrl = TextEditingController(text: 'x^2 + 3*x + 2');
  final _variableCtrl = TextEditingController(text: 'x');
  final _pointCtrl = TextEditingController(text: '1');
  var _order = 1;
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _variableCtrl.dispose();
    _pointCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final expr = _expressionCtrl.text;
      final variable = _variableCtrl.text;
      final point = double.parse(_pointCtrl.text);

      // Use Rust backend for computation
      final result = await MathService.instance.differentiate(
        expr,
        variable,
        point,
        order: _order,
      );

      final primeSymbol = "'" * _order;
      setState(() {
        _result = 'f$primeSymbol($point) = ${_formatNumber(result.value)}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Numerical Differentiation',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., x^2 + sin(x)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _variableCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Variable',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _pointCtrl,
                  decoration: const InputDecoration(
                    labelText: 'At point',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('Order: '),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text("f'")),
                  ButtonSegment(value: 2, label: Text("f''")),
                  ButtonSegment(value: 3, label: Text("f'''")),
                ],
                selected: {_order},
                onSelectionChanged: (s) => setState(() => _order = s.first),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _compute,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Differentiate'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// PARTIAL DERIVATIVE CALCULATOR
// ============================================================================

class _PartialDerivativeCalculator extends StatefulWidget {
  const _PartialDerivativeCalculator();

  @override
  State<_PartialDerivativeCalculator> createState() =>
      _PartialDerivativeCalculatorState();
}

class _PartialDerivativeCalculatorState
    extends State<_PartialDerivativeCalculator> {
  final _expressionCtrl = TextEditingController(text: 'x^2*y + y^3');
  final _variablesCtrl = TextEditingController(text: 'x, y');
  final _pointCtrl = TextEditingController(text: '1, 2');
  var _partialVar = 'x';
  var _order = 1;
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _variablesCtrl.dispose();
    _pointCtrl.dispose();
    super.dispose();
  }

  double _evaluateMultivar(
    String expr,
    List<String> vars,
    List<double> values,
  ) {
    var e = expr.replaceAll(' ', '').toLowerCase();
    for (var i = 0; i < vars.length; i++) {
      e = e.replaceAll(vars[i].toLowerCase(), '(${values[i]})');
    }
    e = e.replaceAll('pi', '(${math.pi})');
    e = e.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z])'),
      (m) => '(${math.e})',
    );
    e = _processFunctions(e);
    return _calculate(e);
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final expr = _expressionCtrl.text;
      final vars = _variablesCtrl.text.split(',').map((v) => v.trim()).toList();
      final pointStrs = _pointCtrl.text
          .split(',')
          .map((v) => v.trim())
          .toList();

      if (vars.length != pointStrs.length) {
        throw Exception(
          'Number of variables must match number of point values',
        );
      }

      final point = pointStrs.map((s) => double.parse(s)).toList();
      final varIndex = vars.indexOf(_partialVar);
      if (varIndex == -1) {
        throw Exception('Variable "$_partialVar" not found in variables list');
      }

      double f(List<double> p) => _evaluateMultivar(expr, vars, p);

      // Numerical partial derivative using central difference
      const h = 1e-5;
      var derivative = 0.0;
      final pointPlus = List<double>.from(point);
      final pointMinus = List<double>.from(point);

      for (var o = 0; o < _order; o++) {
        pointPlus[varIndex] = point[varIndex] + h;
        pointMinus[varIndex] = point[varIndex] - h;
        if (o == 0) {
          derivative = (f(pointPlus) - f(pointMinus)) / (2 * h);
        } else {
          // Higher order - use more complex formula
          const h2 = h * 10; // Larger step for stability
          pointPlus[varIndex] = point[varIndex] + h2;
          pointMinus[varIndex] = point[varIndex] - h2;
          final plus2 = List<double>.from(point)
            ..[varIndex] = point[varIndex] + 2 * h2;
          final minus2 = List<double>.from(point)
            ..[varIndex] = point[varIndex] - 2 * h2;
          derivative =
              (-f(plus2) + 8 * f(pointPlus) - 8 * f(pointMinus) + f(minus2)) /
              (12 * h2);
        }
        point[varIndex] = point[varIndex]; // Reset
      }

      final orderStr = _order == 1 ? '' : '$_order';
      final subscript = _order == 1 ? _partialVar : _partialVar * _order;
      setState(() {
        _result =
            '∂$orderStr f/∂$subscript at (${pointStrs.join(', ')})\n= ${_formatNumber(derivative)}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vars = _variablesCtrl.text.split(',').map((v) => v.trim()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partial Derivative (Numerical)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x, y, ...)',
              hintText: 'e.g., x^2*y + y^3',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _variablesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Variables (comma-separated)',
                    hintText: 'x, y',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _pointCtrl,
                  decoration: const InputDecoration(
                    labelText: 'At point (comma-separated)',
                    hintText: '1, 2',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('∂/∂ '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: vars.contains(_partialVar)
                    ? _partialVar
                    : (vars.isNotEmpty ? vars.first : 'x'),
                items: vars
                    .where((v) => v.isNotEmpty)
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _partialVar = v ?? 'x'),
              ),
              const SizedBox(width: 24),
              const Text('Order: '),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1st')),
                  ButtonSegment(value: 2, label: Text('2nd')),
                ],
                selected: {_order},
                onSelectionChanged: (s) => setState(() => _order = s.first),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _compute,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Compute Partial'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
              ),
            ),

          const SizedBox(height: 24),
          Text('Examples:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '• f(x,y) = x²y + y³ → ∂f/∂x = 2xy\n'
            '• f(x,y) = sin(x*y) → ∂f/∂x = y*cos(xy)\n'
            '• f(x,y,z) = x*y*z → ∂f/∂z = xy',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INTEGRAL CALCULATOR
// ============================================================================

class _IntegralCalculator extends StatefulWidget {
  const _IntegralCalculator();

  @override
  State<_IntegralCalculator> createState() => _IntegralCalculatorState();
}

class _IntegralCalculatorState extends State<_IntegralCalculator> {
  final _expressionCtrl = TextEditingController(text: 'x^2');
  final _variableCtrl = TextEditingController(text: 'x');
  final _lowerCtrl = TextEditingController(text: '0');
  final _upperCtrl = TextEditingController(text: '1');
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _variableCtrl.dispose();
    _lowerCtrl.dispose();
    _upperCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final expr = _expressionCtrl.text;
      final variable = _variableCtrl.text;
      final a = double.parse(_lowerCtrl.text);
      final b = double.parse(_upperCtrl.text);

      // Use Rust backend for integration
      final result = await MathService.instance.integrate(
        expr,
        variable,
        a,
        b,
        numIntervals: 1000,
      );

      setState(() {
        _result =
            '∫ $expr d$variable from $a to $b\n= ${_formatNumber(result.value)}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Definite Integration (Simpson\'s Rule)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., x^2, sin(x)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _variableCtrl,
            decoration: const InputDecoration(
              labelText: 'Variable',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lowerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lower bound',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _upperCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Upper bound',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _compute,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Integrate'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// MULTIPLE INTEGRAL CALCULATOR
// ============================================================================

class _MultipleIntegralCalculator extends StatefulWidget {
  const _MultipleIntegralCalculator();

  @override
  State<_MultipleIntegralCalculator> createState() =>
      _MultipleIntegralCalculatorState();
}

class _MultipleIntegralCalculatorState
    extends State<_MultipleIntegralCalculator> {
  final _expressionCtrl = TextEditingController(text: 'x*y');
  var _integralType = 'double'; // 'double', 'triple'

  // Double integral bounds
  final _xLowerCtrl = TextEditingController(text: '0');
  final _xUpperCtrl = TextEditingController(text: '1');
  final _yLowerCtrl = TextEditingController(text: '0');
  final _yUpperCtrl = TextEditingController(text: '1');

  // Triple integral bounds
  final _zLowerCtrl = TextEditingController(text: '0');
  final _zUpperCtrl = TextEditingController(text: '1');

  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _xLowerCtrl.dispose();
    _xUpperCtrl.dispose();
    _yLowerCtrl.dispose();
    _yUpperCtrl.dispose();
    _zLowerCtrl.dispose();
    _zUpperCtrl.dispose();
    super.dispose();
  }

  double _evaluateMultivar(String expr, double x, double y, [double z = 0]) {
    var e = expr.replaceAll(' ', '').toLowerCase();
    e = e.replaceAll('x', '($x)');
    e = e.replaceAll('y', '($y)');
    e = e.replaceAll('z', '($z)');
    e = e.replaceAll('pi', '(${math.pi})');
    e = e.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z])'),
      (m) => '(${math.e})',
    );
    e = _processFunctions(e);
    return _calculate(e);
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final expr = _expressionCtrl.text;
      final xLower = double.parse(_xLowerCtrl.text);
      final xUpper = double.parse(_xUpperCtrl.text);
      final yLower = double.parse(_yLowerCtrl.text);
      final yUpper = double.parse(_yUpperCtrl.text);

      double result;

      if (_integralType == 'double') {
        // Simpson's rule for double integral
        const n = 50; // Subdivisions per dimension
        final hx = (xUpper - xLower) / n;
        final hy = (yUpper - yLower) / n;

        var sum = 0.0;
        for (var i = 0; i <= n; i++) {
          final x = xLower + i * hx;
          final wx = (i == 0 || i == n) ? 1 : (i.isEven ? 2 : 4);

          for (var j = 0; j <= n; j++) {
            final y = yLower + j * hy;
            final wy = (j == 0 || j == n) ? 1 : (j.isEven ? 2 : 4);
            sum += wx * wy * _evaluateMultivar(expr, x, y);
          }
        }
        result = sum * hx * hy / 9;

        setState(() {
          _result =
              '∬ $expr dx dy\n'
              'x: [$xLower, $xUpper], y: [$yLower, $yUpper]\n'
              '≈ ${_formatNumber(result)}';
          _isComputing = false;
        });
      } else {
        // Triple integral
        final zLower = double.parse(_zLowerCtrl.text);
        final zUpper = double.parse(_zUpperCtrl.text);

        const n = 20; // Fewer subdivisions for triple
        final hx = (xUpper - xLower) / n;
        final hy = (yUpper - yLower) / n;
        final hz = (zUpper - zLower) / n;

        var sum = 0.0;
        for (var i = 0; i <= n; i++) {
          final x = xLower + i * hx;
          final wx = (i == 0 || i == n) ? 1 : (i.isEven ? 2 : 4);

          for (var j = 0; j <= n; j++) {
            final y = yLower + j * hy;
            final wy = (j == 0 || j == n) ? 1 : (j.isEven ? 2 : 4);

            for (var k = 0; k <= n; k++) {
              final z = zLower + k * hz;
              final wz = (k == 0 || k == n) ? 1 : (k.isEven ? 2 : 4);
              sum += wx * wy * wz * _evaluateMultivar(expr, x, y, z);
            }
          }
        }
        result = sum * hx * hy * hz / 27;

        setState(() {
          _result =
              '∭ $expr dx dy dz\n'
              'x: [$xLower, $xUpper], y: [$yLower, $yUpper], z: [$zLower, $zUpper]\n'
              '≈ ${_formatNumber(result)}';
          _isComputing = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multiple Integral (Numerical)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'double', label: Text('Double ∬')),
              ButtonSegment(value: 'triple', label: Text('Triple ∭')),
            ],
            selected: {_integralType},
            onSelectionChanged: (s) => setState(() => _integralType = s.first),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: InputDecoration(
              labelText: _integralType == 'double' ? 'f(x, y)' : 'f(x, y, z)',
              hintText: _integralType == 'double' ? 'e.g., x*y' : 'e.g., x*y*z',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Text('X bounds:', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _xLowerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lower',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _xUpperCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Upper',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text('Y bounds:', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yLowerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lower',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _yUpperCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Upper',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),

          if (_integralType == 'triple') ...[
            const SizedBox(height: 16),
            Text('Z bounds:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _zLowerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lower',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _zUpperCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Upper',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _compute,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: Text('Compute ${_integralType == 'double' ? '∬' : '∭'}'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
              ),
            ),

          const SizedBox(height: 24),
          Text('Examples:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '• ∬ xy dx dy over [0,1]×[0,1] = 0.25\n'
            '• ∬ x² + y² dx dy over [0,1]×[0,1] = 2/3\n'
            '• ∭ xyz dx dy dz over [0,1]³ = 1/8',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LIMIT CALCULATOR
// ============================================================================

class _LimitCalculator extends StatefulWidget {
  const _LimitCalculator();

  @override
  State<_LimitCalculator> createState() => _LimitCalculatorState();
}

class _LimitCalculatorState extends State<_LimitCalculator> {
  final _expressionCtrl = TextEditingController(text: 'sin(x)/x');
  final _variableCtrl = TextEditingController(text: 'x');
  final _approachCtrl = TextEditingController(text: '0');
  var _direction = 'both'; // 'left', 'right', 'both'
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _variableCtrl.dispose();
    _approachCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final expr = _expressionCtrl.text;
      final variable = _variableCtrl.text;
      final approach = double.parse(_approachCtrl.text);

      // Use Rust backend for limit computation
      final fromLeft = _direction == 'left' || _direction == 'both';
      final fromRight = _direction == 'right' || _direction == 'both';

      final result = await MathService.instance.computeLimit(
        expr,
        variable,
        approach,
        fromLeft: fromLeft,
        fromRight: fromRight,
      );

      String resultText;
      if (_direction == 'both') {
        if (result.success) {
          resultText =
              'lim(x→$approach) $expr = ${_formatNumber(result.value)}';
        } else {
          resultText = result.error ?? 'Limit does not exist or is undefined';
        }
      } else if (_direction == 'left') {
        resultText =
            'lim(x→$approach⁻) $expr = ${result.success ? _formatNumber(result.value) : "undefined"}';
      } else {
        resultText =
            'lim(x→$approach⁺) $expr = ${result.success ? _formatNumber(result.value) : "undefined"}';
      }

      setState(() {
        _result = resultText;
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Limit Calculator',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., sin(x)/x',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _variableCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Variable',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _approachCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Approaches',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'left', label: Text('Left (x→a⁻)')),
              ButtonSegment(value: 'both', label: Text('Both')),
              ButtonSegment(value: 'right', label: Text('Right (x→a⁺)')),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _compute,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Compute Limit'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// SERIES CALCULATOR (Taylor/Maclaurin)
// ============================================================================

class _SeriesCalculator extends StatefulWidget {
  const _SeriesCalculator();

  @override
  State<_SeriesCalculator> createState() => _SeriesCalculatorState();
}

class _SeriesCalculatorState extends State<_SeriesCalculator> {
  final _expressionCtrl = TextEditingController(text: 'exp(x)');
  final _variableCtrl = TextEditingController(text: 'x');
  final _centerCtrl = TextEditingController(text: '0');
  var _terms = 5;
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _variableCtrl.dispose();
    _centerCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final expr = _expressionCtrl.text;
      final variable = _variableCtrl.text;
      final a = double.parse(_centerCtrl.text);

      // Use Rust backend for Taylor coefficients
      final coefficients = await MathService.instance.taylorCoefficients(
        expr,
        variable,
        a,
        _terms,
      );

      // Build series string
      final termStrings = <String>[];
      for (var n = 0; n < coefficients.length; n++) {
        final coef = coefficients[n];
        if (coef.abs() < 1e-10) continue;

        var term = _formatNumber(coef);
        if (n > 0) {
          if (a == 0) {
            term += n == 1 ? variable : '$variable^$n';
          } else {
            term += n == 1 ? '($variable-$a)' : '($variable-$a)^$n';
          }
        }
        termStrings.add(term);
      }

      final seriesName = a == 0 ? 'Maclaurin' : 'Taylor';
      setState(() {
        _result =
            '$seriesName series of $expr around $variable = $a:\n\n${termStrings.join(' + ')}\n\n+ O($variable^$_terms)';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Taylor/Maclaurin Series',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., exp(x), sin(x), cos(x)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _variableCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Variable',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _centerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Center (a)',
                    hintText: '0 for Maclaurin',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('Terms: '),
              Slider(
                value: _terms.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                label: '$_terms',
                onChanged: (v) => setState(() => _terms = v.toInt()),
              ),
              Text('$_terms'),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _compute,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Compute Series'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}
