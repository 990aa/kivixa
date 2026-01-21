//! Kivixa Native Rust Library
//!
//! This library provides the native Rust backend for Kivixa's AI features:
//! - Multi-model inference engine with llama.cpp (Phi-4, Qwen, Functionary)
//! - Model Context Protocol (MCP) for AI-powered tool execution
//! - Knowledge graph with force-directed layout
//! - Vector embeddings for semantic search
//! - K-Means clustering for automatic note grouping
//! - Quadtree spatial indexing for viewport culling
//! - Streaming graph simulation at 60fps

mod frb_generated;

pub mod api;
pub mod clustering;
pub mod embeddings;
pub mod graph;
pub mod inference;
pub mod mcp;
pub mod quadtree;
pub mod streaming;

pub use api::*;
