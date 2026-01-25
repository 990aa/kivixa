import 'package:flutter/material.dart';

/// Algebra tab - Matrix operations, complex numbers, equation solving
/// Features: Matrix calculator, LU/QR/SVD decomposition, complex arithmetic
class MathAlgebraTab extends StatefulWidget {
  const MathAlgebraTab({super.key});

  @override
  State<MathAlgebraTab> createState() => _MathAlgebraTabState();
}

class _MathAlgebraTabState extends State<MathAlgebraTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Matrix'),
            Tab(text: 'Complex'),
            Tab(text: 'Equations'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _MatrixCalculator(),
              _ComplexCalculator(),
              _EquationSolver(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatrixCalculator extends StatefulWidget {
  const _MatrixCalculator();

  @override
  State<_MatrixCalculator> createState() => _MatrixCalculatorState();
}

class _MatrixCalculatorState extends State<_MatrixCalculator> {
  var _rowsA = 3;
  var _colsA = 3;
  var _rowsB = 3;
  var _colsB = 3;
  var _operation = 'multiply';
  final List<List<TextEditingController>> _matrixA = [];
  final List<List<TextEditingController>> _matrixB = [];
  List<List<double>>? _result;
  String? _error;
  var _isComputing = false;

  @override
  void initState() {
    super.initState();
    _initMatrices();
  }

  void _initMatrices() {
    _matrixA.clear();
    _matrixB.clear();
    for (int i = 0; i < _rowsA; i++) {
      _matrixA.add(
        List.generate(_colsA, (_) => TextEditingController(text: '0')),
      );
    }
    for (int i = 0; i < _rowsB; i++) {
      _matrixB.add(
        List.generate(_colsB, (_) => TextEditingController(text: '0')),
      );
    }
  }

  @override
  void dispose() {
    for (final row in _matrixA) {
      for (final ctrl in row) {
        ctrl.dispose();
      }
    }
    for (final row in _matrixB) {
      for (final ctrl in row) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _compute() async {
    setState(() {
      _isComputing = true;
      _error = null;
    });

    try {
      // TODO: Call Rust backend
      // final aData = _getMatrixData(_matrixA, _rowsA, _colsA);
      // final bData = _getMatrixData(_matrixB, _rowsB, _colsB);
      // final result = await api.matrixOperation(aData, _rowsA, _colsA, bData, _rowsB, _colsB, _operation);

      // Placeholder
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _result = [
          [1, 0, 0],
          [0, 1, 0],
          [0, 0, 1],
        ];
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matrix A
          _buildMatrixSection('Matrix A', _matrixA, _rowsA, _colsA, (r, c) {
            setState(() {
              _rowsA = r;
              _colsA = c;
              _initMatrices();
            });
          }),
          const SizedBox(height: 16),

          // Operation selector
          Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'add', label: Text('A + B')),
                ButtonSegment(value: 'subtract', label: Text('A - B')),
                ButtonSegment(value: 'multiply', label: Text('A × B')),
                ButtonSegment(value: 'transpose', label: Text('Aᵀ')),
                ButtonSegment(value: 'inverse', label: Text('A⁻¹')),
                ButtonSegment(value: 'det', label: Text('det(A)')),
              ],
              selected: {_operation},
              onSelectionChanged: (s) => setState(() => _operation = s.first),
            ),
          ),
          const SizedBox(height: 16),

          // Matrix B (if needed)
          if (_operation == 'add' ||
              _operation == 'subtract' ||
              _operation == 'multiply')
            _buildMatrixSection('Matrix B', _matrixB, _rowsB, _colsB, (r, c) {
              setState(() {
                _rowsB = r;
                _colsB = c;
                _initMatrices();
              });
            }),

          const SizedBox(height: 24),

          // Compute button
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

          const SizedBox(height: 24),

          // Result
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),

          if (_result != null) ...[
            Text('Result:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildResultMatrix(_result!),
          ],

          const SizedBox(height: 24),

          // Decomposition section
          Text(
            'Matrix Decomposition',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('LU'), onPressed: () {}),
              ActionChip(label: const Text('QR'), onPressed: () {}),
              ActionChip(label: const Text('SVD'), onPressed: () {}),
              ActionChip(label: const Text('Cholesky'), onPressed: () {}),
              ActionChip(label: const Text('Eigenvalues'), onPressed: () {}),
              ActionChip(label: const Text('RREF'), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixSection(
    String title,
    List<List<TextEditingController>> matrix,
    int rows,
    int cols,
    void Function(int, int) onDimensionChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            // Dimension controls
            IconButton(
              icon: const Icon(Icons.remove),
              iconSize: 18,
              onPressed: rows > 1
                  ? () => onDimensionChange(rows - 1, cols)
                  : null,
            ),
            Text('$rows×$cols'),
            IconButton(
              icon: const Icon(Icons.add),
              iconSize: 18,
              onPressed: rows < 6
                  ? () => onDimensionChange(rows + 1, cols + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMatrixGrid(matrix, rows, cols),
      ],
    );
  }

  Widget _buildMatrixGrid(
    List<List<TextEditingController>> matrix,
    int rows,
    int cols,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(rows, (i) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cols, (j) {
              return Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 60,
                  child: TextField(
                    controller: matrix[i][j],
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildResultMatrix(List<List<double>> matrix) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: matrix.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((val) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  val.toStringAsFixed(4),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _ComplexCalculator extends StatefulWidget {
  const _ComplexCalculator();

  @override
  State<_ComplexCalculator> createState() => _ComplexCalculatorState();
}

class _ComplexCalculatorState extends State<_ComplexCalculator> {
  final _aRealCtrl = TextEditingController(text: '1');
  final _aImagCtrl = TextEditingController(text: '0');
  final _bRealCtrl = TextEditingController(text: '1');
  final _bImagCtrl = TextEditingController(text: '0');
  var _operation = 'add';
  var _result = '';

  @override
  void dispose() {
    _aRealCtrl.dispose();
    _aImagCtrl.dispose();
    _bRealCtrl.dispose();
    _bImagCtrl.dispose();
    super.dispose();
  }

  void _compute() {
    // TODO: Call Rust backend
    setState(() {
      _result = '(Result from Rust backend)';
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
            'Complex Number A',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aRealCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Real',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('+'),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _aImagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Imaginary',
                    border: OutlineInputBorder(),
                    suffixText: 'i',
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

          Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'add', label: Text('+')),
                ButtonSegment(value: 'sub', label: Text('-')),
                ButtonSegment(value: 'mul', label: Text('×')),
                ButtonSegment(value: 'div', label: Text('÷')),
                ButtonSegment(value: 'pow', label: Text('^')),
              ],
              selected: {_operation},
              onSelectionChanged: (s) => setState(() => _operation = s.first),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Complex Number B',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bRealCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Real',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('+'),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _bImagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Imaginary',
                    border: OutlineInputBorder(),
                    suffixText: 'i',
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
              onPressed: _compute,
              icon: const Icon(Icons.calculate),
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
                style: const TextStyle(fontSize: 20, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),
          Text('Conversions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('To Polar'), onPressed: () {}),
              ActionChip(label: const Text('Conjugate'), onPressed: () {}),
              ActionChip(label: const Text('Magnitude'), onPressed: () {}),
              ActionChip(label: const Text('Argument'), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _EquationSolver extends StatefulWidget {
  const _EquationSolver();

  @override
  State<_EquationSolver> createState() => _EquationSolverState();
}

class _EquationSolverState extends State<_EquationSolver> {
  final _equationCtrl = TextEditingController(text: 'x^2 - 4');
  final _variableCtrl = TextEditingController(text: 'x');
  final _guessCtrl = TextEditingController(text: '1');
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _equationCtrl.dispose();
    _variableCtrl.dispose();
    _guessCtrl.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() => _isComputing = true);

    // TODO: Call Rust backend
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _result = 'x = 2.0, -2.0 (placeholder)';
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
            'Solve f(x) = 0',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _equationCtrl,
            decoration: const InputDecoration(
              labelText: 'Equation f(x)',
              hintText: 'e.g., x^2 - 4, sin(x) - 0.5',
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
                  controller: _guessCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Initial guess',
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
              onPressed: _isComputing ? null : _solve,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Find Roots'),
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
              ),
            ),

          const SizedBox(height: 24),
          Text('Quick Solvers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('Quadratic'), onPressed: () {}),
              ActionChip(label: const Text('Cubic'), onPressed: () {}),
              ActionChip(label: const Text('System (Ax=b)'), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
