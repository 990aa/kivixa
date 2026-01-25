//! Calculus operations: differentiation, integration, equation solving

use fasteval::{Compiler, Evaler, Slab};
use serde::{Deserialize, Serialize};
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
pub fn differentiate(
    expression: &str,
    variable: &str,
    at_value: f64,
    order: u32,
) -> CalculusResult {
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

    let n = if num_intervals < 2 {
        100
    } else {
        num_intervals
    };
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
    let max_iter = if max_iterations == 0 {
        100
    } else {
        max_iterations
    };
    let h = 1e-8;

    let mut x = initial_guess;

    for i in 0..max_iter {
        let iterations = i + 1;

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
    let second_last = values
        .get(values.len().saturating_sub(2))
        .copied()
        .unwrap_or(last);

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

// ============================================================================
// Partial Differentiation
// ============================================================================

/// Evaluate expression with multiple variables
fn eval_with_vars(expr: &str, vars: &BTreeMap<String, f64>) -> Result<f64, String> {
    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();

    let compiled = parser
        .parse(expr, &mut slab.ps)
        .map_err(|e| format!("Parse error: {:?}", e))?
        .from(&slab.ps)
        .compile(&slab.ps, &mut slab.cs);

    compiled
        .eval(&slab, &mut vars.clone())
        .map_err(|e| format!("Eval error: {:?}", e))
}

/// Partial derivative with respect to one variable
/// Uses central difference: ∂f/∂x ≈ (f(x+h) - f(x-h)) / (2h)
pub fn partial_derivative(
    expression: &str,
    variable: &str,
    point: Vec<(&str, f64)>,
    order: u32,
) -> CalculusResult {
    if order == 0 {
        let vars: BTreeMap<String, f64> = point.iter().map(|(k, v)| (k.to_string(), *v)).collect();
        match eval_with_vars(expression, &vars) {
            Ok(val) => return CalculusResult::value(val),
            Err(e) => return CalculusResult::error(&e),
        }
    }

    let h = 1e-6;
    let mut vars: BTreeMap<String, f64> = point.iter().map(|(k, v)| (k.to_string(), *v)).collect();

    if order == 1 {
        let original = *vars.get(variable).ok_or("Variable not found").unwrap_or(&0.0);

        // f(x+h)
        vars.insert(variable.to_string(), original + h);
        let f_plus = match eval_with_vars(expression, &vars) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        // f(x-h)
        vars.insert(variable.to_string(), original - h);
        let f_minus = match eval_with_vars(expression, &vars) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        let derivative = (f_plus - f_minus) / (2.0 * h);
        CalculusResult::value(derivative)
    } else if order == 2 {
        let original = *vars.get(variable).ok_or("Variable not found").unwrap_or(&0.0);

        // f(x+h)
        vars.insert(variable.to_string(), original + h);
        let f_plus = match eval_with_vars(expression, &vars) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        // f(x)
        vars.insert(variable.to_string(), original);
        let f_center = match eval_with_vars(expression, &vars) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        // f(x-h)
        vars.insert(variable.to_string(), original - h);
        let f_minus = match eval_with_vars(expression, &vars) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        let derivative = (f_plus - 2.0 * f_center + f_minus) / (h * h);
        CalculusResult::value(derivative)
    } else {
        // Higher order using recursive approach
        let h_adj = h.powf(1.0 / order as f64);

        fn partial_finite_diff(
            expr: &str,
            var: &str,
            vars: &BTreeMap<String, f64>,
            h: f64,
            n: u32,
        ) -> Result<f64, String> {
            if n == 0 {
                return eval_with_vars(expr, vars);
            }
            let original = *vars.get(var).ok_or("Variable not found")?;

            let mut vars_plus = vars.clone();
            vars_plus.insert(var.to_string(), original + h / 2.0);
            let d1 = partial_finite_diff(expr, var, &vars_plus, h, n - 1)?;

            let mut vars_minus = vars.clone();
            vars_minus.insert(var.to_string(), original - h / 2.0);
            let d2 = partial_finite_diff(expr, var, &vars_minus, h, n - 1)?;

            Ok((d1 - d2) / h)
        }

        match partial_finite_diff(expression, variable, &vars, h_adj, order) {
            Ok(val) => CalculusResult::value(val),
            Err(e) => CalculusResult::error(&e),
        }
    }
}

/// Mixed partial derivative ∂²f/∂x∂y
/// Uses central differences for both variables
pub fn mixed_partial_derivative(
    expression: &str,
    var1: &str,
    var2: &str,
    point: Vec<(&str, f64)>,
) -> CalculusResult {
    let h = 1e-5;
    let vars: BTreeMap<String, f64> = point.iter().map(|(k, v)| (k.to_string(), *v)).collect();

    let x0 = *vars.get(var1).unwrap_or(&0.0);
    let y0 = *vars.get(var2).unwrap_or(&0.0);

    // ∂²f/∂x∂y ≈ [f(x+h,y+h) - f(x+h,y-h) - f(x-h,y+h) + f(x-h,y-h)] / (4h²)
    let mut v_pp = vars.clone();
    v_pp.insert(var1.to_string(), x0 + h);
    v_pp.insert(var2.to_string(), y0 + h);

    let mut v_pm = vars.clone();
    v_pm.insert(var1.to_string(), x0 + h);
    v_pm.insert(var2.to_string(), y0 - h);

    let mut v_mp = vars.clone();
    v_mp.insert(var1.to_string(), x0 - h);
    v_mp.insert(var2.to_string(), y0 + h);

    let mut v_mm = vars.clone();
    v_mm.insert(var1.to_string(), x0 - h);
    v_mm.insert(var2.to_string(), y0 - h);

    let f_pp = match eval_with_vars(expression, &v_pp) {
        Ok(v) => v,
        Err(e) => return CalculusResult::error(&e),
    };
    let f_pm = match eval_with_vars(expression, &v_pm) {
        Ok(v) => v,
        Err(e) => return CalculusResult::error(&e),
    };
    let f_mp = match eval_with_vars(expression, &v_mp) {
        Ok(v) => v,
        Err(e) => return CalculusResult::error(&e),
    };
    let f_mm = match eval_with_vars(expression, &v_mm) {
        Ok(v) => v,
        Err(e) => return CalculusResult::error(&e),
    };

    let mixed = (f_pp - f_pm - f_mp + f_mm) / (4.0 * h * h);
    CalculusResult::value(mixed)
}

/// Gradient vector (all first partial derivatives)
pub fn gradient(
    expression: &str,
    variables: &[&str],
    point: Vec<(&str, f64)>,
) -> Vec<f64> {
    variables
        .iter()
        .map(|var| {
            let result = partial_derivative(expression, var, point.clone(), 1);
            if result.success {
                result.value
            } else {
                f64::NAN
            }
        })
        .collect()
}

// ============================================================================
// Multiple Integration
// ============================================================================

/// Double integral using iterated Simpson's rule
/// ∫∫ f(x,y) dx dy over [x_min, x_max] × [y_min, y_max]
pub fn double_integral(
    expression: &str,
    x_var: &str,
    y_var: &str,
    x_min: f64,
    x_max: f64,
    y_min: f64,
    y_max: f64,
    num_intervals: u32,
) -> CalculusResult {
    if x_min >= x_max || y_min >= y_max {
        return CalculusResult::error("Lower bounds must be less than upper bounds");
    }

    let n = if num_intervals < 4 { 50 } else { num_intervals };
    let n = if n % 2 == 1 { n + 1 } else { n }; // Must be even for Simpson's

    let hx = (x_max - x_min) / n as f64;
    let hy = (y_max - y_min) / n as f64;

    let mut sum = 0.0;

    for i in 0..=n {
        let x = x_min + i as f64 * hx;
        let wx = if i == 0 || i == n {
            1.0
        } else if i % 2 == 1 {
            4.0
        } else {
            2.0
        };

        for j in 0..=n {
            let y = y_min + j as f64 * hy;
            let wy = if j == 0 || j == n {
                1.0
            } else if j % 2 == 1 {
                4.0
            } else {
                2.0
            };

            let mut vars = BTreeMap::new();
            vars.insert(x_var.to_string(), x);
            vars.insert(y_var.to_string(), y);

            let f_val = match eval_with_vars(expression, &vars) {
                Ok(v) => v,
                Err(e) => return CalculusResult::error(&e),
            };

            sum += wx * wy * f_val;
        }
    }

    let result = (hx / 3.0) * (hy / 3.0) * sum;
    CalculusResult::value(result)
}

/// Triple integral using iterated Simpson's rule
/// ∫∫∫ f(x,y,z) dx dy dz over [x_min, x_max] × [y_min, y_max] × [z_min, z_max]
pub fn triple_integral(
    expression: &str,
    x_var: &str,
    y_var: &str,
    z_var: &str,
    x_min: f64,
    x_max: f64,
    y_min: f64,
    y_max: f64,
    z_min: f64,
    z_max: f64,
    num_intervals: u32,
) -> CalculusResult {
    if x_min >= x_max || y_min >= y_max || z_min >= z_max {
        return CalculusResult::error("Lower bounds must be less than upper bounds");
    }

    // Use fewer intervals for triple integral due to O(n³) complexity
    let n = if num_intervals < 4 { 20 } else { num_intervals.min(40) };
    let n = if n % 2 == 1 { n + 1 } else { n };

    let hx = (x_max - x_min) / n as f64;
    let hy = (y_max - y_min) / n as f64;
    let hz = (z_max - z_min) / n as f64;

    let mut sum = 0.0;

    for i in 0..=n {
        let x = x_min + i as f64 * hx;
        let wx = if i == 0 || i == n {
            1.0
        } else if i % 2 == 1 {
            4.0
        } else {
            2.0
        };

        for j in 0..=n {
            let y = y_min + j as f64 * hy;
            let wy = if j == 0 || j == n {
                1.0
            } else if j % 2 == 1 {
                4.0
            } else {
                2.0
            };

            for k in 0..=n {
                let z = z_min + k as f64 * hz;
                let wz = if k == 0 || k == n {
                    1.0
                } else if k % 2 == 1 {
                    4.0
                } else {
                    2.0
                };

                let mut vars = BTreeMap::new();
                vars.insert(x_var.to_string(), x);
                vars.insert(y_var.to_string(), y);
                vars.insert(z_var.to_string(), z);

                let f_val = match eval_with_vars(expression, &vars) {
                    Ok(v) => v,
                    Err(e) => return CalculusResult::error(&e),
                };

                sum += wx * wy * wz * f_val;
            }
        }
    }

    let result = (hx / 3.0) * (hy / 3.0) * (hz / 3.0) * sum;
    CalculusResult::value(result)
}

/// Line integral along a parameterized path
/// ∫_C f(x,y) ds where x = x(t), y = y(t) for t in [t_min, t_max]
pub fn line_integral(
    expression: &str,
    x_param: &str,  // expression for x(t)
    y_param: &str,  // expression for y(t)
    t_var: &str,
    t_min: f64,
    t_max: f64,
    num_intervals: u32,
) -> CalculusResult {
    if t_min >= t_max {
        return CalculusResult::error("t_min must be less than t_max");
    }

    let n = if num_intervals < 10 { 100 } else { num_intervals };
    let h = (t_max - t_min) / n as f64;

    let mut sum = 0.0;

    for i in 0..n {
        let t = t_min + i as f64 * h;
        let t_next = t + h;
        let t_mid = t + h / 2.0;

        // Evaluate x(t), y(t) at midpoint
        let x_val = match eval_at(x_param, t_var, t_mid) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };
        let y_val = match eval_at(y_param, t_var, t_mid) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        // Evaluate f at (x(t), y(t))
        let mut vars = BTreeMap::new();
        vars.insert("x".to_string(), x_val);
        vars.insert("y".to_string(), y_val);
        let f_val = match eval_with_vars(expression, &vars) {
            Ok(v) => v,
            Err(e) => return CalculusResult::error(&e),
        };

        // Compute ds = sqrt(dx² + dy²)
        let x1 = eval_at(x_param, t_var, t).unwrap_or(0.0);
        let x2 = eval_at(x_param, t_var, t_next).unwrap_or(0.0);
        let y1 = eval_at(y_param, t_var, t).unwrap_or(0.0);
        let y2 = eval_at(y_param, t_var, t_next).unwrap_or(0.0);

        let ds = ((x2 - x1).powi(2) + (y2 - y1).powi(2)).sqrt();
        sum += f_val * ds;
    }

    CalculusResult::value(sum)
}
