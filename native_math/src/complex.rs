//! Complex number operations

use num_complex::Complex64;
use serde::{Deserialize, Serialize};

/// Result of complex number operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplexNumber {
    pub real: f64,
    pub imag: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplexResult {
    pub success: bool,
    pub real: f64,
    pub imag: f64,
    pub magnitude: f64,
    pub angle_rad: f64,
    pub angle_deg: f64,
    pub formatted_rect: String,
    pub formatted_polar: String,
    pub error: Option<String>,
}

impl ComplexResult {
    pub fn from_complex(c: Complex64) -> Self {
        let magnitude = c.norm();
        let angle_rad = c.arg();
        let angle_deg = angle_rad.to_degrees();

        Self {
            success: true,
            real: c.re,
            imag: c.im,
            magnitude,
            angle_rad,
            angle_deg,
            formatted_rect: format_rectangular(c.re, c.im),
            formatted_polar: format_polar(magnitude, angle_deg),
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            real: 0.0,
            imag: 0.0,
            magnitude: 0.0,
            angle_rad: 0.0,
            angle_deg: 0.0,
            formatted_rect: String::new(),
            formatted_polar: String::new(),
            error: Some(msg.to_string()),
        }
    }
}

/// Perform complex number operations
pub fn complex_operation(
    a_real: f64,
    a_imag: f64,
    b_real: f64,
    b_imag: f64,
    operation: &str,
) -> ComplexResult {
    let a = Complex64::new(a_real, a_imag);
    let b = Complex64::new(b_real, b_imag);

    let result = match operation.to_lowercase().as_str() {
        "add" | "+" => a + b,
        "subtract" | "sub" | "-" => a - b,
        "multiply" | "mul" | "*" | "×" => a * b,
        "divide" | "div" | "/" | "÷" => {
            if b.norm() == 0.0 {
                return ComplexResult::error("Division by zero");
            }
            a / b
        }
        "power" | "pow" | "^" => a.powc(b),
        "conjugate" | "conj" => a.conj(),
        "sqrt" => a.sqrt(),
        "exp" => a.exp(),
        "ln" | "log" => a.ln(),
        "sin" => a.sin(),
        "cos" => a.cos(),
        "tan" => a.tan(),
        "sinh" => a.sinh(),
        "cosh" => a.cosh(),
        "tanh" => a.tanh(),
        _ => return ComplexResult::error(&format!("Unknown operation: {}", operation)),
    };

    ComplexResult::from_complex(result)
}

/// Convert between rectangular and polar forms
pub fn convert_form(real: f64, imag: f64, to_polar: bool) -> ComplexResult {
    if to_polar {
        // Input is rectangular, output polar interpretation
        let c = Complex64::new(real, imag);
        ComplexResult::from_complex(c)
    } else {
        // Input is polar (magnitude, angle in degrees), convert to rectangular
        let magnitude = real;
        let angle_rad = imag.to_radians();
        let c = Complex64::from_polar(magnitude, angle_rad);
        ComplexResult::from_complex(c)
    }
}

fn format_rectangular(real: f64, imag: f64) -> String {
    if imag >= 0.0 {
        format!("{:.6} + {:.6}i", real, imag)
    } else {
        format!("{:.6} - {:.6}i", real, imag.abs())
    }
}

fn format_polar(magnitude: f64, angle_deg: f64) -> String {
    format!("{:.6} ∠ {:.2}°", magnitude, angle_deg)
}
