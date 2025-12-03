//! Kivixa Native Rust Library
//!
//! This library provides the native Rust backend for Kivixa's AI features:
//! - Phi-4 inference engine with llama.cpp
//! - Knowledge graph with force-directed layout
//! - Vector embeddings for semantic search

pub mod api;
pub mod inference;
pub mod graph;
pub mod embeddings;

pub use api::*;
