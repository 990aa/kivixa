.import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Calculus tab - Derivatives, integrals, limits, series
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
    _subTabController = TabController(length: 4, vsync: this);
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
            Tab(text: 'Integral'),
            Tab(text: 'Limits'),
            Tab(text: 'Series'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _DerivativeCalculator(),
              _IntegralCalculator(),
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

      double f(double x) => _evaluateExpr(expr, variable, x);

      // Numerical differentiation using central difference
      const h = 1e-5;
      double derivative;

      if (_order == 1) {
        // First derivative: f'(x) ≈ (f(x+h) - f(x-h)) / 2h
        derivative = (f(point + h) - f(point - h)) / (2 * h);
      } else if (_order == 2) {
        // Second derivative: f''(x) ≈ (f(x+h) - 2f(x) + f(x-h)) / h²
        derivative = (f(point + h) - 2 * f(point) + f(point - h)) / (h * h);
      } else {
        // Third derivative: f'''(x) ≈ (f(x+2h) - 2f(x+h) + 2f(x-h) - f(x-2h)) / 2h³
        derivative =
            (f(point + 2 * h) -
                2 * f(point + h) +
                2 * f(point - h) -
                f(point - 2 * h)) /
            (2 * h * h * h);
      }

      final primeSymbol = "'" * _order;
      setState(() {
        _result = 'f$primeSymbol($point) = ${_formatNumber(derivative)}';
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
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
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

      double f(double x) => _evaluateExpr(expr, variable, x);

      // Simpson's rule with adaptive step count
      const n = 1000; // Number of intervals (must be even)
      final h = (b - a) / n;

      var sum = f(a) + f(b);
      for (var i = 1; i < n; i++) {
        final x = a + i * h;
        sum += (i % 2 == 0 ? 2 : 4) * f(x);
      }
      final integral = sum * h / 3;

      setState(() {
        _result =
            '∫ $expr d$variable from $a to $b\n= ${_formatNumber(integral)}';
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
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
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

      double f(double x) => _evaluateExpr(expr, variable, x);

      // Numerical limit computation
      double? leftLimit, rightLimit;

      if (_direction == 'left' || _direction == 'both') {
        // Approach from left
        var sum = 0.0;
        var count = 0;
        for (final h in [1e-3, 1e-4, 1e-5, 1e-6, 1e-7]) {
          final val = f(approach - h);
          if (val.isFinite) {
            sum += val;
            count++;
          }
        }
        leftLimit = count > 0 ? sum / count : null;
      }

      if (_direction == 'right' || _direction == 'both') {
        // Approach from right
        var sum = 0.0;
        var count = 0;
        for (final h in [1e-3, 1e-4, 1e-5, 1e-6, 1e-7]) {
          final val = f(approach + h);
          if (val.isFinite) {
            sum += val;
            count++;
          }
        }
        rightLimit = count > 0 ? sum / count : null;
      }

      String resultText;
      if (_direction == 'both') {
        if (leftLimit != null &&
            rightLimit != null &&
            (leftLimit - rightLimit).abs() < 1e-4) {
          resultText =
              'lim(x→$approach) $expr = ${_formatNumber((leftLimit + rightLimit) / 2)}';
        } else {
          resultText =
              'Left limit: ${leftLimit != null ? _formatNumber(leftLimit) : "undefined"}\n'
              'Right limit: ${rightLimit != null ? _formatNumber(rightLimit) : "undefined"}\n'
              '${leftLimit != rightLimit ? "Limit does not exist (one-sided limits differ)" : ""}';
        }
      } else if (_direction == 'left') {
        resultText =
            'lim(x→$approach⁻) $expr = ${leftLimit != null ? _formatNumber(leftLimit) : "undefined"}';
      } else {
        resultText =
            'lim(x→$approach⁺) $expr = ${rightLimit != null ? _formatNumber(rightLimit) : "undefined"}';
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
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
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

      double f(double x) => _evaluateExpr(expr, variable, x);

      // Compute Taylor coefficients numerically
      final coefficients = <double>[];
      const h = 1e-4;

      for (var n = 0; n < _terms; n++) {
        // n-th derivative at a using finite differences
        double derivative;
        if (n == 0) {
          derivative = f(a);
        } else {
          // Use central difference for higher derivatives
          derivative = _nthDerivative(f, a, n, h);
        }
        coefficients.add(derivative / _factorial(n));
      }

      // Build series string
      final termStrings = <String>[];
      for (var n = 0; n < coefficients.length; n++) {
        final coef = coefficients[n];
        if (coef.abs() < 1e-10) continue;

        var term = _formatNumber(coef);
        if (n > 0) {
          if (a == 0) {
            term += n == 1 ? '$variable' : '$variable^$n';
          } else {
            term += n == 1 ? '($variable-$a)' : '($variable-$a)^$n';
          }
        }
        termStrings.add(term);
      }

      final seriesName = a == 0 ? 'Maclaurin' : 'Taylor';
      setState(() {
        _result =
            '$seriesName series of $expr around $variable = $a:\n\n${termStrings.join(' + ')}\n\n+ O(${variable}^$_terms)';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  double _nthDerivative(double Function(double) f, double x, int n, double h) {
    if (n == 0) return f(x);
    if (n == 1) return (f(x + h) - f(x - h)) / (2 * h);
    if (n == 2) return (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);

    // Higher derivatives using recursive central difference
    double prev(double t) => _nthDerivative(f, t, n - 1, h);
    return (prev(x + h) - prev(x - h)) / (2 * h);
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    var result = 1;
    for (var i = 2; i <= n; i++) result *= i;
    return result;
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
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
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
