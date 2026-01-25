import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// General tab - Scientific Calculator
/// Features: Expression evaluation, number system conversion, constants
class MathGeneralTab extends StatefulWidget {
  const MathGeneralTab({super.key});

  @override
  State<MathGeneralTab> createState() => _MathGeneralTabState();
}

class _MathGeneralTabState extends State<MathGeneralTab> {
  final _expressionController = TextEditingController();
  final _focusNode = FocusNode();
  String _result = '';
  String _error = '';
  bool _isComputing = false;
  int _selectedBase = 10; // Decimal by default
  bool _showScientific = true;

  // History of calculations
  final List<_CalculationEntry> _history = [];

  @override
  void dispose() {
    _expressionController.dispose();
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
      // TODO: Call Rust backend when FRB is generated
      // final result = await api.evaluateExpression(expression);

      // Placeholder calculation for demo
      final result = _placeholderEvaluate(expression);

      setState(() {
        _result = result;
        _isComputing = false;
        _history.insert(
          0,
          _CalculationEntry(
            expression: expression,
            result: result,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _result = '';
        _isComputing = false;
      });
    }
  }

  String _placeholderEvaluate(String expr) {
    // Basic placeholder - will be replaced by Rust backend
    try {
      // Very simple evaluation for demo
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
      expr = expr.replaceAll('π', '3.14159265359');
      expr = expr.replaceAll('e', '2.71828182846');

      // This is a placeholder - real evaluation happens in Rust
      return '= (Rust backend not yet connected)';
    } catch (e) {
      return 'Error: $e';
    }
  }

  void _insertText(String text) {
    final currentText = _expressionController.text;
    final selection = _expressionController.selection;
    final newText =
        currentText.substring(0, selection.start) +
        text +
        currentText.substring(selection.end);
    _expressionController.text = newText;
    _expressionController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
    _focusNode.requestFocus();
  }

  void _clear() {
    _expressionController.clear();
    setState(() {
      _result = '';
      _error = '';
    });
    _focusNode.requestFocus();
  }

  void _backspace() {
    final currentText = _expressionController.text;
    if (currentText.isNotEmpty) {
      _expressionController.text = currentText.substring(
        0,
        currentText.length - 1,
      );
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 800;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildCalculator(colorScheme)),
                const SizedBox(width: 16),
                Expanded(child: _buildSidebar(colorScheme)),
              ],
            )
          : SingleChildScrollView(child: _buildCalculator(colorScheme)),
    );
  }

  Widget _buildCalculator(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Display
        _buildDisplay(colorScheme),
        const SizedBox(height: 16),

        // Mode toggles
        _buildModeToggles(colorScheme),
        const SizedBox(height: 16),

        // Keypad
        _buildKeypad(colorScheme),
      ],
    );
  }

  Widget _buildDisplay(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expression input
          TextField(
            controller: _expressionController,
            focusNode: _focusNode,
            style: TextStyle(
              fontSize: 24,
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
            ),
            maxLines: 2,
            minLines: 1,
            onSubmitted: (_) => _evaluate(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9+\-*/^().,%!eπ√sincotaglb\s]'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Result display
          if (_isComputing)
            const LinearProgressIndicator()
          else if (_error.isNotEmpty)
            Text(
              _error,
              style: TextStyle(color: colorScheme.error, fontSize: 16),
            )
          else if (_result.isNotEmpty)
            SelectableText(
              _result,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggles(ColorScheme colorScheme) {
    return Row(
      children: [
        // Number base selector
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('BIN')),
            ButtonSegment(value: 8, label: Text('OCT')),
            ButtonSegment(value: 10, label: Text('DEC')),
            ButtonSegment(value: 16, label: Text('HEX')),
          ],
          selected: {_selectedBase},
          onSelectionChanged: (set) {
            setState(() => _selectedBase = set.first);
          },
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const Spacer(),
        // Scientific mode toggle
        FilterChip(
          label: const Text('Scientific'),
          selected: _showScientific,
          onSelected: (v) => setState(() => _showScientific = v),
        ),
      ],
    );
  }

  Widget _buildKeypad(ColorScheme colorScheme) {
    final buttons = _showScientific ? _scientificButtons : _basicButtons;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _showScientific ? 5 : 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final btn = buttons[index];
        return _CalcButton(
          label: btn.label,
          color: btn.color?.call(colorScheme),
          textColor: btn.textColor?.call(colorScheme),
          onPressed: () => btn.action(this),
        );
      },
    );
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Constants section
        Text('Constants', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ConstantChip(
              label: 'π',
              value: 'π',
              onTap: () => _insertText('π'),
            ),
            _ConstantChip(
              label: 'e',
              value: 'e',
              onTap: () => _insertText('e'),
            ),
            _ConstantChip(
              label: 'φ',
              value: '1.618',
              onTap: () => _insertText('1.6180339887'),
            ),
            _ConstantChip(
              label: '√2',
              value: '1.414',
              onTap: () => _insertText('1.4142135624'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent calculations
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final entry = _history[index];
              return ListTile(
                dense: true,
                title: Text(
                  entry.expression,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  entry.result,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                onTap: () {
                  _expressionController.text = entry.expression;
                  _focusNode.requestFocus();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Button definitions
  static final _basicButtons = <_ButtonDef>[
    _ButtonDef('C', action: (s) => s._clear(), color: (c) => c.errorContainer),
    _ButtonDef('(', action: (s) => s._insertText('(')),
    _ButtonDef(')', action: (s) => s._insertText(')')),
    _ButtonDef(
      '÷',
      action: (s) => s._insertText('/'),
      color: (c) => c.primaryContainer,
    ),
    _ButtonDef('7', action: (s) => s._insertText('7')),
    _ButtonDef('8', action: (s) => s._insertText('8')),
    _ButtonDef('9', action: (s) => s._insertText('9')),
    _ButtonDef(
      '×',
      action: (s) => s._insertText('*'),
      color: (c) => c.primaryContainer,
    ),
    _ButtonDef('4', action: (s) => s._insertText('4')),
    _ButtonDef('5', action: (s) => s._insertText('5')),
    _ButtonDef('6', action: (s) => s._insertText('6')),
    _ButtonDef(
      '-',
      action: (s) => s._insertText('-'),
      color: (c) => c.primaryContainer,
    ),
    _ButtonDef('1', action: (s) => s._insertText('1')),
    _ButtonDef('2', action: (s) => s._insertText('2')),
    _ButtonDef('3', action: (s) => s._insertText('3')),
    _ButtonDef(
      '+',
      action: (s) => s._insertText('+'),
      color: (c) => c.primaryContainer,
    ),
    _ButtonDef('±', action: (s) => s._insertText('-')),
    _ButtonDef('0', action: (s) => s._insertText('0')),
    _ButtonDef('.', action: (s) => s._insertText('.')),
    _ButtonDef(
      '=',
      action: (s) => s._evaluate(),
      color: (c) => c.primary,
      textColor: (c) => c.onPrimary,
    ),
  ];

  static final _scientificButtons = <_ButtonDef>[
    _ButtonDef('C', action: (s) => s._clear(), color: (c) => c.errorContainer),
    _ButtonDef('(', action: (s) => s._insertText('(')),
    _ButtonDef(')', action: (s) => s._insertText(')')),
    _ButtonDef('⌫', action: (s) => s._backspace()),
    _ButtonDef(
      '÷',
      action: (s) => s._insertText('/'),
      color: (c) => c.primaryContainer,
    ),

    _ButtonDef('sin', action: (s) => s._insertText('sin(')),
    _ButtonDef('cos', action: (s) => s._insertText('cos(')),
    _ButtonDef('tan', action: (s) => s._insertText('tan(')),
    _ButtonDef('^', action: (s) => s._insertText('^')),
    _ButtonDef(
      '×',
      action: (s) => s._insertText('*'),
      color: (c) => c.primaryContainer,
    ),

    _ButtonDef('ln', action: (s) => s._insertText('ln(')),
    _ButtonDef('log', action: (s) => s._insertText('log(')),
    _ButtonDef('√', action: (s) => s._insertText('sqrt(')),
    _ButtonDef('x²', action: (s) => s._insertText('^2')),
    _ButtonDef(
      '-',
      action: (s) => s._insertText('-'),
      color: (c) => c.primaryContainer,
    ),

    _ButtonDef('7', action: (s) => s._insertText('7')),
    _ButtonDef('8', action: (s) => s._insertText('8')),
    _ButtonDef('9', action: (s) => s._insertText('9')),
    _ButtonDef('π', action: (s) => s._insertText('π')),
    _ButtonDef(
      '+',
      action: (s) => s._insertText('+'),
      color: (c) => c.primaryContainer,
    ),

    _ButtonDef('4', action: (s) => s._insertText('4')),
    _ButtonDef('5', action: (s) => s._insertText('5')),
    _ButtonDef('6', action: (s) => s._insertText('6')),
    _ButtonDef('e', action: (s) => s._insertText('e')),
    _ButtonDef('%', action: (s) => s._insertText('%')),

    _ButtonDef('1', action: (s) => s._insertText('1')),
    _ButtonDef('2', action: (s) => s._insertText('2')),
    _ButtonDef('3', action: (s) => s._insertText('3')),
    _ButtonDef('!', action: (s) => s._insertText('!')),
    _ButtonDef('|x|', action: (s) => s._insertText('abs(')),

    _ButtonDef('±', action: (s) => s._insertText('-')),
    _ButtonDef('0', action: (s) => s._insertText('0')),
    _ButtonDef('.', action: (s) => s._insertText('.')),
    _ButtonDef(',', action: (s) => s._insertText(',')),
    _ButtonDef(
      '=',
      action: (s) => s._evaluate(),
      color: (c) => c.primary,
      textColor: (c) => c.onPrimary,
    ),
  ];
}

class _ButtonDef {
  final String label;
  final void Function(_MathGeneralTabState) action;
  final Color? Function(ColorScheme)? color;
  final Color? Function(ColorScheme)? textColor;

  const _ButtonDef(
    this.label, {
    required this.action,
    this.color,
    this.textColor,
  });
}

class _CalcButton extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final VoidCallback onPressed;

  const _CalcButton({
    required this.label,
    this.color,
    this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ConstantChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ConstantChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap, tooltip: value);
  }
}

class _CalculationEntry {
  final String expression;
  final String result;
  final DateTime timestamp;

  _CalculationEntry({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}
