import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Custom Formulae tab - Create, store, and use custom mathematical formulas
class MathFormulaeTab extends StatefulWidget {
  const MathFormulaeTab({super.key});

  @override
  State<MathFormulaeTab> createState() => _MathFormulaeTabState();
}

class _MathFormulaeTabState extends State<MathFormulaeTab> {
  final _formulae = <_Formula>[];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormulae();
  }

  Future<void> _loadFormulae() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('custom_formulae');
      if (json != null) {
        final list = jsonDecode(json) as List;
        setState(() {
          _formulae.clear();
          _formulae.addAll(list.map((e) => _Formula.fromJson(e)));
        });
      }
    } catch (e) {
      // Ignore errors on load
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFormulae() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'custom_formulae',
        jsonEncode(_formulae.map((f) => f.toJson()).toList()),
      );
    } catch (e) {
      // Ignore errors on save
    }
  }

  void _addFormula() {
    showDialog(
      context: context,
      builder: (context) => _FormulaEditorDialog(
        onSave: (formula) {
          setState(() => _formulae.add(formula));
          _saveFormulae();
        },
      ),
    );
  }

  void _editFormula(int index) {
    showDialog(
      context: context,
      builder: (context) => _FormulaEditorDialog(
        formula: _formulae[index],
        onSave: (formula) {
          setState(() => _formulae[index] = formula);
          _saveFormulae();
        },
      ),
    );
  }

  void _deleteFormula(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Formula'),
        content: Text('Delete "${_formulae[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _formulae.removeAt(index));
              _saveFormulae();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _useFormula(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormulaCalculator(formula: _formulae[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _formulae.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildFormulaList(colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFormula,
        icon: const Icon(Icons.add),
        label: const Text('New Formula'),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.functions,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Formulae',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create reusable mathematical formulas\nwith named variables',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addFormula,
            icon: const Icon(Icons.add),
            label: const Text('Create Formula'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _formulae.length,
      itemBuilder: (context, index) {
        final formula = _formulae[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _useFormula(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formula.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editFormula(index),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        onPressed: () => _deleteFormula(index),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  if (formula.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      formula.description,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formula.expression,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: formula.variables.map((v) {
                      return Chip(
                        label: Text(v),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Formula {
  final String name;
  final String description;
  final String expression;
  final List<String> variables;

  _Formula({
    required this.name,
    required this.expression,
    this.description = '',
    List<String>? variables,
  }) : variables = variables ?? _extractVariables(expression);

  static List<String> _extractVariables(String expr) {
    // Find all single-letter or named variables (not function names)
    final reserved = {
      'sin',
      'cos',
      'tan',
      'asin',
      'acos',
      'atan',
      'sinh',
      'cosh',
      'tanh',
      'asinh',
      'acosh',
      'atanh',
      'log',
      'ln',
      'exp',
      'sqrt',
      'cbrt',
      'abs',
      'floor',
      'ceil',
      'round',
      'sign',
      'pi',
      'e',
      'phi',
      'tau',
    };

    final pattern = RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\b');
    final matches = pattern.allMatches(expr);
    final vars = <String>{};

    for (final match in matches) {
      final name = match.group(1)!.toLowerCase();
      if (!reserved.contains(name)) {
        vars.add(match.group(1)!);
      }
    }

    return vars.toList()..sort();
  }

  factory _Formula.fromJson(Map<String, dynamic> json) {
    return _Formula(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      expression: json['expression'] as String,
      variables: (json['variables'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'expression': expression,
      'variables': variables,
    };
  }
}

class _FormulaEditorDialog extends StatefulWidget {
  final _Formula? formula;
  final ValueChanged<_Formula> onSave;

  const _FormulaEditorDialog({this.formula, required this.onSave});

  @override
  State<_FormulaEditorDialog> createState() => _FormulaEditorDialogState();
}

class _FormulaEditorDialogState extends State<_FormulaEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _exprCtrl;
  List<String> _detectedVars = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.formula?.name ?? '');
    _descCtrl = TextEditingController(text: widget.formula?.description ?? '');
    _exprCtrl = TextEditingController(text: widget.formula?.expression ?? '');
    _detectedVars = widget.formula?.variables ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _exprCtrl.dispose();
    super.dispose();
  }

  void _updateVariables() {
    setState(() {
      _detectedVars = _Formula._extractVariables(_exprCtrl.text);
    });
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a formula name')),
      );
      return;
    }
    if (_exprCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expression')),
      );
      return;
    }

    widget.onSave(
      _Formula(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        expression: _exprCtrl.text.trim(),
        variables: _detectedVars,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.formula != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Formula' : 'New Formula'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Quadratic Formula',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of the formula',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _exprCtrl,
              decoration: const InputDecoration(
                labelText: 'Expression',
                hintText: 'e.g., (-b + sqrt(b^2 - 4*a*c)) / (2*a)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => _updateVariables(),
            ),
            const SizedBox(height: 12),
            if (_detectedVars.isNotEmpty) ...[
              Text(
                'Detected Variables:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _detectedVars.map((v) {
                  return Chip(
                    label: Text(v),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Supported: +, -, *, /, ^, sqrt, sin, cos, tan, log, ln, exp, abs, pi, e',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

class _FormulaCalculator extends StatefulWidget {
  final _Formula formula;

  const _FormulaCalculator({required this.formula});

  @override
  State<_FormulaCalculator> createState() => _FormulaCalculatorState();
}

class _FormulaCalculatorState extends State<_FormulaCalculator> {
  late final Map<String, TextEditingController> _controllers;
  var _result = '';
  var _error = '';

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final v in widget.formula.variables) v: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _error = '';
      _result = '';
    });

    try {
      // Build variable map
      final vars = <String, double>{};
      for (final entry in _controllers.entries) {
        final value = double.tryParse(entry.value.text);
        if (value == null) {
          throw Exception('Invalid value for ${entry.key}');
        }
        vars[entry.key] = value;
      }

      // Evaluate expression
      final result = _evaluate(widget.formula.expression, vars);
      setState(() => _result = _formatNumber(result));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  double _evaluate(String expr, Map<String, double> vars) {
    // Replace variables with values
    var processed = expr;

    // Sort variables by length (longest first) to avoid partial replacements
    final sortedVars = vars.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final v in sortedVars) {
      // Use word boundary replacement
      processed = processed.replaceAll(RegExp('\\b$v\\b'), '(${vars[v]})');
    }

    // Replace constants
    processed = processed.replaceAll(
      RegExp(r'\bpi\b', caseSensitive: false),
      '(${math.pi})',
    );
    processed = processed.replaceAll(
      RegExp(r'\be\b', caseSensitive: false),
      '(${math.e})',
    );
    processed = processed.replaceAll(
      RegExp(r'\bphi\b', caseSensitive: false),
      '(1.6180339887)',
    );
    processed = processed.replaceAll(
      RegExp(r'\btau\b', caseSensitive: false),
      '(${2 * math.pi})',
    );

    // Evaluate the expression
    return _evaluateExpression(processed);
  }

  double _evaluateExpression(String expr) {
    expr = expr.trim();

    // Handle functions first
    expr = _replaceFunctions(expr);

    // Handle power operator
    if (expr.contains('^')) {
      final idx = expr.lastIndexOf('^');
      final base = _evaluateExpression(expr.substring(0, idx));
      final exp = _evaluateExpression(expr.substring(idx + 1));
      return math.pow(base, exp).toDouble();
    }

    // Handle addition and subtraction (lowest precedence)
    var depth = 0;
    for (var i = expr.length - 1; i >= 0; i--) {
      final c = expr[i];
      if (c == ')') depth++;
      if (c == '(') depth--;
      if (depth == 0 && (c == '+' || c == '-') && i > 0) {
        final left = expr.substring(0, i).trim();
        final right = expr.substring(i + 1).trim();
        if (left.isNotEmpty) {
          final leftVal = _evaluateExpression(left);
          final rightVal = _evaluateExpression(right);
          return c == '+' ? leftVal + rightVal : leftVal - rightVal;
        }
      }
    }

    // Handle multiplication and division
    depth = 0;
    for (var i = expr.length - 1; i >= 0; i--) {
      final c = expr[i];
      if (c == ')') depth++;
      if (c == '(') depth--;
      if (depth == 0 && (c == '*' || c == '/')) {
        final left = _evaluateExpression(expr.substring(0, i));
        final right = _evaluateExpression(expr.substring(i + 1));
        return c == '*' ? left * right : left / right;
      }
    }

    // Handle parentheses
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _evaluateExpression(expr.substring(1, expr.length - 1));
    }

    // Handle negative numbers
    if (expr.startsWith('-')) {
      return -_evaluateExpression(expr.substring(1));
    }

    // Try parsing as a number
    final num = double.tryParse(expr);
    if (num != null) return num;

    throw Exception('Cannot evaluate: $expr');
  }

  String _replaceFunctions(String expr) {
    // Process function calls recursively
    final funcPattern = RegExp(
      r'(sqrt|sin|cos|tan|asin|acos|atan|sinh|cosh|tanh|log|ln|exp|abs|floor|ceil|round)\s*\(',
    );

    while (funcPattern.hasMatch(expr)) {
      final match = funcPattern.firstMatch(expr)!;
      final funcName = match.group(1)!;
      final start = match.start;
      final parenStart = match.end - 1;

      // Find matching closing parenthesis
      var depth = 1;
      var end = parenStart + 1;
      while (depth > 0 && end < expr.length) {
        if (expr[end] == '(') depth++;
        if (expr[end] == ')') depth--;
        end++;
      }

      final argStr = expr.substring(parenStart + 1, end - 1);
      final arg = _evaluateExpression(argStr);

      double result;
      switch (funcName) {
        case 'sqrt':
          result = math.sqrt(arg);
        case 'sin':
          result = math.sin(arg);
        case 'cos':
          result = math.cos(arg);
        case 'tan':
          result = math.tan(arg);
        case 'asin':
          result = math.asin(arg);
        case 'acos':
          result = math.acos(arg);
        case 'atan':
          result = math.atan(arg);
        case 'sinh':
          result = (math.exp(arg) - math.exp(-arg)) / 2;
        case 'cosh':
          result = (math.exp(arg) + math.exp(-arg)) / 2;
        case 'tanh':
          result =
              (math.exp(arg) - math.exp(-arg)) /
              (math.exp(arg) + math.exp(-arg));
        case 'log':
          result = math.log(arg) / math.ln10;
        case 'ln':
          result = math.log(arg);
        case 'exp':
          result = math.exp(arg);
        case 'abs':
          result = arg.abs();
        case 'floor':
          result = arg.floorToDouble();
        case 'ceil':
          result = arg.ceilToDouble();
        case 'round':
          result = arg.roundToDouble();
        default:
          throw Exception('Unknown function: $funcName');
      }

      expr = '${expr.substring(0, start)}($result)${expr.substring(end)}';
    }

    return expr;
  }

  String _formatNumber(double n) {
    if (n.isNaN) return 'NaN';
    if (n.isInfinite) return n.isNegative ? '-∞' : '∞';
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n
        .toStringAsFixed(10)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.formula.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.formula.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.formula.description,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.formula.expression,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter Values:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...widget.formula.variables.map((v) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _controllers[v],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: v,
                      border: const OutlineInputBorder(),
                      prefixText: '$v = ',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculate'),
                ),
              ),
              const SizedBox(height: 16),
              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              if (_result.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Result:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
