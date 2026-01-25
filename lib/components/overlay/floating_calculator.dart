import 'package:flutter/material.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// Floating calculator widget that shows in the overlay.
/// Supports basic operations: +, -, *, /, %, and exponent (^).
class FloatingCalculatorWindow extends StatefulWidget {
  const FloatingCalculatorWindow({super.key});

  @override
  State<FloatingCalculatorWindow> createState() =>
      _FloatingCalculatorWindowState();
}

class _FloatingCalculatorWindowState extends State<FloatingCalculatorWindow> {
  var _display = '0';
  var _expression = '';
  double? _firstOperand;
  String? _operator;
  var _shouldReset = false;

  void _onDigitPressed(String digit) {
    setState(() {
      if (_shouldReset) {
        _display = digit;
        _shouldReset = false;
      } else if (_display == '0' && digit != '.') {
        _display = digit;
      } else if (digit == '.' && _display.contains('.')) {
        // Don't add another decimal point
        return;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperatorPressed(String op) {
    setState(() {
      if (_firstOperand != null && _operator != null && !_shouldReset) {
        // Perform chained calculation
        _calculate();
      }
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '$_display $op';
      _shouldReset = true;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;

    final secondOperand = double.tryParse(_display);
    if (secondOperand == null) return;

    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
      case '-':
        result = _firstOperand! - secondOperand;
      case '×':
        result = _firstOperand! * secondOperand;
      case '÷':
        if (secondOperand == 0) {
          setState(() {
            _display = 'Error';
            _expression = '';
            _firstOperand = null;
            _operator = null;
            _shouldReset = true;
          });
          return;
        }
        result = _firstOperand! / secondOperand;
      case '%':
        if (secondOperand == 0) {
          setState(() {
            _display = 'Error';
            _expression = '';
            _firstOperand = null;
            _operator = null;
            _shouldReset = true;
          });
          return;
        }
        result = _firstOperand! % secondOperand;
      case '^':
        result = _pow(_firstOperand!, secondOperand);
      default:
        return;
    }

    setState(() {
      // Format result to remove unnecessary decimal places
      if (result == result.toInt()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _expression = '';
      _firstOperand = result;
      _operator = null;
      _shouldReset = true;
    });
  }

  double _pow(double base, double exponent) {
    // Handle integer exponents for better precision
    if (exponent == exponent.toInt() && exponent >= 0) {
      double result = 1;
      for (int i = 0; i < exponent.toInt(); i++) {
        result *= base;
      }
      return result;
    }
    // Use dart:math for non-integer exponents
    return _power(base, exponent);
  }

  double _power(double base, double exponent) {
    if (base == 0) return 0;
    if (exponent == 0) return 1;
    if (exponent == 1) return base;

    // Use logarithms for fractional exponents
    if (base > 0) {
      return _exp(exponent * _ln(base));
    }
    // Negative base with non-integer exponent results in NaN
    return double.nan;
  }

  // Natural logarithm approximation
  double _ln(double x) {
    if (x <= 0) return double.nan;
    double result = 0;
    final double term = (x - 1) / (x + 1);
    final double termSquared = term * term;
    double currentTerm = term;
    for (int n = 1; n <= 100; n += 2) {
      result += currentTerm / n;
      currentTerm *= termSquared;
    }
    return 2 * result;
  }

  // Exponential function approximation
  double _exp(double x) {
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 100; n++) {
      term *= x / n;
      result += term;
      if (term.abs() < 1e-15) break;
    }
    return result;
  }

  void _onEqualsPressed() {
    _calculate();
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldReset = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onPercentValue() {
    // Convert current value to percentage (divide by 100)
    final value = double.tryParse(_display);
    if (value == null) return;

    setState(() {
      final result = value / 100;
      if (result == result.toInt()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _shouldReset = true;
    });
  }

  void _onNegate() {
    setState(() {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else if (_display != '0') {
        _display = '-$_display';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;
    final rect =
        controller.getToolWindowRect('calculator') ??
        const Rect.fromLTWH(100, 100, 320, 480);

    return FloatingWindow(
      rect: rect,
      onRectChanged: (newRect) =>
          controller.updateToolWindowRect('calculator', newRect),
      onClose: () => controller.closeToolWindow('calculator'),
      title: 'Calculator',
      icon: Icons.calculate,
      minWidth: 280,
      minHeight: 400,
      child: _CalculatorContent(
        display: _display,
        expression: _expression,
        onDigitPressed: _onDigitPressed,
        onOperatorPressed: _onOperatorPressed,
        onEqualsPressed: _onEqualsPressed,
        onClearPressed: _onClearPressed,
        onBackspacePressed: _onBackspacePressed,
        onPercentValue: _onPercentValue,
        onNegate: _onNegate,
      ),
    );
  }
}

class _CalculatorContent extends StatelessWidget {
  const _CalculatorContent({
    required this.display,
    required this.expression,
    required this.onDigitPressed,
    required this.onOperatorPressed,
    required this.onEqualsPressed,
    required this.onClearPressed,
    required this.onBackspacePressed,
    required this.onPercentValue,
    required this.onNegate,
  });

  final String display;
  final String expression;
  final void Function(String) onDigitPressed;
  final void Function(String) onOperatorPressed;
  final VoidCallback onEqualsPressed;
  final VoidCallback onClearPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onPercentValue;
  final VoidCallback onNegate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Display area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Expression
              Text(
                expression,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              // Current value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Calculator buttons
        Expanded(
          child: _CalculatorKeypad(
            onDigitPressed: onDigitPressed,
            onOperatorPressed: onOperatorPressed,
            onEqualsPressed: onEqualsPressed,
            onClearPressed: onClearPressed,
            onBackspacePressed: onBackspacePressed,
            onPercentValue: onPercentValue,
            onNegate: onNegate,
          ),
        ),
      ],
    );
  }
}

class _CalculatorKeypad extends StatelessWidget {
  const _CalculatorKeypad({
    required this.onDigitPressed,
    required this.onOperatorPressed,
    required this.onEqualsPressed,
    required this.onClearPressed,
    required this.onBackspacePressed,
    required this.onPercentValue,
    required this.onNegate,
  });

  final void Function(String) onDigitPressed;
  final void Function(String) onOperatorPressed;
  final VoidCallback onEqualsPressed;
  final VoidCallback onClearPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onPercentValue;
  final VoidCallback onNegate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Row 1: C, ⌫, %, ÷
        Expanded(
          child: Row(
            children: [
              _CalcButton(
                label: 'C',
                onPressed: onClearPressed,
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
              _CalcButton(
                label: '⌫',
                onPressed: onBackspacePressed,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              _CalcButton(
                label: '%',
                onPressed: onPercentValue,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              _CalcButton(
                label: '÷',
                onPressed: () => onOperatorPressed('÷'),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
        // Row 2: 7, 8, 9, ×
        Expanded(
          child: Row(
            children: [
              _CalcButton(label: '7', onPressed: () => onDigitPressed('7')),
              _CalcButton(label: '8', onPressed: () => onDigitPressed('8')),
              _CalcButton(label: '9', onPressed: () => onDigitPressed('9')),
              _CalcButton(
                label: '×',
                onPressed: () => onOperatorPressed('×'),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
        // Row 3: 4, 5, 6, -
        Expanded(
          child: Row(
            children: [
              _CalcButton(label: '4', onPressed: () => onDigitPressed('4')),
              _CalcButton(label: '5', onPressed: () => onDigitPressed('5')),
              _CalcButton(label: '6', onPressed: () => onDigitPressed('6')),
              _CalcButton(
                label: '-',
                onPressed: () => onOperatorPressed('-'),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
        // Row 4: 1, 2, 3, +
        Expanded(
          child: Row(
            children: [
              _CalcButton(label: '1', onPressed: () => onDigitPressed('1')),
              _CalcButton(label: '2', onPressed: () => onDigitPressed('2')),
              _CalcButton(label: '3', onPressed: () => onDigitPressed('3')),
              _CalcButton(
                label: '+',
                onPressed: () => onOperatorPressed('+'),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
        // Row 5: ±, 0, ., =
        Expanded(
          child: Row(
            children: [
              _CalcButton(
                label: '±',
                onPressed: onNegate,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              _CalcButton(label: '0', onPressed: () => onDigitPressed('0')),
              _CalcButton(label: '.', onPressed: () => onDigitPressed('.')),
              _CalcButton(
                label: '=',
                onPressed: onEqualsPressed,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ],
          ),
        ),
        // Row 6: mod, ^, (extra operations)
        Expanded(
          child: Row(
            children: [
              _CalcButton(
                label: 'mod',
                onPressed: () => onOperatorPressed('%'),
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                fontSize: 14,
              ),
              _CalcButton(
                label: 'xʸ',
                onPressed: () => onOperatorPressed('^'),
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: backgroundColor ?? colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize ?? 24,
                  fontWeight: FontWeight.w500,
                  color: foregroundColor ?? colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
