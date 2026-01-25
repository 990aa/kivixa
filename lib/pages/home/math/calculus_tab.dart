import 'package:flutter/material.dart';

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
    setState(() => _isComputing = true);

    // TODO: Call Rust backend
    // final result = await api.differentiate(
    //   _expressionCtrl.text,
    //   _variableCtrl.text,
    //   double.parse(_pointCtrl.text),
    //   _order,
    // );

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _result = 'f\'(${_pointCtrl.text}) = 5.0 (placeholder)';
      _isComputing = false;
    });
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
            style: Theme.of(context).textTheme.titleMedium,
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
              const Text('Derivative order: '),
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
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: const TextStyle(fontSize: 20, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

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
    setState(() => _isComputing = true);

    // TODO: Call Rust backend
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _result = '∫ x² dx from 0 to 1 = 0.3333... (placeholder)';
      _isComputing = false;
    });
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., x^2, sin(x), exp(-x^2)',
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
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _LimitCalculator extends StatefulWidget {
  const _LimitCalculator();

  @override
  State<_LimitCalculator> createState() => _LimitCalculatorState();
}

class _LimitCalculatorState extends State<_LimitCalculator> {
  final _expressionCtrl = TextEditingController(text: 'sin(x)/x');
  final _variableCtrl = TextEditingController(text: 'x');
  final _approachCtrl = TextEditingController(text: '0');
  var _fromLeft = true;
  var _fromRight = true;
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
    setState(() => _isComputing = true);

    // TODO: Call Rust backend
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _result = 'lim(x→0) sin(x)/x = 1.0 (placeholder)';
      _isComputing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Numerical Limits',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., sin(x)/x, (1+1/x)^x',
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

          Row(
            children: [
              FilterChip(
                label: const Text('From left (x⁻)'),
                selected: _fromLeft,
                onSelected: (v) => setState(() => _fromLeft = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('From right (x⁺)'),
                selected: _fromRight,
                onSelected: (v) => setState(() => _fromRight = v),
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
              label: const Text('Compute Limit'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _SeriesCalculator extends StatefulWidget {
  const _SeriesCalculator();

  @override
  State<_SeriesCalculator> createState() => _SeriesCalculatorState();
}

class _SeriesCalculatorState extends State<_SeriesCalculator> {
  final _expressionCtrl = TextEditingController(text: 'exp(x)');
  final _variableCtrl = TextEditingController(text: 'x');
  final _aroundCtrl = TextEditingController(text: '0');
  var _numTerms = 5;
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _variableCtrl.dispose();
    _aroundCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend for Taylor series
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _result =
          'Taylor series: 1 + x + x²/2 + x³/6 + x⁴/24 + ... (placeholder)';
      _isComputing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Taylor Series Expansion',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _expressionCtrl,
            decoration: const InputDecoration(
              labelText: 'f(x)',
              hintText: 'e.g., exp(x), sin(x), 1/(1-x)',
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
                  controller: _aroundCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Around point',
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
              const Text('Number of terms: '),
              Slider(
                value: _numTerms.toDouble(),
                min: 2,
                max: 20,
                divisions: 18,
                label: '$_numTerms',
                onChanged: (v) => setState(() => _numTerms = v.round()),
              ),
              Text('$_numTerms'),
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
              label: const Text('Expand'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}
