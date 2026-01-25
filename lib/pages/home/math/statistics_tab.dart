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

class _DescriptiveStats extends StatefulWidget {
  const _DescriptiveStats();

  @override
  State<_DescriptiveStats> createState() => _DescriptiveStatsState();
}

class _DescriptiveStatsState extends State<_DescriptiveStats> {
  final _dataCtrl = TextEditingController(
    text: '1, 2, 3, 4, 5, 6, 7, 8, 9, 10',
  );
  Map<String, double> _results = {};
  bool _isComputing = false;

  @override
  void dispose() {
    _dataCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend api.compute_statistics
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _results = {
        'Mean': 5.5,
        'Median': 5.5,
        'Mode': double.nan,
        'Variance': 8.25,
        'Std Dev': 2.872,
        'Skewness': 0.0,
        'Kurtosis': -1.2,
        'Min': 1.0,
        'Max': 10.0,
        'Range': 9.0,
        'Count': 10.0,
      };
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

          if (_results.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _results.entries.map((e) {
                  final value = e.value.isNaN
                      ? 'N/A'
                      : e.value.toStringAsFixed(4);
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
                          value,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DistributionCalculator extends StatefulWidget {
  const _DistributionCalculator();

  @override
  State<_DistributionCalculator> createState() =>
      _DistributionCalculatorState();
}

class _DistributionCalculatorState extends State<_DistributionCalculator> {
  String _distribution = 'Normal';
  final _param1Ctrl = TextEditingController(text: '0');
  final _param2Ctrl = TextEditingController(text: '1');
  final _xCtrl = TextEditingController(text: '1');
  String _operation = 'pdf';
  String _result = '';
  bool _isComputing = false;

  final _distributions = [
    'Normal',
    'Uniform',
    'Exponential',
    'ChiSquared',
    'StudentsT',
    'Binomial',
    'Poisson',
  ];

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
      case 'ChiSquared':
        return 'Degrees of freedom (k)';
      case 'StudentsT':
        return 'Degrees of freedom (ν)';
      case 'Binomial':
        return 'Trials (n)';
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
      case 'Binomial':
        return 'Probability (p)';
      default:
        return null;
    }
  }

  Future<void> _compute() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend api.distribution_compute
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _result =
          '$_operation($_distribution, x=${_xCtrl.text}) = 0.2420 (placeholder)';
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
                label: const Text('Quantile'),
                selected: _operation == 'quantile',
                onSelected: (_) => setState(() => _operation = 'quantile'),
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

class _RegressionCalculator extends StatefulWidget {
  const _RegressionCalculator();

  @override
  State<_RegressionCalculator> createState() => _RegressionCalculatorState();
}

class _RegressionCalculatorState extends State<_RegressionCalculator> {
  final _xDataCtrl = TextEditingController(text: '1, 2, 3, 4, 5');
  final _yDataCtrl = TextEditingController(text: '2.1, 3.9, 6.1, 8.0, 10.2');
  String _regressionType = 'linear';
  int _polyDegree = 2;
  String _result = '';
  bool _isComputing = false;

  @override
  void dispose() {
    _xDataCtrl.dispose();
    _yDataCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend api.linear_regression or api.polynomial_regression
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      if (_regressionType == 'linear') {
        _result = 'y = 2.00x + 0.02\nR² = 0.9997 (placeholder)';
      } else {
        _result = 'y = 0.01x² + 1.98x + 0.04\nR² = 0.9999 (placeholder)';
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
                  max: 10,
                  divisions: 8,
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

class _HypothesisTest extends StatefulWidget {
  const _HypothesisTest();

  @override
  State<_HypothesisTest> createState() => _HypothesisTestState();
}

class _HypothesisTestState extends State<_HypothesisTest> {
  String _testType = 'one_sample_t';
  final _dataCtrl = TextEditingController(text: '5.1, 5.2, 4.9, 5.3, 5.0, 5.1');
  final _hypothesizedMeanCtrl = TextEditingController(text: '5.0');
  final _data2Ctrl = TextEditingController(text: '4.8, 4.9, 5.0, 5.1, 4.7');
  String _alternative = 'two_sided';
  String _result = '';
  bool _isComputing = false;

  @override
  void dispose() {
    _dataCtrl.dispose();
    _hypothesizedMeanCtrl.dispose();
    _data2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend api.t_test or api.two_sample_t_test
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _result =
          't-statistic = 2.135\np-value = 0.086\n\nFail to reject H₀ at α = 0.05 (placeholder)';
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
                child: Text('Two-sample t-test'),
              ),
              DropdownMenuItem(
                value: 'chi_squared',
                child: Text('Chi-squared test'),
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
          Row(
            children: [
              ChoiceChip(
                label: const Text('Two-sided'),
                selected: _alternative == 'two_sided',
                onSelected: (_) => setState(() => _alternative = 'two_sided'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Less than'),
                selected: _alternative == 'less',
                onSelected: (_) => setState(() => _alternative = 'less'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Greater than'),
                selected: _alternative == 'greater',
                onSelected: (_) => setState(() => _alternative = 'greater'),
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
