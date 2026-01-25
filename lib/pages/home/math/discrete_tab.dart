import 'package:flutter/material.dart';

/// Discrete Math tab - Number theory, combinatorics, sequences
class MathDiscreteTab extends StatefulWidget {
  const MathDiscreteTab({super.key});

  @override
  State<MathDiscreteTab> createState() => _MathDiscreteTabState();
}

class _MathDiscreteTabState extends State<MathDiscreteTab>
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
            Tab(text: 'Primes'),
            Tab(text: 'Factors'),
            Tab(text: 'Combinatorics'),
            Tab(text: 'Sequences'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _PrimeCalculator(),
              _FactorCalculator(),
              _CombinatoricsCalculator(),
              _SequenceCalculator(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimeCalculator extends StatefulWidget {
  const _PrimeCalculator();

  @override
  State<_PrimeCalculator> createState() => _PrimeCalculatorState();
}

class _PrimeCalculatorState extends State<_PrimeCalculator> {
  final _numberCtrl = TextEditingController(text: '97');
  final _sieveUpToCtrl = TextEditingController(text: '100');
  String _primeCheckResult = '';
  List<int> _sieveResult = [];
  bool _isChecking = false;
  bool _isSieving = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _sieveUpToCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPrime() async {
    setState(() => _isChecking = true);

    // TODO: Call Rust backend api.is_prime
    final n = int.tryParse(_numberCtrl.text) ?? 0;
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _primeCheckResult = '$n is ${n.isPrime ? "" : "NOT "}prime (placeholder)';
      _isChecking = false;
    });
  }

  Future<void> _sieve() async {
    setState(() => _isSieving = true);

    // TODO: Call Rust backend api.sieve_of_eratosthenes
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _sieveResult = [
        2,
        3,
        5,
        7,
        11,
        13,
        17,
        19,
        23,
        29,
        31,
        37,
        41,
        43,
        47,
        53,
        59,
        61,
        67,
        71,
        73,
        79,
        83,
        89,
        97,
      ];
      _isSieving = false;
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
            'Prime Number Checker',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isChecking ? null : _checkPrime,
                child: _isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_primeCheckResult.isNotEmpty)
            Text(
              _primeCheckResult,
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),

          const Divider(height: 32),

          Text(
            'Sieve of Eratosthenes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sieveUpToCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Find primes up to',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isSieving ? null : _sieve,
                child: _isSieving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_sieveResult.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sieveResult.map((p) {
                  return Chip(
                    label: Text('$p'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

extension on int {
  bool get isPrime {
    if (this < 2) return false;
    if (this == 2) return true;
    if (this % 2 == 0) return false;
    for (var i = 3; i * i <= this; i += 2) {
      if (this % i == 0) return false;
    }
    return true;
  }
}

class _FactorCalculator extends StatefulWidget {
  const _FactorCalculator();

  @override
  State<_FactorCalculator> createState() => _FactorCalculatorState();
}

class _FactorCalculatorState extends State<_FactorCalculator> {
  final _numberCtrl = TextEditingController(text: '360');
  final _aCtrl = TextEditingController(text: '48');
  final _bCtrl = TextEditingController(text: '18');
  String _primeFactors = '';
  String _gcdLcmResult = '';
  bool _isFactoring = false;
  bool _isComputingGcdLcm = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  Future<void> _factor() async {
    setState(() => _isFactoring = true);

    // TODO: Call Rust backend api.prime_factors
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() {
      _primeFactors = '360 = 2³ × 3² × 5 (placeholder)';
      _isFactoring = false;
    });
  }

  Future<void> _computeGcdLcm() async {
    setState(() => _isComputingGcdLcm = true);

    // TODO: Call Rust backend api.gcd and api.lcm
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _gcdLcmResult = 'GCD(48, 18) = 6\nLCM(48, 18) = 144 (placeholder)';
      _isComputingGcdLcm = false;
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
            'Prime Factorization',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isFactoring ? null : _factor,
                child: _isFactoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Factor'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_primeFactors.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _primeFactors,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
              ),
            ),

          const Divider(height: 32),

          Text('GCD & LCM', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aCtrl,
                  decoration: const InputDecoration(
                    labelText: 'a',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _bCtrl,
                  decoration: const InputDecoration(
                    labelText: 'b',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isComputingGcdLcm ? null : _computeGcdLcm,
                child: _isComputingGcdLcm
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Compute'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_gcdLcmResult.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _gcdLcmResult,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CombinatoricsCalculator extends StatefulWidget {
  const _CombinatoricsCalculator();

  @override
  State<_CombinatoricsCalculator> createState() =>
      _CombinatoricsCalculatorState();
}

class _CombinatoricsCalculatorState extends State<_CombinatoricsCalculator> {
  final _nCtrl = TextEditingController(text: '10');
  final _rCtrl = TextEditingController(text: '3');
  final _factorialCtrl = TextEditingController(text: '10');
  String _result = '';
  String _factorialResult = '';
  bool _isComputing = false;
  bool _isComputingFactorial = false;

  @override
  void dispose() {
    _nCtrl.dispose();
    _rCtrl.dispose();
    _factorialCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend api.combinations and api.permutations
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _result = 'C(10,3) = 120\nP(10,3) = 720 (placeholder)';
      _isComputing = false;
    });
  }

  Future<void> _computeFactorial() async {
    setState(() => _isComputingFactorial = true);

    // TODO: Call Rust backend api.factorial
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _factorialResult = '10! = 3,628,800 (placeholder)';
      _isComputingFactorial = false;
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
            'Combinations & Permutations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nCtrl,
                  decoration: const InputDecoration(
                    labelText: 'n (total items)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _rCtrl,
                  decoration: const InputDecoration(
                    labelText: 'r (choose)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isComputing ? null : _compute,
                child: _isComputing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Compute'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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

          const Divider(height: 32),

          Text('Factorial', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _factorialCtrl,
                  decoration: const InputDecoration(
                    labelText: 'n',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isComputingFactorial ? null : _computeFactorial,
                child: _isComputingFactorial
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('n!'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_factorialResult.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _factorialResult,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SequenceCalculator extends StatefulWidget {
  const _SequenceCalculator();

  @override
  State<_SequenceCalculator> createState() => _SequenceCalculatorState();
}

class _SequenceCalculatorState extends State<_SequenceCalculator> {
  String _sequence = 'fibonacci';
  final _nCtrl = TextEditingController(text: '20');
  List<String> _result = [];
  bool _isComputing = false;

  @override
  void dispose() {
    _nCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend for sequences
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      if (_sequence == 'fibonacci') {
        _result = [
          '0',
          '1',
          '1',
          '2',
          '3',
          '5',
          '8',
          '13',
          '21',
          '34',
          '55',
          '89',
          '144',
          '233',
          '377',
          '610',
          '987',
          '1597',
          '2584',
          '4181',
        ];
      } else if (_sequence == 'catalan') {
        _result = [
          '1',
          '1',
          '2',
          '5',
          '14',
          '42',
          '132',
          '429',
          '1430',
          '4862',
        ];
      } else if (_sequence == 'bell') {
        _result = [
          '1',
          '1',
          '2',
          '5',
          '15',
          '52',
          '203',
          '877',
          '4140',
          '21147',
        ];
      } else if (_sequence == 'euler_totient') {
        _result = List.generate(20, (i) => '${i + 1}: φ(${i + 1})');
      }
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
            'Number Sequences',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _sequence,
            decoration: const InputDecoration(
              labelText: 'Sequence',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'fibonacci', child: Text('Fibonacci')),
              DropdownMenuItem(
                value: 'catalan',
                child: Text('Catalan Numbers'),
              ),
              DropdownMenuItem(value: 'bell', child: Text('Bell Numbers')),
              DropdownMenuItem(
                value: 'euler_totient',
                child: Text('Euler\'s Totient'),
              ),
            ],
            onChanged: (v) => setState(() => _sequence = v ?? 'fibonacci'),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Number of terms',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isComputing ? null : _generate,
                child: _isComputing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _result.asMap().entries.map((e) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Text(
                        '${e.key}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    label: Text(e.value),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
