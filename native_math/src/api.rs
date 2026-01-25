//! Main API module - exposes all math functions to Flutter via flutter_rust_bridge
//!
//! All functions here are async or use rayon for parallel execution to ensure
//! the Flutter UI thread never blocks.

use crate::basic::{self, ExpressionResult};
use crate::calculus::{self, CalculusResult, SolveResult};
use crate::complex::{self, ComplexResult};
use crate::discrete::{self, DiscreteResult};
use crate::graphing::{self, GraphResult};
use crate::matrix::{self, MatrixResult, MatrixDecomposition};
use crate::statistics::{self, StatisticsResult, DistributionResult, RegressionResult, HypothesisTestResult};
use crate::units::{self, UnitResult};
use flutter_rust_bridge::frb;

// ============================================================================
// Basic & Scientific Calculator
// ============================================================================

/// Evaluate a mathematical expression string
/// Supports: +, -, *, /, ^, sqrt, sin, cos, tan, log, ln, abs, etc.
#[frb(sync)]
pub fn evaluate_expression(expression: String) -> ExpressionResult {
    basic::evaluate_expression(&expression)
}

/// Convert between number systems (binary, octal, decimal, hex)
#[frb(sync)]
pub fn convert_number_system(value: String, from_base: u32, to_base: u32) -> String {
    basic::convert_number_system(&value, from_base, to_base)
}

/// Get mathematical constants
#[frb(sync)]
pub fn get_constant(name: String) -> f64 {
    basic::get_constant(&name)
}

// ============================================================================
// Complex Numbers
// ============================================================================

/// Perform complex number operations
#[frb(sync)]
pub fn complex_operation(
    a_real: f64,
    a_imag: f64,
    b_real: f64,
    b_imag: f64,
    operation: String,
) -> ComplexResult {
    complex::complex_operation(a_real, a_imag, b_real, b_imag, &operation)
}

/// Convert complex number between rectangular and polar forms
#[frb(sync)]
pub fn complex_convert(real: f64, imag: f64, to_polar: bool) -> ComplexResult {
    complex::convert_form(real, imag, to_polar)
}

// ============================================================================
// Matrix Operations (Linear Algebra)
// ============================================================================

/// Perform matrix operations (add, multiply, transpose, inverse, etc.)
/// Matrix data is passed as a flat array with dimensions
pub async fn matrix_operation(
    a_data: Vec<f64>,
    a_rows: usize,
    a_cols: usize,
    b_data: Option<Vec<f64>>,
    b_rows: Option<usize>,
    b_cols: Option<usize>,
    operation: String,
) -> MatrixResult {
    tokio::task::spawn_blocking(move || {
        matrix::matrix_operation(
            &a_data, a_rows, a_cols,
            b_data.as_deref(), b_rows, b_cols,
            &operation,
        )
    }).await.unwrap_or_else(|_| MatrixResult::error("Task panicked"))
}

/// Compute matrix decompositions (LU, QR, SVD, Cholesky, Eigen)
pub async fn matrix_decomposition(
    data: Vec<f64>,
    rows: usize,
    cols: usize,
    decomposition_type: String,
) -> MatrixDecomposition {
    tokio::task::spawn_blocking(move || {
        matrix::decompose(&data, rows, cols, &decomposition_type)
    }).await.unwrap_or_else(|_| MatrixDecomposition::error("Task panicked"))
}

/// Compute matrix properties (determinant, rank, trace, eigenvalues)
pub async fn matrix_properties(
    data: Vec<f64>,
    rows: usize,
    cols: usize,
) -> MatrixResult {
    tokio::task::spawn_blocking(move || {
        matrix::compute_properties(&data, rows, cols)
    }).await.unwrap_or_else(|_| MatrixResult::error("Task panicked"))
}

/// Row reduce matrix to echelon form (RREF)
pub async fn matrix_rref(
    data: Vec<f64>,
    rows: usize,
    cols: usize,
) -> MatrixResult {
    tokio::task::spawn_blocking(move || {
        matrix::row_reduce(&data, rows, cols)
    }).await.unwrap_or_else(|_| MatrixResult::error("Task panicked"))
}

// ============================================================================
// Calculus
// ============================================================================

/// Compute numerical derivative at a point
pub async fn differentiate(
    expression: String,
    variable: String,
    point: f64,
    order: u32,
) -> CalculusResult {
    tokio::task::spawn_blocking(move || {
        calculus::differentiate(&expression, &variable, point, order)
    }).await.unwrap_or_else(|_| CalculusResult::error("Task panicked"))
}

/// Compute numerical integral (definite)
pub async fn integrate(
    expression: String,
    variable: String,
    lower: f64,
    upper: f64,
    num_intervals: u32,
) -> CalculusResult {
    tokio::task::spawn_blocking(move || {
        calculus::integrate(&expression, &variable, lower, upper, num_intervals)
    }).await.unwrap_or_else(|_| CalculusResult::error("Task panicked"))
}

/// Solve equation f(x) = 0 using Newton-Raphson
pub async fn solve_equation(
    expression: String,
    variable: String,
    initial_guess: f64,
    tolerance: f64,
    max_iterations: u32,
) -> SolveResult {
    tokio::task::spawn_blocking(move || {
        calculus::solve_equation(&expression, &variable, initial_guess, tolerance, max_iterations)
    }).await.unwrap_or_else(|_| SolveResult::error("Task panicked"))
}

/// Find multiple roots in an interval
pub async fn find_roots_in_interval(
    expression: String,
    variable: String,
    start: f64,
    end: f64,
    num_samples: u32,
) -> SolveResult {
    tokio::task::spawn_blocking(move || {
        calculus::find_roots_in_interval(&expression, &variable, start, end, num_samples)
    }).await.unwrap_or_else(|_| SolveResult::error("Task panicked"))
}

/// Compute limit numerically
pub async fn compute_limit(
    expression: String,
    variable: String,
    approach_value: f64,
    from_left: bool,
    from_right: bool,
) -> CalculusResult {
    tokio::task::spawn_blocking(move || {
        calculus::compute_limit(&expression, &variable, approach_value, from_left, from_right)
    }).await.unwrap_or_else(|_| CalculusResult::error("Task panicked"))
}

/// Get Taylor series coefficients
pub async fn taylor_coefficients(
    expression: String,
    variable: String,
    around: f64,
    num_terms: u32,
) -> Vec<f64> {
    tokio::task::spawn_blocking(move || {
        calculus::taylor_coefficients(&expression, &variable, around, num_terms)
    }).await.unwrap_or_else(|_| vec![])
}

// ============================================================================
// Statistics & Probability
// ============================================================================

/// Compute descriptive statistics from a dataset
pub async fn compute_statistics(data: Vec<f64>) -> StatisticsResult {
    tokio::task::spawn_blocking(move || {
        statistics::compute_statistics(&data)
    }).await.unwrap_or_else(|_| StatisticsResult::error("Task panicked"))
}

/// Compute probability distribution values (PDF, CDF)
pub async fn distribution_compute(
    distribution_type: String,
    params: Vec<f64>,
    x: f64,
) -> DistributionResult {
    tokio::task::spawn_blocking(move || {
        statistics::distribution_compute(&distribution_type, &params, x)
    }).await.unwrap_or_else(|_| DistributionResult::error("Task panicked"))
}

/// Perform linear regression
pub async fn linear_regression(
    x_data: Vec<f64>,
    y_data: Vec<f64>,
) -> RegressionResult {
    tokio::task::spawn_blocking(move || {
        statistics::linear_regression(&x_data, &y_data)
    }).await.unwrap_or_else(|_| RegressionResult::error("Task panicked"))
}

/// Perform polynomial regression
pub async fn polynomial_regression(
    x_data: Vec<f64>,
    y_data: Vec<f64>,
    degree: usize,
) -> RegressionResult {
    tokio::task::spawn_blocking(move || {
        statistics::polynomial_regression(&x_data, &y_data, degree)
    }).await.unwrap_or_else(|_| RegressionResult::error("Task panicked"))
}

/// One-sample t-test
pub async fn t_test(
    data: Vec<f64>,
    hypothesized_mean: f64,
    alpha: f64,
) -> HypothesisTestResult {
    tokio::task::spawn_blocking(move || {
        statistics::t_test(&data, hypothesized_mean, alpha)
    }).await.unwrap_or_else(|_| HypothesisTestResult::error("Task panicked"))
}

/// Two-sample t-test
pub async fn two_sample_t_test(
    data1: Vec<f64>,
    data2: Vec<f64>,
    alpha: f64,
) -> HypothesisTestResult {
    tokio::task::spawn_blocking(move || {
        statistics::two_sample_t_test(&data1, &data2, alpha)
    }).await.unwrap_or_else(|_| HypothesisTestResult::error("Task panicked"))
}

/// Chi-squared test
pub async fn chi_squared_test(
    observed: Vec<f64>,
    expected: Vec<f64>,
    alpha: f64,
) -> HypothesisTestResult {
    tokio::task::spawn_blocking(move || {
        statistics::chi_squared_test(&observed, &expected, alpha)
    }).await.unwrap_or_else(|_| HypothesisTestResult::error("Task panicked"))
}
// ============================================================================
// Discrete Mathematics
// ============================================================================

/// Check primality using Miller-Rabin
#[frb(sync)]
pub fn is_prime(n: u64) -> bool {
    discrete::is_prime(n)
}

/// Compute GCD
#[frb(sync)]
pub fn gcd(a: u64, b: u64) -> u64 {
    discrete::gcd(a, b)
}

/// Compute LCM
#[frb(sync)]
pub fn lcm(a: u64, b: u64) -> u64 {
    discrete::lcm(a, b)
}

/// Compute combinations nCr
#[frb(sync)]
pub fn combinations(n: u64, r: u64) -> DiscreteResult {
    discrete::combinations(n, r)
}

/// Compute permutations nPr
#[frb(sync)]
pub fn permutations(n: u64, r: u64) -> DiscreteResult {
    discrete::permutations(n, r)
}

/// Compute factorial
#[frb(sync)]
pub fn factorial(n: u64) -> DiscreteResult {
    discrete::factorial(n)
}

/// Modular exponentiation (a^b mod m)
#[frb(sync)]
pub fn mod_pow(base: u64, exp: u64, modulus: u64) -> DiscreteResult {
    discrete::mod_pow(base, exp, modulus)
}

/// Modular inverse
#[frb(sync)]
pub fn mod_inverse(a: u64, m: u64) -> DiscreteResult {
    discrete::mod_inverse(a, m)
}

/// Prime factorization
#[frb(sync)]
pub fn prime_factors(n: u64) -> DiscreteResult {
    discrete::prime_factors(n)
}

/// Generate primes up to n (sieve)
pub async fn sieve_primes(n: u64) -> DiscreteResult {
    tokio::task::spawn_blocking(move || {
        discrete::sieve_of_eratosthenes(n)
    }).await.unwrap_or_else(|_| DiscreteResult::error("Task panicked"))
}

/// Nth Fibonacci number
#[frb(sync)]
pub fn fibonacci(n: u64) -> DiscreteResult {
    discrete::fibonacci(n)
}

/// Euler's totient function
#[frb(sync)]
pub fn euler_totient(n: u64) -> DiscreteResult {
    discrete::euler_totient(n)
}

/// Get divisors of a number
#[frb(sync)]
pub fn list_divisors(n: u64) -> DiscreteResult {
    discrete::list_divisors(n)
}

/// Catalan number
#[frb(sync)]
pub fn catalan(n: u64) -> DiscreteResult {
    discrete::catalan(n)
}

/// Check if perfect number
#[frb(sync)]
pub fn is_perfect(n: u64) -> DiscreteResult {
    discrete::is_perfect(n)
}

// ============================================================================
// Unit Conversion
// ============================================================================

/// Convert between units
#[frb(sync)]
pub fn convert_unit(
    value: f64,
    from_unit: String,
    to_unit: String,
) -> UnitResult {
    units::convert_unit(value, &from_unit, &to_unit)
}

/// Get available units for a category
#[frb(sync)]
pub fn get_units_for_category(category: String) -> Vec<String> {
    units::get_units_in_category(&category)
}

/// Get all unit categories
#[frb(sync)]
pub fn get_unit_categories() -> Vec<String> {
    units::get_categories()
}

/// Convert to all units in same category
#[frb(sync)]
pub fn convert_to_all_units(value: f64, from_unit: String) -> Vec<UnitResult> {
    units::convert_to_all_in_category(value, &from_unit)
}

// ============================================================================
// Graphing (Parallel Function Evaluation)
// ============================================================================

/// Evaluate a function over a range for graphing
/// Uses rayon for parallel evaluation - extremely fast
pub async fn evaluate_graph_points(
    expression: String,
    variable: String,
    x_values: Vec<f64>,
) -> GraphResult {
    tokio::task::spawn_blocking(move || {
        graphing::evaluate_graph_points(&expression, &variable, &x_values)
    }).await.unwrap_or_else(|_| GraphResult::error("Task panicked"))
}

/// Generate x values for a range
#[frb(sync)]
pub fn generate_x_range(start: f64, end: f64, num_points: usize) -> Vec<f64> {
    graphing::generate_x_range(start, end, num_points)
}

/// Find function roots in a range
pub async fn find_graph_roots(
    expression: String,
    variable: String,
    x_min: f64,
    x_max: f64,
    num_samples: usize,
) -> Vec<f64> {
    tokio::task::spawn_blocking(move || {
        graphing::find_zeros(&expression, &variable, x_min, x_max, num_samples)
    }).await.unwrap_or_else(|_| vec![])
}

/// Find local extrema (maxima/minima) in a range
pub async fn find_extrema(
    expression: String,
    variable: String,
    x_min: f64,
    x_max: f64,
    num_samples: usize,
) -> (Vec<(f64, f64)>, Vec<(f64, f64)>) {
    tokio::task::spawn_blocking(move || {
        graphing::find_extrema(&expression, &variable, x_min, x_max, num_samples)
    }).await.unwrap_or_else(|_| (vec![], vec![]))
}

/// Compute derivative graph
pub async fn derivative_graph(
    expression: String,
    variable: String,
    x_values: Vec<f64>,
) -> GraphResult {
    tokio::task::spawn_blocking(move || {
        graphing::derivative_graph(&expression, &variable, &x_values)
    }).await.unwrap_or_else(|_| GraphResult::error("Task panicked"))
}

/// Compute integral graph (cumulative)
pub async fn integral_graph(
    expression: String,
    variable: String,
    x_values: Vec<f64>,
    initial_value: f64,
) -> GraphResult {
    tokio::task::spawn_blocking(move || {
        graphing::integral_graph(&expression, &variable, &x_values, initial_value)
    }).await.unwrap_or_else(|_| GraphResult::error("Task panicked"))
}

// ============================================================================
// Custom Formula Manager
// ============================================================================

/// Parse a custom formula and extract variables
#[frb(sync)]
pub fn parse_formula(formula: String) -> Vec<String> {
    basic::parse_formula_variables(&formula)
}

/// Evaluate a custom formula with given variable values
#[frb(sync)]
pub fn evaluate_formula(
    formula: String,
    variables: Vec<String>,
    values: Vec<f64>,
) -> ExpressionResult {
    basic::evaluate_formula(&formula, &variables, &values)
}

// ============================================================================
// Initialization
// ============================================================================

/// Initialize the math library (called once on app start)
#[frb(init)]
pub fn init_app() {
    // Initialize logging
    #[cfg(debug_assertions)]
    {
        let _ = env_logger::try_init();
    }
    
    // Pre-warm rayon thread pool
    rayon::ThreadPoolBuilder::new()
        .num_threads(num_cpus::get().max(2))
        .build_global()
        .ok();
}
