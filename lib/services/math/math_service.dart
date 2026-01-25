/// Math service for initializing and interfacing with the Rust math backend.
/// All math computations are performed in Rust for optimal performance.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:kivixa/src/rust_math/api.dart' as math_api;
import 'package:kivixa/src/rust_math/basic.dart';
import 'package:kivixa/src/rust_math/calculus.dart';
import 'package:kivixa/src/rust_math/complex.dart';
import 'package:kivixa/src/rust_math/discrete.dart';
import 'package:kivixa/src/rust_math/frb_generated.dart';
import 'package:kivixa/src/rust_math/graphing.dart';
import 'package:kivixa/src/rust_math/matrix.dart';
import 'package:kivixa/src/rust_math/statistics.dart';
import 'package:kivixa/src/rust_math/units.dart';

/// Singleton service for math computations via Rust backend
class MathService {
  static final _instance = MathService._();
  static MathService get instance => _instance;

  MathService._();

  var _isInitialized = false;

  /// Check if the math backend is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the math Rust library
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      ExternalLibrary? externalLibrary;

      if (Platform.isWindows) {
        // On Windows, try the local build path
        final exePath = Platform.resolvedExecutable;
        final exeDir = File(exePath).parent.path;
        final dllPath = '$exeDir/kivixa_math.dll';

        if (File(dllPath).existsSync()) {
          externalLibrary = ExternalLibrary.open(dllPath);
          debugPrint('MathService: Loading from $dllPath');
        } else {
          // Try development path
          const devDllPath = 'native_math/target/release/kivixa_math.dll';
          if (File(devDllPath).existsSync()) {
            externalLibrary = ExternalLibrary.open(devDllPath);
            debugPrint('MathService: Loading from dev path $devDllPath');
          }
        }
      } else if (Platform.isAndroid) {
        // Android loads from jniLibs automatically
        debugPrint('MathService: Using Android default loading');
      } else if (Platform.isLinux) {
        final exePath = Platform.resolvedExecutable;
        final exeDir = File(exePath).parent.path;
        final soPath = '$exeDir/lib/libkivixa_math.so';

        if (File(soPath).existsSync()) {
          externalLibrary = ExternalLibrary.open(soPath);
          debugPrint('MathService: Loading from $soPath');
        }
      } else if (Platform.isMacOS || Platform.isIOS) {
        debugPrint('MathService: Using macOS/iOS default loading');
      }

      await MathRustLib.init(externalLibrary: externalLibrary);
      _isInitialized = true;
      debugPrint('MathService: Initialized successfully');
    } catch (e) {
      debugPrint('MathService: Failed to initialize - $e');
      // Don't rethrow - allow graceful degradation
    }
  }

  /// Ensure the library is initialized before use
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'MathService not initialized. Call MathService.instance.initialize() first.',
      );
    }
  }

  // ============================================================================
  // Basic Operations
  // ============================================================================

  /// Evaluate a mathematical expression
  ExpressionResult evaluateExpression(String expression) {
    _ensureInitialized();
    return math_api.evaluateExpression(expression: expression);
  }

  /// Get a mathematical constant by name
  double getConstant(String name) {
    _ensureInitialized();
    return math_api.getConstant(name: name);
  }

  /// Convert between number systems
  String convertNumberSystem(String value, int fromBase, int toBase) {
    _ensureInitialized();
    return math_api.convertNumberSystem(
      value: value,
      fromBase: fromBase,
      toBase: toBase,
    );
  }

  // ============================================================================
  // Discrete Mathematics / Modular Arithmetic
  // ============================================================================

  /// Check if a number is prime
  bool isPrime(int n) {
    _ensureInitialized();
    return math_api.isPrime(n: BigInt.from(n));
  }

  /// Calculate GCD of two numbers
  int gcd(int a, int b) {
    _ensureInitialized();
    return math_api.gcd(a: BigInt.from(a), b: BigInt.from(b)).toInt();
  }

  /// Calculate LCM of two numbers
  int lcm(int a, int b) {
    _ensureInitialized();
    return math_api.lcm(a: BigInt.from(a), b: BigInt.from(b)).toInt();
  }

  /// Modular addition: (a + b) mod m
  DiscreteResult modAdd(BigInt a, BigInt b, BigInt m) {
    _ensureInitialized();
    return math_api.modAdd(a: a, b: b, m: m);
  }

  /// Modular subtraction: (a - b) mod m
  DiscreteResult modSub(BigInt a, BigInt b, BigInt m) {
    _ensureInitialized();
    return math_api.modSub(a: a, b: b, m: m);
  }

  /// Modular multiplication: (a * b) mod m
  DiscreteResult modMultiply(BigInt a, BigInt b, BigInt m) {
    _ensureInitialized();
    return math_api.modMultiply(a: a, b: b, m: m);
  }

  /// Modular exponentiation: a^b mod m
  DiscreteResult modPow(BigInt base, BigInt exp, BigInt modulus) {
    _ensureInitialized();
    return math_api.modPow(base: base, exp: exp, modulus: modulus);
  }

  /// Modular inverse: a^(-1) mod m
  DiscreteResult modInverse(BigInt a, BigInt m) {
    _ensureInitialized();
    return math_api.modInverse(a: a, m: m);
  }

  /// Modular division: (a / b) mod m
  DiscreteResult modDivide(BigInt a, BigInt b, BigInt m) {
    _ensureInitialized();
    return math_api.modDivide(a: a, b: b, m: m);
  }

  /// Calculate factorial
  DiscreteResult factorial(int n) {
    _ensureInitialized();
    return math_api.factorial(n: BigInt.from(n));
  }

  /// Calculate combinations C(n, r)
  DiscreteResult combinations(int n, int r) {
    _ensureInitialized();
    return math_api.combinations(n: BigInt.from(n), r: BigInt.from(r));
  }

  /// Calculate permutations P(n, r)
  DiscreteResult permutations(int n, int r) {
    _ensureInitialized();
    return math_api.permutations(n: BigInt.from(n), r: BigInt.from(r));
  }

  /// Get prime factors
  DiscreteResult primeFactors(int n) {
    _ensureInitialized();
    return math_api.primeFactors(n: BigInt.from(n));
  }

  /// Generate primes using Sieve of Eratosthenes
  Future<DiscreteResult> sievePrimes(int n) async {
    _ensureInitialized();
    return await math_api.sievePrimes(n: BigInt.from(n));
  }

  /// Calculate Fibonacci number
  DiscreteResult fibonacci(int n) {
    _ensureInitialized();
    return math_api.fibonacci(n: BigInt.from(n));
  }

  /// Calculate Euler's totient
  DiscreteResult eulerTotient(int n) {
    _ensureInitialized();
    return math_api.eulerTotient(n: BigInt.from(n));
  }

  /// Get divisors
  DiscreteResult listDivisors(int n) {
    _ensureInitialized();
    return math_api.listDivisors(n: BigInt.from(n));
  }

  /// Calculate Catalan number
  DiscreteResult catalan(int n) {
    _ensureInitialized();
    return math_api.catalan(n: BigInt.from(n));
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// Compute comprehensive statistics
  Future<StatisticsResult> computeStatistics(List<double> data) async {
    _ensureInitialized();
    return await math_api.computeStatistics(data: data);
  }

  /// Calculate correlation and covariance
  Future<CorrelationResult> correlationCovariance(
    List<double> x,
    List<double> y,
  ) async {
    _ensureInitialized();
    return await math_api.correlationCovariance(x: x, y: y);
  }

  /// Confidence interval for mean
  Future<ConfidenceIntervalResult> confidenceIntervalMean(
    List<double> data,
    double confidenceLevel,
  ) async {
    _ensureInitialized();
    return await math_api.confidenceIntervalMean(
      data: data,
      confidenceLevel: confidenceLevel,
    );
  }

  /// Confidence interval for proportion
  ConfidenceIntervalResult confidenceIntervalProportion(
    int successes,
    int n,
    double confidenceLevel,
  ) {
    _ensureInitialized();
    return math_api.confidenceIntervalProportion(
      successes: BigInt.from(successes),
      n: BigInt.from(n),
      confidenceLevel: confidenceLevel,
    );
  }

  /// Confidence interval for variance
  Future<ConfidenceIntervalResult> confidenceIntervalVariance(
    List<double> data,
    double confidenceLevel,
  ) async {
    _ensureInitialized();
    return await math_api.confidenceIntervalVariance(
      data: data,
      confidenceLevel: confidenceLevel,
    );
  }

  /// Linear regression
  Future<RegressionResult> linearRegression(
    List<double> x,
    List<double> y,
  ) async {
    _ensureInitialized();
    return await math_api.linearRegression(xData: x, yData: y);
  }

  /// Polynomial regression
  Future<RegressionResult> polynomialRegression(
    List<double> x,
    List<double> y,
    int degree,
  ) async {
    _ensureInitialized();
    return await math_api.polynomialRegression(
      xData: x,
      yData: y,
      degree: BigInt.from(degree),
    );
  }

  /// One-sample t-test
  Future<HypothesisTestResult> tTest(
    List<double> data,
    double hypothesizedMean,
    double alpha,
  ) async {
    _ensureInitialized();
    return await math_api.tTest(
      data: data,
      hypothesizedMean: hypothesizedMean,
      alpha: alpha,
    );
  }

  /// Two-sample t-test
  Future<HypothesisTestResult> twoSampleTTest(
    List<double> data1,
    List<double> data2,
    double alpha,
  ) async {
    _ensureInitialized();
    return await math_api.twoSampleTTest(
      data1: data1,
      data2: data2,
      alpha: alpha,
    );
  }

  /// Chi-squared test
  Future<HypothesisTestResult> chiSquaredTest(
    List<double> observed,
    List<double> expected,
    double alpha,
  ) async {
    _ensureInitialized();
    return await math_api.chiSquaredTest(
      observed: observed,
      expected: expected,
      alpha: alpha,
    );
  }

  /// One-sample z-test (known population standard deviation)
  Future<HypothesisTestResult> zTest(
    List<double> data,
    double hypothesizedMean,
    double populationStd,
    double alpha,
  ) async {
    _ensureInitialized();
    return await math_api.zTest(
      data: data,
      hypothesizedMean: hypothesizedMean,
      populationStd: populationStd,
      alpha: alpha,
    );
  }

  /// Two-sample z-test (known population standard deviations)
  Future<HypothesisTestResult> twoSampleZTest(
    List<double> data1,
    List<double> data2,
    double std1,
    double std2,
    double alpha,
  ) async {
    _ensureInitialized();
    return await math_api.twoSampleZTest(
      data1: data1,
      data2: data2,
      std1: std1,
      std2: std2,
      alpha: alpha,
    );
  }

  /// One-way ANOVA
  Future<HypothesisTestResult> anova(
    List<List<double>> groups,
    double alpha,
  ) async {
    _ensureInitialized();
    // Convert List<List<double>> to List<Float64List>
    final float64Groups = groups.map((g) => Float64List.fromList(g)).toList();
    return await math_api.anova(groups: float64Groups, alpha: alpha);
  }

  /// Distribution computation
  Future<DistributionResult> distributionCompute(
    String distributionType,
    List<double> params,
    double x,
  ) async {
    _ensureInitialized();
    return await math_api.distributionCompute(
      distributionType: distributionType,
      params: params,
      x: x,
    );
  }

  // ============================================================================
  // Matrix Operations
  // ============================================================================

  /// Perform matrix operation
  Future<MatrixResult> matrixOperation({
    required List<double> aData,
    required int aRows,
    required int aCols,
    List<double>? bData,
    int? bRows,
    int? bCols,
    required String operation,
  }) async {
    _ensureInitialized();
    return await math_api.matrixOperation(
      aData: aData,
      aRows: BigInt.from(aRows),
      aCols: BigInt.from(aCols),
      bData: bData != null ? Float64List.fromList(bData) : null,
      bRows: bRows != null ? BigInt.from(bRows) : null,
      bCols: bCols != null ? BigInt.from(bCols) : null,
      operation: operation,
    );
  }

  /// Matrix decomposition
  Future<MatrixDecomposition> matrixDecomposition({
    required List<double> data,
    required int rows,
    required int cols,
    required String decompositionType,
  }) async {
    _ensureInitialized();
    return await math_api.matrixDecomposition(
      data: data,
      rows: BigInt.from(rows),
      cols: BigInt.from(cols),
      decompositionType: decompositionType,
    );
  }

  // ============================================================================
  // Calculus
  // ============================================================================

  /// Differentiate an expression at a point
  Future<CalculusResult> differentiate(
    String expression,
    String variable,
    double point, {
    int order = 1,
  }) async {
    _ensureInitialized();
    return await math_api.differentiate(
      expression: expression,
      variable: variable,
      point: point,
      order: order,
    );
  }

  /// Integrate an expression (definite integral)
  Future<CalculusResult> integrate(
    String expression,
    String variable,
    double lower,
    double upper, {
    int numIntervals = 1000,
  }) async {
    _ensureInitialized();
    return await math_api.integrate(
      expression: expression,
      variable: variable,
      lower: lower,
      upper: upper,
      numIntervals: numIntervals,
    );
  }

  /// Solve equation f(x) = 0 using Newton-Raphson
  Future<SolveResult> solveEquation(
    String expression,
    String variable,
    double initialGuess, {
    double tolerance = 1e-10,
    int maxIterations = 100,
  }) async {
    _ensureInitialized();
    return await math_api.solveEquation(
      expression: expression,
      variable: variable,
      initialGuess: initialGuess,
      tolerance: tolerance,
      maxIterations: maxIterations,
    );
  }

  /// Compute limit numerically
  Future<CalculusResult> computeLimit(
    String expression,
    String variable,
    double approachValue, {
    required bool fromLeft,
    required bool fromRight,
  }) async {
    _ensureInitialized();
    return await math_api.computeLimit(
      expression: expression,
      variable: variable,
      approachValue: approachValue,
      fromLeft: fromLeft,
      fromRight: fromRight,
    );
  }

  /// Get Taylor series coefficients
  Future<Float64List> taylorCoefficients(
    String expression,
    String variable,
    double around,
    int numTerms,
  ) async {
    _ensureInitialized();
    return await math_api.taylorCoefficients(
      expression: expression,
      variable: variable,
      around: around,
      numTerms: numTerms,
    );
  }

  /// Compute partial derivative with respect to one variable
  Future<CalculusResult> partialDerivative(
    String expression,
    String variable,
    Map<String, double> point,
    int order,
  ) async {
    _ensureInitialized();
    final pointList = point.entries.map((e) => (e.key, e.value)).toList();
    return await math_api.partialDerivative(
      expression: expression,
      variable: variable,
      point: pointList,
      order: order,
    );
  }

  /// Compute mixed partial derivative ∂²f/∂x∂y
  Future<CalculusResult> mixedPartialDerivative(
    String expression,
    String var1,
    String var2,
    Map<String, double> point,
  ) async {
    _ensureInitialized();
    final pointList = point.entries.map((e) => (e.key, e.value)).toList();
    return await math_api.mixedPartialDerivative(
      expression: expression,
      var1: var1,
      var2: var2,
      point: pointList,
    );
  }

  /// Compute gradient vector
  Future<Float64List> gradient(
    String expression,
    List<String> variables,
    Map<String, double> point,
  ) async {
    _ensureInitialized();
    final pointList = point.entries.map((e) => (e.key, e.value)).toList();
    return await math_api.gradient(
      expression: expression,
      variables: variables,
      point: pointList,
    );
  }

  /// Compute double integral ∫∫ f(x,y) dx dy
  Future<CalculusResult> doubleIntegral(
    String expression,
    String xVar,
    String yVar,
    double xMin,
    double xMax,
    double yMin,
    double yMax, {
    int numIntervals = 50,
  }) async {
    _ensureInitialized();
    return await math_api.doubleIntegral(
      expression: expression,
      xVar: xVar,
      yVar: yVar,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
      numIntervals: numIntervals,
    );
  }

  /// Compute triple integral ∫∫∫ f(x,y,z) dx dy dz
  Future<CalculusResult> tripleIntegral(
    String expression,
    String xVar,
    String yVar,
    String zVar,
    double xMin,
    double xMax,
    double yMin,
    double yMax,
    double zMin,
    double zMax, {
    int numIntervals = 20,
  }) async {
    _ensureInitialized();
    return await math_api.tripleIntegral(
      expression: expression,
      xVar: xVar,
      yVar: yVar,
      zVar: zVar,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
      zMin: zMin,
      zMax: zMax,
      numIntervals: numIntervals,
    );
  }

  /// Compute line integral along a parameterized path
  Future<CalculusResult> lineIntegral(
    String expression,
    String xParam,
    String yParam,
    String tVar,
    double tMin,
    double tMax, {
    int numIntervals = 100,
  }) async {
    _ensureInitialized();
    return await math_api.lineIntegral(
      expression: expression,
      xParam: xParam,
      yParam: yParam,
      tVar: tVar,
      tMin: tMin,
      tMax: tMax,
      numIntervals: numIntervals,
    );
  }

  // ============================================================================
  // Graphing
  // ============================================================================

  /// Evaluate graph points
  Future<GraphResult> evaluateGraphPoints(
    String expression,
    String variable,
    List<double> xValues,
  ) async {
    _ensureInitialized();
    return await math_api.evaluateGraphPoints(
      expression: expression,
      variable: variable,
      xValues: xValues,
    );
  }

  /// Generate x range
  Float64List generateXRange(double start, double end, int numPoints) {
    _ensureInitialized();
    return math_api.generateXRange(
      start: start,
      end: end,
      numPoints: BigInt.from(numPoints),
    );
  }

  /// Find graph roots
  Future<Float64List> findGraphRoots(
    String expression,
    String variable,
    double xMin,
    double xMax,
    int numSamples,
  ) async {
    _ensureInitialized();
    return await math_api.findGraphRoots(
      expression: expression,
      variable: variable,
      xMin: xMin,
      xMax: xMax,
      numSamples: BigInt.from(numSamples),
    );
  }

  /// Find local extrema (maxima/minima) in a range
  Future<(List<(double, double)>, List<(double, double)>)> findExtrema(
    String expression,
    String variable,
    double xMin,
    double xMax,
    int numSamples,
  ) async {
    _ensureInitialized();
    return await math_api.findExtrema(
      expression: expression,
      variable: variable,
      xMin: xMin,
      xMax: xMax,
      numSamples: BigInt.from(numSamples),
    );
  }

  /// Compute derivative graph
  Future<GraphResult> derivativeGraph(
    String expression,
    String variable,
    List<double> xValues,
  ) async {
    _ensureInitialized();
    return await math_api.derivativeGraph(
      expression: expression,
      variable: variable,
      xValues: xValues,
    );
  }

  /// Compute integral graph (cumulative)
  Future<GraphResult> integralGraph(
    String expression,
    String variable,
    List<double> xValues,
    double initialValue,
  ) async {
    _ensureInitialized();
    return await math_api.integralGraph(
      expression: expression,
      variable: variable,
      xValues: xValues,
      initialValue: initialValue,
    );
  }

  // ============================================================================
  // Complex Numbers
  // ============================================================================

  /// Complex number operation
  ComplexResult complexOperation({
    required double aReal,
    required double aImag,
    required double bReal,
    required double bImag,
    required String operation,
  }) {
    _ensureInitialized();
    return math_api.complexOperation(
      aReal: aReal,
      aImag: aImag,
      bReal: bReal,
      bImag: bImag,
      operation: operation,
    );
  }

  // ============================================================================
  // Unit Conversion
  // ============================================================================

  /// Convert units
  UnitResult convertUnit(double value, String fromUnit, String toUnit) {
    _ensureInitialized();
    return math_api.convertUnit(
      value: value,
      fromUnit: fromUnit,
      toUnit: toUnit,
    );
  }

  /// Get unit categories
  List<String> getUnitCategories() {
    _ensureInitialized();
    return math_api.getUnitCategories();
  }

  /// Get units for category
  List<String> getUnitsForCategory(String category) {
    _ensureInitialized();
    return math_api.getUnitsForCategory(category: category);
  }

  // ============================================================================
  // Formulas
  // ============================================================================

  /// Parse formula to extract variables
  List<String> parseFormula(String formula) {
    _ensureInitialized();
    return math_api.parseFormula(formula: formula);
  }

  /// Evaluate formula with variables
  ExpressionResult evaluateFormula(
    String formula,
    List<String> variables,
    List<double> values,
  ) {
    _ensureInitialized();
    return math_api.evaluateFormula(
      formula: formula,
      variables: variables,
      values: values,
    );
  }
}
