//! Statistics and probability using statrs

use serde::{Deserialize, Serialize};
use statrs::distribution::{
    Bernoulli, Binomial, ChiSquared, Continuous, ContinuousCDF, Discrete, DiscreteCDF, Exp,
    Geometric, Normal, Poisson, StudentsT, Uniform,
};
use statrs::statistics::{Distribution, Statistics};

/// Result of statistical computations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatisticsResult {
    pub success: bool,
    pub values: Vec<(String, f64)>,
    pub error: Option<String>,
}

impl StatisticsResult {
    pub fn new(values: Vec<(String, f64)>) -> Self {
        Self {
            success: true,
            values,
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            values: vec![],
            error: Some(msg.to_string()),
        }
    }
}

/// Result of distribution computations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DistributionResult {
    pub success: bool,
    pub pdf: f64,
    pub cdf: f64,
    pub mean: f64,
    pub variance: f64,
    pub std_dev: f64,
    pub error: Option<String>,
}

impl DistributionResult {
    pub fn continuous<D: Continuous<f64, f64> + ContinuousCDF<f64, f64> + Distribution<f64>>(
        dist: &D,
        x: f64,
    ) -> Self {
        let mean = dist.mean().unwrap_or(f64::NAN);
        let variance = dist.variance().unwrap_or(f64::NAN);
        Self {
            success: true,
            pdf: dist.pdf(x),
            cdf: dist.cdf(x),
            mean,
            variance,
            std_dev: variance.sqrt(),
            error: None,
        }
    }

    pub fn discrete<D: Discrete<u64, f64> + DiscreteCDF<u64, f64> + Distribution<f64>>(
        dist: &D,
        x: u64,
    ) -> Self {
        let mean = dist.mean().unwrap_or(f64::NAN);
        let variance = dist.variance().unwrap_or(f64::NAN);
        Self {
            success: true,
            pdf: dist.pmf(x),
            cdf: dist.cdf(x),
            mean,
            variance,
            std_dev: variance.sqrt(),
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            pdf: f64::NAN,
            cdf: f64::NAN,
            mean: f64::NAN,
            variance: f64::NAN,
            std_dev: f64::NAN,
            error: Some(msg.to_string()),
        }
    }
}

/// Result of regression analysis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegressionResult {
    pub success: bool,
    pub coefficients: Vec<f64>,
    pub r_squared: f64,
    pub residuals: Vec<f64>,
    pub error: Option<String>,
}

impl RegressionResult {
    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            coefficients: vec![],
            r_squared: f64::NAN,
            residuals: vec![],
            error: Some(msg.to_string()),
        }
    }
}

/// Result of hypothesis tests
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HypothesisTestResult {
    pub success: bool,
    pub test_statistic: f64,
    pub p_value: f64,
    pub critical_value: f64,
    pub reject_null: bool,
    pub confidence_interval: (f64, f64),
    pub error: Option<String>,
}

impl HypothesisTestResult {
    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            test_statistic: f64::NAN,
            p_value: f64::NAN,
            critical_value: f64::NAN,
            reject_null: false,
            confidence_interval: (f64::NAN, f64::NAN),
            error: Some(msg.to_string()),
        }
    }
}

/// Compute descriptive statistics
pub fn compute_statistics(data: &[f64]) -> StatisticsResult {
    if data.is_empty() {
        return StatisticsResult::error("No data provided");
    }

    let mut sorted = data.to_vec();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

    let n = data.len() as f64;
    let mean = data.mean();
    let variance = data.variance();
    let std_dev = variance.sqrt();
    let min = data.min();
    let max = data.max();

    // Median
    let median = if sorted.len() % 2 == 0 {
        (sorted[sorted.len() / 2 - 1] + sorted[sorted.len() / 2]) / 2.0
    } else {
        sorted[sorted.len() / 2]
    };

    // Quartiles
    let q1_idx = (0.25 * (n - 1.0)) as usize;
    let q3_idx = (0.75 * (n - 1.0)) as usize;
    let q1 = sorted.get(q1_idx).copied().unwrap_or(f64::NAN);
    let q3 = sorted.get(q3_idx).copied().unwrap_or(f64::NAN);
    let iqr = q3 - q1;

    // Mode (most frequent value, approximate for floats)
    let mode = find_mode(&sorted);

    // Skewness and kurtosis
    let skewness = if n > 2.0 && std_dev > 0.0 {
        let m3 = data
            .iter()
            .map(|x| ((x - mean) / std_dev).powi(3))
            .sum::<f64>()
            / n;
        m3
    } else {
        f64::NAN
    };

    let kurtosis = if n > 3.0 && std_dev > 0.0 {
        let m4 = data
            .iter()
            .map(|x| ((x - mean) / std_dev).powi(4))
            .sum::<f64>()
            / n;
        m4 - 3.0 // Excess kurtosis
    } else {
        f64::NAN
    };

    StatisticsResult::new(vec![
        ("count".to_string(), n),
        ("mean".to_string(), mean),
        ("median".to_string(), median),
        ("mode".to_string(), mode),
        ("variance".to_string(), variance),
        ("std_dev".to_string(), std_dev),
        ("min".to_string(), min),
        ("max".to_string(), max),
        ("range".to_string(), max - min),
        ("q1".to_string(), q1),
        ("q3".to_string(), q3),
        ("iqr".to_string(), iqr),
        ("skewness".to_string(), skewness),
        ("kurtosis".to_string(), kurtosis),
    ])
}

/// Find mode of sorted data
fn find_mode(sorted: &[f64]) -> f64 {
    if sorted.is_empty() {
        return f64::NAN;
    }

    let mut max_count = 1;
    let mut current_count = 1;
    let mut mode = sorted[0];

    for i in 1..sorted.len() {
        if (sorted[i] - sorted[i - 1]).abs() < 1e-10 {
            current_count += 1;
        } else {
            if current_count > max_count {
                max_count = current_count;
                mode = sorted[i - 1];
            }
            current_count = 1;
        }
    }

    if current_count > max_count {
        mode = *sorted.last().unwrap();
    }

    mode
}

/// Compute distribution values
pub fn distribution_compute(distribution_type: &str, params: &[f64], x: f64) -> DistributionResult {
    match distribution_type.to_lowercase().as_str() {
        "normal" | "gaussian" => {
            let mean = params.first().copied().unwrap_or(0.0);
            let std_dev = params.get(1).copied().unwrap_or(1.0);
            if std_dev <= 0.0 {
                return DistributionResult::error("Standard deviation must be positive");
            }
            match Normal::new(mean, std_dev) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "uniform" => {
            let min = params.first().copied().unwrap_or(0.0);
            let max = params.get(1).copied().unwrap_or(1.0);
            match Uniform::new(min, max) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "exponential" => {
            let rate = params.first().copied().unwrap_or(1.0);
            match Exp::new(rate) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "chi_squared" | "chi2" => {
            let df = params.first().copied().unwrap_or(1.0);
            match ChiSquared::new(df) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "t" | "student_t" | "students_t" => {
            let df = params.first().copied().unwrap_or(1.0);
            match StudentsT::new(0.0, 1.0, df) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "binomial" => {
            let n = params.first().copied().unwrap_or(10.0) as u64;
            let p = params.get(1).copied().unwrap_or(0.5);
            match Binomial::new(p, n) {
                Ok(dist) => DistributionResult::discrete(&dist, x as u64),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "poisson" => {
            let lambda = params.first().copied().unwrap_or(1.0);
            match Poisson::new(lambda) {
                Ok(dist) => DistributionResult::discrete(&dist, x as u64),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "geometric" => {
            let p = params.first().copied().unwrap_or(0.5);
            match Geometric::new(p) {
                Ok(dist) => DistributionResult::discrete(&dist, x as u64),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "bernoulli" => {
            let p = params.first().copied().unwrap_or(0.5);
            match Bernoulli::new(p) {
                Ok(dist) => DistributionResult::discrete(&dist, x as u64),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        _ => DistributionResult::error(&format!("Unknown distribution: {}", distribution_type)),
    }
}

/// Linear regression (y = mx + b)
pub fn linear_regression(x: &[f64], y: &[f64]) -> RegressionResult {
    if x.len() != y.len() || x.is_empty() {
        return RegressionResult::error("X and Y must have same non-zero length");
    }

    let n = x.len() as f64;
    let sum_x: f64 = x.iter().sum();
    let sum_y: f64 = y.iter().sum();
    let sum_xy: f64 = x.iter().zip(y.iter()).map(|(xi, yi)| xi * yi).sum();
    let sum_x2: f64 = x.iter().map(|xi| xi * xi).sum();

    let mean_x = sum_x / n;
    let mean_y = sum_y / n;

    let slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x);
    let intercept = mean_y - slope * mean_x;

    // R-squared
    let ss_tot: f64 = y.iter().map(|yi| (yi - mean_y).powi(2)).sum();
    let residuals: Vec<f64> = x
        .iter()
        .zip(y.iter())
        .map(|(xi, yi)| yi - (slope * xi + intercept))
        .collect();
    let ss_res: f64 = residuals.iter().map(|r| r * r).sum();
    let r_squared = 1.0 - ss_res / ss_tot;

    RegressionResult {
        success: true,
        coefficients: vec![intercept, slope],
        r_squared,
        residuals,
        error: None,
    }
}

/// Polynomial regression
pub fn polynomial_regression(x: &[f64], y: &[f64], degree: usize) -> RegressionResult {
    if x.len() != y.len() || x.is_empty() || degree == 0 {
        return RegressionResult::error("Invalid input data");
    }

    let n = x.len();
    let m = degree + 1;

    // Build Vandermonde-like matrix (normal equations)
    let mut xtx = vec![0.0; m * m];
    let mut xty = vec![0.0; m];

    for i in 0..n {
        for j in 0..m {
            let xj = x[i].powi(j as i32);
            xty[j] += xj * y[i];
            for k in 0..m {
                xtx[j * m + k] += xj * x[i].powi(k as i32);
            }
        }
    }

    // Solve using Gaussian elimination
    let coeffs = match solve_linear_system(&xtx, &xty, m) {
        Some(c) => c,
        None => return RegressionResult::error("Failed to solve regression"),
    };

    // Calculate R-squared
    let mean_y: f64 = y.iter().sum::<f64>() / n as f64;
    let ss_tot: f64 = y.iter().map(|yi| (yi - mean_y).powi(2)).sum();

    let residuals: Vec<f64> = x
        .iter()
        .zip(y.iter())
        .map(|(xi, yi)| {
            let pred: f64 = coeffs
                .iter()
                .enumerate()
                .map(|(j, cj)| cj * xi.powi(j as i32))
                .sum();
            yi - pred
        })
        .collect();

    let ss_res: f64 = residuals.iter().map(|r| r * r).sum();
    let r_squared = 1.0 - ss_res / ss_tot;

    RegressionResult {
        success: true,
        coefficients: coeffs,
        r_squared,
        residuals,
        error: None,
    }
}

/// Solve linear system Ax = b using Gaussian elimination
fn solve_linear_system(a: &[f64], b: &[f64], n: usize) -> Option<Vec<f64>> {
    let mut aug = vec![vec![0.0; n + 1]; n];

    for i in 0..n {
        for j in 0..n {
            aug[i][j] = a[i * n + j];
        }
        aug[i][n] = b[i];
    }

    // Forward elimination
    for i in 0..n {
        // Find pivot
        let mut max_row = i;
        for k in (i + 1)..n {
            if aug[k][i].abs() > aug[max_row][i].abs() {
                max_row = k;
            }
        }
        aug.swap(i, max_row);

        if aug[i][i].abs() < 1e-12 {
            return None;
        }

        for k in (i + 1)..n {
            let factor = aug[k][i] / aug[i][i];
            for j in i..=n {
                aug[k][j] -= factor * aug[i][j];
            }
        }
    }

    // Back substitution
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        x[i] = aug[i][n];
        for j in (i + 1)..n {
            x[i] -= aug[i][j] * x[j];
        }
        x[i] /= aug[i][i];
    }

    Some(x)
}

/// One-sample t-test
pub fn t_test(data: &[f64], hypothesized_mean: f64, alpha: f64) -> HypothesisTestResult {
    if data.len() < 2 {
        return HypothesisTestResult::error("Need at least 2 data points");
    }

    let n = data.len() as f64;
    let mean = data.mean();
    let std_dev = data.std_dev();
    let se = std_dev / n.sqrt();
    let df = n - 1.0;

    let t_stat = (mean - hypothesized_mean) / se;

    // Get critical value and p-value from t-distribution
    let t_dist = match StudentsT::new(0.0, 1.0, df) {
        Ok(d) => d,
        Err(_) => return HypothesisTestResult::error("Failed to create t-distribution"),
    };

    let p_value = 2.0 * (1.0 - t_dist.cdf(t_stat.abs()));
    let critical = t_dist.inverse_cdf(1.0 - alpha / 2.0);

    // Confidence interval
    let margin = critical * se;
    let ci = (mean - margin, mean + margin);

    HypothesisTestResult {
        success: true,
        test_statistic: t_stat,
        p_value,
        critical_value: critical,
        reject_null: p_value < alpha,
        confidence_interval: ci,
        error: None,
    }
}

/// Two-sample t-test
pub fn two_sample_t_test(data1: &[f64], data2: &[f64], alpha: f64) -> HypothesisTestResult {
    if data1.len() < 2 || data2.len() < 2 {
        return HypothesisTestResult::error("Need at least 2 data points in each sample");
    }

    let n1 = data1.len() as f64;
    let n2 = data2.len() as f64;
    let mean1 = data1.mean();
    let mean2 = data2.mean();
    let var1 = data1.variance();
    let var2 = data2.variance();

    // Welch's t-test (unequal variances)
    let se = (var1 / n1 + var2 / n2).sqrt();
    let t_stat = (mean1 - mean2) / se;

    // Welch-Satterthwaite degrees of freedom
    let num = (var1 / n1 + var2 / n2).powi(2);
    let denom = (var1 / n1).powi(2) / (n1 - 1.0) + (var2 / n2).powi(2) / (n2 - 1.0);
    let df = num / denom;

    let t_dist = match StudentsT::new(0.0, 1.0, df) {
        Ok(d) => d,
        Err(_) => return HypothesisTestResult::error("Failed to create t-distribution"),
    };

    let p_value = 2.0 * (1.0 - t_dist.cdf(t_stat.abs()));
    let critical = t_dist.inverse_cdf(1.0 - alpha / 2.0);

    let margin = critical * se;
    let diff = mean1 - mean2;
    let ci = (diff - margin, diff + margin);

    HypothesisTestResult {
        success: true,
        test_statistic: t_stat,
        p_value,
        critical_value: critical,
        reject_null: p_value < alpha,
        confidence_interval: ci,
        error: None,
    }
}

/// Chi-squared test for independence
pub fn chi_squared_test(observed: &[f64], expected: &[f64], alpha: f64) -> HypothesisTestResult {
    if observed.len() != expected.len() || observed.is_empty() {
        return HypothesisTestResult::error("Observed and expected must have same non-zero length");
    }

    let chi_sq: f64 = observed
        .iter()
        .zip(expected.iter())
        .map(|(o, e)| if *e > 0.0 { (o - e).powi(2) / e } else { 0.0 })
        .sum();

    let df = (observed.len() - 1) as f64;

    let chi_dist = match ChiSquared::new(df) {
        Ok(d) => d,
        Err(_) => return HypothesisTestResult::error("Failed to create chi-squared distribution"),
    };

    let p_value = 1.0 - chi_dist.cdf(chi_sq);
    let critical = chi_dist.inverse_cdf(1.0 - alpha);

    HypothesisTestResult {
        success: true,
        test_statistic: chi_sq,
        p_value,
        critical_value: critical,
        reject_null: chi_sq > critical,
        confidence_interval: (f64::NAN, f64::NAN),
        error: None,
    }
}
