//! Kivixa Math Native Rust Library
//!
//! This library provides the native Rust backend for Kivixa's Math features:
//! - Expression evaluation and scientific calculations
//! - Matrix operations and linear algebra (nalgebra)
//! - Calculus: differentiation, integration, equation solving
//! - Probability and statistics (statrs)
//! - Discrete math: combinatorics, number theory
//! - Unit conversions
//! - Function graphing with parallel evaluation
//!
//! This module is completely isolated from the AI inference code.

mod frb_generated;

pub mod api;
pub mod basic;
pub mod matrix;
pub mod calculus;
pub mod statistics;
pub mod discrete;
pub mod graphing;
pub mod units;
pub mod complex;

pub use api::*;
