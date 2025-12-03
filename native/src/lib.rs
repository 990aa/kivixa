//! Kivixa Native Rust Library
//!
//! This library provides the native Rust backend for Kivixa's AI features:
//! - Phi-4 inference engine with llama.cpp
//! - Knowledge graph with force-directed layout
//! - Vector embeddings for semantic search
//! - Quadtree spatial indexing for viewport culling
//! - Streaming graph simulation at 60fps

mod frb_generated;

pub mod api;
pub mod embeddings;
pub mod graph;
pub mod inference;
pub mod quadtree;
pub mod streaming;

pub use api::*;
