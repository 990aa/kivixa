import 'dart:math' as math;

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

String _formatBigInt(BigInt n) {
  final str = n.toString();
  if (str.length <= 15) {
    // Add thousand separators
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0 && str[0] != '-')
        buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
  // Scientific notation for very large numbers
  final exp = str.length - 1;
  return '${str[0]}.${str.substring(1, math.min(6, str.length))}e$exp';
}

// ============================================================================
// PRIME CALCULATOR
// ============================================================================

class _PrimeCalculator extends StatefulWidget {
  const _PrimeCalculator();

  @override
  State<_PrimeCalculator> createState() => _PrimeCalculatorState();
}

class _PrimeCalculatorState extends State<_PrimeCalculator> {
  final _numberCtrl = TextEditingController(text: '97');
  final _sieveUpToCtrl = TextEditingController(text: '100');
  var _primeCheckResult = '';
  List<int> _sieveResult = [];
  var _isChecking = false;
  var _isSieving = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _sieveUpToCtrl.dispose();
    super.dispose();
  }

  bool _isPrime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    for (var i = 3; i * i <= n; i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }

  Future<void> _checkPrime() async {
    setState(() {
      _isChecking = true;
      _primeCheckResult = '';
    });

    try {
      final n = int.parse(_numberCtrl.text);
      final isPrime = _isPrime(n);

      String additionalInfo = '';
      if (!isPrime && n > 1) {
        // Find smallest factor
        var factor = 2;
        while (n % factor != 0) factor++;
        additionalInfo = '\nSmallest factor: $factor';
      }

      setState(() {
        _primeCheckResult =
            '$n is ${isPrime ? "" : "NOT "}a prime number$additionalInfo';
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _primeCheckResult = 'Error: Invalid number';
        _isChecking = false;
      });
    }
  }

  Future<void> _sieve() async {
    setState(() {
      _isSieving = true;
      _sieveResult = [];
    });

    try {
      final limit = int.parse(_sieveUpToCtrl.text);
      if (limit < 2) {
        setState(() {
          _sieveResult = [];
          _isSieving = false;
        });
        return;
      }
      if (limit > 100000) {
        setState(() {
          _primeCheckResult = 'Error: Limit too large (max 100,000)';
          _isSieving = false;
        });
        return;
      }

      // Sieve of Eratosthenes
      final sieve = List.filled(limit + 1, true);
      sieve[0] = false;
      sieve[1] = false;

      for (var i = 2; i * i <= limit; i++) {
        if (sieve[i]) {
          for (var j = i * i; j <= limit; j += i) {
            sieve[j] = false;
          }
        }
      }

      final primes = <int>[];
      for (var i = 2; i <= limit; i++) {
        if (sieve[i]) primes.add(i);
      }

      setState(() {
        _sieveResult = primes;
        _isSieving = false;
      });
    } catch (e) {
      setState(() {
        _primeCheckResult = 'Error: Invalid number';
        _isSieving = false;
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
                _primeCheckResult,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
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

          if (_sieveResult.isNotEmpty) ...[
            Text(
              'Found ${_sieveResult.length} primes:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sieveResult
                      .map(
                        (p) => Chip(
                          label: Text('$p'),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// FACTOR CALCULATOR
// ============================================================================

class _FactorCalculator extends StatefulWidget {
  const _FactorCalculator();

  @override
  State<_FactorCalculator> createState() => _FactorCalculatorState();
}

class _FactorCalculatorState extends State<_FactorCalculator> {
  final _numberCtrl = TextEditingController(text: '360');
  final _aCtrl = TextEditingController(text: '48');
  final _bCtrl = TextEditingController(text: '18');
  var _primeFactors = '';
  var _gcdLcmResult = '';
  var _isFactoring = false;
  var _isComputingGcdLcm = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  Future<void> _factor() async {
    setState(() {
      _isFactoring = true;
      _primeFactors = '';
    });

    try {
      var n = int.parse(_numberCtrl.text);
      if (n <= 1) {
        setState(() {
          _primeFactors = n <= 0
              ? 'Error: Must be positive'
              : '1 has no prime factors';
          _isFactoring = false;
        });
        return;
      }

      final original = n;
      final factors = <int, int>{};

      // Find factors of 2
      while (n % 2 == 0) {
        factors[2] = (factors[2] ?? 0) + 1;
        n ~/= 2;
      }

      // Find odd factors
      for (var i = 3; i * i <= n; i += 2) {
        while (n % i == 0) {
          factors[i] = (factors[i] ?? 0) + 1;
          n ~/= i;
        }
      }

      // If n is still > 1, then it's a prime factor
      if (n > 1) {
        factors[n] = (factors[n] ?? 0) + 1;
      }

      // Format output
      final factorStrings = factors.entries.map((e) {
        final base = e.key;
        final exp = e.value;
        if (exp == 1) return '$base';
        return '$base${_superscript(exp)}';
      }).toList();

      setState(() {
        _primeFactors = '$original = ${factorStrings.join(' × ')}';
        _isFactoring = false;
      });
    } catch (e) {
      setState(() {
        _primeFactors = 'Error: Invalid number';
        _isFactoring = false;
      });
    }
  }

  String _superscript(int n) {
    const superscripts = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
    return n.toString().split('').map((d) => superscripts[int.parse(d)]).join();
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  Future<void> _computeGcdLcm() async {
    setState(() {
      _isComputingGcdLcm = true;
      _gcdLcmResult = '';
    });

    try {
      final a = int.parse(_aCtrl.text).abs();
      final b = int.parse(_bCtrl.text).abs();

      if (a == 0 && b == 0) {
        setState(() {
          _gcdLcmResult = 'GCD(0, 0) is undefined\nLCM(0, 0) is undefined';
          _isComputingGcdLcm = false;
        });
        return;
      }

      final gcd = _gcd(a, b);
      final lcm = a == 0 || b == 0 ? 0 : (a * b) ~/ gcd;

      setState(() {
        _gcdLcmResult = 'GCD($a, $b) = $gcd\nLCM($a, $b) = $lcm';
        _isComputingGcdLcm = false;
      });
    } catch (e) {
      setState(() {
        _gcdLcmResult = 'Error: Invalid numbers';
        _isComputingGcdLcm = false;
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

// ============================================================================
// COMBINATORICS CALCULATOR
// ============================================================================

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
  var _result = '';
  var _factorialResult = '';
  var _isComputing = false;
  var _isComputingFactorial = false;

  @override
  void dispose() {
    _nCtrl.dispose();
    _rCtrl.dispose();
    _factorialCtrl.dispose();
    super.dispose();
  }

  BigInt _factorial(int n) {
    if (n <= 1) return BigInt.one;
    var result = BigInt.one;
    for (var i = 2; i <= n; i++) {
      result *= BigInt.from(i);
    }
    return result;
  }

  BigInt _combination(int n, int r) {
    if (r > n) return BigInt.zero;
    if (r == 0 || r == n) return BigInt.one;
    // C(n,r) = n! / (r! * (n-r)!)
    // Optimized: C(n,r) = product(n-r+1 to n) / r!
    r = math.min(r, n - r);
    var result = BigInt.one;
    for (var i = 0; i < r; i++) {
      result = result * BigInt.from(n - i) ~/ BigInt.from(i + 1);
    }
    return result;
  }

  BigInt _permutation(int n, int r) {
    if (r > n) return BigInt.zero;
    // P(n,r) = n! / (n-r)!
    var result = BigInt.one;
    for (var i = n - r + 1; i <= n; i++) {
      result *= BigInt.from(i);
    }
    return result;
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final n = int.parse(_nCtrl.text);
      final r = int.parse(_rCtrl.text);

      if (n < 0 || r < 0) {
        setState(() {
          _result = 'Error: n and r must be non-negative';
          _isComputing = false;
        });
        return;
      }
      if (n > 1000) {
        setState(() {
          _result = 'Error: n too large (max 1000)';
          _isComputing = false;
        });
        return;
      }

      final comb = _combination(n, r);
      final perm = _permutation(n, r);

      setState(() {
        _result =
            'C($n,$r) = ${_formatBigInt(comb)}\nP($n,$r) = ${_formatBigInt(perm)}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: Invalid numbers';
        _isComputing = false;
      });
    }
  }

  Future<void> _computeFactorial() async {
    setState(() {
      _isComputingFactorial = true;
      _factorialResult = '';
    });

    try {
      final n = int.parse(_factorialCtrl.text);

      if (n < 0) {
        setState(() {
          _factorialResult = 'Error: n must be non-negative';
          _isComputingFactorial = false;
        });
        return;
      }
      if (n > 1000) {
        setState(() {
          _factorialResult = 'Error: n too large (max 1000)';
          _isComputingFactorial = false;
        });
        return;
      }

      final fact = _factorial(n);

      setState(() {
        _factorialResult = '$n! = ${_formatBigInt(fact)}';
        _isComputingFactorial = false;
      });
    } catch (e) {
      setState(() {
        _factorialResult = 'Error: Invalid number';
        _isComputingFactorial = false;
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
                color: _factorialResult.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _factorialResult,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEQUENCE CALCULATOR
// ============================================================================

class _SequenceCalculator extends StatefulWidget {
  const _SequenceCalculator();

  @override
  State<_SequenceCalculator> createState() => _SequenceCalculatorState();
}

class _SequenceCalculatorState extends State<_SequenceCalculator> {
  var _sequence = 'fibonacci';
  final _nCtrl = TextEditingController(text: '20');
  List<String> _result = [];
  var _isComputing = false;
  var _error = '';

  @override
  void dispose() {
    _nCtrl.dispose();
    super.dispose();
  }

  List<BigInt> _fibonacci(int n) {
    if (n <= 0) return [];
    if (n == 1) return [BigInt.zero];
    final seq = <BigInt>[BigInt.zero, BigInt.one];
    for (var i = 2; i < n; i++) {
      seq.add(seq[i - 1] + seq[i - 2]);
    }
    return seq;
  }

  List<BigInt> _catalan(int n) {
    if (n <= 0) return [];
    // C(n) = C(2n, n) / (n + 1)
    final seq = <BigInt>[BigInt.one];
    for (var i = 1; i < n; i++) {
      // C(i) = C(i-1) * 2*(2*i - 1) / (i + 1)
      seq.add(seq[i - 1] * BigInt.from(2 * (2 * i - 1)) ~/ BigInt.from(i + 1));
    }
    return seq;
  }

  List<BigInt> _bell(int n) {
    if (n <= 0) return [];
    // Bell numbers using Bell triangle
    final bell = List<List<BigInt>>.generate(
      n,
      (_) => List<BigInt>.filled(n, BigInt.zero),
    );
    bell[0][0] = BigInt.one;

    for (var i = 1; i < n; i++) {
      bell[i][0] = bell[i - 1][i - 1];
      for (var j = 1; j <= i; j++) {
        bell[i][j] = bell[i - 1][j - 1] + bell[i][j - 1];
      }
    }

    return List.generate(n, (i) => bell[i][0]);
  }

  List<int> _eulerTotient(int n) {
    // φ(n) using formula: n * product(1 - 1/p) for all prime factors p of n
    final result = <int>[];
    for (var i = 1; i <= n; i++) {
      var phi = i;
      var temp = i;

      // Find all prime factors
      for (var p = 2; p * p <= temp; p++) {
        if (temp % p == 0) {
          while (temp % p == 0) temp ~/= p;
          phi -= phi ~/ p;
        }
      }
      if (temp > 1) phi -= phi ~/ temp;

      result.add(phi);
    }
    return result;
  }

  Future<void> _generate() async {
    setState(() {
      _isComputing = true;
      _result = [];
      _error = '';
    });

    try {
      final n = int.parse(_nCtrl.text);

      if (n <= 0) {
        setState(() {
          _error = 'Error: Must be positive';
          _isComputing = false;
        });
        return;
      }
      if (n > 100) {
        setState(() {
          _error = 'Error: Max 100 terms';
          _isComputing = false;
        });
        return;
      }

      List<String> result;

      switch (_sequence) {
        case 'fibonacci':
          result = _fibonacci(n).map((b) => _formatBigInt(b)).toList();
        case 'catalan':
          result = _catalan(n).map((b) => _formatBigInt(b)).toList();
        case 'bell':
          result = _bell(n).map((b) => _formatBigInt(b)).toList();
        case 'euler_totient':
          result = _eulerTotient(
            n,
          ).asMap().entries.map((e) => 'φ(${e.key + 1}) = ${e.value}').toList();
        default:
          result = [];
      }

      setState(() {
        _result = result;
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: Invalid number';
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
                child: Text("Euler's Totient"),
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

          if (_error.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _result.asMap().entries.map((e) {
                    final showIndex = _sequence != 'euler_totient';
                    return Chip(
                      avatar: showIndex
                          ? CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              child: Text(
                                '${e.key}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            )
                          : null,
                      label: Text(e.value),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
