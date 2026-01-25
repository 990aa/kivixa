import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// General tab - Scientific Calculator with Constants & Number Conversion
/// Features: Expression evaluation, number system conversion, constants
class MathGeneralTab extends StatefulWidget {
  const MathGeneralTab({super.key});

  @override
  State<MathGeneralTab> createState() => _MathGeneralTabState();
}

class _MathGeneralTabState extends State<MathGeneralTab> {
  final _expressionController = TextEditingController();
  final _focusNode = FocusNode();
  var _result = '';
  var _error = '';
  var _isComputing = false;
  var _showConstants = false;

  // Number conversion
  final _conversionController = TextEditingController();
  var _fromBase = 10;
  var _toBase = 2;
  var _conversionResult = '';

  static const _prefsKey = 'math_general_expression';
  static const _conversionPrefsKey = 'math_general_conversion';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedExpr = prefs.getString(_prefsKey);
    final savedConv = prefs.getString(_conversionPrefsKey);
    if (savedExpr != null && savedExpr.isNotEmpty) {
      _expressionController.text = savedExpr;
    }
    if (savedConv != null && savedConv.isNotEmpty) {
      _conversionController.text = savedConv;
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _expressionController.text);
    await prefs.setString(_conversionPrefsKey, _conversionController.text);
  }

  @override
  void dispose() {
    _saveState();
    _expressionController.dispose();
    _conversionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final expression = _expressionController.text.trim();
    if (expression.isEmpty) return;

    setState(() {
      _isComputing = true;
      _error = '';
    });

    try {
      final result = _evaluateExpression(expression);
      setState(() {
        _result = '= $result';
        _isComputing = false;
      });
      _saveState();
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _result = '';
        _isComputing = false;
      });
    }
  }

  String _evaluateExpression(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    expr = expr.replaceAll('π', '(${math.pi})');
    expr = expr.replaceAll('φ', '(1.6180339887)');

    // Handle 'e' carefully - only replace standalone e, not in function names
    expr = expr.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z])'),
      (m) => '(${math.e})',
    );

    expr = _processFunctions(expr);
    final result = _calculate(expr);

    if (result == result.toInt().toDouble() && result.abs() < 1e15) {
      return result.toInt().toString();
    }
    return result
        .toStringAsFixed(10)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _processFunctions(String expr) {
    // Process nested functions from innermost to outermost
    var changed = true;
    var iterations = 0;
    while (changed && iterations < 100) {
      changed = false;
      iterations++;

      // sqrt
      final sqrtMatch = RegExp(r'sqrt\(([^()]+)\)').firstMatch(expr);
      if (sqrtMatch != null) {
        final inner = _calculate(sqrtMatch.group(1)!);
        expr = expr.replaceFirst(sqrtMatch.group(0)!, '(${math.sqrt(inner)})');
        changed = true;
        continue;
      }

      // sin
      final sinMatch = RegExp(r'sin\(([^()]+)\)').firstMatch(expr);
      if (sinMatch != null) {
        final inner = _calculate(sinMatch.group(1)!);
        expr = expr.replaceFirst(sinMatch.group(0)!, '(${math.sin(inner)})');
        changed = true;
        continue;
      }

      // cos
      final cosMatch = RegExp(r'cos\(([^()]+)\)').firstMatch(expr);
      if (cosMatch != null) {
        final inner = _calculate(cosMatch.group(1)!);
        expr = expr.replaceFirst(cosMatch.group(0)!, '(${math.cos(inner)})');
        changed = true;
        continue;
      }

      // tan
      final tanMatch = RegExp(r'tan\(([^()]+)\)').firstMatch(expr);
      if (tanMatch != null) {
        final inner = _calculate(tanMatch.group(1)!);
        expr = expr.replaceFirst(tanMatch.group(0)!, '(${math.tan(inner)})');
        changed = true;
        continue;
      }

      // ln
      final lnMatch = RegExp(r'ln\(([^()]+)\)').firstMatch(expr);
      if (lnMatch != null) {
        final inner = _calculate(lnMatch.group(1)!);
        expr = expr.replaceFirst(lnMatch.group(0)!, '(${math.log(inner)})');
        changed = true;
        continue;
      }

      // log (base 10)
      final logMatch = RegExp(r'log\(([^()]+)\)').firstMatch(expr);
      if (logMatch != null) {
        final inner = _calculate(logMatch.group(1)!);
        expr = expr.replaceFirst(
          logMatch.group(0)!,
          '(${math.log(inner) / math.ln10})',
        );
        changed = true;
        continue;
      }

      // abs
      final absMatch = RegExp(r'abs\(([^()]+)\)').firstMatch(expr);
      if (absMatch != null) {
        final inner = _calculate(absMatch.group(1)!);
        expr = expr.replaceFirst(absMatch.group(0)!, '(${inner.abs()})');
        changed = true;
        continue;
      }
    }

    // Handle factorial
    expr = expr.replaceAllMapped(
      RegExp(r'(\d+)!'),
      (m) => '(${_factorial(int.parse(m.group(1)!))})',
    );

    return expr;
  }

  int _factorial(int n) {
    if (n < 0) throw Exception('Factorial undefined for negative numbers');
    if (n <= 1) return 1;
    var result = 1;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  double _calculate(String expr) {
    expr = expr.trim();
    if (expr.isEmpty) throw Exception('Empty expression');

    // Remove outer parentheses if they match
    while (expr.startsWith('(') &&
        expr.endsWith(')') &&
        _isMatchingParens(expr)) {
      expr = expr.substring(1, expr.length - 1).trim();
    }

    // Handle parentheses by finding innermost first
    while (expr.contains('(')) {
      final match = RegExp(r'\(([^()]+)\)').firstMatch(expr);
      if (match == null) throw Exception('Mismatched parentheses');
      final inner = _calculate(match.group(1)!);
      expr = expr.replaceFirst(match.group(0)!, inner.toString());
    }

    // Split by addition/subtraction (lowest precedence, right to left)
    for (var i = expr.length - 1; i >= 0; i--) {
      if ((expr[i] == '+' || expr[i] == '-') && i > 0) {
        // Make sure this isn't part of a number (like 1e-5)
        if (i > 0 && (expr[i - 1] == 'e' || expr[i - 1] == 'E')) continue;

        final left = expr.substring(0, i).trim();
        final right = expr.substring(i + 1).trim();
        if (left.isNotEmpty && right.isNotEmpty) {
          final leftVal = _calculate(left);
          final rightVal = _calculate(right);
          return expr[i] == '+' ? leftVal + rightVal : leftVal - rightVal;
        }
      }
    }

    // Split by multiplication/division
    for (var i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == '*' || expr[i] == '/') {
        final left = expr.substring(0, i).trim();
        final right = expr.substring(i + 1).trim();
        if (left.isNotEmpty && right.isNotEmpty) {
          final leftVal = _calculate(left);
          final rightVal = _calculate(right);
          if (expr[i] == '/' && rightVal == 0)
            throw Exception('Division by zero');
          return expr[i] == '*' ? leftVal * rightVal : leftVal / rightVal;
        }
      }
    }

    // Handle power (^)
    final powerIndex = expr.lastIndexOf('^');
    if (powerIndex > 0) {
      final base = _calculate(expr.substring(0, powerIndex).trim());
      final exp = _calculate(expr.substring(powerIndex + 1).trim());
      return math.pow(base, exp).toDouble();
    }

    // Handle percentage
    if (expr.endsWith('%')) {
      return _calculate(expr.substring(0, expr.length - 1)) / 100;
    }

    // Parse as number
    final num = double.tryParse(expr);
    if (num == null) throw Exception('Invalid expression: $expr');
    return num;
  }

  bool _isMatchingParens(String expr) {
    var depth = 0;
    for (var i = 0; i < expr.length; i++) {
      if (expr[i] == '(') depth++;
      if (expr[i] == ')') depth--;
      if (depth == 0 && i < expr.length - 1) return false;
    }
    return depth == 0;
  }

  void _insertText(String text) {
    final currentText = _expressionController.text;
    final selection = _expressionController.selection;
    final start = selection.start >= 0 ? selection.start : currentText.length;
    final end = selection.end >= 0 ? selection.end : currentText.length;
    final newText =
        currentText.substring(0, start) + text + currentText.substring(end);
    _expressionController.text = newText;
    _expressionController.selection = TextSelection.collapsed(
      offset: start + text.length,
    );
    _focusNode.requestFocus();
    _saveState();
  }

  void _clear() {
    _expressionController.clear();
    setState(() {
      _result = '';
      _error = '';
    });
    _focusNode.requestFocus();
    _saveState();
  }

  void _backspace() {
    final currentText = _expressionController.text;
    if (currentText.isNotEmpty) {
      _expressionController.text = currentText.substring(
        0,
        currentText.length - 1,
      );
      _saveState();
    }
    _focusNode.requestFocus();
  }

  void _convertNumber() {
    final input = _conversionController.text.trim();
    if (input.isEmpty) {
      setState(() => _conversionResult = '');
      return;
    }

    try {
      final decimalValue = int.parse(input.toUpperCase(), radix: _fromBase);
      final converted = decimalValue.toRadixString(_toBase).toUpperCase();
      setState(() => _conversionResult = converted);
    } catch (e) {
      setState(() => _conversionResult = 'Invalid input for base $_fromBase');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDisplay(colorScheme),
          const SizedBox(height: 12),
          _buildCompactKeypad(colorScheme),
          const SizedBox(height: 16),
          _buildConstantsSection(colorScheme),
          const SizedBox(height: 16),
          _buildConversionSection(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDisplay(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _expressionController,
            focusNode: _focusNode,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'monospace',
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Enter expression...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            maxLines: 2,
            minLines: 1,
            onSubmitted: (_) => _evaluate(),
            onChanged: (_) => _saveState(),
          ),
          const SizedBox(height: 4),

          if (_isComputing)
            const LinearProgressIndicator()
          else if (_error.isNotEmpty)
            Text(
              _error,
              style: TextStyle(color: colorScheme.error, fontSize: 14),
            )
          else if (_result.isNotEmpty)
            SelectableText(
              _result,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactKeypad(ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      childAspectRatio: 1.4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      children: [
        // Row 1: Functions
        _compactBtn(
          'sin',
          () => _insertText('sin('),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'cos',
          () => _insertText('cos('),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'tan',
          () => _insertText('tan('),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'ln',
          () => _insertText('ln('),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'log',
          () => _insertText('log('),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          '√',
          () => _insertText('sqrt('),
          colorScheme.tertiaryContainer,
        ),

        // Row 2: Powers and special
        _compactBtn(
          'x²',
          () => _insertText('^2'),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'xʸ',
          () => _insertText('^'),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          '|x|',
          () => _insertText('abs('),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'n!',
          () => _insertText('!'),
          colorScheme.tertiaryContainer,
        ),
        _compactBtn(
          'π',
          () => _insertText('π'),
          colorScheme.secondaryContainer,
        ),
        _compactBtn(
          'e',
          () => _insertText('e'),
          colorScheme.secondaryContainer,
        ),

        // Row 3: Brackets and clear
        _compactBtn('C', _clear, colorScheme.errorContainer),
        _compactBtn('(', () => _insertText('('), null),
        _compactBtn(')', () => _insertText(')'), null),
        _compactBtn(
          '⌫',
          _backspace,
          colorScheme.errorContainer.withOpacity(0.5),
        ),
        _compactBtn('%', () => _insertText('%'), colorScheme.primaryContainer),
        _compactBtn('÷', () => _insertText('/'), colorScheme.primaryContainer),

        // Row 4: Numbers 7-9 and multiply
        _compactBtn('7', () => _insertText('7'), null),
        _compactBtn('8', () => _insertText('8'), null),
        _compactBtn('9', () => _insertText('9'), null),
        _compactBtn('×', () => _insertText('*'), colorScheme.primaryContainer),
        _compactBtn(
          'A',
          () => _insertText('A'),
          colorScheme.surfaceContainerHigh,
        ),
        _compactBtn(
          'B',
          () => _insertText('B'),
          colorScheme.surfaceContainerHigh,
        ),

        // Row 5: Numbers 4-6 and subtract
        _compactBtn('4', () => _insertText('4'), null),
        _compactBtn('5', () => _insertText('5'), null),
        _compactBtn('6', () => _insertText('6'), null),
        _compactBtn('-', () => _insertText('-'), colorScheme.primaryContainer),
        _compactBtn(
          'C',
          () => _insertText('C'),
          colorScheme.surfaceContainerHigh,
        ),
        _compactBtn(
          'D',
          () => _insertText('D'),
          colorScheme.surfaceContainerHigh,
        ),

        // Row 6: Numbers 1-3 and add
        _compactBtn('1', () => _insertText('1'), null),
        _compactBtn('2', () => _insertText('2'), null),
        _compactBtn('3', () => _insertText('3'), null),
        _compactBtn('+', () => _insertText('+'), colorScheme.primaryContainer),
        _compactBtn(
          'E',
          () => _insertText('E'),
          colorScheme.surfaceContainerHigh,
        ),
        _compactBtn(
          'F',
          () => _insertText('F'),
          colorScheme.surfaceContainerHigh,
        ),

        // Row 7: Zero, decimal, equals
        _compactBtn('±', () {
          final text = _expressionController.text;
          if (text.startsWith('-')) {
            _expressionController.text = text.substring(1);
          } else if (text.isNotEmpty) {
            _expressionController.text = '-$text';
          }
          _saveState();
        }, null),
        _compactBtn('0', () => _insertText('0'), null),
        _compactBtn('.', () => _insertText('.'), null),
        _compactBtn('=', _evaluate, colorScheme.primary, colorScheme.onPrimary),
        _compactBtn(',', () => _insertText(','), null),
        _compactBtn('Ans', () {
          if (_result.startsWith('= ')) {
            _insertText(_result.substring(2));
          }
        }, colorScheme.secondaryContainer),
      ],
    );
  }

  Widget _compactBtn(
    String label,
    VoidCallback onPressed,
    Color? bgColor, [
    Color? fgColor,
  ]) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: bgColor ?? colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fgColor ?? colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConstantsSection(ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('Constants'),
            trailing: Icon(
              _showConstants ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _showConstants = !_showConstants),
          ),
          if (_showConstants)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _constants.map((c) {
                  return ActionChip(
                    label: Text(c.symbol, style: const TextStyle(fontSize: 12)),
                    tooltip: '${c.name}: ${c.value}',
                    onPressed: () => _insertText(c.insertValue),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversionSection(ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number System Conversion',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _conversionController,
                    decoration: const InputDecoration(
                      labelText: 'Input',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) {
                      _convertNumber();
                      _saveState();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _BaseDropdown(
                  value: _fromBase,
                  onChanged: (v) {
                    setState(() => _fromBase = v!);
                    _convertNumber();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: colorScheme.outline,
                  ),
                ),
                _BaseDropdown(
                  value: _toBase,
                  onChanged: (v) {
                    setState(() => _toBase = v!);
                    _convertNumber();
                  },
                ),
              ],
            ),
            if (_conversionResult.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _conversionResult,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _constants = [
    _Constant('π', 'Pi', '3.14159265358979', 'π'),
    _Constant('e', 'Euler\'s number', '2.71828182845905', 'e'),
    _Constant('φ', 'Golden ratio', '1.61803398874989', '1.6180339887'),
    _Constant('√2', 'Square root of 2', '1.41421356237310', '1.4142135624'),
    _Constant('√3', 'Square root of 3', '1.73205080756888', '1.7320508076'),
    _Constant('c', 'Speed of light (m/s)', '299792458', '299792458'),
    _Constant('G', 'Gravitational const', '6.67430e-11', '6.67430e-11'),
    _Constant('h', 'Planck constant', '6.62607015e-34', '6.62607015e-34'),
    _Constant('kB', 'Boltzmann const', '1.380649e-23', '1.380649e-23'),
    _Constant('NA', 'Avogadro const', '6.02214076e23', '6.02214076e23'),
    _Constant('R', 'Gas constant', '8.314462618', '8.314462618'),
    _Constant('g', 'Standard gravity', '9.80665', '9.80665'),
  ];
}

class _Constant {
  final String symbol;
  final String name;
  final String value;
  final String insertValue;

  const _Constant(this.symbol, this.name, this.value, this.insertValue);
}

class _BaseDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;

  const _BaseDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      items: const [
        DropdownMenuItem(value: 2, child: Text('BIN')),
        DropdownMenuItem(value: 8, child: Text('OCT')),
        DropdownMenuItem(value: 10, child: Text('DEC')),
        DropdownMenuItem(value: 16, child: Text('HEX')),
      ],
      onChanged: onChanged,
      isDense: true,
      underline: const SizedBox(),
    );
  }
}
