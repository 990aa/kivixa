import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Statistics tab - Descriptive stats, distributions, regression, hypothesis testing
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
              _HypothesisTest(),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatNumber(double n) {
  if (n.isNaN) return 'N/A';
  if (n.isInfinite) return n > 0 ? '∞' : '-∞';
  if (n == n.toInt().toDouble() && n.abs() < 1e10) return n.toInt().toString();
  return n
      .toStringAsFixed(6)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

List<double> _parseData(String text) {
  return text
      .split(RegExp(r'[,\s]+'))
      .where((s) => s.trim().isNotEmpty)
      .map((s) => double.parse(s.trim()))
      .toList();
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
  final _dataCtrl = TextEditingController(
    text: '1, 2, 3, 4, 5, 6, 7, 8, 9, 10',
  );
  Map<String, String> _results = {};
  var _isComputing = false;
  var _error = '';

  @override
  void dispose() {
    _dataCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _error = '';
    });

    try {
      final data = _parseData(_dataCtrl.text);
      if (data.isEmpty) {
        throw Exception('No data provided');
      }

      final n = data.length;
      final sorted = List<double>.from(data)..sort();

      // Mean
      final sum = data.reduce((a, b) => a + b);
      final mean = sum / n;

      // Median
      double median;
      if (n % 2 == 0) {
        median = (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
      } else {
        median = sorted[n ~/ 2];
      }

      // Mode
      final freq = <double, int>{};
      for (final v in data) {
        freq[v] = (freq[v] ?? 0) + 1;
      }
      final maxFreq = freq.values.reduce(math.max);
      final modes = freq.entries
          .where((e) => e.value == maxFreq)
          .map((e) => e.key)
          .toList();
      final modeStr = maxFreq == 1
          ? 'None'
          : modes.map((m) => _formatNumber(m)).join(', ');

      // Variance and Std Dev (sample)
      final variance =
          data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          (n - 1);
      final stdDev = math.sqrt(variance);

      // Skewness
      final m3 =
          data.map((x) => math.pow(x - mean, 3)).reduce((a, b) => a + b) / n;
      final skewness = m3 / math.pow(stdDev, 3);

      // Kurtosis (excess)
      final m4 =
          data.map((x) => math.pow(x - mean, 4)).reduce((a, b) => a + b) / n;
      final kurtosis = m4 / math.pow(variance, 2) - 3;

      // Quartiles
      final q1Idx = (n - 1) * 0.25;
      final q1 =
          sorted[q1Idx.floor()] +
          (q1Idx - q1Idx.floor()) *
              (sorted[q1Idx.ceil()] - sorted[q1Idx.floor()]);
      final q3Idx = (n - 1) * 0.75;
      final q3 =
          sorted[q3Idx.floor()] +
          (q3Idx - q3Idx.floor()) *
              (sorted[q3Idx.ceil()] - sorted[q3Idx.floor()]);
      final iqr = q3 - q1;

      setState(() {
        _results = {
          'Count': n.toString(),
          'Sum': _formatNumber(sum),
          'Mean': _formatNumber(mean),
          'Median': _formatNumber(median),
          'Mode': modeStr,
          'Minimum': _formatNumber(sorted.first),
          'Maximum': _formatNumber(sorted.last),
          'Range': _formatNumber(sorted.last - sorted.first),
          'Variance (s²)': _formatNumber(variance),
          'Std Dev (s)': _formatNumber(stdDev),
          'Skewness': _formatNumber(skewness),
          'Kurtosis': _formatNumber(kurtosis),
          'Q1 (25%)': _formatNumber(q1),
          'Q3 (75%)': _formatNumber(q3),
          'IQR': _formatNumber(iqr),
        };
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _results = {};
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
            'Descriptive Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Enter comma-separated values:'),
          const SizedBox(height: 8),

          TextField(
            controller: _dataCtrl,
            decoration: const InputDecoration(
              labelText: 'Data',
              hintText: '1, 2, 3, 4, 5, ...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
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
                  : const Icon(Icons.analytics),
              label: const Text('Compute Statistics'),
            ),
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

          if (_results.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _results.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          e.value,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DISTRIBUTION CALCULATOR
// ============================================================================

class _DistributionCalculator extends StatefulWidget {
  const _DistributionCalculator();

  @override
  State<_DistributionCalculator> createState() =>
      _DistributionCalculatorState();
}

class _DistributionCalculatorState extends State<_DistributionCalculator> {
  var _distribution = 'Normal';
  final _param1Ctrl = TextEditingController(text: '0');
  final _param2Ctrl = TextEditingController(text: '1');
  final _xCtrl = TextEditingController(text: '1');
  var _operation = 'pdf';
  var _result = '';
  var _isComputing = false;

  final _distributions = ['Normal', 'Uniform', 'Exponential', 'Poisson'];

  @override
  void dispose() {
    _param1Ctrl.dispose();
    _param2Ctrl.dispose();
    _xCtrl.dispose();
    super.dispose();
  }

  String get _param1Label {
    switch (_distribution) {
      case 'Normal':
        return 'Mean (μ)';
      case 'Uniform':
        return 'Min (a)';
      case 'Exponential':
        return 'Rate (λ)';
      case 'Poisson':
        return 'Rate (λ)';
      default:
        return 'Param 1';
    }
  }

  String? get _param2Label {
    switch (_distribution) {
      case 'Normal':
        return 'Std Dev (σ)';
      case 'Uniform':
        return 'Max (b)';
      default:
        return null;
    }
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final p1 = double.parse(_param1Ctrl.text);
      final p2 = _param2Label != null ? double.parse(_param2Ctrl.text) : 0.0;
      final x = double.parse(_xCtrl.text);

      double result;

      switch (_operation) {
        case 'pdf':
          result = _computePdf(_distribution, p1, p2, x);
        case 'cdf':
          result = _computeCdf(_distribution, p1, p2, x);
        case 'mean':
          result = _computeMean(_distribution, p1, p2);
        case 'variance':
          result = _computeVariance(_distribution, p1, p2);
        default:
          result = double.nan;
      }

      setState(() {
        _result =
            '$_operation($_distribution, x=$x) = ${_formatNumber(result)}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  double _computePdf(String dist, double p1, double p2, double x) {
    switch (dist) {
      case 'Normal':
        final mu = p1, sigma = p2;
        return (1 / (sigma * math.sqrt(2 * math.pi))) *
            math.exp(-0.5 * math.pow((x - mu) / sigma, 2));
      case 'Uniform':
        final a = p1, b = p2;
        return (x >= a && x <= b) ? 1 / (b - a) : 0;
      case 'Exponential':
        final lambda = p1;
        return x >= 0 ? lambda * math.exp(-lambda * x) : 0;
      case 'Poisson':
        final lambda = p1;
        final k = x.toInt();
        if (k < 0) return 0;
        return math.exp(-lambda) * math.pow(lambda, k) / _factorial(k);
      default:
        return double.nan;
    }
  }

  double _computeCdf(String dist, double p1, double p2, double x) {
    switch (dist) {
      case 'Normal':
        final mu = p1, sigma = p2;
        // Standard normal CDF using error function approximation
        return 0.5 * (1 + _erf((x - mu) / (sigma * math.sqrt(2))));
      case 'Uniform':
        final a = p1, b = p2;
        if (x < a) return 0;
        if (x > b) return 1;
        return (x - a) / (b - a);
      case 'Exponential':
        final lambda = p1;
        return x >= 0 ? 1 - math.exp(-lambda * x) : 0;
      case 'Poisson':
        final lambda = p1;
        final k = x.floor();
        if (k < 0) return 0;
        var sum = 0.0;
        for (var i = 0; i <= k; i++) {
          sum += math.exp(-lambda) * math.pow(lambda, i) / _factorial(i);
        }
        return sum;
      default:
        return double.nan;
    }
  }

  double _computeMean(String dist, double p1, double p2) {
    switch (dist) {
      case 'Normal':
        return p1;
      case 'Uniform':
        return (p1 + p2) / 2;
      case 'Exponential':
        return 1 / p1;
      case 'Poisson':
        return p1;
      default:
        return double.nan;
    }
  }

  double _computeVariance(String dist, double p1, double p2) {
    switch (dist) {
      case 'Normal':
        return p2 * p2;
      case 'Uniform':
        return math.pow(p2 - p1, 2) / 12;
      case 'Exponential':
        return 1 / (p1 * p1);
      case 'Poisson':
        return p1;
      default:
        return double.nan;
    }
  }

  double _erf(double x) {
    // Approximation of error function
    final a1 = 0.254829592;
    final a2 = -0.284496736;
    final a3 = 1.421413741;
    final a4 = -1.453152027;
    final a5 = 1.061405429;
    final p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  double _factorial(int n) {
    if (n <= 1) return 1;
    var result = 1.0;
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
            'Probability Distributions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _distribution,
            decoration: const InputDecoration(
              labelText: 'Distribution',
              border: OutlineInputBorder(),
            ),
            items: _distributions
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _distribution = v ?? 'Normal'),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _param1Ctrl,
                  decoration: InputDecoration(
                    labelText: _param1Label,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              if (_param2Label != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _param2Ctrl,
                    decoration: InputDecoration(
                      labelText: _param2Label,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _xCtrl,
            decoration: const InputDecoration(
              labelText: 'x value',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('PDF'),
                selected: _operation == 'pdf',
                onSelected: (_) => setState(() => _operation = 'pdf'),
              ),
              ChoiceChip(
                label: const Text('CDF'),
                selected: _operation == 'cdf',
                onSelected: (_) => setState(() => _operation = 'cdf'),
              ),
              ChoiceChip(
                label: const Text('Mean'),
                selected: _operation == 'mean',
                onSelected: (_) => setState(() => _operation = 'mean'),
              ),
              ChoiceChip(
                label: const Text('Variance'),
                selected: _operation == 'variance',
                onSelected: (_) => setState(() => _operation = 'variance'),
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
              label: const Text('Compute'),
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

// ============================================================================
// REGRESSION CALCULATOR
// ============================================================================

class _RegressionCalculator extends StatefulWidget {
  const _RegressionCalculator();

  @override
  State<_RegressionCalculator> createState() => _RegressionCalculatorState();
}

class _RegressionCalculatorState extends State<_RegressionCalculator> {
  final _xDataCtrl = TextEditingController(text: '1, 2, 3, 4, 5');
  final _yDataCtrl = TextEditingController(text: '2.1, 3.9, 6.1, 8.0, 10.2');
  var _regressionType = 'linear';
  var _polyDegree = 2;
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _xDataCtrl.dispose();
    _yDataCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final xData = _parseData(_xDataCtrl.text);
      final yData = _parseData(_yDataCtrl.text);

      if (xData.length != yData.length) {
        throw Exception('X and Y must have the same number of values');
      }
      if (xData.length < 2) {
        throw Exception('Need at least 2 data points');
      }

      final n = xData.length;

      if (_regressionType == 'linear') {
        // Linear regression: y = ax + b
        final sumX = xData.reduce((a, b) => a + b);
        final sumY = yData.reduce((a, b) => a + b);
        final sumXY = List.generate(
          n,
          (i) => xData[i] * yData[i],
        ).reduce((a, b) => a + b);
        final sumX2 = xData.map((x) => x * x).reduce((a, b) => a + b);

        final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        final intercept = (sumY - slope * sumX) / n;

        // R² calculation
        final yMean = sumY / n;
        final ssTot = yData
            .map((y) => math.pow(y - yMean, 2))
            .reduce((a, b) => a + b);
        final ssRes = List.generate(
          n,
          (i) => math.pow(yData[i] - (slope * xData[i] + intercept), 2),
        ).reduce((a, b) => a + b);
        final r2 = 1 - ssRes / ssTot;

        final interceptSign = intercept >= 0 ? '+' : '-';
        setState(() {
          _result =
              'y = ${_formatNumber(slope)}x $interceptSign ${_formatNumber(intercept.abs())}\nR² = ${_formatNumber(r2)}';
          _isComputing = false;
        });
      } else {
        // Polynomial regression using normal equations
        final degree = _polyDegree;

        // Build Vandermonde matrix
        final matrix = List.generate(
          n,
          (i) => List.generate(
            degree + 1,
            (j) => math.pow(xData[i], j).toDouble(),
          ),
        );

        // Solve normal equations: (X'X)β = X'y
        final xtx = List.generate(
          degree + 1,
          (i) => List.generate(degree + 1, (j) {
            var sum = 0.0;
            for (var k = 0; k < n; k++) sum += matrix[k][i] * matrix[k][j];
            return sum;
          }),
        );

        final xty = List.generate(degree + 1, (i) {
          var sum = 0.0;
          for (var k = 0; k < n; k++) sum += matrix[k][i] * yData[k];
          return sum;
        });

        // Gaussian elimination
        final coeffs = _solveLinearSystem(xtx, xty);

        // Build polynomial string
        final terms = <String>[];
        for (var i = degree; i >= 0; i--) {
          final c = coeffs[i];
          if (c.abs() < 1e-10) continue;

          String term;
          if (i == 0) {
            term = _formatNumber(c);
          } else if (i == 1) {
            term = '${_formatNumber(c)}x';
          } else {
            term = '${_formatNumber(c)}x^$i';
          }
          terms.add(term);
        }

        // R² calculation
        final yMean = yData.reduce((a, b) => a + b) / n;
        final ssTot = yData
            .map((y) => math.pow(y - yMean, 2))
            .reduce((a, b) => a + b);
        final predicted = xData.map((x) {
          var y = 0.0;
          for (var i = 0; i <= degree; i++) y += coeffs[i] * math.pow(x, i);
          return y;
        }).toList();
        final ssRes = List.generate(
          n,
          (i) => math.pow(yData[i] - predicted[i], 2),
        ).reduce((a, b) => a + b);
        final r2 = 1 - ssRes / ssTot;

        setState(() {
          _result =
              'y = ${terms.join(' + ').replaceAll('+ -', '- ')}\nR² = ${_formatNumber(r2)}';
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

  List<double> _solveLinearSystem(List<List<double>> matrix, List<double> b) {
    final n = b.length;
    final aug = List.generate(n, (i) => [...matrix[i], b[i]]);

    // Forward elimination
    for (var col = 0; col < n; col++) {
      var maxRow = col;
      for (var row = col + 1; row < n; row++) {
        if (aug[row][col].abs() > aug[maxRow][col].abs()) maxRow = row;
      }
      final temp = aug[col];
      aug[col] = aug[maxRow];
      aug[maxRow] = temp;

      for (var row = col + 1; row < n; row++) {
        final f = aug[row][col] / aug[col][col];
        for (var j = col; j <= n; j++) aug[row][j] -= f * aug[col][j];
      }
    }

    // Back substitution
    final x = List<double>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      x[i] = aug[i][n];
      for (var j = i + 1; j < n; j++) x[i] -= aug[i][j] * x[j];
      x[i] /= aug[i][i];
    }

    return x;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regression Analysis',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _xDataCtrl,
            decoration: const InputDecoration(
              labelText: 'X values (comma-separated)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _yDataCtrl,
            decoration: const InputDecoration(
              labelText: 'Y values (comma-separated)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              ChoiceChip(
                label: const Text('Linear'),
                selected: _regressionType == 'linear',
                onSelected: (_) => setState(() => _regressionType = 'linear'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Polynomial'),
                selected: _regressionType == 'polynomial',
                onSelected: (_) =>
                    setState(() => _regressionType = 'polynomial'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_regressionType == 'polynomial')
            Row(
              children: [
                const Text('Degree: '),
                Slider(
                  value: _polyDegree.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: '$_polyDegree',
                  onChanged: (v) => setState(() => _polyDegree = v.round()),
                ),
                Text('$_polyDegree'),
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
                  : const Icon(Icons.show_chart),
              label: const Text('Fit Regression'),
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

// ============================================================================
// HYPOTHESIS TESTING
// ============================================================================

class _HypothesisTest extends StatefulWidget {
  const _HypothesisTest();

  @override
  State<_HypothesisTest> createState() => _HypothesisTestState();
}

class _HypothesisTestState extends State<_HypothesisTest> {
  var _testType = 'one_sample_t';
  final _dataCtrl = TextEditingController(text: '5.1, 5.2, 4.9, 5.3, 5.0, 5.1');
  final _hypothesizedMeanCtrl = TextEditingController(text: '5.0');
  final _data2Ctrl = TextEditingController(text: '4.8, 4.9, 5.0, 5.1, 4.7');
  var _alpha = 0.05;
  var _alternative = 'two_sided';
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _dataCtrl.dispose();
    _hypothesizedMeanCtrl.dispose();
    _data2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final data1 = _parseData(_dataCtrl.text);
      if (data1.length < 2) throw Exception('Need at least 2 data points');

      final n1 = data1.length;
      final mean1 = data1.reduce((a, b) => a + b) / n1;
      final var1 =
          data1.map((x) => math.pow(x - mean1, 2)).reduce((a, b) => a + b) /
          (n1 - 1);
      final std1 = math.sqrt(var1);

      double tStatistic;
      int df;

      if (_testType == 'one_sample_t') {
        final mu0 = double.parse(_hypothesizedMeanCtrl.text);
        tStatistic = (mean1 - mu0) / (std1 / math.sqrt(n1));
        df = n1 - 1;
      } else {
        // Two-sample t-test
        final data2 = _parseData(_data2Ctrl.text);
        if (data2.length < 2)
          throw Exception('Need at least 2 data points in sample 2');

        final n2 = data2.length;
        final mean2 = data2.reduce((a, b) => a + b) / n2;
        final var2 =
            data2.map((x) => math.pow(x - mean2, 2)).reduce((a, b) => a + b) /
            (n2 - 1);

        // Welch's t-test
        tStatistic = (mean1 - mean2) / math.sqrt(var1 / n1 + var2 / n2);
        df =
            ((var1 / n1 + var2 / n2) *
                    (var1 / n1 + var2 / n2) /
                    (math.pow(var1 / n1, 2) / (n1 - 1) +
                        math.pow(var2 / n2, 2) / (n2 - 1)))
                .floor();
      }

      // Approximate p-value using Student's t distribution
      final pValue = _tDistributionPValue(tStatistic, df, _alternative);

      final conclusion = pValue < _alpha
          ? 'Reject H₀ at α = $_alpha'
          : 'Fail to reject H₀ at α = $_alpha';

      setState(() {
        _result =
            't-statistic = ${_formatNumber(tStatistic)}\n'
            'df = $df\n'
            'p-value = ${_formatNumber(pValue)}\n\n'
            '$conclusion';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  double _tDistributionPValue(double t, int df, String alternative) {
    // Approximation of t-distribution CDF using normal approximation for large df
    // For small df, use a better approximation

    double cdf(double x) {
      if (df > 30) {
        // Use normal approximation
        return 0.5 * (1 + _erf(x / math.sqrt(2)));
      }

      // Use regularized incomplete beta function approximation
      final x2 = df / (df + x * x);
      final a = df / 2.0;
      final b = 0.5;

      if (x >= 0) {
        return 1 - 0.5 * _incompleteBeta(x2, a, b);
      } else {
        return 0.5 * _incompleteBeta(x2, a, b);
      }
    }

    switch (alternative) {
      case 'two_sided':
        return 2 * (1 - cdf(t.abs()));
      case 'less':
        return cdf(t);
      case 'greater':
        return 1 - cdf(t);
      default:
        return 2 * (1 - cdf(t.abs()));
    }
  }

  double _erf(double x) {
    final a1 = 0.254829592;
    final a2 = -0.284496736;
    final a3 = 1.421413741;
    final a4 = -1.453152027;
    final a5 = 1.061405429;
    final p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  double _incompleteBeta(double x, double a, double b) {
    // Simple approximation of regularized incomplete beta function
    if (x <= 0) return 0;
    if (x >= 1) return 1;

    // Use continued fraction approximation
    final bt = math.exp(
      _lnGamma(a + b) -
          _lnGamma(a) -
          _lnGamma(b) +
          a * math.log(x) +
          b * math.log(1 - x),
    );

    if (x < (a + 1) / (a + b + 2)) {
      return bt * _betaCf(x, a, b) / a;
    } else {
      return 1 - bt * _betaCf(1 - x, b, a) / b;
    }
  }

  double _betaCf(double x, double a, double b) {
    const maxIter = 100;
    const eps = 1e-10;

    var c = 1.0;
    var d = 1 - (a + b) * x / (a + 1);
    if (d.abs() < 1e-30) d = 1e-30;
    d = 1 / d;
    var h = d;

    for (var m = 1; m <= maxIter; m++) {
      final m2 = 2 * m;

      var aa = m * (b - m) * x / ((a + m2 - 1) * (a + m2));
      d = 1 + aa * d;
      if (d.abs() < 1e-30) d = 1e-30;
      c = 1 + aa / c;
      if (c.abs() < 1e-30) c = 1e-30;
      d = 1 / d;
      h *= d * c;

      aa = -(a + m) * (a + b + m) * x / ((a + m2) * (a + m2 + 1));
      d = 1 + aa * d;
      if (d.abs() < 1e-30) d = 1e-30;
      c = 1 + aa / c;
      if (c.abs() < 1e-30) c = 1e-30;
      d = 1 / d;
      final del = d * c;
      h *= del;

      if ((del - 1).abs() < eps) break;
    }

    return h;
  }

  double _lnGamma(double x) {
    // Lanczos approximation
    final g = 7;
    final c = [
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

    if (x < 0.5) {
      return math.log(math.pi / math.sin(math.pi * x)) - _lnGamma(1 - x);
    }

    x -= 1;
    var a = c[0];
    for (var i = 1; i < g + 2; i++) {
      a += c[i] / (x + i);
    }

    final t = x + g + 0.5;
    return 0.5 * math.log(2 * math.pi) +
        (x + 0.5) * math.log(t) -
        t +
        math.log(a);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hypothesis Testing',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _testType,
            decoration: const InputDecoration(
              labelText: 'Test Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'one_sample_t',
                child: Text('One-sample t-test'),
              ),
              DropdownMenuItem(
                value: 'two_sample_t',
                child: Text('Two-sample t-test (Welch)'),
              ),
            ],
            onChanged: (v) => setState(() => _testType = v ?? 'one_sample_t'),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _dataCtrl,
            decoration: InputDecoration(
              labelText: _testType == 'two_sample_t'
                  ? 'Sample 1 (comma-separated)'
                  : 'Data (comma-separated)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          if (_testType == 'one_sample_t')
            TextField(
              controller: _hypothesizedMeanCtrl,
              decoration: const InputDecoration(
                labelText: 'Hypothesized mean (μ₀)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),

          if (_testType == 'two_sample_t')
            TextField(
              controller: _data2Ctrl,
              decoration: const InputDecoration(
                labelText: 'Sample 2 (comma-separated)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          const SizedBox(height: 16),

          const Text('Alternative hypothesis:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Two-sided'),
                selected: _alternative == 'two_sided',
                onSelected: (_) => setState(() => _alternative = 'two_sided'),
              ),
              ChoiceChip(
                label: const Text('Less than'),
                selected: _alternative == 'less',
                onSelected: (_) => setState(() => _alternative = 'less'),
              ),
              ChoiceChip(
                label: const Text('Greater than'),
                selected: _alternative == 'greater',
                onSelected: (_) => setState(() => _alternative = 'greater'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('α = '),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0.01, label: Text('0.01')),
                  ButtonSegment(value: 0.05, label: Text('0.05')),
                  ButtonSegment(value: 0.10, label: Text('0.10')),
                ],
                selected: {_alpha},
                onSelectionChanged: (s) => setState(() => _alpha = s.first),
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
                  : const Icon(Icons.science),
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
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
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
