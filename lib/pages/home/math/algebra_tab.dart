import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Algebra tab - Matrix operations, complex numbers, equation solving
/// Features: Dynamic matrices, equation solver, system of linear equations
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
            Tab(text: 'Matrix'),
            Tab(text: 'Complex'),
            Tab(text: 'Equations'),
            Tab(text: 'Systems'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _MatrixCalculator(),
              _ComplexCalculator(),
              _EquationSolver(),
              _SystemSolver(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MATRIX CALCULATOR - Dynamic matrices with any dimensions
// ============================================================================

class _MatrixCalculator extends StatefulWidget {
  const _MatrixCalculator();

  @override
  State<_MatrixCalculator> createState() => _MatrixCalculatorState();
}

class _Matrix {
  String name;
  int rows;
  int cols;
  List<List<TextEditingController>> controllers;

  _Matrix({required this.name, this.rows = 2, this.cols = 2})
    : controllers = List.generate(
        rows,
        (_) => List.generate(cols, (_) => TextEditingController(text: '0')),
      );

  void resize(int newRows, int newCols) {
    final newControllers = List.generate(
      newRows,
      (i) => List.generate(newCols, (j) {
        if (i < rows && j < cols) {
          return controllers[i][j];
        }
        return TextEditingController(text: '0');
      }),
    );
    // Dispose old controllers that are no longer needed
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if (i >= newRows || j >= newCols) {
          controllers[i][j].dispose();
        }
      }
    }
    controllers = newControllers;
    rows = newRows;
    cols = newCols;
  }

  List<List<double>> getData() {
    return controllers.map((row) {
      return row.map((c) => double.tryParse(c.text) ?? 0.0).toList();
    }).toList();
  }

  void dispose() {
    for (final row in controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
  }
}

class _MatrixCalculatorState extends State<_MatrixCalculator> {
  final List<_Matrix> _matrices = [];
  var _selectedIndices = <int>{0};
  var _operation = 'det';
  String? _result;
  String? _error;
  var _isComputing = false;
  var _matrixPowerN = 2; // For matrix power operation
  var _scalarValue = 2.0; // For scalar multiplication

  @override
  void initState() {
    super.initState();
    _matrices.add(_Matrix(name: 'A'));
  }

  @override
  void dispose() {
    for (final m in _matrices) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMatrix() {
    final name = String.fromCharCode('A'.codeUnitAt(0) + _matrices.length);
    setState(() {
      _matrices.add(_Matrix(name: name));
    });
  }

  void _removeMatrix(int index) {
    if (_matrices.length <= 1) return;
    setState(() {
      _matrices[index].dispose();
      _matrices.removeAt(index);
      _selectedIndices.remove(index);
      _selectedIndices = _selectedIndices
          .map((i) => i > index ? i - 1 : i)
          .toSet();
      if (_selectedIndices.isEmpty) _selectedIndices = {0};
    });
  }

  Future<void> _compute() async {
    if (_selectedIndices.isEmpty) return;

    setState(() {
      _isComputing = true;
      _error = null;
      _result = null;
    });

    try {
      final selectedMatrices = _selectedIndices
          .map((i) => _matrices[i])
          .toList();
      String result;

      switch (_operation) {
        case 'det':
          if (selectedMatrices.length != 1) {
            throw Exception('Determinant requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception(
              'Determinant requires a square matrix (${m.rows}×${m.cols} is not square)',
            );
          }
          final det = _determinant(m.getData());
          result = 'det(${m.name}) = ${_formatNumber(det)}';

        case 'inv':
          if (selectedMatrices.length != 1) {
            throw Exception('Inverse requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception(
              'Inverse requires a square matrix (${m.rows}×${m.cols} is not square)',
            );
          }
          final det = _determinant(m.getData());
          if (det.abs() < 1e-10) {
            throw Exception(
              'Matrix is singular (det ≈ 0), inverse does not exist',
            );
          }
          final inv = _inverse(m.getData());
          result = '${m.name}⁻¹ =\n${_formatMatrix(inv)}';

        case 'transpose':
          if (selectedMatrices.length != 1) {
            throw Exception('Transpose requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          final transposed = _transpose(m.getData());
          result = '${m.name}ᵀ =\n${_formatMatrix(transposed)}';

        case 'add':
          if (selectedMatrices.length != 2) {
            throw Exception('Addition requires exactly 2 matrices');
          }
          final a = selectedMatrices[0];
          final b = selectedMatrices[1];
          if (a.rows != b.rows || a.cols != b.cols) {
            throw Exception(
              'Matrices must have same dimensions for addition (${a.rows}×${a.cols} vs ${b.rows}×${b.cols})',
            );
          }
          final sum = _addMatrices(a.getData(), b.getData());
          result = '${a.name} + ${b.name} =\n${_formatMatrix(sum)}';

        case 'subtract':
          if (selectedMatrices.length != 2) {
            throw Exception('Subtraction requires exactly 2 matrices');
          }
          final a = selectedMatrices[0];
          final b = selectedMatrices[1];
          if (a.rows != b.rows || a.cols != b.cols) {
            throw Exception(
              'Matrices must have same dimensions for subtraction',
            );
          }
          final diff = _subtractMatrices(a.getData(), b.getData());
          result = '${a.name} - ${b.name} =\n${_formatMatrix(diff)}';

        case 'multiply':
          if (selectedMatrices.length != 2) {
            throw Exception('Multiplication requires exactly 2 matrices');
          }
          final a = selectedMatrices[0];
          final b = selectedMatrices[1];
          if (a.cols != b.rows) {
            throw Exception(
              'For A×B, columns of A (${a.cols}) must equal rows of B (${b.rows})',
            );
          }
          final product = _multiplyMatrices(a.getData(), b.getData());
          result = '${a.name} × ${b.name} =\n${_formatMatrix(product)}';

        case 'eigenvalues':
          if (selectedMatrices.length != 1) {
            throw Exception('Eigenvalues requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception('Eigenvalues require a square matrix');
          }
          if (m.rows > 3) {
            throw Exception('Eigenvalue computation limited to 3×3 matrices');
          }
          final eigenvalues = _computeEigenvalues(m.getData());
          result =
              'Eigenvalues of ${m.name}:\n${eigenvalues.map((e) => _formatNumber(e)).join(', ')}';

        case 'eigenvectors':
          if (selectedMatrices.length != 1) {
            throw Exception('Eigenvectors requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception('Eigenvectors require a square matrix');
          }
          if (m.rows > 3) {
            throw Exception('Eigenvector computation limited to 3×3 matrices');
          }
          final eigen = _computeEigenvectors(m.getData());
          result = 'Eigenvectors of ${m.name}:\n\n';
          for (var i = 0; i < eigen.length; i++) {
            result +=
                'λ${i + 1} = ${_formatNumber(eigen[i].$1)}\n'
                'v${i + 1} = [${eigen[i].$2.map(_formatNumber).join(', ')}]\n\n';
          }

        case 'trace':
          if (selectedMatrices.length != 1) {
            throw Exception('Trace requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception('Trace requires a square matrix');
          }
          final trace = _computeTrace(m.getData());
          result = 'tr(${m.name}) = ${_formatNumber(trace)}';

        case 'norm':
          if (selectedMatrices.length != 1) {
            throw Exception('Norm requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          final frobenius = _computeFrobeniusNorm(m.getData());
          result = '‖${m.name}‖_F = ${_formatNumber(frobenius)}';

        case 'power':
          if (selectedMatrices.length != 1) {
            throw Exception('Matrix power requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception('Matrix power requires a square matrix');
          }
          // Use power = 2 as default; user can modify matrix name to indicate power
          final powered = _matrixPower(m.getData(), _matrixPowerN);
          result = '${m.name}^$_matrixPowerN =\n${_formatMatrix(powered)}';

        case 'adjoint':
          if (selectedMatrices.length != 1) {
            throw Exception('Adjoint requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception('Adjoint requires a square matrix');
          }
          final adj = _computeAdjoint(m.getData());
          result = 'adj(${m.name}) =\n${_formatMatrix(adj)}';

        case 'scalar':
          if (selectedMatrices.length != 1) {
            throw Exception('Scalar multiplication requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          final scaled = _scalarMultiply(m.getData(), _scalarValue);
          result = '$_scalarValue × ${m.name} =\n${_formatMatrix(scaled)}';

        case 'dot':
          if (selectedMatrices.length != 2) {
            throw Exception(
              'Dot product requires exactly 2 matrices (vectors)',
            );
          }
          final a = selectedMatrices[0];
          final b = selectedMatrices[1];
          // For vectors, convert to 1D arrays
          final aData = a.getData();
          final bData = b.getData();
          // Flatten matrices to vectors for dot product
          final aVec = aData.expand((r) => r).toList();
          final bVec = bData.expand((r) => r).toList();
          if (aVec.length != bVec.length) {
            throw Exception(
              'Vectors must have the same dimension for dot product',
            );
          }
          final dot = _dotProduct(aVec, bVec);
          result = '${a.name} · ${b.name} = ${_formatNumber(dot)}';

        case 'rank':
          if (selectedMatrices.length != 1) {
            throw Exception('Rank requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          final rank = _computeRank(m.getData());
          result = 'rank(${m.name}) = $rank';

        case 'rref':
          if (selectedMatrices.length != 1) {
            throw Exception('RREF requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          final rref = _computeRref(m.getData());
          result = 'RREF(${m.name}) =\n${_formatMatrix(rref)}';

        case 'lu':
          if (selectedMatrices.length != 1) {
            throw Exception('LU decomposition requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows != m.cols) {
            throw Exception('LU decomposition requires a square matrix');
          }
          final lu = _computeLU(m.getData());
          result =
              'LU Decomposition of ${m.name}:\n\n'
              'L =\n${_formatMatrix(lu.$1)}\n\n'
              'U =\n${_formatMatrix(lu.$2)}';

        case 'qr':
          if (selectedMatrices.length != 1) {
            throw Exception('QR decomposition requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          if (m.rows < m.cols) {
            throw Exception('QR decomposition requires rows ≥ columns');
          }
          final qr = _computeQR(m.getData());
          result =
              'QR Decomposition of ${m.name}:\n\n'
              'Q =\n${_formatMatrix(qr.$1)}\n\n'
              'R =\n${_formatMatrix(qr.$2)}';

        case 'svd':
          if (selectedMatrices.length != 1) {
            throw Exception('SVD requires exactly 1 matrix');
          }
          final m = selectedMatrices[0];
          final svd = _computeSVD(m.getData());
          result =
              'SVD of ${m.name}:\n\n'
              'U =\n${_formatMatrix(svd.$1)}\n\n'
              'Σ (singular values) = ${svd.$2.map(_formatNumber).join(', ')}\n\n'
              'Vᵀ =\n${_formatMatrix(svd.$3)}';

        default:
          throw Exception('Unknown operation');
      }

      setState(() {
        _result = result;
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isComputing = false;
      });
    }
  }

  // Matrix operations
  double _determinant(List<List<double>> m) {
    final n = m.length;
    if (n == 1) return m[0][0];
    if (n == 2) return m[0][0] * m[1][1] - m[0][1] * m[1][0];

    double det = 0;
    for (var j = 0; j < n; j++) {
      det += (j.isEven ? 1 : -1) * m[0][j] * _determinant(_minor(m, 0, j));
    }
    return det;
  }

  List<List<double>> _minor(List<List<double>> m, int row, int col) {
    return [
      for (var i = 0; i < m.length; i++)
        if (i != row)
          [
            for (var j = 0; j < m[0].length; j++)
              if (j != col) m[i][j],
          ],
    ];
  }

  List<List<double>> _inverse(List<List<double>> m) {
    final n = m.length;
    final det = _determinant(m);

    // Compute adjugate (transpose of cofactor matrix)
    final adj = List.generate(
      n,
      (i) => List.generate(n, (j) {
        final cofactor =
            ((i + j).isEven ? 1 : -1) * _determinant(_minor(m, j, i));
        return cofactor / det;
      }),
    );

    return adj;
  }

  List<List<double>> _transpose(List<List<double>> m) {
    final rows = m.length;
    final cols = m[0].length;
    return List.generate(cols, (i) => List.generate(rows, (j) => m[j][i]));
  }

  List<List<double>> _addMatrices(List<List<double>> a, List<List<double>> b) {
    return List.generate(
      a.length,
      (i) => List.generate(a[0].length, (j) => a[i][j] + b[i][j]),
    );
  }

  List<List<double>> _subtractMatrices(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    return List.generate(
      a.length,
      (i) => List.generate(a[0].length, (j) => a[i][j] - b[i][j]),
    );
  }

  List<List<double>> _multiplyMatrices(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    final m = a.length;
    final n = b[0].length;
    final k = a[0].length;
    return List.generate(
      m,
      (i) => List.generate(n, (j) {
        double sum = 0;
        for (var l = 0; l < k; l++) {
          sum += a[i][l] * b[l][j];
        }
        return sum;
      }),
    );
  }

  // Compute trace (sum of diagonal elements)
  double _computeTrace(List<List<double>> m) {
    double trace = 0;
    for (var i = 0; i < m.length; i++) {
      trace += m[i][i];
    }
    return trace;
  }

  // Compute Frobenius norm (sqrt of sum of squared elements)
  double _computeFrobeniusNorm(List<List<double>> m) {
    double sum = 0;
    for (final row in m) {
      for (final val in row) {
        sum += val * val;
      }
    }
    return math.sqrt(sum);
  }

  // Matrix power A^n using repeated multiplication
  List<List<double>> _matrixPower(List<List<double>> m, int n) {
    if (n == 0) {
      // Return identity matrix
      return List.generate(
        m.length,
        (i) => List.generate(m.length, (j) => i == j ? 1.0 : 0.0),
      );
    }
    if (n == 1) return m;
    if (n < 0) {
      // For negative powers, compute inverse first then power
      final inv = _inverse(m);
      return _matrixPower(inv, -n);
    }
    // Use binary exponentiation for efficiency
    var result = _matrixPower(m, n ~/ 2);
    result = _multiplyMatrices(result, result);
    if (n.isOdd) {
      result = _multiplyMatrices(result, m);
    }
    return result;
  }

  // Compute adjoint (adjugate) matrix
  List<List<double>> _computeAdjoint(List<List<double>> m) {
    final n = m.length;
    return List.generate(
      n,
      (i) => List.generate(n, (j) {
        // Cofactor with transpose (swap i,j)
        return ((i + j).isEven ? 1 : -1) * _determinant(_minor(m, j, i));
      }),
    );
  }

  // Scalar multiplication
  List<List<double>> _scalarMultiply(List<List<double>> m, double scalar) {
    return m.map((row) => row.map((val) => val * scalar).toList()).toList();
  }

  // Compute eigenvectors for 2x2 and 3x3 matrices
  List<(double, List<double>)> _computeEigenvectors(List<List<double>> m) {
    final eigenvalues = _computeEigenvalues(m);
    final results = <(double, List<double>)>[];

    for (final lambda in eigenvalues) {
      final n = m.length;
      // Create (A - λI)
      final shifted = List.generate(
        n,
        (i) => List.generate(n, (j) => m[i][j] - (i == j ? lambda : 0)),
      );

      // Find null space using RREF
      final rref = _computeRref(shifted);

      // Find free variables and construct eigenvector
      final eigenvector = List.filled(n, 0.0);
      var foundFree = false;

      for (var col = n - 1; col >= 0; col--) {
        var isPivot = false;
        for (var row = 0; row < n; row++) {
          if (rref[row][col].abs() > 1e-10) {
            var isLeading = true;
            for (var c = 0; c < col; c++) {
              if (rref[row][c].abs() > 1e-10) {
                isLeading = false;
                break;
              }
            }
            if (isLeading) {
              isPivot = true;
              break;
            }
          }
        }

        if (!isPivot && !foundFree) {
          eigenvector[col] = 1.0;
          foundFree = true;
        }
      }

      // Back substitute to find dependent variables
      for (var row = n - 1; row >= 0; row--) {
        var pivotCol = -1;
        for (var col = 0; col < n; col++) {
          if (rref[row][col].abs() > 1e-10) {
            pivotCol = col;
            break;
          }
        }
        if (pivotCol >= 0) {
          double sum = 0;
          for (var col = pivotCol + 1; col < n; col++) {
            sum += rref[row][col] * eigenvector[col];
          }
          eigenvector[pivotCol] = -sum;
        }
      }

      // Normalize
      final norm = _vectorNorm(eigenvector);
      if (norm > 1e-10) {
        for (var i = 0; i < n; i++) {
          eigenvector[i] /= norm;
        }
      } else {
        // Fallback: use a unit vector
        eigenvector[0] = 1.0;
      }

      results.add((lambda, eigenvector));
    }

    return results;
  }

  List<double> _computeEigenvalues(List<List<double>> m) {
    final n = m.length;
    if (n == 2) {
      // For 2x2: λ² - tr(A)λ + det(A) = 0
      final trace = m[0][0] + m[1][1];
      final det = _determinant(m);
      final discriminant = trace * trace - 4 * det;
      if (discriminant >= 0) {
        final sqrt = math.sqrt(discriminant);
        return [(trace + sqrt) / 2, (trace - sqrt) / 2];
      } else {
        // Complex eigenvalues - return real parts
        return [trace / 2, trace / 2];
      }
    }
    // For 3x3, use characteristic polynomial (simplified)
    // This is a basic implementation
    final a = m[0][0], b = m[0][1], c = m[0][2];
    final d = m[1][0], e = m[1][1], f = m[1][2];
    final g = m[2][0], h = m[2][1], i = m[2][2];

    final trace = a + e + i;
    final determinant = _determinant(m);
    final sumMinors = (a * e + e * i + a * i - b * d - c * g - f * h);

    // Solve cubic: λ³ - trace*λ² + sumMinors*λ - det = 0
    // Using depressed cubic transformation: t = λ - trace/3
    // t³ + pt + q = 0 where:
    final p = sumMinors - trace * trace / 3;
    final q =
        2 * trace * trace * trace / 27 - trace * sumMinors / 3 + determinant;

    // Use Cardano's formula for real roots
    final discriminant = q * q / 4 + p * p * p / 27;
    final shift = trace / 3;

    if (discriminant >= 0) {
      // One real root, two complex conjugates (return real parts)
      final sqrtDisc = math.sqrt(discriminant);
      final u = _cubeRoot(-q / 2 + sqrtDisc);
      final v = _cubeRoot(-q / 2 - sqrtDisc);
      final lambda1 = u + v + shift;
      return [lambda1, shift, shift]; // Simplified
    } else {
      // Three distinct real roots (Vieta's trigonometric method)
      final r = math.sqrt(-p * p * p / 27);
      final phi = math.acos(-q / (2 * r));
      final lambda1 = 2 * _cubeRoot(r) * math.cos(phi / 3) + shift;
      final lambda2 =
          2 * _cubeRoot(r) * math.cos((phi + 2 * math.pi) / 3) + shift;
      final lambda3 =
          2 * _cubeRoot(r) * math.cos((phi + 4 * math.pi) / 3) + shift;
      return [lambda1, lambda2, lambda3];
    }
  }

  double _cubeRoot(double x) =>
      x >= 0 ? math.pow(x, 1 / 3).toDouble() : -math.pow(-x, 1 / 3).toDouble();

  int _computeRank(List<List<double>> m) {
    // Use row echelon form to compute rank
    final rows = m.length;
    final cols = m[0].length;
    final matrix = m.map((r) => r.toList()).toList();

    var rank = 0;
    for (var col = 0; col < cols && rank < rows; col++) {
      // Find pivot
      var pivotRow = -1;
      for (var row = rank; row < rows; row++) {
        if (matrix[row][col].abs() > 1e-10) {
          pivotRow = row;
          break;
        }
      }
      if (pivotRow == -1) continue;

      // Swap rows
      final temp = matrix[rank];
      matrix[rank] = matrix[pivotRow];
      matrix[pivotRow] = temp;

      // Eliminate
      for (var row = rank + 1; row < rows; row++) {
        final factor = matrix[row][col] / matrix[rank][col];
        for (var c = col; c < cols; c++) {
          matrix[row][c] -= factor * matrix[rank][c];
        }
      }
      rank++;
    }
    return rank;
  }

  List<List<double>> _computeRref(List<List<double>> m) {
    final rows = m.length;
    final cols = m[0].length;
    final matrix = m.map((r) => r.toList()).toList();

    var pivotRow = 0;
    for (var col = 0; col < cols && pivotRow < rows; col++) {
      // Find the largest pivot
      var maxRow = pivotRow;
      for (var row = pivotRow + 1; row < rows; row++) {
        if (matrix[row][col].abs() > matrix[maxRow][col].abs()) {
          maxRow = row;
        }
      }

      if (matrix[maxRow][col].abs() < 1e-10) continue;

      // Swap rows
      final temp = matrix[pivotRow];
      matrix[pivotRow] = matrix[maxRow];
      matrix[maxRow] = temp;

      // Scale pivot row to make pivot = 1
      final pivot = matrix[pivotRow][col];
      for (var c = 0; c < cols; c++) {
        matrix[pivotRow][c] /= pivot;
      }

      // Eliminate all other entries in this column
      for (var row = 0; row < rows; row++) {
        if (row != pivotRow && matrix[row][col].abs() > 1e-10) {
          final factor = matrix[row][col];
          for (var c = 0; c < cols; c++) {
            matrix[row][c] -= factor * matrix[pivotRow][c];
          }
        }
      }
      pivotRow++;
    }

    // Clean up very small values
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if (matrix[i][j].abs() < 1e-10) matrix[i][j] = 0;
      }
    }

    return matrix;
  }

  (List<List<double>>, List<List<double>>) _computeLU(List<List<double>> m) {
    final n = m.length;
    final L = List.generate(
      n,
      (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0),
    );
    final U = m.map((r) => r.toList()).toList();

    for (var k = 0; k < n; k++) {
      for (var i = k + 1; i < n; i++) {
        if (U[k][k].abs() < 1e-10) {
          throw Exception('LU decomposition failed: zero pivot encountered');
        }
        L[i][k] = U[i][k] / U[k][k];
        for (var j = k; j < n; j++) {
          U[i][j] -= L[i][k] * U[k][j];
        }
      }
    }

    // Clean up small values
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (L[i][j].abs() < 1e-10) L[i][j] = 0;
        if (U[i][j].abs() < 1e-10) U[i][j] = 0;
      }
    }

    return (L, U);
  }

  (List<List<double>>, List<List<double>>) _computeQR(List<List<double>> m) {
    final rows = m.length;
    final cols = m[0].length;
    final Q = List.generate(rows, (_) => List.filled(rows, 0.0));
    final R = List.generate(rows, (_) => List.filled(cols, 0.0));
    final A = m.map((r) => r.toList()).toList();

    // Gram-Schmidt orthogonalization
    final u = <List<double>>[];
    for (var j = 0; j < cols; j++) {
      // Get column j of A
      final a = List.generate(rows, (i) => A[i][j]);
      final proj = List.filled(rows, 0.0);

      // Subtract projections
      for (var k = 0; k < j; k++) {
        final dot = _dotProduct(a, u[k]);
        R[k][j] = dot;
        for (var i = 0; i < rows; i++) {
          proj[i] += dot * u[k][i];
        }
      }

      final v = List.generate(rows, (i) => a[i] - proj[i]);
      final norm = _vectorNorm(v);

      if (norm > 1e-10) {
        for (var i = 0; i < rows; i++) {
          v[i] /= norm;
        }
        R[j][j] = norm;
      }
      u.add(v);

      // Fill Q column
      for (var i = 0; i < rows; i++) {
        Q[i][j] = v[i];
      }
    }

    // Fill remaining Q columns with orthogonal vectors if needed
    for (var j = cols; j < rows; j++) {
      for (var i = 0; i < rows; i++) {
        Q[i][j] = i == j ? 1.0 : 0.0;
      }
    }

    return (Q, R);
  }

  (List<List<double>>, List<double>, List<List<double>>) _computeSVD(
    List<List<double>> m,
  ) {
    final rows = m.length;
    final cols = m[0].length;

    // Compute A^T * A
    final ata = _multiplyMatrices(_transpose(m), m);

    // Get eigenvalues and eigenvectors of A^T * A (simplified for small matrices)
    // This is a basic power iteration approach
    final k = math.min(rows, cols);
    final singularValues = <double>[];
    final V = List.generate(cols, (_) => List.filled(cols, 0.0));
    final U = List.generate(rows, (_) => List.filled(k, 0.0));

    final ataTemp = ata.map((r) => r.toList()).toList();

    for (var i = 0; i < k; i++) {
      // Power iteration for largest eigenvalue
      var v = List.generate(cols, (j) => j == i ? 1.0 : 0.0);
      for (var iter = 0; iter < 50; iter++) {
        final newV = _matVecMul(ataTemp, v);
        final norm = _vectorNorm(newV);
        if (norm < 1e-10) break;
        v = List.generate(cols, (j) => newV[j] / norm);
      }

      final eigenvalue = _dotProduct(_matVecMul(ataTemp, v), v);
      final sigma = eigenvalue > 0 ? math.sqrt(eigenvalue) : 0.0;
      singularValues.add(sigma);

      // Store right singular vector
      for (var j = 0; j < cols; j++) {
        V[j][i] = v[j];
      }

      // Compute left singular vector: u = Av / sigma
      if (sigma > 1e-10) {
        final av = _matVecMul(m, v);
        for (var j = 0; j < rows; j++) {
          U[j][i] = av[j] / sigma;
        }
      }

      // Deflate
      for (var p = 0; p < cols; p++) {
        for (var q = 0; q < cols; q++) {
          ataTemp[p][q] -= eigenvalue * v[p] * v[q];
        }
      }
    }

    return (U, singularValues, _transpose(V));
  }

  double _dotProduct(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  double _vectorNorm(List<double> v) {
    return math.sqrt(_dotProduct(v, v));
  }

  List<double> _matVecMul(List<List<double>> m, List<double> v) {
    return List.generate(m.length, (i) => _dotProduct(m[i], v));
  }

  String _formatNumber(double n) {
    if (n == n.toInt().toDouble() && n.abs() < 1e10) {
      return n.toInt().toString();
    }
    return n
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatMatrix(List<List<double>> m) {
    return m
        .map((row) => '[ ${row.map(_formatNumber).join('  ')} ]')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matrices list
          ..._matrices.asMap().entries.map(
            (entry) => _buildMatrixCard(entry.key, entry.value, colorScheme),
          ),

          // Add matrix button
          Center(
            child: TextButton.icon(
              onPressed: _addMatrix,
              icon: const Icon(Icons.add),
              label: const Text('Add Matrix'),
            ),
          ),
          const SizedBox(height: 12),

          // Operation selector
          Text('Operation', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _opChip('det', 'Determinant'),
              _opChip('inv', 'Inverse'),
              _opChip('transpose', 'Transpose'),
              _opChip('trace', 'Trace'),
              _opChip('rank', 'Rank'),
              _opChip('norm', 'Norm'),
              _opChip('rref', 'RREF'),
              _opChip('eigenvalues', 'Eigenvalues'),
              _opChip('eigenvectors', 'Eigenvectors'),
              _opChip('power', 'A^n'),
              _opChip('adjoint', 'Adjoint'),
              _opChip('lu', 'LU'),
              _opChip('qr', 'QR'),
              _opChip('svd', 'SVD'),
              _opChip('add', 'A + B'),
              _opChip('subtract', 'A - B'),
              _opChip('multiply', 'A × B'),
              _opChip('scalar', 'k × A'),
              _opChip('dot', 'A · B'),
            ],
          ),

          // Additional inputs for power and scalar operations
          if (_operation == 'power') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Power n = '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _matrixPowerN.toString(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) {
                        setState(() => _matrixPowerN = n);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(negative for inverse)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (_operation == 'scalar') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Scalar k = '),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _scalarValue.toString(),
                    ),
                    onChanged: (v) {
                      final k = double.tryParse(v);
                      if (k != null) {
                        setState(() => _scalarValue = k);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          // Result/Error
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

          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _opChip(String value, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _operation == value,
      onSelected: (_) => setState(() => _operation = value),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMatrixCard(int index, _Matrix matrix, ColorScheme colorScheme) {
    final isSelected = _selectedIndices.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v ?? false) {
                        _selectedIndices.add(index);
                      } else {
                        _selectedIndices.remove(index);
                      }
                    });
                  },
                ),
                Text(
                  'Matrix ${matrix.name}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                // Dimension controls
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: matrix.rows > 1
                      ? () {
                          setState(
                            () => matrix.resize(matrix.rows - 1, matrix.cols),
                          );
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove row',
                ),
                Text('${matrix.rows}×${matrix.cols}'),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: matrix.rows < 10
                      ? () {
                          setState(
                            () => matrix.resize(matrix.rows + 1, matrix.cols),
                          );
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add row',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: matrix.cols > 1
                      ? () {
                          setState(
                            () => matrix.resize(matrix.rows, matrix.cols - 1),
                          );
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove column',
                ),
                const Text('cols'),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: matrix.cols < 10
                      ? () {
                          setState(
                            () => matrix.resize(matrix.rows, matrix.cols + 1),
                          );
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add column',
                ),
                if (_matrices.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _removeMatrix(index),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete matrix',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMatrixGrid(matrix),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixGrid(_Matrix matrix) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: List.generate(matrix.rows, (i) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(matrix.cols, (j) {
              return Padding(
                padding: const EdgeInsets.all(2),
                child: SizedBox(
                  width: 50,
                  child: TextField(
                    controller: matrix.controllers[i][j],
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// COMPLEX CALCULATOR
// ============================================================================

class _ComplexCalculator extends StatefulWidget {
  const _ComplexCalculator();

  @override
  State<_ComplexCalculator> createState() => _ComplexCalculatorState();
}

class _ComplexCalculatorState extends State<_ComplexCalculator> {
  // Input mode: 'rectangular' or 'polar'
  var _inputMode = 'rectangular';

  // Rectangular inputs
  final _aRealCtrl = TextEditingController(text: '3');
  final _aImagCtrl = TextEditingController(text: '4');
  final _bRealCtrl = TextEditingController(text: '1');
  final _bImagCtrl = TextEditingController(text: '2');

  // Polar inputs
  final _aMagCtrl = TextEditingController(text: '5');
  final _aAngleCtrl = TextEditingController(text: '53.13');
  final _bMagCtrl = TextEditingController(text: '2.236');
  final _bAngleCtrl = TextEditingController(text: '63.43');
  var _angleUnit = 'degrees';

  var _operation = 'add';
  var _result = '';
  var _showBothForms = true;

  @override
  void dispose() {
    _aRealCtrl.dispose();
    _aImagCtrl.dispose();
    _bRealCtrl.dispose();
    _bImagCtrl.dispose();
    _aMagCtrl.dispose();
    _aAngleCtrl.dispose();
    _bMagCtrl.dispose();
    _bAngleCtrl.dispose();
    super.dispose();
  }

  (double real, double imag) _getComplexA() {
    if (_inputMode == 'rectangular') {
      return (
        double.tryParse(_aRealCtrl.text) ?? 0,
        double.tryParse(_aImagCtrl.text) ?? 0,
      );
    } else {
      final mag = double.tryParse(_aMagCtrl.text) ?? 0;
      var angle = double.tryParse(_aAngleCtrl.text) ?? 0;
      if (_angleUnit == 'degrees') angle = angle * math.pi / 180;
      return (mag * math.cos(angle), mag * math.sin(angle));
    }
  }

  (double real, double imag) _getComplexB() {
    if (_inputMode == 'rectangular') {
      return (
        double.tryParse(_bRealCtrl.text) ?? 0,
        double.tryParse(_bImagCtrl.text) ?? 0,
      );
    } else {
      final mag = double.tryParse(_bMagCtrl.text) ?? 0;
      var angle = double.tryParse(_bAngleCtrl.text) ?? 0;
      if (_angleUnit == 'degrees') angle = angle * math.pi / 180;
      return (mag * math.cos(angle), mag * math.sin(angle));
    }
  }

  String _formatComplex(double real, double imag) {
    final sign = imag >= 0 ? '+' : '-';
    return '${_formatNum(real)} $sign ${_formatNum(imag.abs())}i';
  }

  String _formatPolar(double real, double imag) {
    final mag = math.sqrt(real * real + imag * imag);
    final angle = math.atan2(imag, real);
    final angleDeg = angle * 180 / math.pi;
    return '${_formatNum(mag)} ∠ ${_formatNum(angleDeg)}°  (= ${_formatNum(angle)} rad)';
  }

  void _compute() {
    final (aReal, aImag) = _getComplexA();
    final (bReal, bImag) = _getComplexB();

    double resultReal, resultImag;
    String op;

    switch (_operation) {
      case 'add':
        resultReal = aReal + bReal;
        resultImag = aImag + bImag;
        op = '+';
      case 'sub':
        resultReal = aReal - bReal;
        resultImag = aImag - bImag;
        op = '-';
      case 'mul':
        resultReal = aReal * bReal - aImag * bImag;
        resultImag = aReal * bImag + aImag * bReal;
        op = '×';
      case 'div':
        final denom = bReal * bReal + bImag * bImag;
        if (denom.abs() < 1e-15) {
          setState(() => _result = 'Error: Division by zero');
          return;
        }
        resultReal = (aReal * bReal + aImag * bImag) / denom;
        resultImag = (aImag * bReal - aReal * bImag) / denom;
        op = '÷';
      case 'pow':
        // (a+bi)^(c+di) using e^(n*ln(z))
        if (aReal == 0 && aImag == 0) {
          if (bReal > 0) {
            resultReal = 0;
            resultImag = 0;
          } else {
            setState(() => _result = 'Error: 0^(non-positive) is undefined');
            return;
          }
        } else {
          final r = math.sqrt(aReal * aReal + aImag * aImag);
          final theta = math.atan2(aImag, aReal);
          final lnR = math.log(r);
          // (c+di) * (ln(r) + i*theta) = c*ln(r) - d*theta + i*(d*ln(r) + c*theta)
          final newLnMag = bReal * lnR - bImag * theta;
          final newTheta = bImag * lnR + bReal * theta;
          final newMag = math.exp(newLnMag);
          resultReal = newMag * math.cos(newTheta);
          resultImag = newMag * math.sin(newTheta);
        }
        op = '^';
      case 'sqrt':
        // sqrt(a+bi) - principal square root
        final mag = math.sqrt(aReal * aReal + aImag * aImag);
        resultReal = math.sqrt((mag + aReal) / 2);
        resultImag = aImag >= 0
            ? math.sqrt((mag - aReal) / 2)
            : -math.sqrt((mag - aReal) / 2);
        op = '√';
      default:
        return;
    }

    final aStr = _formatComplex(aReal, aImag);
    final bStr = _formatComplex(bReal, bImag);

    setState(() {
      var resultStr = '';
      if (_operation == 'sqrt') {
        resultStr = '√($aStr)\n';
      } else {
        resultStr = '($aStr) $op ($bStr)\n';
      }
      resultStr +=
          '\nRectangular Form:\n  = ${_formatComplex(resultReal, resultImag)}';
      if (_showBothForms) {
        resultStr +=
            '\n\nPolar Form:\n  = ${_formatPolar(resultReal, resultImag)}';
      }
      _result = resultStr;
    });
  }

  String _formatNum(double n) {
    if (n.abs() < 1e-10) return '0';
    if (n == n.toInt().toDouble() && n.abs() < 1e10)
      return n.toInt().toString();
    return n
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _computeConversion(String type) {
    final (real, imag) = _getComplexA();

    switch (type) {
      case 'polar':
        final r = math.sqrt(real * real + imag * imag);
        final theta = math.atan2(imag, real);
        final thetaDeg = theta * 180 / math.pi;
        setState(
          () => _result =
              'Polar form of A:\n  r = ${_formatNum(r)}\n  θ = ${_formatNum(thetaDeg)}°  (= ${_formatNum(theta)} rad)\n\n  = ${_formatNum(r)} ∠ ${_formatNum(thetaDeg)}°',
        );
      case 'rectangular':
        setState(
          () => _result =
              'Rectangular form of A:\n  = ${_formatComplex(real, imag)}',
        );
      case 'conjugate':
        setState(
          () => _result = 'Conjugate of A:\n  = ${_formatComplex(real, -imag)}',
        );
      case 'magnitude':
        final mag = math.sqrt(real * real + imag * imag);
        setState(() => _result = 'Magnitude of A:\n  |z| = ${_formatNum(mag)}');
      case 'argument':
        final arg = math.atan2(imag, real);
        final argDeg = arg * 180 / math.pi;
        setState(
          () => _result =
              'Argument of A:\n  arg(z) = ${_formatNum(argDeg)}°  (= ${_formatNum(arg)} rad)',
        );
      case 'inverse':
        final denom = real * real + imag * imag;
        if (denom.abs() < 1e-15) {
          setState(() => _result = 'Error: Cannot invert zero');
          return;
        }
        final invReal = real / denom;
        final invImag = -imag / denom;
        setState(
          () => _result =
              'Inverse of A:\n  1/z = ${_formatComplex(invReal, invImag)}\n  Polar: ${_formatPolar(invReal, invImag)}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input mode selector
          Row(
            children: [
              Text(
                'Input Mode:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'rectangular', label: Text('a + bi')),
                  ButtonSegment(value: 'polar', label: Text('r ∠ θ')),
                ],
                selected: {_inputMode},
                onSelectionChanged: (s) => setState(() => _inputMode = s.first),
              ),
            ],
          ),
          if (_inputMode == 'polar') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Angle unit:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'degrees', label: Text('Degrees')),
                    ButtonSegment(value: 'radians', label: Text('Radians')),
                  ],
                  selected: {_angleUnit},
                  onSelectionChanged: (s) =>
                      setState(() => _angleUnit = s.first),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          Text(
            'Complex Number A',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_inputMode == 'rectangular')
            _buildRectangularInput(_aRealCtrl, _aImagCtrl)
          else
            _buildPolarInput(_aMagCtrl, _aAngleCtrl),
          const SizedBox(height: 16),

          Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'add', label: Text('+')),
                ButtonSegment(value: 'sub', label: Text('-')),
                ButtonSegment(value: 'mul', label: Text('×')),
                ButtonSegment(value: 'div', label: Text('÷')),
                ButtonSegment(value: 'pow', label: Text('^')),
                ButtonSegment(value: 'sqrt', label: Text('√A')),
              ],
              selected: {_operation},
              onSelectionChanged: (s) => setState(() => _operation = s.first),
            ),
          ),
          const SizedBox(height: 16),

          if (_operation != 'sqrt') ...[
            Text(
              'Complex Number B',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_inputMode == 'rectangular')
              _buildRectangularInput(_bRealCtrl, _bImagCtrl)
            else
              _buildPolarInput(_bMagCtrl, _bAngleCtrl),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Checkbox(
                value: _showBothForms,
                onChanged: (v) => setState(() => _showBothForms = v ?? true),
              ),
              const Text('Show both rectangular & polar forms'),
            ],
          ),
          const SizedBox(height: 8),

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
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),

          const SizedBox(height: 24),
          Text(
            'Conversions & Properties (for A)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('To Polar'),
                onPressed: () => _computeConversion('polar'),
              ),
              ActionChip(
                label: const Text('To Rectangular'),
                onPressed: () => _computeConversion('rectangular'),
              ),
              ActionChip(
                label: const Text('Conjugate'),
                onPressed: () => _computeConversion('conjugate'),
              ),
              ActionChip(
                label: const Text('Magnitude'),
                onPressed: () => _computeConversion('magnitude'),
              ),
              ActionChip(
                label: const Text('Argument'),
                onPressed: () => _computeConversion('argument'),
              ),
              ActionChip(
                label: const Text('Inverse (1/z)'),
                onPressed: () => _computeConversion('inverse'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRectangularInput(
    TextEditingController realCtrl,
    TextEditingController imagCtrl,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: realCtrl,
            decoration: const InputDecoration(
              labelText: 'Real',
              border: OutlineInputBorder(),
              isDense: true,
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
            controller: imagCtrl,
            decoration: const InputDecoration(
              labelText: 'Imaginary',
              border: OutlineInputBorder(),
              isDense: true,
              suffixText: 'i',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolarInput(
    TextEditingController magCtrl,
    TextEditingController angleCtrl,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: magCtrl,
            decoration: const InputDecoration(
              labelText: 'Magnitude (r)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('∠'),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: angleCtrl,
            decoration: InputDecoration(
              labelText: 'Angle (θ)',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixText: _angleUnit == 'degrees' ? '°' : 'rad',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EQUATION SOLVER - Solve any equation
// ============================================================================

class _EquationSolver extends StatefulWidget {
  const _EquationSolver();

  @override
  State<_EquationSolver> createState() => _EquationSolverState();
}

class _EquationSolverState extends State<_EquationSolver> {
  final _equationCtrl = TextEditingController(text: 'x^2 - 4 = 0');
  final _variableCtrl = TextEditingController(text: 'x');
  var _result = '';
  var _isComputing = false;

  @override
  void dispose() {
    _equationCtrl.dispose();
    _variableCtrl.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      final equation = _equationCtrl.text.trim();
      final variable = _variableCtrl.text.trim();
      if (variable.isEmpty) throw Exception('Variable cannot be empty');

      // Parse equation: left = right
      String left, right;
      if (equation.contains('=')) {
        final parts = equation.split('=');
        left = parts[0].trim();
        right = parts.length > 1 ? parts[1].trim() : '0';
      } else {
        left = equation;
        right = '0';
      }

      // Move everything to left side: left - right = 0
      final f = '$left - ($right)';

      // Try to identify polynomial and solve algebraically
      final roots = _solveEquation(f, variable);

      setState(() {
        _result =
            'Solutions for $variable:\n${roots.map((r) => '$variable = ${_formatNumber(r)}').join('\n')}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  List<double> _solveEquation(String expr, String variable) {
    // Simplify and identify polynomial degree
    expr = expr.replaceAll(' ', '').toLowerCase();
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');

    // Try to parse as polynomial ax^n + bx^(n-1) + ... = 0
    final coefficients = _extractPolynomialCoefficients(expr, variable);

    if (coefficients.isEmpty) {
      // Fall back to numerical methods
      return _numericalSolve(expr, variable);
    }

    final degree = coefficients.length - 1;

    if (degree == 1) {
      // Linear: ax + b = 0 => x = -b/a
      final a = coefficients[1];
      final b = coefficients[0];
      if (a == 0) throw Exception('Not a valid equation');
      return [-b / a];
    }

    if (degree == 2) {
      // Quadratic: ax² + bx + c = 0
      final a = coefficients[2];
      final b = coefficients[1];
      final c = coefficients[0];
      final discriminant = b * b - 4 * a * c;
      if (discriminant < 0) {
        throw Exception('No real solutions (discriminant < 0)');
      }
      final sqrtD = math.sqrt(discriminant);
      return [(-b + sqrtD) / (2 * a), (-b - sqrtD) / (2 * a)];
    }

    if (degree == 3) {
      // Cubic: use Cardano's formula (simplified)
      return _solveCubic(coefficients);
    }

    // Higher degree: numerical methods
    return _numericalSolve(expr, variable);
  }

  Map<int, double> _parsePolynomialTerms(String expr, String v) {
    final coeffs = <int, double>{};

    // Normalize: add + before - for splitting
    expr = expr.replaceAllMapped(
      RegExp(r'(?<=[^+\-(*])(\-)'),
      (m) => '+${m.group(1)}',
    );

    // Split by + (keeping - signs)
    final terms = expr.split('+').where((t) => t.isNotEmpty).toList();

    for (var term in terms) {
      term = term.trim();
      if (term.isEmpty) continue;

      // Check for variable with power: coef*x^n or x^n or coef*x or x or constant
      final powerMatch = RegExp(
        '^([+-]?[\\d.]*)[*]?$v\\^([\\d]+)\$',
      ).firstMatch(term);
      final linearMatch = RegExp('^([+-]?[\\d.]*)[*]?$v\$').firstMatch(term);
      final constantMatch = RegExp('^([+-]?[\\d.]+)\$').firstMatch(term);

      if (powerMatch != null) {
        final coefStr = powerMatch.group(1)!;
        final power = int.parse(powerMatch.group(2)!);
        final coef = coefStr.isEmpty || coefStr == '+'
            ? 1.0
            : (coefStr == '-' ? -1.0 : double.parse(coefStr));
        coeffs[power] = (coeffs[power] ?? 0) + coef;
      } else if (linearMatch != null) {
        final coefStr = linearMatch.group(1)!;
        final coef = coefStr.isEmpty || coefStr == '+'
            ? 1.0
            : (coefStr == '-' ? -1.0 : double.parse(coefStr));
        coeffs[1] = (coeffs[1] ?? 0) + coef;
      } else if (constantMatch != null) {
        final coef = double.parse(constantMatch.group(1)!);
        coeffs[0] = (coeffs[0] ?? 0) + coef;
      }
    }

    return coeffs;
  }

  List<double> _extractPolynomialCoefficients(String expr, String v) {
    try {
      final terms = _parsePolynomialTerms(expr, v);
      if (terms.isEmpty) return [];

      final maxPower = terms.keys.reduce(math.max);
      return List.generate(maxPower + 1, (i) => terms[i] ?? 0.0);
    } catch (e) {
      return [];
    }
  }

  List<double> _solveCubic(List<double> coeffs) {
    // Depressed cubic using Cardano's formula
    final a = coeffs[3];
    final b = coeffs[2];
    final c = coeffs[1];
    final d = coeffs[0];

    // Convert to depressed cubic t³ + pt + q = 0
    final p = (3 * a * c - b * b) / (3 * a * a);
    final q =
        (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (27 * a * a * a);

    final discriminant = q * q / 4 + p * p * p / 27;

    final List<double> roots = [];

    if (discriminant > 0) {
      // One real root
      final sqrtD = math.sqrt(discriminant);
      final u = _cbrt(-q / 2 + sqrtD);
      final v = _cbrt(-q / 2 - sqrtD);
      roots.add(u + v - b / (3 * a));
    } else if (discriminant == 0) {
      // Multiple roots
      final u = _cbrt(-q / 2);
      roots.add(2 * u - b / (3 * a));
      roots.add(-u - b / (3 * a));
    } else {
      // Three real roots (use trigonometric method)
      final r = math.sqrt(-p * p * p / 27);
      final theta = math.acos(-q / (2 * r)) / 3;
      final m = 2 * _cbrt(r);
      roots.add(m * math.cos(theta) - b / (3 * a));
      roots.add(m * math.cos(theta + 2 * math.pi / 3) - b / (3 * a));
      roots.add(m * math.cos(theta + 4 * math.pi / 3) - b / (3 * a));
    }

    return roots;
  }

  double _cbrt(double x) =>
      x >= 0 ? math.pow(x, 1 / 3).toDouble() : -math.pow(-x, 1 / 3).toDouble();

  List<double> _numericalSolve(String expr, String variable) {
    // Newton-Raphson method to find roots
    final roots = <double>[];
    const h = 1e-7;

    double f(double x) {
      final e = expr.replaceAll(variable, '($x)');
      return _evaluateSimple(e);
    }

    double df(double x) => (f(x + h) - f(x - h)) / (2 * h);

    // Try multiple starting points
    for (var start = -10.0; start <= 10.0; start += 2.0) {
      var x = start;
      for (var i = 0; i < 100; i++) {
        final fx = f(x);
        final dfx = df(x);
        if (dfx.abs() < 1e-15) break;
        final newX = x - fx / dfx;
        if ((newX - x).abs() < 1e-10) {
          // Check if it's a real root
          if (f(newX).abs() < 1e-6) {
            // Check if we already have this root
            final isDuplicate = roots.any((r) => (r - newX).abs() < 1e-4);
            if (!isDuplicate) roots.add(newX);
          }
          break;
        }
        x = newX;
      }
    }

    if (roots.isEmpty) throw Exception('No solutions found in range [-10, 10]');
    roots.sort();
    return roots;
  }

  double _evaluateSimple(String expr) {
    // Very basic expression evaluator
    expr = expr.replaceAll(' ', '');
    return _parseExpr(expr);
  }

  double _parseExpr(String expr) {
    // Handle parentheses
    while (expr.contains('(')) {
      expr = expr.replaceAllMapped(
        RegExp(r'\(([^()]+)\)'),
        (m) => _parseExpr(m.group(1)!).toString(),
      );
    }

    // Handle power
    while (expr.contains('^')) {
      expr = expr.replaceAllMapped(
        RegExp(r'([+-]?\d+\.?\d*)\^([+-]?\d+\.?\d*)'),
        (m) => math
            .pow(double.parse(m.group(1)!), double.parse(m.group(2)!))
            .toString(),
      );
    }

    // Handle +/- (right to left)
    for (var i = expr.length - 1; i >= 0; i--) {
      if ((expr[i] == '+' || expr[i] == '-') &&
          i > 0 &&
          expr[i - 1] != 'e' &&
          expr[i - 1] != 'E') {
        final left = expr.substring(0, i);
        final right = expr.substring(i + 1);
        if (left.isNotEmpty && right.isNotEmpty) {
          return expr[i] == '+'
              ? _parseExpr(left) + _parseExpr(right)
              : _parseExpr(left) - _parseExpr(right);
        }
      }
    }

    // Handle */
    for (var i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == '*' || expr[i] == '/') {
        final left = expr.substring(0, i);
        final right = expr.substring(i + 1);
        if (left.isNotEmpty && right.isNotEmpty) {
          final r = _parseExpr(right);
          return expr[i] == '*' ? _parseExpr(left) * r : _parseExpr(left) / r;
        }
      }
    }

    return double.parse(expr);
  }

  String _formatNumber(double n) {
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
            'Equation Solver',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter any equation (e.g., x^2 - 4 = 0, 2x + 3 = 7, x^3 - x = 0)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _equationCtrl,
            decoration: const InputDecoration(
              labelText: 'Equation',
              hintText: 'e.g., x^2 - 4 = 0',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _variableCtrl,
            decoration: const InputDecoration(
              labelText: 'Variable',
              border: OutlineInputBorder(),
            ),
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
              label: const Text('Solve'),
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
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),

          const SizedBox(height: 24),
          Text('Quick Solvers', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Quadratic'),
                onPressed: () {
                  _equationCtrl.text = 'ax^2 + bx + c = 0';
                },
              ),
              ActionChip(
                label: const Text('Linear'),
                onPressed: () {
                  _equationCtrl.text = 'ax + b = 0';
                },
              ),
              ActionChip(
                label: const Text('Cubic'),
                onPressed: () {
                  _equationCtrl.text = 'x^3 - 6x^2 + 11x - 6 = 0';
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SYSTEM OF LINEAR EQUATIONS SOLVER
// ============================================================================

class _SystemSolver extends StatefulWidget {
  const _SystemSolver();

  @override
  State<_SystemSolver> createState() => _SystemSolverState();
}

class _SystemSolverState extends State<_SystemSolver> {
  final _equations = <TextEditingController>[
    TextEditingController(text: '2x + 3y = 8'),
    TextEditingController(text: 'x - y = 1'),
  ];
  var _result = '';
  var _isComputing = false;

  void _addEquation() {
    setState(() {
      _equations.add(TextEditingController());
    });
  }

  void _removeEquation(int index) {
    if (_equations.length <= 2) return;
    setState(() {
      _equations[index].dispose();
      _equations.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final c in _equations) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    try {
      // Parse equations
      final eqs = _equations
          .map((c) => c.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (eqs.isEmpty) throw Exception('Enter at least one equation');

      // Extract variables
      final variables = <String>{};
      for (final eq in eqs) {
        variables.addAll(
          RegExp(r'[a-zA-Z]').allMatches(eq).map((m) => m.group(0)!),
        );
      }
      final varList = variables.toList()..sort();

      if (varList.isEmpty) throw Exception('No variables found');
      if (eqs.length < varList.length) {
        throw Exception(
          'Need at least ${varList.length} equations for ${varList.length} variables',
        );
      }

      // Build augmented matrix [A|b]
      final n = varList.length;
      final matrix = <List<double>>[];

      for (final eq in eqs) {
        final parts = eq.split('=');
        if (parts.length != 2) throw Exception('Invalid equation format: $eq');

        final leftSide = parts[0].trim();
        final rightSide = double.tryParse(parts[1].trim()) ?? 0;

        final row = List<double>.filled(n + 1, 0);
        row[n] = rightSide;

        // Parse coefficients
        var expr = leftSide.replaceAll(' ', '');
        expr = expr.replaceAllMapped(
          RegExp(r'(?<=[^+\-])(\-)'),
          (m) => '+${m.group(1)}',
        );

        final terms = expr.split('+').where((t) => t.isNotEmpty);
        for (var term in terms) {
          term = term.trim();
          for (var i = 0; i < varList.length; i++) {
            final v = varList[i];
            final match = RegExp('^([+-]?[\\d.]*)[*]?$v\$').firstMatch(term);
            if (match != null) {
              final coefStr = match.group(1)!;
              final coef = coefStr.isEmpty || coefStr == '+'
                  ? 1.0
                  : (coefStr == '-' ? -1.0 : double.parse(coefStr));
              row[i] = coef;
            }
          }
        }

        matrix.add(row);
      }

      // Gaussian elimination with partial pivoting
      final result = _gaussianElimination(matrix, n);

      setState(() {
        _result =
            'Solution:\n${varList.asMap().entries.map((e) => '${e.value} = ${_formatNumber(result[e.key])}').join('\n')}';
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isComputing = false;
      });
    }
  }

  List<double> _gaussianElimination(List<List<double>> matrix, int n) {
    // Forward elimination
    for (var col = 0; col < n; col++) {
      // Find pivot
      var maxRow = col;
      for (var row = col + 1; row < matrix.length; row++) {
        if (matrix[row][col].abs() > matrix[maxRow][col].abs()) {
          maxRow = row;
        }
      }

      // Swap rows
      final temp = matrix[col];
      matrix[col] = matrix[maxRow];
      matrix[maxRow] = temp;

      if (matrix[col][col].abs() < 1e-10) {
        throw Exception('System has no unique solution');
      }

      // Eliminate below
      for (var row = col + 1; row < matrix.length; row++) {
        final factor = matrix[row][col] / matrix[col][col];
        for (var j = col; j <= n; j++) {
          matrix[row][j] -= factor * matrix[col][j];
        }
      }
    }

    // Back substitution
    final solution = List<double>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      var sum = matrix[i][n];
      for (var j = i + 1; j < n; j++) {
        sum -= matrix[i][j] * solution[j];
      }
      solution[i] = sum / matrix[i][i];
    }

    return solution;
  }

  String _formatNumber(double n) {
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
            'System of Linear Equations',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter equations like: 2x + 3y = 8',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          ..._equations.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Equation ${entry.key + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_equations.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeEquation(entry.key),
                    ),
                ],
              ),
            );
          }),

          TextButton.icon(
            onPressed: _addEquation,
            icon: const Icon(Icons.add),
            label: const Text('Add Equation'),
          ),
          const SizedBox(height: 16),

          Center(
            child: FilledButton.icon(
              onPressed: _isComputing ? null : _solve,
              icon: _isComputing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Solve System'),
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
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}
