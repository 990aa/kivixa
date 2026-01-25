//! Calculus operations: differentiation, integration, equation solving

use serde::{Deserialize, Serialize};
use fasteval::{Compiler, Evaler, Slab};
use std::collections::BTreeMap;

/// Result of calculus operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalculusResult {
    pub success: bool,
    pub value: f64,
    pub symbolic: Option<String>,
    pub error: Option<String>,
}

impl CalculusResult {
    pub fn value(val: f64) -> Self {
        Self {
            success: true,
            value: val,
            symbolic: None,
            error: None,
        }
    }

    pub fn symbolic(expr: &str) -> Self {
        Self {
            success: true,
            value: f64::NAN,
            symbolic: Some(expr.to_string()),
            error: None,
        }
    }

    pub fn with_both(val: f64, expr: &str) -> Self {
        Self {
            success: true,
            value: val,
            symbolic: Some(expr.to_string()),
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            value: f64::NAN,
            symbolic: None,
            error: Some(msg.to_string()),
        }
    }
}

/// Result of equation solving
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SolveResult {
    pub success: bool,
    pub roots: Vec<f64>,
    pub iterations: usize,
    pub error: Option<String>,
}

impl SolveResult {
    pub fn roots(roots: Vec<f64>, iters: usize) -> Self {
        Self {
            success: true,
            roots,
            iterations: iters,
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            roots: vec![],
            iterations: 0,
            error: Some(msg.to_string()),
        }
    }
}

/// Evaluate expression with given variable value
fn eval_at(expr: &str, var: &str, val: f64) -> Result<f64, String> {
    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();
    
    let compiled = parser
        .parse(expr, &mut slab.ps)
        .map_err(|e| format!("Parse error: {:?}", e))?
        .from(&slab.ps)
        .compile(&slab.ps, &mut slab.cs);
    
    let mut map = BTreeMap::new();
    map.insert(var.to_string(), val);
    
    compiled
        .eval(&slab, &mut map)
        .map_err(|e| format!("Eval error: {:?}", e))
}

/// Numerical differentiation using central difference
pub fn differentiate(expression: &str, variable: &str, at_value: f64, order: u32) -> CalculusResult {
    if order == 0 {
        match eval_at(expression, variable, at_value) {
            Ok(val) => return CalculusResult::value(val),
            Err(e) => return CalculusResult::error(&e),
        }
    }

    let h = 1e-6;

    if order == 1 {
        // First derivative: (f(x+h) - f(x-h)) / (2h)
        let f_plus = match eval_at(expression, variable, at_value + h) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };
        let f_minus = match eval_at(expression, variable, at_value - h) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };
        let derivative = (f_plus - f_minus) / (2.0 * h);
        CalculusResult::value(derivative)
    } else if order == 2 {
        // Second derivative: (f(x+h) - 2f(x) + f(x-h)) / h²
        let f_plus = match eval_at(expression, variable, at_value + h) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };
        let f_center = match eval_at(expression, variable, at_value) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };
        let f_minus = match eval_at(expression, variable, at_value - h) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };
        let derivative = (f_plus - 2.0 * f_center + f_minus) / (h * h);
        CalculusResult::value(derivative)
    } else {
        // Higher order derivatives using recursive finite differences
        let h_adj = h.powf(1.0 / order as f64);
        
        fn finite_diff(expr: &str, var: &str, x: f64, h: f64, n: u32) -> Result<f64, String> {
            if n == 0 {
                return eval_at(expr, var, x);
            }
            let d1 = finite_diff(expr, var, x + h / 2.0, h, n - 1)?;
            let d2 = finite_diff(expr, var, x - h / 2.0, h, n - 1)?;
            Ok((d1 - d2) / h)
        }

        match finite_diff(expression, variable, at_value, h_adj, order) {
            Ok(val) => CalculusResult::value(val),
            Err(e) => CalculusResult::error(&e),
        }
    }
}

/// Numerical integration using adaptive Simpson's rule
pub fn integrate(
    expression: &str,
    variable: &str,
    lower_bound: f64,
    upper_bound: f64,
    num_intervals: u32,
) -> CalculusResult {
    if lower_bound >= upper_bound {
        return CalculusResult::error("Lower bound must be less than upper bound");
    }

    let n = if num_intervals < 2 { 100 } else { num_intervals };
    let n = if n % 2 == 1 { n + 1 } else { n }; // Must be even for Simpson's

    let h = (upper_bound - lower_bound) / n as f64;
    let mut sum = 0.0;

    // Simpson's 1/3 rule
    for i in 0..=n {
        let x = lower_bound + i as f64 * h;
        let y = match eval_at(expression, variable, x) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        let coeff = if i == 0 || i == n {
            1.0
        } else if i % 2 == 1 {
            4.0
        } else {
            2.0
        };

        sum += coeff * y;
    }

    let result = (h / 3.0) * sum;
    CalculusResult::value(result)
}

/// Solve equation f(x) = 0 using Newton-Raphson method
pub fn solve_equation(
    expression: &str,
    variable: &str,
    initial_guess: f64,
    tolerance: f64,
    max_iterations: u32,
) -> SolveResult {
    let tol = if tolerance <= 0.0 { 1e-10 } else { tolerance };
    let max_iter = if max_iterations == 0 { 100 } else { max_iterations };
    let h = 1e-8;

    let mut x = initial_guess;
    let mut iterations = 0;

    for i in 0..max_iter {
        iterations = i + 1;

        let fx = match eval_at(expression, variable, x) {
            Ok(v) => v,
            Err(e) => return SolveResult::error(&e),
        };

        if fx.abs() < tol {
            return SolveResult::roots(vec![x], iterations as usize);
        }

        // Numerical derivative
        let fx_plus = match eval_at(expression, variable, x + h) {
            Ok(v) => v,
            Err(e) => return SolveResult::error(&e),
        };
        let fx_minus = match eval_at(expression, variable, x - h) {
            Ok(v) => v,
            Err(e) => return SolveResult::error(&e),
        };
        let fpx = (fx_plus - fx_minus) / (2.0 * h);

        if fpx.abs() < 1e-15 {
            return SolveResult::error("Derivative near zero, cannot continue");
        }

        let x_new = x - fx / fpx;

        if (x_new - x).abs() < tol {
            return SolveResult::roots(vec![x_new], iterations as usize);
        }

        x = x_new;
    }

    SolveResult::error(&format!(
        "Did not converge within {} iterations. Last value: {}",
        max_iter, x
    ))
}

/// Find multiple roots using bisection across an interval
pub fn find_roots_in_interval(
    expression: &str,
    variable: &str,
    start: f64,
    end: f64,
    num_samples: u32,
) -> SolveResult {
    let samples = if num_samples < 10 { 100 } else { num_samples };
    let step = (end - start) / samples as f64;
    let mut roots: Vec<f64> = Vec::new();
    #[allow(unused_assignments)]
    let mut iterations = 0;

    let mut prev_x = start;
    let mut prev_y = match eval_at(expression, variable, prev_x) {
        Ok(v) => v,
        Err(_) => f64::NAN,
    };

    for i in 1..=samples {
        let x = start + i as f64 * step;
        let y = match eval_at(expression, variable, x) {
            Ok(v) => v,
            Err(_) => {
                prev_x = x;
                prev_y = f64::NAN;
                continue;
            }
        };

        // Sign change detected
        if !prev_y.is_nan() && !y.is_nan() && prev_y * y < 0.0 {
            // Bisection to find exact root
            let mut a = prev_x;
            let mut b = x;
            let mut fa = prev_y;

            for _ in 0..50 {
                iterations += 1;
                let mid = (a + b) / 2.0;
                let fm = match eval_at(expression, variable, mid) {
                    Ok(v) => v,
                    Err(_) => break,
                };

                if fm.abs() < 1e-10 || (b - a) / 2.0 < 1e-10 {
                    // Avoid duplicates
                    if roots.is_empty() || (mid - roots.last().unwrap()).abs() > 1e-8 {
                        roots.push(mid);
                    }
                    break;
                }

                if fa * fm < 0.0 {
                    b = mid;
                } else {
                    a = mid;
                    fa = fm;
                }
            }
        }

        prev_x = x;
        prev_y = y;
    }

    SolveResult::roots(roots, iterations)
}

/// Compute limit numerically
pub fn compute_limit(
    expression: &str,
    variable: &str,
    approach_value: f64,
    from_left: bool,
    from_right: bool,
) -> CalculusResult {
    let hs = [1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8];
    let mut values = Vec::new();

    for &h in &hs {
        if from_left && from_right {
            // Two-sided limit
            let left = eval_at(expression, variable, approach_value - h).ok();
            let right = eval_at(expression, variable, approach_value + h).ok();
            
            match (left, right) {
                (Some(l), Some(r)) => {
                    if (l - r).abs() < 1e-6 {
                        values.push((l + r) / 2.0);
                    }
                }
                _ => continue,
            }
        } else if from_left {
            if let Ok(v) = eval_at(expression, variable, approach_value - h) {
                values.push(v);
            }
        } else if from_right {
            if let Ok(v) = eval_at(expression, variable, approach_value + h) {
                values.push(v);
            }
        }
    }

    if values.is_empty() {
        return CalculusResult::error("Could not compute limit");
    }

    // Check convergence
    let last = *values.last().unwrap();
    let second_last = values.get(values.len().saturating_sub(2)).copied().unwrap_or(last);

    if (last - second_last).abs() < 1e-6 {
        CalculusResult::value(last)
    } else if last.is_infinite() {
        CalculusResult::with_both(last, if last > 0.0 { "+∞" } else { "-∞" })
    } else {
        CalculusResult::error("Limit may not exist or did not converge")
    }
}

/// Taylor series expansion coefficients
pub fn taylor_coefficients(
    expression: &str,
    variable: &str,
    around: f64,
    num_terms: u32,
) -> Vec<f64> {
    let mut coeffs = Vec::new();
    let mut factorial = 1u64;

    for n in 0..num_terms {
        if n > 0 {
            factorial *= n as u64;
        }

        let deriv = differentiate(expression, variable, around, n);
        if deriv.success {
            coeffs.push(deriv.value / factorial as f64);
        } else {
            coeffs.push(f64::NAN);
        }
    }

    coeffs
}
