//! Statistics and probability using statrs

use serde::{Deserialize, Serialize};
use statrs::distribution::{
    Bernoulli, Beta, Binomial, Cauchy, ChiSquared, Continuous, ContinuousCDF, Discrete,
    DiscreteCDF, Exp, FisherSnedecor, Gamma, Geometric, Hypergeometric, Normal, Poisson, StudentsT,
    Uniform,
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
    let median = if sorted.len().is_multiple_of(2) {
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
        "chi_squared" | "chi2" | "chisquared" => {
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
        "beta" => {
            let alpha = params.first().copied().unwrap_or(1.0);
            let beta = params.get(1).copied().unwrap_or(1.0);
            match Beta::new(alpha, beta) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "gamma" => {
            let shape = params.first().copied().unwrap_or(1.0);
            let rate = params.get(1).copied().unwrap_or(1.0);
            match Gamma::new(shape, rate) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "cauchy" => {
            let location = params.first().copied().unwrap_or(0.0);
            let scale = params.get(1).copied().unwrap_or(1.0);
            match Cauchy::new(location, scale) {
                Ok(dist) => DistributionResult::continuous(&dist, x),
                Err(e) => DistributionResult::error(&format!("Invalid parameters: {:?}", e)),
            }
        }
        "f" | "fisher" | "f_distribution" => {
            let d1 = params.first().copied().unwrap_or(1.0);
            let d2 = params.get(1).copied().unwrap_or(1.0);
            match FisherSnedecor::new(d1, d2) {
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
        "hypergeometric" => {
            // N = population size, K = success states in population, n = draws
            let big_n = params.first().copied().unwrap_or(50.0) as u64;
            let big_k = params.get(1).copied().unwrap_or(10.0) as u64;
            let n = params.get(2).copied().unwrap_or(5.0) as u64;
            match Hypergeometric::new(big_n, big_k, n) {
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
#[allow(clippy::needless_range_loop)]
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

/// One-sample z-test (known population standard deviation)
pub fn z_test(
    data: &[f64],
    hypothesized_mean: f64,
    population_std: f64,
    alpha: f64,
) -> HypothesisTestResult {
    if data.is_empty() {
        return HypothesisTestResult::error("Need at least 1 data point");
    }
    if population_std <= 0.0 {
        return HypothesisTestResult::error("Population standard deviation must be positive");
    }

    let n = data.len() as f64;
    let mean = data.mean();
    let se = population_std / n.sqrt();

    let z_stat = (mean - hypothesized_mean) / se;

    // Standard normal distribution
    let normal = match Normal::new(0.0, 1.0) {
        Ok(d) => d,
        Err(_) => return HypothesisTestResult::error("Failed to create normal distribution"),
    };

    let p_value = 2.0 * (1.0 - normal.cdf(z_stat.abs()));
    let critical = normal.inverse_cdf(1.0 - alpha / 2.0);

    // Confidence interval
    let margin = critical * se;
    let ci = (mean - margin, mean + margin);

    HypothesisTestResult {
        success: true,
        test_statistic: z_stat,
        p_value,
        critical_value: critical,
        reject_null: p_value < alpha,
        confidence_interval: ci,
        error: None,
    }
}

/// Two-sample z-test (known population standard deviations)
pub fn two_sample_z_test(
    data1: &[f64],
    data2: &[f64],
    std1: f64,
    std2: f64,
    alpha: f64,
) -> HypothesisTestResult {
    if data1.is_empty() || data2.is_empty() {
        return HypothesisTestResult::error("Need at least 1 data point in each sample");
    }
    if std1 <= 0.0 || std2 <= 0.0 {
        return HypothesisTestResult::error("Standard deviations must be positive");
    }

    let n1 = data1.len() as f64;
    let n2 = data2.len() as f64;
    let mean1 = data1.mean();
    let mean2 = data2.mean();

    let se = ((std1 * std1 / n1) + (std2 * std2 / n2)).sqrt();
    let z_stat = (mean1 - mean2) / se;

    let normal = match Normal::new(0.0, 1.0) {
        Ok(d) => d,
        Err(_) => return HypothesisTestResult::error("Failed to create normal distribution"),
    };

    let p_value = 2.0 * (1.0 - normal.cdf(z_stat.abs()));
    let critical = normal.inverse_cdf(1.0 - alpha / 2.0);

    let margin = critical * se;
    let diff = mean1 - mean2;
    let ci = (diff - margin, diff + margin);

    HypothesisTestResult {
        success: true,
        test_statistic: z_stat,
        p_value,
        critical_value: critical,
        reject_null: p_value < alpha,
        confidence_interval: ci,
        error: None,
    }
}

/// One-way ANOVA (Analysis of Variance)
/// Takes a vector of groups, where each group is a vector of observations
pub fn anova(groups: &[Vec<f64>], alpha: f64) -> HypothesisTestResult {
    if groups.len() < 2 {
        return HypothesisTestResult::error("Need at least 2 groups for ANOVA");
    }

    for (i, group) in groups.iter().enumerate() {
        if group.len() < 2 {
            return HypothesisTestResult::error(&format!(
                "Group {} needs at least 2 observations",
                i + 1
            ));
        }
    }

    let k = groups.len() as f64; // Number of groups
    let n: f64 = groups.iter().map(|g| g.len() as f64).sum(); // Total observations

    // Grand mean
    let grand_total: f64 = groups.iter().flat_map(|g| g.iter()).sum();
    let grand_mean = grand_total / n;

    // Between-group sum of squares (SSB)
    let ssb: f64 = groups
        .iter()
        .map(|g| {
            let group_mean: f64 = g.iter().sum::<f64>() / g.len() as f64;
            g.len() as f64 * (group_mean - grand_mean).powi(2)
        })
        .sum();

    // Within-group sum of squares (SSW)
    let ssw: f64 = groups
        .iter()
        .map(|g| {
            let group_mean: f64 = g.iter().sum::<f64>() / g.len() as f64;
            g.iter().map(|x| (x - group_mean).powi(2)).sum::<f64>()
        })
        .sum();

    let df_between = k - 1.0;
    let df_within = n - k;

    // Mean squares
    let msb = ssb / df_between;
    let msw = ssw / df_within;

    // F-statistic
    let f_stat = if msw.abs() < 1e-12 {
        return HypothesisTestResult::error("Within-group variance is zero");
    } else {
        msb / msw
    };

    // F-distribution
    let f_dist = match FisherSnedecor::new(df_between, df_within) {
        Ok(d) => d,
        Err(_) => return HypothesisTestResult::error("Failed to create F-distribution"),
    };

    let p_value = 1.0 - f_dist.cdf(f_stat);
    let critical = f_dist.inverse_cdf(1.0 - alpha);

    HypothesisTestResult {
        success: true,
        test_statistic: f_stat,
        p_value,
        critical_value: critical,
        reject_null: f_stat > critical,
        confidence_interval: (df_between, df_within), // Store degrees of freedom as a tuple
        error: None,
    }
}

/// Correlation and covariance result
#[derive(Debug, Clone)]
pub struct CorrelationResult {
    pub success: bool,
    pub correlation: f64,
    pub covariance: f64,
    pub p_value: f64,
    pub error: Option<String>,
}

impl CorrelationResult {
    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            correlation: f64::NAN,
            covariance: f64::NAN,
            p_value: f64::NAN,
            error: Some(msg.to_string()),
        }
    }
}

/// Calculate Pearson correlation coefficient and covariance
pub fn correlation_covariance(x: &[f64], y: &[f64]) -> CorrelationResult {
    if x.len() != y.len() {
        return CorrelationResult::error("X and Y must have the same length");
    }
    if x.len() < 3 {
        return CorrelationResult::error("Need at least 3 data points");
    }

    let n = x.len() as f64;
    let mean_x: f64 = x.iter().sum::<f64>() / n;
    let mean_y: f64 = y.iter().sum::<f64>() / n;

    let mut sum_xy = 0.0;
    let mut sum_x2 = 0.0;
    let mut sum_y2 = 0.0;

    for i in 0..x.len() {
        let dx = x[i] - mean_x;
        let dy = y[i] - mean_y;
        sum_xy += dx * dy;
        sum_x2 += dx * dx;
        sum_y2 += dy * dy;
    }

    // Covariance (sample)
    let covariance = sum_xy / (n - 1.0);

    // Pearson correlation
    let denom = (sum_x2 * sum_y2).sqrt();
    if denom < 1e-12 {
        return CorrelationResult::error("Variance is zero - cannot compute correlation");
    }
    let correlation = sum_xy / denom;

    // P-value using t-distribution transformation
    let df = n - 2.0;
    let t_stat = correlation * (df / (1.0 - correlation * correlation)).sqrt();

    let p_value = if let Ok(t_dist) = StudentsT::new(0.0, 1.0, df) {
        2.0 * (1.0 - t_dist.cdf(t_stat.abs()))
    } else {
        f64::NAN
    };

    CorrelationResult {
        success: true,
        correlation,
        covariance,
        p_value,
        error: None,
    }
}

/// Confidence interval result
#[derive(Debug, Clone)]
pub struct ConfidenceIntervalResult {
    pub success: bool,
    pub lower: f64,
    pub upper: f64,
    pub center: f64,
    pub margin_of_error: f64,
    pub error: Option<String>,
}

impl ConfidenceIntervalResult {
    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            lower: f64::NAN,
            upper: f64::NAN,
            center: f64::NAN,
            margin_of_error: f64::NAN,
            error: Some(msg.to_string()),
        }
    }
}

/// Calculate confidence interval for the mean
pub fn confidence_interval_mean(data: &[f64], confidence_level: f64) -> ConfidenceIntervalResult {
    if data.len() < 2 {
        return ConfidenceIntervalResult::error("Need at least 2 data points");
    }
    if confidence_level <= 0.0 || confidence_level >= 1.0 {
        return ConfidenceIntervalResult::error("Confidence level must be between 0 and 1");
    }

    let n = data.len() as f64;
    let mean = data.mean();
    let std_dev = data.std_dev();
    let se = std_dev / n.sqrt();
    let df = n - 1.0;
    let alpha = 1.0 - confidence_level;

    let t_dist = match StudentsT::new(0.0, 1.0, df) {
        Ok(d) => d,
        Err(_) => return ConfidenceIntervalResult::error("Failed to create t-distribution"),
    };

    let critical = t_dist.inverse_cdf(1.0 - alpha / 2.0);
    let margin = critical * se;

    ConfidenceIntervalResult {
        success: true,
        lower: mean - margin,
        upper: mean + margin,
        center: mean,
        margin_of_error: margin,
        error: None,
    }
}

/// Calculate confidence interval for proportion
pub fn confidence_interval_proportion(
    successes: u64,
    n: u64,
    confidence_level: f64,
) -> ConfidenceIntervalResult {
    if n == 0 {
        return ConfidenceIntervalResult::error("Sample size must be greater than 0");
    }
    if successes > n {
        return ConfidenceIntervalResult::error("Successes cannot exceed sample size");
    }
    if confidence_level <= 0.0 || confidence_level >= 1.0 {
        return ConfidenceIntervalResult::error("Confidence level must be between 0 and 1");
    }

    let p = successes as f64 / n as f64;
    let alpha = 1.0 - confidence_level;

    // Use normal approximation (valid for np and n(1-p) >= 10)
    let normal = match Normal::new(0.0, 1.0) {
        Ok(d) => d,
        Err(_) => return ConfidenceIntervalResult::error("Failed to create normal distribution"),
    };

    let z = normal.inverse_cdf(1.0 - alpha / 2.0);
    let se = (p * (1.0 - p) / n as f64).sqrt();
    let margin = z * se;

    ConfidenceIntervalResult {
        success: true,
        lower: (p - margin).max(0.0),
        upper: (p + margin).min(1.0),
        center: p,
        margin_of_error: margin,
        error: None,
    }
}

/// Calculate confidence interval for variance (using chi-squared distribution)
pub fn confidence_interval_variance(
    data: &[f64],
    confidence_level: f64,
) -> ConfidenceIntervalResult {
    if data.len() < 2 {
        return ConfidenceIntervalResult::error("Need at least 2 data points");
    }
    if confidence_level <= 0.0 || confidence_level >= 1.0 {
        return ConfidenceIntervalResult::error("Confidence level must be between 0 and 1");
    }

    let n = data.len() as f64;
    let variance = data.variance();
    let df = n - 1.0;
    let alpha = 1.0 - confidence_level;

    let chi_dist = match ChiSquared::new(df) {
        Ok(d) => d,
        Err(_) => {
            return ConfidenceIntervalResult::error("Failed to create chi-squared distribution")
        }
    };

    let chi_lower = chi_dist.inverse_cdf(alpha / 2.0);
    let chi_upper = chi_dist.inverse_cdf(1.0 - alpha / 2.0);

    // CI for variance: ((n-1)s^2 / chi_upper, (n-1)s^2 / chi_lower)
    let lower = df * variance / chi_upper;
    let upper = df * variance / chi_lower;

    ConfidenceIntervalResult {
        success: true,
        lower,
        upper,
        center: variance,
        margin_of_error: (upper - lower) / 2.0,
        error: None,
    }
}
