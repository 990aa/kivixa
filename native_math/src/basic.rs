//! Basic expression evaluation and scientific calculator functions

use serde::{Deserialize, Serialize};

/// Result of expression evaluation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExpressionResult {
    pub success: bool,
    pub value: f64,
    pub error: Option<String>,
    pub formatted: String,
}

impl ExpressionResult {
    pub fn ok(value: f64) -> Self {
        let formatted = format_number(value);
        Self {
            success: true,
            value,
            error: None,
            formatted,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            value: 0.0,
            error: Some(msg.to_string()),
            formatted: String::new(),
        }
    }
}

/// Number system for conversions
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum NumberSystem {
    Binary,
    Octal,
    Decimal,
    Hexadecimal,
}

/// Evaluate a mathematical expression
pub fn evaluate_expression(expression: &str) -> ExpressionResult {
    // Create a namespace with mathematical functions
    let mut ns = |name: &str, args: Vec<f64>| -> Option<f64> {
        match name {
            // Trigonometric (radians)
            "sin" => Some(args.first()?.sin()),
            "cos" => Some(args.first()?.cos()),
            "tan" => Some(args.first()?.tan()),
            "asin" => Some(args.first()?.asin()),
            "acos" => Some(args.first()?.acos()),
            "atan" => Some(args.first()?.atan()),
            "atan2" => Some(args.first()?.atan2(*args.get(1)?)),

            // Trigonometric (degrees)
            "sind" => Some(args.first()?.to_radians().sin()),
            "cosd" => Some(args.first()?.to_radians().cos()),
            "tand" => Some(args.first()?.to_radians().tan()),

            // Hyperbolic
            "sinh" => Some(args.first()?.sinh()),
            "cosh" => Some(args.first()?.cosh()),
            "tanh" => Some(args.first()?.tanh()),
            "asinh" => Some(args.first()?.asinh()),
            "acosh" => Some(args.first()?.acosh()),
            "atanh" => Some(args.first()?.atanh()),

            // Logarithms
            "ln" => Some(args.first()?.ln()),
            "log" => Some(args.first()?.log10()),
            "log2" => Some(args.first()?.log2()),
            "logb" => Some(args.first()?.log(*args.get(1)?)),

            // Exponential
            "exp" => Some(args.first()?.exp()),
            "pow" => Some(args.first()?.powf(*args.get(1)?)),
            "sqrt" => Some(args.first()?.sqrt()),
            "cbrt" => Some(args.first()?.cbrt()),
            "root" => Some(args.first()?.powf(1.0 / args.get(1)?)),

            // Rounding
            "floor" => Some(args.first()?.floor()),
            "ceil" => Some(args.first()?.ceil()),
            "round" => Some(args.first()?.round()),
            "trunc" => Some(args.first()?.trunc()),
            "frac" => Some(args.first()?.fract()),

            // Other
            "abs" => Some(args.first()?.abs()),
            "sign" => Some(args.first()?.signum()),
            "min" => args.iter().copied().reduce(f64::min),
            "max" => args.iter().copied().reduce(f64::max),
            "clamp" => Some(args.first()?.clamp(*args.get(1)?, *args.get(2)?)),

            // Constants
            "pi" => Some(std::f64::consts::PI),
            "e" => Some(std::f64::consts::E),
            "tau" => Some(std::f64::consts::TAU),
            "phi" => Some(1.618033988749895), // Golden ratio

            // Factorial (for small numbers)
            "fact" | "factorial" => {
                let n = args.first()?.round() as u64;
                if n > 170 {
                    Some(f64::INFINITY)
                } else {
                    Some((1..=n).fold(1u64, |a, b| a.saturating_mul(b)) as f64)
                }
            }

            _ => None,
        }
    };

    // Clean expression
    let expr = expression
        .replace("×", "*")
        .replace("÷", "/")
        .replace("−", "-")
        .replace("π", "pi()")
        .replace("√", "sqrt");

    match fasteval::ez_eval(&expr, &mut ns) {
        Ok(val) => ExpressionResult::ok(val),
        Err(e) => ExpressionResult::error(&format!("Evaluation error: {}", e)),
    }
}

/// Convert between number systems
pub fn convert_number_system(value: &str, from: NumberSystem, to: NumberSystem) -> String {
    // Parse input to decimal
    let decimal: Result<i64, _> = match from {
        NumberSystem::Binary => i64::from_str_radix(value.trim_start_matches("0b"), 2),
        NumberSystem::Octal => i64::from_str_radix(value.trim_start_matches("0o"), 8),
        NumberSystem::Decimal => value.parse(),
        NumberSystem::Hexadecimal => i64::from_str_radix(value.trim_start_matches("0x"), 16),
    };

    match decimal {
        Ok(dec) => match to {
            NumberSystem::Binary => format!("{:b}", dec),
            NumberSystem::Octal => format!("{:o}", dec),
            NumberSystem::Decimal => dec.to_string(),
            NumberSystem::Hexadecimal => format!("{:X}", dec),
        },
        Err(_) => "Error".to_string(),
    }
}

/// Get a mathematical constant by name
pub fn get_constant(name: &str) -> f64 {
    match name.to_lowercase().as_str() {
        "pi" | "π" => std::f64::consts::PI,
        "e" => std::f64::consts::E,
        "tau" | "τ" => std::f64::consts::TAU,
        "phi" | "φ" | "golden" => 1.618033988749895,
        "sqrt2" | "√2" => std::f64::consts::SQRT_2,
        "sqrt3" | "√3" => 1.7320508075688772,
        "ln2" => std::f64::consts::LN_2,
        "ln10" => std::f64::consts::LN_10,
        "avogadro" | "na" => 6.02214076e23,
        "planck" | "h" => 6.62607015e-34,
        "boltzmann" | "kb" => 1.380649e-23,
        "light" | "c" => 299792458.0,
        "gravity" | "g" => 9.80665,
        _ => f64::NAN,
    }
}

/// Parse a formula string and extract variable names
pub fn parse_formula_variables(formula: &str) -> Vec<String> {
    let mut variables = Vec::new();
    let mut current = String::new();
    let mut in_word = false;

    for c in formula.chars() {
        if c.is_alphabetic() || (in_word && (c.is_alphanumeric() || c == '_')) {
            current.push(c);
            in_word = true;
        } else {
            if !current.is_empty()
                && !is_function_name(&current)
                && !is_constant_name(&current)
                && !variables.contains(&current)
            {
                variables.push(current.clone());
            }
            current.clear();
            in_word = false;
        }
    }

    // Check last word
    if !current.is_empty()
        && !is_function_name(&current)
        && !is_constant_name(&current)
        && !variables.contains(&current)
    {
        variables.push(current);
    }

    variables
}

fn is_function_name(name: &str) -> bool {
    matches!(
        name.to_lowercase().as_str(),
        "sin"
            | "cos"
            | "tan"
            | "asin"
            | "acos"
            | "atan"
            | "atan2"
            | "sind"
            | "cosd"
            | "tand"
            | "sinh"
            | "cosh"
            | "tanh"
            | "asinh"
            | "acosh"
            | "atanh"
            | "ln"
            | "log"
            | "log2"
            | "logb"
            | "exp"
            | "pow"
            | "sqrt"
            | "cbrt"
            | "root"
            | "floor"
            | "ceil"
            | "round"
            | "trunc"
            | "frac"
            | "abs"
            | "sign"
            | "min"
            | "max"
            | "clamp"
            | "fact"
            | "factorial"
    )
}

fn is_constant_name(name: &str) -> bool {
    matches!(name.to_lowercase().as_str(), "pi" | "e" | "tau" | "phi")
}

/// Evaluate a formula with given variable values
pub fn evaluate_formula(formula: &str, variables: &[String], values: &[f64]) -> ExpressionResult {
    if variables.len() != values.len() {
        return ExpressionResult::error("Variable count mismatch");
    }

    // Build expression with substituted values
    let mut expr = formula.to_string();
    for (var, val) in variables.iter().zip(values.iter()) {
        // Simple replacement - works for single-letter variables
        expr = expr.replace(var, &format!("({})", val));
    }

    evaluate_expression(&expr)
}

/// Format a number for display
fn format_number(value: f64) -> String {
    if value.is_nan() {
        return "NaN".to_string();
    }
    if value.is_infinite() {
        return if value > 0.0 { "∞" } else { "-∞" }.to_string();
    }

    // Check if it's effectively an integer
    if value.fract().abs() < 1e-10 && value.abs() < 1e15 {
        return (value.round() as i64).to_string();
    }

    // Use scientific notation for very large or small numbers
    if value.abs() >= 1e10 || (value.abs() < 1e-6 && value != 0.0) {
        format!("{:.6e}", value)
    } else {
        // Trim trailing zeros
        let s = format!("{:.10}", value);
        let s = s.trim_end_matches('0');
        let s = s.trim_end_matches('.');
        s.to_string()
    }
}
