//! Graphing utilities: evaluate functions in parallel for plotting

use fasteval::{Compiler, Evaler, Slab};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// Point on a graph
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphPoint {
    pub x: f64,
    pub y: f64,
    pub valid: bool,
}

/// Result of graph evaluation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphResult {
    pub success: bool,
    pub points: Vec<GraphPoint>,
    pub x_min: f64,
    pub x_max: f64,
    pub y_min: f64,
    pub y_max: f64,
    pub error: Option<String>,
}

impl GraphResult {
    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            points: vec![],
            x_min: 0.0,
            x_max: 0.0,
            y_min: 0.0,
            y_max: 0.0,
            error: Some(msg.to_string()),
        }
    }
}

/// Evaluate a function at multiple x values in parallel
pub fn evaluate_graph_points(
    expression: &str,
    variable: &str,
    x_values: &[f64],
) -> GraphResult {
    if x_values.is_empty() {
        return GraphResult::error("No x values provided");
    }

    // Pre-compile the expression
    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();
    
    let compiled = match parser.parse(expression, &mut slab.ps) {
        Ok(expr) => expr.from(&slab.ps).compile(&slab.ps, &mut slab.cs),
        Err(e) => return GraphResult::error(&format!("Parse error: {:?}", e)),
    };

    // Evaluate in parallel
    let points: Vec<GraphPoint> = x_values
        .par_iter()
        .map(|&x| {
            let mut map = BTreeMap::new();
            map.insert(variable.to_string(), x);
            
            match compiled.eval(&slab, &mut map) {
                Ok(y) if y.is_finite() => GraphPoint { x, y, valid: true },
                _ => GraphPoint { x, y: f64::NAN, valid: false },
            }
        })
        .collect();

    // Calculate bounds from valid points
    let valid_points: Vec<&GraphPoint> = points.iter().filter(|p| p.valid).collect();
    
    if valid_points.is_empty() {
        return GraphResult::error("No valid points computed");
    }

    let x_min = valid_points.iter().map(|p| p.x).fold(f64::INFINITY, f64::min);
    let x_max = valid_points.iter().map(|p| p.x).fold(f64::NEG_INFINITY, f64::max);
    let y_min = valid_points.iter().map(|p| p.y).fold(f64::INFINITY, f64::min);
    let y_max = valid_points.iter().map(|p| p.y).fold(f64::NEG_INFINITY, f64::max);

    GraphResult {
        success: true,
        points,
        x_min,
        x_max,
        y_min,
        y_max,
        error: None,
    }
}

/// Generate evenly spaced x values
pub fn generate_x_range(start: f64, end: f64, num_points: usize) -> Vec<f64> {
    if num_points < 2 {
        return vec![start];
    }
    
    let step = (end - start) / (num_points - 1) as f64;
    (0..num_points).map(|i| start + i as f64 * step).collect()
}

/// Evaluate multiple functions at the same x values
pub fn evaluate_multiple_graphs(
    expressions: &[String],
    variable: &str,
    x_values: &[f64],
) -> Vec<GraphResult> {
    expressions
        .par_iter()
        .map(|expr| evaluate_graph_points(expr, variable, x_values))
        .collect()
}

/// Find roots (x-intercepts) of a function within a range
pub fn find_zeros(
    expression: &str,
    variable: &str,
    x_start: f64,
    x_end: f64,
    num_samples: usize,
) -> Vec<f64> {
    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();
    
    let compiled = match parser.parse(expression, &mut slab.ps) {
        Ok(expr) => expr.from(&slab.ps).compile(&slab.ps, &mut slab.cs),
        Err(_) => return vec![],
    };

    let eval = |x: f64| -> Option<f64> {
        let mut map = BTreeMap::new();
        map.insert(variable.to_string(), x);
        compiled.eval(&slab, &mut map).ok()
    };

    let x_vals = generate_x_range(x_start, x_end, num_samples);
    let mut zeros = Vec::new();

    for i in 0..x_vals.len() - 1 {
        let x1 = x_vals[i];
        let x2 = x_vals[i + 1];
        
        let y1 = match eval(x1) {
            Some(y) => y,
            None => continue,
        };
        let y2 = match eval(x2) {
            Some(y) => y,
            None => continue,
        };

        // Sign change indicates a root
        if y1 * y2 < 0.0 {
            // Bisection to refine
            let mut a = x1;
            let mut b = x2;
            let mut fa = y1;

            for _ in 0..50 {
                let mid = (a + b) / 2.0;
                let fm = match eval(mid) {
                    Some(y) => y,
                    None => break,
                };

                if fm.abs() < 1e-10 || (b - a) < 1e-12 {
                    zeros.push(mid);
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
    }

    zeros
}

/// Find local extrema (minima and maxima) of a function
pub fn find_extrema(
    expression: &str,
    variable: &str,
    x_start: f64,
    x_end: f64,
    num_samples: usize,
) -> (Vec<(f64, f64)>, Vec<(f64, f64)>) {
    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();
    
    let compiled = match parser.parse(expression, &mut slab.ps) {
        Ok(expr) => expr.from(&slab.ps).compile(&slab.ps, &mut slab.cs),
        Err(_) => return (vec![], vec![]),
    };

    let eval = |x: f64| -> Option<f64> {
        let mut map = BTreeMap::new();
        map.insert(variable.to_string(), x);
        compiled.eval(&slab, &mut map).ok()
    };

    let x_vals = generate_x_range(x_start, x_end, num_samples);
    let mut minima = Vec::new();
    let mut maxima = Vec::new();

    for i in 1..x_vals.len() - 1 {
        let x_prev = x_vals[i - 1];
        let x_curr = x_vals[i];
        let x_next = x_vals[i + 1];

        let y_prev = match eval(x_prev) {
            Some(y) => y,
            None => continue,
        };
        let y_curr = match eval(x_curr) {
            Some(y) => y,
            None => continue,
        };
        let y_next = match eval(x_next) {
            Some(y) => y,
            None => continue,
        };

        if y_curr < y_prev && y_curr < y_next {
            // Local minimum - refine using golden section
            let refined = golden_section_min(|x| eval(x).unwrap_or(f64::INFINITY), x_prev, x_next);
            minima.push((refined, eval(refined).unwrap_or(f64::NAN)));
        } else if y_curr > y_prev && y_curr > y_next {
            // Local maximum
            let refined = golden_section_min(|x| -eval(x).unwrap_or(f64::NEG_INFINITY), x_prev, x_next);
            maxima.push((refined, eval(refined).unwrap_or(f64::NAN)));
        }
    }

    (minima, maxima)
}

/// Golden section search for minimum
fn golden_section_min<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 {
    let phi = (1.0 + 5.0_f64.sqrt()) / 2.0;
    let resphi = 2.0 - phi;

    let mut c = b - resphi * (b - a);
    let mut d = a + resphi * (b - a);
    
    let mut fc = f(c);
    let mut fd = f(d);

    for _ in 0..50 {
        if (b - a).abs() < 1e-10 {
            break;
        }

        if fc < fd {
            b = d;
            d = c;
            fd = fc;
            c = b - resphi * (b - a);
            fc = f(c);
        } else {
            a = c;
            c = d;
            fc = fd;
            d = a + resphi * (b - a);
            fd = f(d);
        }
    }

    (a + b) / 2.0
}

/// Calculate the derivative graph (numerical)
pub fn derivative_graph(
    expression: &str,
    variable: &str,
    x_values: &[f64],
) -> GraphResult {
    if x_values.is_empty() {
        return GraphResult::error("No x values provided");
    }

    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();
    
    let compiled = match parser.parse(expression, &mut slab.ps) {
        Ok(expr) => expr.from(&slab.ps).compile(&slab.ps, &mut slab.cs),
        Err(e) => return GraphResult::error(&format!("Parse error: {:?}", e)),
    };

    let h = 1e-6;

    let points: Vec<GraphPoint> = x_values
        .par_iter()
        .map(|&x| {
            let eval = |x_val: f64| -> Option<f64> {
                let mut map = BTreeMap::new();
                map.insert(variable.to_string(), x_val);
                compiled.eval(&slab, &mut map).ok()
            };

            let y_plus = eval(x + h);
            let y_minus = eval(x - h);

            match (y_plus, y_minus) {
                (Some(yp), Some(ym)) if yp.is_finite() && ym.is_finite() => {
                    let deriv = (yp - ym) / (2.0 * h);
                    GraphPoint { x, y: deriv, valid: deriv.is_finite() }
                }
                _ => GraphPoint { x, y: f64::NAN, valid: false },
            }
        })
        .collect();

    let valid_points: Vec<&GraphPoint> = points.iter().filter(|p| p.valid).collect();
    
    if valid_points.is_empty() {
        return GraphResult::error("No valid derivative points");
    }

    let x_min = valid_points.iter().map(|p| p.x).fold(f64::INFINITY, f64::min);
    let x_max = valid_points.iter().map(|p| p.x).fold(f64::NEG_INFINITY, f64::max);
    let y_min = valid_points.iter().map(|p| p.y).fold(f64::INFINITY, f64::min);
    let y_max = valid_points.iter().map(|p| p.y).fold(f64::NEG_INFINITY, f64::max);

    GraphResult {
        success: true,
        points,
        x_min,
        x_max,
        y_min,
        y_max,
        error: None,
    }
}

/// Calculate the integral graph (cumulative)
pub fn integral_graph(
    expression: &str,
    variable: &str,
    x_values: &[f64],
    initial_value: f64,
) -> GraphResult {
    if x_values.is_empty() {
        return GraphResult::error("No x values provided");
    }

    let parser = fasteval::Parser::new();
    let mut slab = Slab::new();
    
    let compiled = match parser.parse(expression, &mut slab.ps) {
        Ok(expr) => expr.from(&slab.ps).compile(&slab.ps, &mut slab.cs),
        Err(e) => return GraphResult::error(&format!("Parse error: {:?}", e)),
    };

    let eval = |x_val: f64| -> Option<f64> {
        let mut map = BTreeMap::new();
        map.insert(variable.to_string(), x_val);
        compiled.eval(&slab, &mut map).ok()
    };

    // Trapezoidal integration
    let mut points = Vec::with_capacity(x_values.len());
    let mut integral = initial_value;

    for (i, &x) in x_values.iter().enumerate() {
        if i > 0 {
            let x_prev = x_values[i - 1];
            let y_prev = eval(x_prev);
            let y_curr = eval(x);

            if let (Some(yp), Some(yc)) = (y_prev, y_curr) {
                if yp.is_finite() && yc.is_finite() {
                    integral += (yp + yc) * (x - x_prev) / 2.0;
                }
            }
        }

        points.push(GraphPoint {
            x,
            y: integral,
            valid: integral.is_finite(),
        });
    }

    let valid_points: Vec<&GraphPoint> = points.iter().filter(|p| p.valid).collect();
    
    if valid_points.is_empty() {
        return GraphResult::error("No valid integral points");
    }

    let x_min = valid_points.iter().map(|p| p.x).fold(f64::INFINITY, f64::min);
    let x_max = valid_points.iter().map(|p| p.x).fold(f64::NEG_INFINITY, f64::max);
    let y_min = valid_points.iter().map(|p| p.y).fold(f64::INFINITY, f64::min);
    let y_max = valid_points.iter().map(|p| p.y).fold(f64::NEG_INFINITY, f64::max);

    GraphResult {
        success: true,
        points,
        x_min,
        x_max,
        y_min,
        y_max,
        error: None,
    }
}
