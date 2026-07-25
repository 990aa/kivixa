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
            "sec" => Some(1.0 / args.first()?.cos()),
            "csc" => Some(1.0 / args.first()?.sin()),
            "cot" => Some(1.0 / args.first()?.tan()),
            "asin" => Some(args.first()?.asin()),
            "acos" => Some(args.first()?.acos()),
            "atan" => Some(args.first()?.atan()),
            "atan2" => Some(args.first()?.atan2(*args.get(1)?)),
            "asec" => Some((1.0 / args.first()?).acos()),
            "acsc" => Some((1.0 / args.first()?).asin()),
            "acot" => Some((1.0 / args.first()?).atan()),

            // Trigonometric (degrees)
            "sind" => Some(args.first()?.to_radians().sin()),
            "cosd" => Some(args.first()?.to_radians().cos()),
            "tand" => Some(args.first()?.to_radians().tan()),
            "secd" => Some(1.0 / args.first()?.to_radians().cos()),
            "cscd" => Some(1.0 / args.first()?.to_radians().sin()),
            "cotd" => Some(1.0 / args.first()?.to_radians().tan()),

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
            "c" => Some(299792458.0),
            "G" => Some(6.67430e-11),
            "h" => Some(6.62607015e-34),
            "kB" => Some(1.380649e-23),
            "NA" => Some(6.02214076e23),
            "R" => Some(8.314462618),
            "g" => Some(9.80665),

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

    let expr = preprocess_expression(expression);

    match fasteval::ez_eval(&expr, &mut ns) {
        Ok(val) => ExpressionResult::ok(val),
        Err(e) => ExpressionResult::error(&format!("Evaluation error: {}", e)),
    }
}

#[derive(Debug, Clone, PartialEq)]
enum Token {
    Number(String),
    FuncConst(String),
    Op(char),
}

fn tokenize(mut s: &str) -> Vec<Token> {
    let mut tokens = Vec::new();
    let funcs_and_consts = [
        "asin",
        "acos",
        "atan",
        "asec",
        "acsc",
        "acot",
        "sind",
        "cosd",
        "tand",
        "secd",
        "cscd",
        "cotd",
        "sinh",
        "cosh",
        "tanh",
        "asinh",
        "acosh",
        "atanh",
        "sin",
        "cos",
        "tan",
        "sec",
        "csc",
        "cot",
        "log2",
        "logb",
        "log",
        "ln",
        "exp",
        "pow",
        "sqrt",
        "cbrt",
        "root",
        "floor",
        "ceil",
        "round",
        "trunc",
        "frac",
        "abs",
        "sign",
        "min",
        "max",
        "clamp",
        "factorial",
        "fact",
        "pi",
        "tau",
        "phi",
        "kB",
        "NA",
        "e",
        "c",
        "G",
        "h",
        "R",
        "g",
    ];

    while !s.is_empty() {
        s = s.trim_start();
        if s.is_empty() {
            break;
        }

        let c = s.chars().next().unwrap();

        if c.is_ascii_digit() || c == '.' {
            let end = s
                .find(|c: char| !c.is_ascii_digit() && c != '.')
                .unwrap_or(s.len());
            tokens.push(Token::Number(s[..end].to_string()));
            s = &s[end..];
        } else if c.is_alphabetic() {
            let mut matched = false;
            for fc in funcs_and_consts.iter() {
                if s.starts_with(fc) {
                    tokens.push(Token::FuncConst(fc.to_string()));
                    s = &s[fc.len()..];
                    matched = true;
                    break;
                }
            }
            if !matched {
                tokens.push(Token::FuncConst(s[..1].to_string()));
                s = &s[1..];
            }
        } else {
            tokens.push(Token::Op(c));
            s = &s[c.len_utf8()..];
        }
    }
    tokens
}

fn convert_power_operators(expr: &str) -> String {
    let mut s = expr.to_string();
    let mut iterations = 0;
    while let Some(idx) = s.find('^') {
        if iterations > 50 {
            break;
        }
        iterations += 1;

        // Find left operand starting before idx
        let bytes = s.as_bytes();
        let mut left_end = idx;
        while left_end > 0 && (bytes[left_end - 1] as char).is_whitespace() {
            left_end -= 1;
        }
        if left_end == 0 {
            break;
        }

        let mut left_start = left_end;
        if bytes[left_end - 1] == b')' {
            let mut depth = 0;
            for i in (0..left_end).rev() {
                if bytes[i] == b')' {
                    depth += 1;
                } else if bytes[i] == b'(' {
                    depth -= 1;
                    if depth == 0 {
                        left_start = i;
                        // Check if there is an identifier before ( e.g. sin(x)
                        while left_start > 0 && (bytes[left_start - 1].is_ascii_alphanumeric() || bytes[left_start - 1] == b'_') {
                            left_start -= 1;
                        }
                        break;
                    }
                }
            }
        } else {
            while left_start > 0 && (bytes[left_start - 1].is_ascii_alphanumeric() || bytes[left_start - 1] == b'.' || bytes[left_start - 1] == b'_') {
                left_start -= 1;
            }
        }

        if left_start == left_end {
            break;
        }
        let left_str = s[left_start..left_end].trim();

        // Find right operand starting after idx
        let mut right_start = idx + 1;
        while right_start < s.len() && (bytes[right_start] as char).is_whitespace() {
            right_start += 1;
        }
        if right_start >= s.len() {
            break;
        }

        let mut right_end = right_start;
        // Handle optional sign like -2
        if (bytes[right_end] == b'+' || bytes[right_end] == b'-') && right_end + 1 < s.len() {
            right_end += 1;
        }

        if bytes[right_end] == b'(' {
            let mut depth = 0;
            for i in right_end..s.len() {
                if bytes[i] == b'(' {
                    depth += 1;
                } else if bytes[i] == b')' {
                    depth -= 1;
                    if depth == 0 {
                        right_end = i + 1;
                        break;
                    }
                }
            }
        } else {
            while right_end < s.len() && (bytes[right_end].is_ascii_alphanumeric() || bytes[right_end] == b'.' || bytes[right_end] == b'_') {
                right_end += 1;
            }
            // If right_end is at '(', it's a function call like sqrt(x)
            if right_end < s.len() && bytes[right_end] == b'(' {
                let mut depth = 0;
                for i in right_end..s.len() {
                    if bytes[i] == b'(' {
                        depth += 1;
                    } else if bytes[i] == b')' {
                        depth -= 1;
                        if depth == 0 {
                            right_end = i + 1;
                            break;
                        }
                    }
                }
            }
        }

        if right_start == right_end {
            break;
        }
        let right_str = s[right_start..right_end].trim();

        let replacement = format!("pow({},{})", left_str, right_str);
        s = format!("{}{}{}", &s[..left_start], replacement, &s[right_end..]);
    }
    s
}

fn preprocess_expression(expr: &str) -> String {
    let clean_expr = expr
        .replace("×", "*")
        .replace("÷", "/")
        .replace("−", "-")
        .replace("π", "pi")
        .replace("√", "sqrt");

    let pow_expr = convert_power_operators(&clean_expr);
    let tokens = tokenize(&pow_expr);
    let mut result = String::new();
    let mut open_brackets = 0;

    for i in 0..tokens.len() {
        let t = &tokens[i];

        if let Token::Op('(') = t {
            open_brackets += 1;
        }
        if let Token::Op(')') = t {
            open_brackets -= 1;
        }

        if i > 0 {
            let prev = &tokens[i - 1];
            let needs_mult = match (prev, t) {
                (Token::Number(_), Token::FuncConst(_)) => true,
                (Token::Number(_), Token::Op('(')) => true,
                (Token::Op(')'), Token::Number(_)) => true,
                (Token::Op(')'), Token::FuncConst(_)) => true,
                (Token::Op(')'), Token::Op('(')) => true,
                (Token::FuncConst(f1), Token::FuncConst(_)) => is_constant_name(f1),
                (Token::FuncConst(f1), Token::Number(_)) => is_constant_name(f1),
                (Token::FuncConst(f1), Token::Op('(')) if is_constant_name(f1) => {
                    let next_next_is_close = if i + 1 < tokens.len() {
                        matches!(tokens[i + 1], Token::Op(')'))
                    } else {
                        false
                    };
                    !next_next_is_close
                }
                _ => false,
            };
            if needs_mult {
                result.push('*');
            }
        }

        match t {
            Token::Number(n) => result.push_str(n),
            Token::FuncConst(f) => {
                if is_constant_name(f) {
                    result.push_str(f);
                    let next_is_paren = if i + 1 < tokens.len() {
                        matches!(tokens[i + 1], Token::Op('('))
                    } else {
                        false
                    };
                    if !next_is_paren {
                        result.push_str("()");
                    }
                } else {
                    result.push_str(f);
                }
            }
            Token::Op(c) => result.push(*c),
        }
    }

    if open_brackets > 0 {
        for _ in 0..open_brackets {
            result.push(')');
        }
    }

    result
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
            | "sec"
            | "csc"
            | "cot"
            | "asin"
            | "acos"
            | "atan"
            | "atan2"
            | "asec"
            | "acsc"
            | "acot"
            | "sind"
            | "cosd"
            | "tand"
            | "secd"
            | "cscd"
            | "cotd"
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
    matches!(
        name,
        "pi" | "e" | "tau" | "phi" | "c" | "G" | "h" | "kB" | "NA" | "R" | "g"
    )
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
