import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Statistics tab - Comprehensive statistical analysis
/// Features: Descriptive stats, 13+ distributions, regression, hypothesis testing
class MathStatisticsTab extends StatefulWidget {
  const MathStatisticsTab({super.key});

  @override
  State<MathStatisticsTab> createState() => _MathStatisticsTabState();
}

class _MathStatisticsTabState extends State<MathStatisticsTab>
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
            Tab(text: 'Descriptive'),
            Tab(text: 'Distributions'),
            Tab(text: 'Regression'),
            Tab(text: 'Hypothesis'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _DescriptiveStats(),
              _DistributionCalculator(),
              _RegressionCalculator(),
              _HypothesisCalculator(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DESCRIPTIVE STATISTICS
// ============================================================================

class _DescriptiveStats extends StatefulWidget {
  const _DescriptiveStats();

  @override
  State<_DescriptiveStats> createState() => _DescriptiveStatsState();
}

class _DescriptiveStatsState extends State<_DescriptiveStats> {
  final _dataController = TextEditingController();
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _compute() {
    final text = _dataController.text.trim();
    if (text.isEmpty) {
      setState(() => _result = 'Please enter data');
      return;
    }

    setState(() => _isComputing = true);

    try {
      final data = text
          .split(RegExp(r'[,\s\n]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.parse(s.trim()))
          .toList();

      if (data.isEmpty) throw Exception('No valid numbers found');

      final n = data.length;
      final sorted = List<double>.from(data)..sort();

      // Mean
      final mean = data.reduce((a, b) => a + b) / n;

      // Median
      final median = n.isOdd
          ? sorted[n ~/ 2]
          : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;

      // Mode
      final freq = <double, int>{};
      for (final x in data) {
        freq[x] = (freq[x] ?? 0) + 1;
      }
      final maxFreq = freq.values.reduce(math.max);
      final modes = freq.entries
          .where((e) => e.value == maxFreq)
          .map((e) => e.key)
          .toList();
      final modeStr = maxFreq == 1
          ? 'No mode (all unique)'
          : modes.map((m) => _formatNumber(m)).join(', ');

      // Variance & Standard Deviation
      final variance =
          data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
      final stdDev = math.sqrt(variance);

      // Sample variance & std dev
      final sampleVariance = n > 1
          ? data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
                (n - 1)
          : 0.0;
      final sampleStdDev = math.sqrt(sampleVariance);

      // Range
      final min = sorted.first;
      final max = sorted.last;
      final range = max - min;

      // Quartiles
      final q1 = _percentile(sorted, 25);
      final q3 = _percentile(sorted, 75);
      final iqr = q3 - q1;

      // Skewness
      final skewness = n > 2 && stdDev > 0
          ? (n / ((n - 1) * (n - 2))) *
                data
                    .map((x) => math.pow((x - mean) / stdDev, 3))
                    .reduce((a, b) => a + b)
          : 0.0;

      // Kurtosis
      final kurtosis = n > 3 && stdDev > 0
          ? ((n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))) *
                    data
                        .map((x) => math.pow((x - mean) / stdDev, 4))
                        .reduce((a, b) => a + b) -
                (3 * (n - 1) * (n - 1)) / ((n - 2) * (n - 3))
          : 0.0;

      // Sum
      final sum = data.reduce((a, b) => a + b);

      // Geometric Mean (for positive values)
      final allPositive = data.every((x) => x > 0);
      final geometricMean = allPositive
          ? math.exp(data.map((x) => math.log(x)).reduce((a, b) => a + b) / n)
          : double.nan;

      // Harmonic Mean (for positive values)
      final harmonicMean = allPositive
          ? n / data.map((x) => 1 / x).reduce((a, b) => a + b)
          : double.nan;

      // Standard Error
      final standardError = stdDev / math.sqrt(n);

      // Coefficient of Variation
      final cv = mean != 0 ? (stdDev / mean.abs()) * 100 : double.infinity;

      setState(() {
        _result =
            '''
CENTRAL TENDENCY
  Mean: ${_formatNumber(mean)}
  Median: ${_formatNumber(median)}
  Mode: $modeStr
  ${allPositive ? 'Geometric Mean: ${_formatNumber(geometricMean)}' : ''}
  ${allPositive ? 'Harmonic Mean: ${_formatNumber(harmonicMean)}' : ''}

DISPERSION
  Range: ${_formatNumber(range)} (${_formatNumber(min)} to ${_formatNumber(max)})
  Variance (pop): ${_formatNumber(variance)}
  Variance (sample): ${_formatNumber(sampleVariance)}
  Std Dev (pop): ${_formatNumber(stdDev)}
  Std Dev (sample): ${_formatNumber(sampleStdDev)}
  Standard Error: ${_formatNumber(standardError)}
  Coeff. of Variation: ${_formatNumber(cv)}%

QUARTILES
  Q1 (25%): ${_formatNumber(q1)}
  Q2 (50%): ${_formatNumber(median)}
  Q3 (75%): ${_formatNumber(q3)}
  IQR: ${_formatNumber(iqr)}

SHAPE
  Skewness: ${_formatNumber(skewness)}
  Kurtosis: ${_formatNumber(kurtosis)}

SUMMARY
  Count: $n
  Sum: ${_formatNumber(sum)}
'''
                .trim();
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted[0];
    final k = (p / 100) * (sorted.length - 1);
    final f = k.floor();
    final c = k.ceil();
    if (f == c) return sorted[f];
    return sorted[f] + (k - f) * (sorted[c] - sorted[f]);
  }

  String _formatNumber(double n) {
    if (n.isNaN) return 'N/A';
    if (n.isInfinite) return '∞';
    if (n == n.toInt().toDouble() && n.abs() < 1e10)
      return n.toInt().toString();
    return n
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter data values',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Separate values with commas, spaces, or newlines',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dataController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '1, 2, 3, 4, 5 or\n1 2 3 4 5',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
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
              label: const Text('Compute Statistics'),
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
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DISTRIBUTION CALCULATOR - 13+ Distributions
// ============================================================================

class _DistributionCalculator extends StatefulWidget {
  const _DistributionCalculator();

  @override
  State<_DistributionCalculator> createState() =>
      _DistributionCalculatorState();
}

class _DistributionCalculatorState extends State<_DistributionCalculator> {
  var _distribution = 'normal';
  final _params = <String, TextEditingController>{};
  final _xCtrl = TextEditingController(text: '0');
  var _calcType = 'pdf';
  var _result = '';

  static const _distributions = {
    'normal': 'Normal (Gaussian)',
    'bernoulli': 'Bernoulli',
    'binomial': 'Binomial',
    'poisson': 'Poisson',
    'hypergeometric': 'Hypergeometric',
    'geometric': 'Geometric',
    'uniform_discrete': 'Uniform (Discrete)',
    'uniform_continuous': 'Uniform (Continuous)',
    'exponential': 'Exponential',
    't': 'Student\'s t',
    'chi_square': 'Chi-Square',
    'beta': 'Beta',
    'gamma': 'Gamma',
    'cauchy': 'Cauchy',
    'f': 'F-Distribution',
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final p in [
      'mean',
      'std',
      'p',
      'n',
      'k',
      'N',
      'K',
      'a',
      'b',
      'rate',
      'df',
      'df1',
      'df2',
      'alpha',
      'beta',
      'x0',
      'gamma',
    ]) {
      _params[p] = TextEditingController();
    }
    _params['mean']!.text = '0';
    _params['std']!.text = '1';
    _params['p']!.text = '0.5';
    _params['n']!.text = '10';
    _params['k']!.text = '3';
    _params['N']!.text = '50';
    _params['K']!.text = '20';
    _params['a']!.text = '0';
    _params['b']!.text = '1';
    _params['rate']!.text = '1';
    _params['df']!.text = '5';
    _params['df1']!.text = '5';
    _params['df2']!.text = '10';
    _params['alpha']!.text = '2';
    _params['beta']!.text = '5';
    _params['x0']!.text = '0';
    _params['gamma']!.text = '1';
  }

  @override
  void dispose() {
    for (final c in _params.values) {
      c.dispose();
    }
    _xCtrl.dispose();
    super.dispose();
  }

  List<(String, String, String)> _getParamsForDistribution() {
    switch (_distribution) {
      case 'normal':
        return [('mean', 'Mean (μ)', '0'), ('std', 'Std Dev (σ)', '1')];
      case 'bernoulli':
        return [('p', 'Probability (p)', '0.5')];
      case 'binomial':
        return [('n', 'Trials (n)', '10'), ('p', 'Probability (p)', '0.5')];
      case 'poisson':
        return [('rate', 'Rate (λ)', '5')];
      case 'hypergeometric':
        return [
          ('N', 'Population (N)', '50'),
          ('K', 'Success states (K)', '20'),
          ('n', 'Draws (n)', '10'),
        ];
      case 'geometric':
        return [('p', 'Probability (p)', '0.5')];
      case 'uniform_discrete':
        return [('a', 'Min (a)', '1'), ('b', 'Max (b)', '6')];
      case 'uniform_continuous':
        return [('a', 'Min (a)', '0'), ('b', 'Max (b)', '1')];
      case 'exponential':
        return [('rate', 'Rate (λ)', '1')];
      case 't':
        return [('df', 'Degrees of Freedom', '5')];
      case 'chi_square':
        return [('df', 'Degrees of Freedom', '5')];
      case 'beta':
        return [('alpha', 'Alpha (α)', '2'), ('beta', 'Beta (β)', '5')];
      case 'gamma':
        return [('alpha', 'Shape (k)', '2'), ('rate', 'Rate (θ)', '1')];
      case 'cauchy':
        return [('x0', 'Location (x₀)', '0'), ('gamma', 'Scale (γ)', '1')];
      case 'f':
        return [
          ('df1', 'df₁ (numerator)', '5'),
          ('df2', 'df₂ (denominator)', '10'),
        ];
      default:
        return [];
    }
  }

  void _compute() {
    try {
      final x = double.parse(_xCtrl.text);
      double result;

      switch (_distribution) {
        case 'normal':
          final mean = double.parse(_params['mean']!.text);
          final std = double.parse(_params['std']!.text);
          if (std <= 0) throw Exception('Std dev must be positive');
          if (_calcType == 'pdf') {
            result = _normalPdf(x, mean, std);
          } else if (_calcType == 'cdf') {
            result = _normalCdf(x, mean, std);
          } else {
            result = _normalInvCdf(x, mean, std);
          }

        case 'bernoulli':
          final p = double.parse(_params['p']!.text);
          if (p < 0 || p > 1) throw Exception('p must be between 0 and 1');
          if (_calcType == 'pdf') {
            result = x == 1 ? p : (x == 0 ? 1 - p : 0);
          } else {
            result = x < 0 ? 0 : (x < 1 ? 1 - p : 1);
          }

        case 'binomial':
          final n = int.parse(_params['n']!.text);
          final p = double.parse(_params['p']!.text);
          if (n < 0) throw Exception('n must be non-negative');
          if (p < 0 || p > 1) throw Exception('p must be between 0 and 1');
          if (_calcType == 'pdf') {
            result = _binomialPmf(x.toInt(), n, p);
          } else {
            result = _binomialCdf(x.toInt(), n, p);
          }

        case 'poisson':
          final lambda = double.parse(_params['rate']!.text);
          if (lambda <= 0) throw Exception('λ must be positive');
          if (_calcType == 'pdf') {
            result = _poissonPmf(x.toInt(), lambda);
          } else {
            result = _poissonCdf(x.toInt(), lambda);
          }

        case 'hypergeometric':
          final bigN = int.parse(_params['N']!.text);
          final bigK = int.parse(_params['K']!.text);
          final n = int.parse(_params['n']!.text);
          if (_calcType == 'pdf') {
            result = _hypergeometricPmf(x.toInt(), bigN, bigK, n);
          } else {
            result = _hypergeometricCdf(x.toInt(), bigN, bigK, n);
          }

        case 'geometric':
          final p = double.parse(_params['p']!.text);
          if (p <= 0 || p > 1) throw Exception('p must be in (0, 1]');
          final k = x.toInt();
          if (_calcType == 'pdf') {
            result = k >= 1 ? (math.pow(1 - p, k - 1) * p).toDouble() : 0;
          } else {
            result = k >= 1 ? (1 - math.pow(1 - p, k)).toDouble() : 0;
          }

        case 'uniform_discrete':
          final a = int.parse(_params['a']!.text);
          final b = int.parse(_params['b']!.text);
          if (a >= b) throw Exception('a must be less than b');
          final k = x.toInt();
          if (_calcType == 'pdf') {
            result = k >= a && k <= b ? 1 / (b - a + 1) : 0;
          } else {
            result = k < a ? 0 : (k > b ? 1 : (k - a + 1) / (b - a + 1));
          }

        case 'uniform_continuous':
          final a = double.parse(_params['a']!.text);
          final b = double.parse(_params['b']!.text);
          if (a >= b) throw Exception('a must be less than b');
          if (_calcType == 'pdf') {
            result = x >= a && x <= b ? 1 / (b - a) : 0;
          } else if (_calcType == 'cdf') {
            result = x < a ? 0 : (x > b ? 1 : (x - a) / (b - a));
          } else {
            result = a + x * (b - a);
          }

        case 'exponential':
          final lambda = double.parse(_params['rate']!.text);
          if (lambda <= 0) throw Exception('λ must be positive');
          if (_calcType == 'pdf') {
            result = x >= 0 ? lambda * math.exp(-lambda * x) : 0;
          } else if (_calcType == 'cdf') {
            result = x >= 0 ? 1 - math.exp(-lambda * x) : 0;
          } else {
            result = -math.log(1 - x) / lambda;
          }

        case 't':
          final df = double.parse(_params['df']!.text);
          if (df <= 0) throw Exception('df must be positive');
          if (_calcType == 'pdf') {
            result = _tPdf(x, df);
          } else {
            result = _tCdf(x, df);
          }

        case 'chi_square':
          final df = double.parse(_params['df']!.text);
          if (df <= 0) throw Exception('df must be positive');
          if (_calcType == 'pdf') {
            result = _chiSquarePdf(x, df);
          } else {
            result = _chiSquareCdf(x, df);
          }

        case 'beta':
          final alpha = double.parse(_params['alpha']!.text);
          final beta = double.parse(_params['beta']!.text);
          if (alpha <= 0 || beta <= 0) {
            throw Exception('α and β must be positive');
          }
          if (_calcType == 'pdf') {
            result = _betaPdf(x, alpha, beta);
          } else {
            result = _betaCdf(x, alpha, beta);
          }

        case 'gamma':
          final k = double.parse(_params['alpha']!.text);
          final theta = double.parse(_params['rate']!.text);
          if (k <= 0 || theta <= 0) {
            throw Exception('k and θ must be positive');
          }
          if (_calcType == 'pdf') {
            result = _gammaPdf(x, k, theta);
          } else {
            result = _gammaCdf(x, k, theta);
          }

        case 'cauchy':
          final x0 = double.parse(_params['x0']!.text);
          final gamma = double.parse(_params['gamma']!.text);
          if (gamma <= 0) throw Exception('γ must be positive');
          if (_calcType == 'pdf') {
            final z = (x - x0) / gamma;
            result = 1 / (math.pi * gamma * (1 + z * z));
          } else if (_calcType == 'cdf') {
            result = 0.5 + math.atan((x - x0) / gamma) / math.pi;
          } else {
            result = x0 + gamma * math.tan(math.pi * (x - 0.5));
          }

        case 'f':
          final d1 = double.parse(_params['df1']!.text);
          final d2 = double.parse(_params['df2']!.text);
          if (d1 <= 0 || d2 <= 0) {
            throw Exception('df values must be positive');
          }
          if (_calcType == 'pdf') {
            result = _fPdf(x, d1, d2);
          } else {
            result = _fCdf(x, d1, d2);
          }

        default:
          throw Exception('Unknown distribution');
      }

      final typeLabel = _calcType == 'pdf'
          ? (_isDiscrete() ? 'P(X = $x)' : 'f($x)')
          : (_calcType == 'cdf' ? 'P(X ≤ $x)' : 'x for P = $x');

      setState(() => _result = '$typeLabel = ${_formatNumber(result)}');
    } catch (e) {
      setState(
        () => _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  bool _isDiscrete() {
    return [
      'bernoulli',
      'binomial',
      'poisson',
      'hypergeometric',
      'geometric',
      'uniform_discrete',
    ].contains(_distribution);
  }

  double _normalPdf(double x, double mean, double std) {
    final z = (x - mean) / std;
    return math.exp(-0.5 * z * z) / (std * math.sqrt(2 * math.pi));
  }

  double _normalCdf(double x, double mean, double std) {
    final z = (x - mean) / (std * math.sqrt(2));
    return 0.5 * (1 + _erf(z));
  }

  double _normalInvCdf(double p, double mean, double std) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;
    if (p == 0.5) return mean;

    final t = p < 0.5
        ? math.sqrt(-2 * math.log(p))
        : math.sqrt(-2 * math.log(1 - p));
    const c0 = 2.515517;
    const c1 = 0.802853;
    const c2 = 0.010328;
    const d1 = 1.432788;
    const d2 = 0.189269;
    const d3 = 0.001308;

    var z =
        t -
        (c0 + c1 * t + c2 * t * t) / (1 + d1 * t + d2 * t * t + d3 * t * t * t);
    if (p < 0.5) z = -z;

    return mean + std * z;
  }

  double _erf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  double _binomialPmf(int k, int n, double p) {
    if (k < 0 || k > n) return 0;
    return _binomialCoef(n, k) * math.pow(p, k) * math.pow(1 - p, n - k);
  }

  double _binomialCdf(int k, int n, double p) {
    var sum = 0.0;
    for (var i = 0; i <= k; i++) {
      sum += _binomialPmf(i, n, p);
    }
    return sum;
  }

  double _poissonPmf(int k, double lambda) {
    if (k < 0) return 0;
    return math.exp(-lambda) * math.pow(lambda, k) / _factorial(k);
  }

  double _poissonCdf(int k, double lambda) {
    var sum = 0.0;
    for (var i = 0; i <= k; i++) {
      sum += _poissonPmf(i, lambda);
    }
    return sum;
  }

  double _hypergeometricPmf(int k, int bigN, int bigK, int n) {
    if (k < math.max(0, n + bigK - bigN) || k > math.min(n, bigK)) return 0;
    return (_binomialCoef(bigK, k) * _binomialCoef(bigN - bigK, n - k)) /
        _binomialCoef(bigN, n);
  }

  double _hypergeometricCdf(int k, int bigN, int bigK, int n) {
    var sum = 0.0;
    for (var i = 0; i <= k; i++) {
      sum += _hypergeometricPmf(i, bigN, bigK, n);
    }
    return sum;
  }

  double _tPdf(double t, double df) {
    return _gammaFunc((df + 1) / 2) /
        (math.sqrt(df * math.pi) * _gammaFunc(df / 2)) *
        math.pow(1 + t * t / df, -(df + 1) / 2);
  }

  double _tCdf(double t, double df) {
    const n = 1000;
    final h = (t - (-10)) / n;
    var sum = (_tPdf(-10, df) + _tPdf(t, df)) / 2;
    for (var i = 1; i < n; i++) {
      sum += _tPdf(-10 + i * h, df);
    }
    return (sum * h).clamp(0.0, 1.0);
  }

  double _chiSquarePdf(double x, double k) {
    if (x < 0) return 0;
    return math.pow(x, k / 2 - 1) *
        math.exp(-x / 2) /
        (math.pow(2, k / 2) * _gammaFunc(k / 2));
  }

  double _chiSquareCdf(double x, double k) {
    if (x <= 0) return 0;
    return _lowerIncompleteGamma(k / 2, x / 2) / _gammaFunc(k / 2);
  }

  double _betaPdf(double x, double alpha, double beta) {
    if (x < 0 || x > 1) return 0;
    return math.pow(x, alpha - 1) *
        math.pow(1 - x, beta - 1) /
        _betaFunc(alpha, beta);
  }

  double _betaCdf(double x, double alpha, double beta) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    return _incompleteBeta(x, alpha, beta);
  }

  double _gammaPdf(double x, double k, double theta) {
    if (x < 0) return 0;
    return math.pow(x, k - 1) *
        math.exp(-x / theta) /
        (math.pow(theta, k) * _gammaFunc(k));
  }

  double _gammaCdf(double x, double k, double theta) {
    if (x <= 0) return 0;
    return _lowerIncompleteGamma(k, x / theta) / _gammaFunc(k);
  }

  double _fPdf(double x, double d1, double d2) {
    if (x < 0) return 0;
    return math.sqrt(
          math.pow(d1 * x, d1) *
              math.pow(d2, d2) /
              math.pow(d1 * x + d2, d1 + d2),
        ) /
        (x * _betaFunc(d1 / 2, d2 / 2));
  }

  double _fCdf(double x, double d1, double d2) {
    if (x <= 0) return 0;
    return _incompleteBeta(d1 * x / (d1 * x + d2), d1 / 2, d2 / 2);
  }

  double _gammaFunc(double z) {
    if (z < 0.5) {
      return math.pi / (math.sin(math.pi * z) * _gammaFunc(1 - z));
    }
    z -= 1;
    const g = 7;
    const c = [
      0.99999999999980993,
      676.5203681218851,
      -1259.1392167224028,
      771.32342877765313,
      -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
      9.9843695780195716e-6,
      1.5056327351493116e-7,
    ];
    var x = c[0];
    for (var i = 1; i < g + 2; i++) {
      x += c[i] / (z + i);
    }
    final t = z + g + 0.5;
    return math.sqrt(2 * math.pi) * math.pow(t, z + 0.5) * math.exp(-t) * x;
  }

  double _betaFunc(double a, double b) {
    return _gammaFunc(a) * _gammaFunc(b) / _gammaFunc(a + b);
  }

  double _lowerIncompleteGamma(double a, double x) {
    if (x == 0) return 0;
    var sum = 0.0;
    var term = 1.0 / a;
    sum = term;
    for (var n = 1; n < 100; n++) {
      term *= x / (a + n);
      sum += term;
      if (term.abs() < 1e-10) break;
    }
    return math.pow(x, a) * math.exp(-x) * sum;
  }

  double _incompleteBeta(double x, double a, double b) {
    const n = 1000;
    final h = x / n;
    var sum = 0.0;
    for (var i = 1; i < n; i++) {
      final t = i * h;
      sum += math.pow(t, a - 1) * math.pow(1 - t, b - 1);
    }
    return h * sum / _betaFunc(a, b);
  }

  double _binomialCoef(int n, int k) {
    if (k > n || k < 0) return 0;
    if (k == 0 || k == n) return 1;
    var result = 1.0;
    for (var i = 0; i < k; i++) {
      result *= (n - i) / (i + 1);
    }
    return result;
  }

  double _factorial(int n) {
    if (n < 0) return double.nan;
    if (n <= 1) return 1;
    var result = 1.0;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  String _formatNumber(double n) {
    if (n.isNaN) return 'N/A';
    if (n.isInfinite) return n > 0 ? '∞' : '-∞';
    if (n == n.toInt().toDouble() && n.abs() < 1e10)
      return n.toInt().toString();
    return n
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final params = _getParamsForDistribution();
    final isDiscrete = _isDiscrete();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _distribution,
            decoration: const InputDecoration(
              labelText: 'Distribution',
              border: OutlineInputBorder(),
            ),
            items: _distributions.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _distribution = v ?? 'normal'),
          ),
          const SizedBox(height: 16),
          ...params.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _params[p.$1],
                decoration: InputDecoration(
                  labelText: p.$2,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
          ),
          TextField(
            controller: _xCtrl,
            decoration: InputDecoration(
              labelText: _calcType == 'icdf' ? 'Probability p' : 'Value x',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'pdf',
                label: Text(isDiscrete ? 'PMF' : 'PDF'),
              ),
              const ButtonSegment(value: 'cdf', label: Text('CDF')),
              if (!isDiscrete)
                const ButtonSegment(value: 'icdf', label: Text('Inverse')),
            ],
            selected: {_calcType},
            onSelectionChanged: (s) => setState(() => _calcType = s.first),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _compute,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
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
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// REGRESSION CALCULATOR
// ============================================================================

class _RegressionCalculator extends StatefulWidget {
  const _RegressionCalculator();

  @override
  State<_RegressionCalculator> createState() => _RegressionCalculatorState();
}

class _RegressionCalculatorState extends State<_RegressionCalculator> {
  final _xController = TextEditingController(text: '1, 2, 3, 4, 5');
  final _yController = TextEditingController(text: '2, 4, 5, 4, 5');
  var _regressionType = 'linear';
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _compute() {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final xData = _xController.text
          .split(RegExp(r'[,\s\n]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.parse(s.trim()))
          .toList();

      final yData = _yController.text
          .split(RegExp(r'[,\s\n]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.parse(s.trim()))
          .toList();

      if (xData.length != yData.length) {
        throw Exception('X and Y must have the same number of values');
      }

      if (xData.length < 2) {
        throw Exception('Need at least 2 data points');
      }

      String resultText;

      switch (_regressionType) {
        case 'linear':
          final result = _linearRegression(xData, yData);
          resultText =
              '''
LINEAR REGRESSION: y = mx + b

Slope (m): ${_formatNumber(result.slope)}
Intercept (b): ${_formatNumber(result.intercept)}

Equation: y = ${_formatNumber(result.slope)}x + ${_formatNumber(result.intercept)}

R² (Coefficient of Determination): ${_formatNumber(result.rSquared)}
R (Correlation Coefficient): ${_formatNumber(result.correlation)}
Standard Error: ${_formatNumber(result.standardError)}
''';

        case 'polynomial':
          final result = _polynomialRegression(xData, yData, 2);
          resultText =
              '''
POLYNOMIAL REGRESSION (degree 2): y = ax² + bx + c

a: ${_formatNumber(result[2])}
b: ${_formatNumber(result[1])}
c: ${_formatNumber(result[0])}

Equation: y = ${_formatNumber(result[2])}x² + ${_formatNumber(result[1])}x + ${_formatNumber(result[0])}
''';

        case 'exponential':
          final lnY = yData.map((y) => math.log(y)).toList();
          final linear = _linearRegression(xData, lnY);
          final a = math.exp(linear.intercept);
          final b = linear.slope;
          resultText =
              '''
EXPONENTIAL REGRESSION: y = a·e^(bx)

a: ${_formatNumber(a)}
b: ${_formatNumber(b)}

Equation: y = ${_formatNumber(a)}·e^(${_formatNumber(b)}x)
''';

        case 'logarithmic':
          final lnX = xData.map((x) => math.log(x)).toList();
          final linear = _linearRegression(lnX, yData);
          resultText =
              '''
LOGARITHMIC REGRESSION: y = a + b·ln(x)

a: ${_formatNumber(linear.intercept)}
b: ${_formatNumber(linear.slope)}

Equation: y = ${_formatNumber(linear.intercept)} + ${_formatNumber(linear.slope)}·ln(x)
R²: ${_formatNumber(linear.rSquared)}
''';

        case 'power':
          final lnX = xData.map((x) => math.log(x)).toList();
          final lnY = yData.map((y) => math.log(y)).toList();
          final linear = _linearRegression(lnX, lnY);
          final a = math.exp(linear.intercept);
          final b = linear.slope;
          resultText =
              '''
POWER REGRESSION: y = a·x^b

a: ${_formatNumber(a)}
b: ${_formatNumber(b)}

Equation: y = ${_formatNumber(a)}·x^${_formatNumber(b)}
''';

        default:
          throw Exception('Unknown regression type');
      }

      setState(() {
        _result = resultText.trim();
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  _LinearResult _linearRegression(List<double> x, List<double> y) {
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);
    final sumY2 = y.map((yi) => yi * yi).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final yMean = sumY / n;
    final ssTot = y
        .map((yi) => (yi - yMean) * (yi - yMean))
        .reduce((a, b) => a + b);
    final ssRes = List.generate(n, (i) {
      final predicted = slope * x[i] + intercept;
      return (y[i] - predicted) * (y[i] - predicted);
    }).reduce((a, b) => a + b);
    final rSquared = 1 - ssRes / ssTot;

    final correlation =
        (n * sumXY - sumX * sumY) /
        math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    final standardError = n > 2 ? math.sqrt(ssRes / (n - 2)) : 0.0;

    return _LinearResult(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
      correlation: correlation,
      standardError: standardError,
    );
  }

  List<double> _polynomialRegression(
    List<double> x,
    List<double> y,
    int degree,
  ) {
    final n = x.length;
    final m = degree + 1;

    final xMatrix = List.generate(
      n,
      (i) => List.generate(m, (j) => math.pow(x[i], j).toDouble()),
    );

    final xtX = List.generate(
      m,
      (i) => List.generate(m, (j) {
        var sum = 0.0;
        for (var k = 0; k < n; k++) {
          sum += xMatrix[k][i] * xMatrix[k][j];
        }
        return sum;
      }),
    );

    final xty = List.generate(m, (i) {
      var sum = 0.0;
      for (var k = 0; k < n; k++) {
        sum += xMatrix[k][i] * y[k];
      }
      return sum;
    });

    return _solveLinearSystem(xtX, xty);
  }

  List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
    final n = a.length;
    final augmented = List.generate(n, (i) => [...a[i], b[i]]);

    for (var col = 0; col < n; col++) {
      var maxRow = col;
      for (var row = col + 1; row < n; row++) {
        if (augmented[row][col].abs() > augmented[maxRow][col].abs()) {
          maxRow = row;
        }
      }
      final temp = augmented[col];
      augmented[col] = augmented[maxRow];
      augmented[maxRow] = temp;

      for (var row = col + 1; row < n; row++) {
        final factor = augmented[row][col] / augmented[col][col];
        for (var j = col; j <= n; j++) {
          augmented[row][j] -= factor * augmented[col][j];
        }
      }
    }

    final solution = List<double>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      var sum = augmented[i][n];
      for (var j = i + 1; j < n; j++) {
        sum -= augmented[i][j] * solution[j];
      }
      solution[i] = sum / augmented[i][i];
    }

    return solution;
  }

  String _formatNumber(double n) {
    if (n.isNaN) return 'N/A';
    if (n.isInfinite) return n > 0 ? '∞' : '-∞';
    if (n == n.toInt().toDouble() && n.abs() < 1e10)
      return n.toInt().toString();
    return n
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter X values', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _xController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '1, 2, 3, 4, 5',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Enter Y values', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _yController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '2, 4, 5, 4, 5',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _regressionType,
            decoration: const InputDecoration(
              labelText: 'Regression Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'linear',
                child: Text('Linear (y = mx + b)'),
              ),
              DropdownMenuItem(
                value: 'polynomial',
                child: Text('Polynomial (y = ax² + bx + c)'),
              ),
              DropdownMenuItem(
                value: 'exponential',
                child: Text('Exponential (y = a·e^bx)'),
              ),
              DropdownMenuItem(
                value: 'logarithmic',
                child: Text('Logarithmic (y = a + b·ln(x))'),
              ),
              DropdownMenuItem(
                value: 'power',
                child: Text('Power (y = a·x^b)'),
              ),
            ],
            onChanged: (v) => setState(() => _regressionType = v ?? 'linear'),
          ),
          const SizedBox(height: 16),
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
              label: const Text('Calculate Regression'),
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
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinearResult {
  final double slope;
  final double intercept;
  final double rSquared;
  final double correlation;
  final double standardError;

  _LinearResult({
    required this.slope,
    required this.intercept,
    required this.rSquared,
    required this.correlation,
    required this.standardError,
  });
}

// ============================================================================
// HYPOTHESIS TESTING - Z-test, T-test, Chi-Square, ANOVA
// ============================================================================

class _HypothesisCalculator extends StatefulWidget {
  const _HypothesisCalculator();

  @override
  State<_HypothesisCalculator> createState() => _HypothesisCalculatorState();
}

class _HypothesisCalculatorState extends State<_HypothesisCalculator> {
  var _testType = 'z_one_sample';
  final _controllers = <String, TextEditingController>{};
  var _alternative = 'two_sided';
  var _result = '';
  var _isComputing = false;

  static const _testTypes = {
    'z_one_sample': 'Z-Test (One Sample)',
    'z_two_sample': 'Z-Test (Two Sample)',
    't_one_sample': 'T-Test (One Sample)',
    't_two_sample': 'T-Test (Two Sample)',
    't_paired': 'T-Test (Paired)',
    'chi_square_gof': 'Chi-Square (Goodness of Fit)',
    'chi_square_ind': 'Chi-Square (Independence)',
    'anova_one_way': 'ANOVA (One-Way)',
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final params = [
      'sample_mean',
      'pop_mean',
      'pop_std',
      'sample_size',
      'sample_mean2',
      'sample_size2',
      'sample_std',
      'sample_std2',
      'sample1_data',
      'sample2_data',
      'observed',
      'expected',
      'contingency',
      'group_data',
      'alpha',
    ];
    for (final p in params) {
      _controllers[p] = TextEditingController();
    }
    _controllers['alpha']!.text = '0.05';
    _controllers['pop_mean']!.text = '0';
    _controllers['pop_std']!.text = '1';
    _controllers['sample_mean']!.text = '1.5';
    _controllers['sample_size']!.text = '30';
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Widget> _buildInputFields() {
    final widgets = <Widget>[];

    switch (_testType) {
      case 'z_one_sample':
        widgets.addAll([
          _buildField('sample_mean', 'Sample Mean (x̄)'),
          _buildField('pop_mean', 'Population Mean (μ₀)'),
          _buildField('pop_std', 'Population Std Dev (σ)'),
          _buildField('sample_size', 'Sample Size (n)'),
        ]);

      case 'z_two_sample':
        widgets.addAll([
          _buildField('sample_mean', 'Sample 1 Mean (x̄₁)'),
          _buildField('sample_mean2', 'Sample 2 Mean (x̄₂)'),
          _buildField('pop_std', 'Population 1 Std (σ₁)'),
          _buildField('sample_std2', 'Population 2 Std (σ₂)'),
          _buildField('sample_size', 'Sample 1 Size (n₁)'),
          _buildField('sample_size2', 'Sample 2 Size (n₂)'),
        ]);

      case 't_one_sample':
        widgets.addAll([
          _buildField('sample_mean', 'Sample Mean (x̄)'),
          _buildField('pop_mean', 'Hypothesized Mean (μ₀)'),
          _buildField('sample_std', 'Sample Std Dev (s)'),
          _buildField('sample_size', 'Sample Size (n)'),
        ]);

      case 't_two_sample':
        widgets.addAll([
          _buildField('sample_mean', 'Sample 1 Mean (x̄₁)'),
          _buildField('sample_mean2', 'Sample 2 Mean (x̄₂)'),
          _buildField('sample_std', 'Sample 1 Std (s₁)'),
          _buildField('sample_std2', 'Sample 2 Std (s₂)'),
          _buildField('sample_size', 'Sample 1 Size (n₁)'),
          _buildField('sample_size2', 'Sample 2 Size (n₂)'),
        ]);

      case 't_paired':
        widgets.add(
          _buildMultiField('sample1_data', 'Sample 1 Data (comma-separated)'),
        );
        widgets.add(
          _buildMultiField('sample2_data', 'Sample 2 Data (comma-separated)'),
        );

      case 'chi_square_gof':
        widgets.add(
          _buildMultiField(
            'observed',
            'Observed Frequencies (comma-separated)',
          ),
        );
        widgets.add(
          _buildMultiField(
            'expected',
            'Expected Frequencies (comma-separated, or leave empty for equal)',
          ),
        );

      case 'chi_square_ind':
        widgets.add(
          _buildMultiField(
            'contingency',
            'Contingency Table (rows separated by semicolons)\nExample: 10,20;30,40',
          ),
        );

      case 'anova_one_way':
        widgets.add(
          _buildMultiField(
            'group_data',
            'Group Data (groups separated by semicolons)\nExample: 1,2,3;4,5,6;7,8,9',
          ),
        );
    }

    widgets.add(_buildField('alpha', 'Significance Level (α)'));
    return widgets;
  }

  Widget _buildField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
      ),
    );
  }

  Widget _buildMultiField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[key],
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _compute() {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final alpha = double.parse(_controllers['alpha']!.text);
      String resultText;

      switch (_testType) {
        case 'z_one_sample':
          resultText = _zTestOneSample(alpha);
        case 'z_two_sample':
          resultText = _zTestTwoSample(alpha);
        case 't_one_sample':
          resultText = _tTestOneSample(alpha);
        case 't_two_sample':
          resultText = _tTestTwoSample(alpha);
        case 't_paired':
          resultText = _tTestPaired(alpha);
        case 'chi_square_gof':
          resultText = _chiSquareGoF(alpha);
        case 'chi_square_ind':
          resultText = _chiSquareIndependence(alpha);
        case 'anova_one_way':
          resultText = _anovaOneWay(alpha);
        default:
          throw Exception('Unknown test type');
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

  String _zTestOneSample(double alpha) {
    final xBar = double.parse(_controllers['sample_mean']!.text);
    final mu0 = double.parse(_controllers['pop_mean']!.text);
    final sigma = double.parse(_controllers['pop_std']!.text);
    final n = int.parse(_controllers['sample_size']!.text);

    final z = (xBar - mu0) / (sigma / math.sqrt(n));
    final pValue = _zPValue(z, _alternative);
    final criticalValue = _zCritical(alpha, _alternative);
    final reject = pValue < alpha;

    return '''
Z-TEST (ONE SAMPLE)
══════════════════

Hypotheses:
  H₀: μ = $mu0
  H₁: μ ${_alternativeSymbol()} $mu0

Test Statistic:
  z = (x̄ - μ₀) / (σ / √n)
  z = ($xBar - $mu0) / ($sigma / √$n)
  z = ${_formatNumber(z)}

P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}
Significance Level: α = $alpha

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}

Conclusion: ${reject ? 'There is sufficient evidence to reject the null hypothesis.' : 'There is insufficient evidence to reject the null hypothesis.'}
''';
  }

  String _zTestTwoSample(double alpha) {
    final xBar1 = double.parse(_controllers['sample_mean']!.text);
    final xBar2 = double.parse(_controllers['sample_mean2']!.text);
    final sigma1 = double.parse(_controllers['pop_std']!.text);
    final sigma2 = double.parse(_controllers['sample_std2']!.text);
    final n1 = int.parse(_controllers['sample_size']!.text);
    final n2 = int.parse(_controllers['sample_size2']!.text);

    final z =
        (xBar1 - xBar2) /
        math.sqrt(sigma1 * sigma1 / n1 + sigma2 * sigma2 / n2);
    final pValue = _zPValue(z, _alternative);
    final criticalValue = _zCritical(alpha, _alternative);
    final reject = pValue < alpha;

    return '''
Z-TEST (TWO SAMPLE)
═══════════════════

Hypotheses:
  H₀: μ₁ - μ₂ = 0
  H₁: μ₁ - μ₂ ${_alternativeSymbol()} 0

Test Statistic:
  z = ${_formatNumber(z)}

P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}
''';
  }

  String _tTestOneSample(double alpha) {
    final xBar = double.parse(_controllers['sample_mean']!.text);
    final mu0 = double.parse(_controllers['pop_mean']!.text);
    final s = double.parse(_controllers['sample_std']!.text);
    final n = int.parse(_controllers['sample_size']!.text);
    final df = n - 1;

    final t = (xBar - mu0) / (s / math.sqrt(n));
    final pValue = _tPValue(t, df.toDouble(), _alternative);
    final criticalValue = _tCritical(alpha, df.toDouble(), _alternative);
    final reject = pValue < alpha;

    return '''
T-TEST (ONE SAMPLE)
═══════════════════

Hypotheses:
  H₀: μ = $mu0
  H₁: μ ${_alternativeSymbol()} $mu0

Test Statistic:
  t = (x̄ - μ₀) / (s / √n)
  t = ${_formatNumber(t)}

Degrees of Freedom: $df
P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}
''';
  }

  String _tTestTwoSample(double alpha) {
    final xBar1 = double.parse(_controllers['sample_mean']!.text);
    final xBar2 = double.parse(_controllers['sample_mean2']!.text);
    final s1 = double.parse(_controllers['sample_std']!.text);
    final s2 = double.parse(_controllers['sample_std2']!.text);
    final n1 = int.parse(_controllers['sample_size']!.text);
    final n2 = int.parse(_controllers['sample_size2']!.text);

    final se = math.sqrt(s1 * s1 / n1 + s2 * s2 / n2);
    final t = (xBar1 - xBar2) / se;

    final v1 = s1 * s1 / n1;
    final v2 = s2 * s2 / n2;
    final df =
        ((v1 + v2) * (v1 + v2)) / (v1 * v1 / (n1 - 1) + v2 * v2 / (n2 - 1));

    final pValue = _tPValue(t, df, _alternative);
    final criticalValue = _tCritical(alpha, df, _alternative);
    final reject = pValue < alpha;

    return '''
T-TEST (TWO SAMPLE - Welch's)
═════════════════════════════

Hypotheses:
  H₀: μ₁ = μ₂
  H₁: μ₁ ${_alternativeSymbol()} μ₂

Test Statistic:
  t = ${_formatNumber(t)}

Degrees of Freedom: ${_formatNumber(df)}
P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}
''';
  }

  String _tTestPaired(double alpha) {
    final sample1 = _parseData(_controllers['sample1_data']!.text);
    final sample2 = _parseData(_controllers['sample2_data']!.text);

    if (sample1.length != sample2.length) {
      throw Exception('Samples must have equal length');
    }

    final differences = List.generate(
      sample1.length,
      (i) => sample1[i] - sample2[i],
    );
    final n = differences.length;
    final dBar = differences.reduce((a, b) => a + b) / n;
    final sd = math.sqrt(
      differences.map((d) => (d - dBar) * (d - dBar)).reduce((a, b) => a + b) /
          (n - 1),
    );
    final df = n - 1;

    final t = dBar / (sd / math.sqrt(n));
    final pValue = _tPValue(t, df.toDouble(), _alternative);
    final criticalValue = _tCritical(alpha, df.toDouble(), _alternative);
    final reject = pValue < alpha;

    return '''
T-TEST (PAIRED)
═══════════════

Hypotheses:
  H₀: μd = 0
  H₁: μd ${_alternativeSymbol()} 0

Mean Difference: ${_formatNumber(dBar)}
Std Dev of Differences: ${_formatNumber(sd)}

Test Statistic:
  t = ${_formatNumber(t)}

Degrees of Freedom: $df
P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}
''';
  }

  String _chiSquareGoF(double alpha) {
    final observed = _parseData(_controllers['observed']!.text);
    final expected = _controllers['expected']!.text.trim().isEmpty
        ? List<double>.filled(
            observed.length,
            observed.reduce((a, b) => a + b) / observed.length,
          )
        : _parseData(_controllers['expected']!.text);

    if (observed.length != expected.length) {
      throw Exception('Observed and expected must have equal length');
    }

    final df = observed.length - 1;
    var chiSquare = 0.0;
    for (var i = 0; i < observed.length; i++) {
      chiSquare +=
          (observed[i] - expected[i]) *
          (observed[i] - expected[i]) /
          expected[i];
    }

    final pValue = 1 - _chiSquareCdf(chiSquare, df.toDouble());
    final criticalValue = _chiSquareInvCdf(1 - alpha, df.toDouble());
    final reject = pValue < alpha;

    return '''
CHI-SQUARE TEST (GOODNESS OF FIT)
═════════════════════════════════

Hypotheses:
  H₀: Data follows the expected distribution
  H₁: Data does not follow the expected distribution

Observed: ${observed.map(_formatNumber).join(', ')}
Expected: ${expected.map(_formatNumber).join(', ')}

Test Statistic:
  χ² = ${_formatNumber(chiSquare)}

Degrees of Freedom: $df
P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}
''';
  }

  String _chiSquareIndependence(double alpha) {
    final rows = _controllers['contingency']!.text
        .split(';')
        .map(
          (row) => row.split(',').map((v) => double.parse(v.trim())).toList(),
        )
        .toList();

    final nRows = rows.length;
    final nCols = rows[0].length;

    final rowTotals = rows.map((row) => row.reduce((a, b) => a + b)).toList();
    final colTotals = List.generate(
      nCols,
      (j) => rows.map((row) => row[j]).reduce((a, b) => a + b),
    );
    final total = rowTotals.reduce((a, b) => a + b);

    var chiSquare = 0.0;
    for (var i = 0; i < nRows; i++) {
      for (var j = 0; j < nCols; j++) {
        final expected = rowTotals[i] * colTotals[j] / total;
        chiSquare +=
            (rows[i][j] - expected) * (rows[i][j] - expected) / expected;
      }
    }

    final df = (nRows - 1) * (nCols - 1);
    final pValue = 1 - _chiSquareCdf(chiSquare, df.toDouble());
    final criticalValue = _chiSquareInvCdf(1 - alpha, df.toDouble());
    final reject = pValue < alpha;

    return '''
CHI-SQUARE TEST (INDEPENDENCE)
══════════════════════════════

Hypotheses:
  H₀: Variables are independent
  H₁: Variables are not independent

Contingency Table: $nRows×$nCols
Total Observations: ${_formatNumber(total)}

Test Statistic:
  χ² = ${_formatNumber(chiSquare)}

Degrees of Freedom: $df
P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}
''';
  }

  String _anovaOneWay(double alpha) {
    final groups = _controllers['group_data']!.text
        .split(';')
        .map((g) => g.split(',').map((v) => double.parse(v.trim())).toList())
        .toList();

    final k = groups.length;
    final n = groups.map((g) => g.length).reduce((a, b) => a + b);

    final allValues = groups.expand((g) => g).toList();
    final grandMean = allValues.reduce((a, b) => a + b) / n;

    final groupMeans = groups
        .map((g) => g.reduce((a, b) => a + b) / g.length)
        .toList();

    var ssBetween = 0.0;
    for (var i = 0; i < k; i++) {
      ssBetween +=
          groups[i].length *
          (groupMeans[i] - grandMean) *
          (groupMeans[i] - grandMean);
    }

    var ssWithin = 0.0;
    for (var i = 0; i < k; i++) {
      for (final x in groups[i]) {
        ssWithin += (x - groupMeans[i]) * (x - groupMeans[i]);
      }
    }

    final ssTotal = ssBetween + ssWithin;
    final dfBetween = k - 1;
    final dfWithin = n - k;
    final dfTotal = n - 1;

    final msBetween = ssBetween / dfBetween;
    final msWithin = ssWithin / dfWithin;
    final f = msBetween / msWithin;

    final pValue = 1 - _fCdf(f, dfBetween.toDouble(), dfWithin.toDouble());
    final criticalValue = _fInvCdf(
      1 - alpha,
      dfBetween.toDouble(),
      dfWithin.toDouble(),
    );
    final reject = pValue < alpha;

    return '''
ONE-WAY ANOVA
═════════════

Hypotheses:
  H₀: All group means are equal
  H₁: At least one group mean differs

Number of Groups: $k
Total Observations: $n
Grand Mean: ${_formatNumber(grandMean)}

ANOVA Table:
Source       │ SS          │ df   │ MS          │ F
─────────────┼─────────────┼──────┼─────────────┼────────────
Between      │ ${_padNum(ssBetween)} │ ${dfBetween.toString().padLeft(4)} │ ${_padNum(msBetween)} │ ${_padNum(f)}
Within       │ ${_padNum(ssWithin)} │ ${dfWithin.toString().padLeft(4)} │ ${_padNum(msWithin)} │
Total        │ ${_padNum(ssTotal)} │ ${dfTotal.toString().padLeft(4)} │             │

F-Statistic: ${_formatNumber(f)}
P-Value: ${_formatNumber(pValue)}
Critical Value: ${_formatNumber(criticalValue)}

Decision: ${reject ? 'REJECT H₀' : 'FAIL TO REJECT H₀'}

${reject ? 'At least one group mean is significantly different.' : 'No significant difference between group means.'}
''';
  }

  String _padNum(double n) => _formatNumber(n).padLeft(11);

  List<double> _parseData(String text) {
    return text
        .split(RegExp(r'[,\s\n]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => double.parse(s.trim()))
        .toList();
  }

  String _alternativeSymbol() {
    switch (_alternative) {
      case 'less':
        return '<';
      case 'greater':
        return '>';
      default:
        return '≠';
    }
  }

  double _zPValue(double z, String alternative) {
    final cdf = _normalCdf(z.abs(), 0, 1);
    switch (alternative) {
      case 'less':
        return _normalCdf(z, 0, 1);
      case 'greater':
        return 1 - _normalCdf(z, 0, 1);
      default:
        return 2 * (1 - cdf);
    }
  }

  double _zCritical(double alpha, String alternative) {
    switch (alternative) {
      case 'less':
        return _normalInvCdf(alpha, 0, 1);
      case 'greater':
        return _normalInvCdf(1 - alpha, 0, 1);
      default:
        return _normalInvCdf(1 - alpha / 2, 0, 1);
    }
  }

  double _tPValue(double t, double df, String alternative) {
    final cdf = _tCdf(t, df);
    switch (alternative) {
      case 'less':
        return cdf;
      case 'greater':
        return 1 - cdf;
      default:
        return 2 * math.min(cdf, 1 - cdf);
    }
  }

  double _tCritical(double alpha, double df, String alternative) {
    double target;
    switch (alternative) {
      case 'less':
        target = alpha;
      case 'greater':
        target = 1 - alpha;
      default:
        target = 1 - alpha / 2;
    }

    var t = _normalInvCdf(target, 0, 1);
    for (var i = 0; i < 20; i++) {
      final cdf = _tCdf(t, df);
      final pdf = _tPdf(t, df);
      if (pdf.abs() < 1e-15) break;
      t -= (cdf - target) / pdf;
    }
    return alternative == 'less' ? t : (alternative == 'greater' ? t : t.abs());
  }

  double _normalCdf(double x, double mean, double std) {
    final z = (x - mean) / (std * math.sqrt(2));
    return 0.5 * (1 + _erf(z));
  }

  double _normalInvCdf(double p, double mean, double std) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;
    if (p == 0.5) return mean;

    final t = p < 0.5
        ? math.sqrt(-2 * math.log(p))
        : math.sqrt(-2 * math.log(1 - p));
    const c0 = 2.515517;
    const c1 = 0.802853;
    const c2 = 0.010328;
    const d1 = 1.432788;
    const d2 = 0.189269;
    const d3 = 0.001308;

    var z =
        t -
        (c0 + c1 * t + c2 * t * t) / (1 + d1 * t + d2 * t * t + d3 * t * t * t);
    if (p < 0.5) z = -z;

    return mean + std * z;
  }

  double _erf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  double _tPdf(double t, double df) {
    return _gammaFunc((df + 1) / 2) /
        (math.sqrt(df * math.pi) * _gammaFunc(df / 2)) *
        math.pow(1 + t * t / df, -(df + 1) / 2);
  }

  double _tCdf(double t, double df) {
    const n = 1000;
    final h = (t - (-10)) / n;
    var sum = (_tPdf(-10, df) + _tPdf(t, df)) / 2;
    for (var i = 1; i < n; i++) {
      sum += _tPdf(-10 + i * h, df);
    }
    return (sum * h).clamp(0.0, 1.0);
  }

  double _chiSquareCdf(double x, double k) {
    if (x <= 0) return 0;
    return _lowerIncompleteGamma(k / 2, x / 2) / _gammaFunc(k / 2);
  }

  double _chiSquareInvCdf(double p, double k) {
    var x = k;
    for (var i = 0; i < 50; i++) {
      final cdf = _chiSquareCdf(x, k);
      final pdf = _chiSquarePdf(x, k);
      if (pdf.abs() < 1e-15) break;
      final newX = x - (cdf - p) / pdf;
      if ((newX - x).abs() < 1e-10) break;
      x = math.max(0.001, newX);
    }
    return x;
  }

  double _chiSquarePdf(double x, double k) {
    if (x < 0) return 0;
    return math.pow(x, k / 2 - 1) *
        math.exp(-x / 2) /
        (math.pow(2, k / 2) * _gammaFunc(k / 2));
  }

  double _fCdf(double x, double d1, double d2) {
    if (x <= 0) return 0;
    return _incompleteBeta(d1 * x / (d1 * x + d2), d1 / 2, d2 / 2);
  }

  double _fInvCdf(double p, double d1, double d2) {
    var x = 1.0;
    for (var i = 0; i < 50; i++) {
      final cdf = _fCdf(x, d1, d2);
      final pdf = _fPdf(x, d1, d2);
      if (pdf.abs() < 1e-15) break;
      final newX = x - (cdf - p) / pdf;
      if ((newX - x).abs() < 1e-10) break;
      x = math.max(0.001, newX);
    }
    return x;
  }

  double _fPdf(double x, double d1, double d2) {
    if (x < 0) return 0;
    return math.sqrt(
          math.pow(d1 * x, d1) *
              math.pow(d2, d2) /
              math.pow(d1 * x + d2, d1 + d2),
        ) /
        (x * _betaFunc(d1 / 2, d2 / 2));
  }

  double _gammaFunc(double z) {
    if (z < 0.5) {
      return math.pi / (math.sin(math.pi * z) * _gammaFunc(1 - z));
    }
    z -= 1;
    const g = 7;
    const c = [
      0.99999999999980993,
      676.5203681218851,
      -1259.1392167224028,
      771.32342877765313,
      -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
      9.9843695780195716e-6,
      1.5056327351493116e-7,
    ];
    var x = c[0];
    for (var i = 1; i < g + 2; i++) {
      x += c[i] / (z + i);
    }
    final t = z + g + 0.5;
    return math.sqrt(2 * math.pi) * math.pow(t, z + 0.5) * math.exp(-t) * x;
  }

  double _betaFunc(double a, double b) {
    return _gammaFunc(a) * _gammaFunc(b) / _gammaFunc(a + b);
  }

  double _lowerIncompleteGamma(double a, double x) {
    if (x == 0) return 0;
    var sum = 0.0;
    var term = 1.0 / a;
    sum = term;
    for (var n = 1; n < 100; n++) {
      term *= x / (a + n);
      sum += term;
      if (term.abs() < 1e-10) break;
    }
    return math.pow(x, a) * math.exp(-x) * sum;
  }

  double _incompleteBeta(double x, double a, double b) {
    const n = 1000;
    final h = x / n;
    var sum = 0.0;
    for (var i = 1; i < n; i++) {
      final t = i * h;
      sum += math.pow(t, a - 1) * math.pow(1 - t, b - 1);
    }
    return h * sum / _betaFunc(a, b);
  }

  String _formatNumber(double n) {
    if (n.isNaN) return 'N/A';
    if (n.isInfinite) return n > 0 ? '∞' : '-∞';
    if (n == n.toInt().toDouble() && n.abs() < 1e10)
      return n.toInt().toString();
    return n
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _testType,
            decoration: const InputDecoration(
              labelText: 'Test Type',
              border: OutlineInputBorder(),
            ),
            items: _testTypes.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _testType = v ?? 'z_one_sample'),
          ),
          const SizedBox(height: 16),
          if (!_testType.startsWith('chi') && !_testType.startsWith('anova'))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'two_sided', label: Text('≠')),
                  ButtonSegment(value: 'less', label: Text('<')),
                  ButtonSegment(value: 'greater', label: Text('>')),
                ],
                selected: {_alternative},
                onSelectionChanged: (s) =>
                    setState(() => _alternative = s.first),
              ),
            ),
          ..._buildInputFields(),
          const SizedBox(height: 8),
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
              label: const Text('Run Test'),
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
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
