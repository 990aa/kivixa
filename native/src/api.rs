//! Flutter Rust Bridge API
//!
//! This module exposes functions to Dart via flutter_rust_bridge.
//! These are the entry points called from Flutter.

use anyhow::Result;
use flutter_rust_bridge::frb;

use crate::clustering;
use crate::embeddings::{self, EmbeddingEntry, SimilarityResult};
use crate::graph::{self, GraphEdge, GraphNode, GraphState};
use crate::inference::{self, InferenceConfig};
use crate::streaming::{self, NodePosition, ViewportUpdate};

// ============================================================================
// Initialization
// ============================================================================

/// Initialize the Phi-4 model from the given path
#[frb(sync)]
pub fn init_model(model_path: String) -> Result<()> {
    inference::init_phi4(model_path, None)
}

/// Initialize the model with custom configuration
#[frb]
pub fn init_model_with_config(
    model_path: String,
    n_gpu_layers: u32,
    n_ctx: u32,
    n_threads: i32,
    temperature: f32,
    top_p: f32,
    max_tokens: u32,
) -> Result<()> {
    let config = InferenceConfig {
        n_gpu_layers,
        n_ctx,
        n_threads,
        temperature,
        top_p,
        max_tokens,
    };
    inference::init_phi4(model_path, Some(config))
}

/// Check if the model is loaded
#[frb(sync)]
pub fn is_model_loaded() -> bool {
    inference::is_model_loaded()
}

/// Unload the model and free resources
#[frb(sync)]
pub fn unload_model() {
    inference::unload_model()
}

/// Get the embedding dimension of the loaded model
#[frb(sync)]
pub fn get_embedding_dimension() -> Result<usize> {
    inference::get_embedding_dimension()
}

// ============================================================================
// Text Generation
// ============================================================================

/// Generate text completion from a prompt
#[frb]
pub fn generate_text(prompt: String, max_tokens: Option<u32>) -> Result<String> {
    inference::generate_text(prompt, max_tokens)
}

/// Chat completion with conversation history
///
/// Messages should be a list of (role, content) tuples where role is
/// "system", "user", or "assistant"
#[frb]
pub fn chat_completion(messages: Vec<(String, String)>, max_tokens: Option<u32>) -> Result<String> {
    inference::chat_completion(messages, max_tokens)
}

/// Extract topics from note content
#[frb]
pub fn extract_topics(text: String, num_topics: Option<u32>) -> Result<Vec<String>> {
    inference::extract_topics(text, num_topics)
}

// ============================================================================
// Embeddings
// ============================================================================

/// Get embedding for text
#[frb]
pub fn get_embedding(text: String) -> Result<Vec<f32>> {
    inference::get_embedding(text)
}

/// Compute embeddings for multiple texts
#[frb]
pub fn batch_embed(texts: Vec<String>) -> Result<Vec<EmbeddingEntry>> {
    embeddings::batch_embed(texts)
}

/// Find similar entries to a query embedding
#[frb]
pub fn find_similar(
    query: Vec<f32>,
    entries: Vec<EmbeddingEntry>,
    top_k: usize,
    threshold: f32,
) -> Vec<SimilarityResult> {
    embeddings::find_similar(&query, &entries, top_k, threshold)
}

/// Semantic search: embed query and find similar entries
#[frb]
pub fn semantic_search(
    query_text: String,
    entries: Vec<EmbeddingEntry>,
    top_k: usize,
) -> Result<Vec<SimilarityResult>> {
    embeddings::semantic_search(query_text, &entries, top_k)
}

/// A cluster of embedding IDs
#[derive(Debug, Clone)]
#[frb]
pub struct EmbeddingCluster {
    /// IDs of embeddings in this cluster
    pub ids: Vec<String>,
}

/// Cluster embeddings by similarity
#[frb]
pub fn cluster_embeddings(entries: Vec<EmbeddingEntry>, threshold: f32) -> Vec<EmbeddingCluster> {
    embeddings::cluster_embeddings(&entries, threshold)
        .into_iter()
        .map(|ids| EmbeddingCluster { ids })
        .collect()
}

/// Compute cosine similarity between two vectors
#[frb(sync)]
pub fn cosine_similarity(a: Vec<f32>, b: Vec<f32>) -> f32 {
    embeddings::cosine_similarity(&a, &b)
}

// ============================================================================
// Knowledge Graph
// ============================================================================

/// Initialize the knowledge graph
#[frb(sync)]
pub fn init_graph() {
    graph::init_graph()
}

/// Add a node to the graph
#[frb]
pub fn add_graph_node(
    id: String,
    label: String,
    node_type: String,
    x: f32,
    y: f32,
    color: Option<String>,
    metadata: Option<String>,
) -> Result<()> {
    graph::add_node(GraphNode {
        id,
        label,
        node_type,
        x,
        y,
        color,
        metadata,
    })
}

/// Add multiple nodes at once
#[frb]
pub fn add_graph_nodes(nodes: Vec<GraphNode>) -> Result<()> {
    graph::add_nodes(nodes)
}

/// Remove a node from the graph
#[frb]
pub fn remove_graph_node(node_id: String) -> Result<()> {
    graph::remove_node(node_id)
}

/// Add an edge to the graph
#[frb]
pub fn add_graph_edge(
    source: String,
    target: String,
    weight: f32,
    edge_type: String,
) -> Result<()> {
    graph::add_edge(GraphEdge {
        source,
        target,
        weight,
        edge_type,
    })
}

/// Add multiple edges at once
#[frb]
pub fn add_graph_edges(edges: Vec<GraphEdge>) -> Result<()> {
    graph::add_edges(edges)
}

/// Compute physics-based layout
#[frb]
pub fn compute_graph_layout(iterations: Option<u32>) -> Result<GraphState> {
    graph::compute_layout(iterations)
}

/// Get current graph state
#[frb]
pub fn get_graph_state() -> Result<GraphState> {
    graph::get_graph_state()
}

/// Clear the graph
#[frb(sync)]
pub fn clear_graph() {
    graph::clear_graph()
}

/// Connect a note to topic hubs
#[frb]
pub fn connect_note_to_topics(note_id: String, topic_ids: Vec<String>) -> Result<()> {
    graph::connect_note_to_topics(note_id, topic_ids)
}

/// Get or create a topic hub node
#[frb]
pub fn get_or_create_topic_hub(topic: String) -> Result<String> {
    graph::get_or_create_topic_hub(topic)
}

// ============================================================================
// Utility
// ============================================================================

/// Simple health check
#[frb(sync)]
pub fn health_check() -> String {
    "Kivixa Native OK".to_string()
}

/// Get version info
#[frb(sync)]
pub fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

// ============================================================================
// Streaming Graph (60fps viewport-culled simulation)
// ============================================================================

/// Start the graph streaming simulation
/// This runs physics simulation at 60fps and streams visible nodes
#[frb]
pub fn start_graph_stream() -> Result<()> {
    streaming::start_stream()
}

/// Stop the graph streaming simulation
#[frb(sync)]
pub fn stop_graph_stream() {
    streaming::stop_stream()
}

/// Check if the graph stream is currently running
#[frb(sync)]
pub fn is_graph_stream_running() -> bool {
    streaming::is_stream_running()
}

/// Update the viewport for culling
/// Only nodes within the viewport will be sent to Flutter
#[frb]
pub fn update_graph_viewport(x: f32, y: f32, width: f32, height: f32, scale: f32) -> Result<()> {
    streaming::update_viewport(ViewportUpdate {
        x,
        y,
        width,
        height,
        scale,
    })
}

/// Get visible nodes within the current viewport
/// Returns positions for nodes that should be rendered
#[frb]
pub fn get_visible_graph_nodes() -> Vec<NodePosition> {
    streaming::get_visible_nodes()
}

/// Add a node to the streaming graph
#[frb]
pub fn add_stream_node(id: String, x: f32, y: f32, radius: f32, color: u32) -> Result<()> {
    streaming::add_node(id, x, y, radius, color)
}

/// Remove a node from the streaming graph
#[frb]
pub fn remove_stream_node(id: String) -> Result<()> {
    streaming::remove_node(id)
}

/// Add an edge to the streaming graph
#[frb]
pub fn add_stream_edge(from_id: String, to_id: String, strength: f32) -> Result<()> {
    streaming::add_edge(from_id, to_id, strength)
}

/// Remove an edge from the streaming graph
#[frb]
pub fn remove_stream_edge(from_id: String, to_id: String) -> Result<()> {
    streaming::remove_edge(from_id, to_id)
}

/// Pin a node at its current position (stops physics for that node)
#[frb]
pub fn pin_stream_node(id: String, pinned: bool) -> Result<()> {
    streaming::pin_node(id, pinned)
}

/// Set node position (for dragging)
#[frb]
pub fn set_stream_node_position(id: String, x: f32, y: f32) -> Result<()> {
    streaming::set_node_position(id, x, y)
}

/// Clear all nodes and edges from the streaming graph
#[frb(sync)]
pub fn clear_stream_graph() {
    streaming::clear_graph()
}

/// Get stats about the streaming graph
#[frb(sync)]
pub fn get_stream_graph_stats() -> StreamGraphStats {
    let (node_count, edge_count, visible_count) = streaming::get_stats();
    StreamGraphStats {
        node_count,
        edge_count,
        visible_count,
    }
}

/// Statistics about the streaming graph
#[derive(Debug, Clone)]
#[frb]
pub struct StreamGraphStats {
    pub node_count: usize,
    pub edge_count: usize,
    pub visible_count: usize,
}

// ============================================================================
// AI Clustering & Semantic Edges
// ============================================================================

pub use crate::clustering::{ClusterAssignment, ClusterInfo, ClusteringResult, SemanticEdge, SemanticEdgeResult};

/// Run K-Means clustering on note embeddings
/// 
/// # Arguments
/// * `entries` - List of embedding entries to cluster
/// * `k` - Number of clusters (if None, auto-detect based on data size)
/// * `max_iterations` - Maximum K-Means iterations (default: 100)
///
/// # Returns
/// * Clustering result with assignments and metadata
#[frb]
pub fn cluster_notes(
    entries: Vec<EmbeddingEntry>,
    k: Option<usize>,
    max_iterations: Option<usize>,
) -> Result<ClusteringResult> {
    clustering::cluster_embeddings_kmeans(&entries, k, max_iterations)
}

/// Discover semantic edges between notes based on embedding similarity
///
/// # Arguments
/// * `entries` - List of embedding entries
/// * `threshold` - Minimum similarity for edge creation (default: 0.85)
/// * `existing_links` - Optional list of existing hard links (source, target pairs)
///
/// # Returns
/// * Semantic edges with similarity scores
#[frb]
pub fn discover_semantic_edges(
    entries: Vec<EmbeddingEntry>,
    threshold: Option<f32>,
    existing_links: Option<Vec<(String, String)>>,
) -> SemanticEdgeResult {
    let links_ref = existing_links.as_ref().map(|v| v.as_slice());
    clustering::discover_semantic_edges(&entries, threshold, links_ref)
}

/// Analyze knowledge graph: cluster and find semantic edges in one pass
///
/// More efficient than calling both functions separately
#[frb]
pub fn analyze_knowledge_graph(
    entries: Vec<EmbeddingEntry>,
    k: Option<usize>,
    similarity_threshold: Option<f32>,
    existing_links: Option<Vec<(String, String)>>,
) -> Result<KnowledgeGraphAnalysis> {
    let links_ref = existing_links.as_ref().map(|v| v.as_slice());
    let (clustering, edges) = clustering::analyze_knowledge_graph(&entries, k, similarity_threshold, links_ref)?;
    
    Ok(KnowledgeGraphAnalysis {
        clustering,
        semantic_edges: edges,
    })
}

/// Combined result of knowledge graph analysis
#[derive(Debug, Clone)]
#[frb]
pub struct KnowledgeGraphAnalysis {
    /// Cluster assignments for each note
    pub clustering: ClusteringResult,
    /// Discovered semantic edges
    pub semantic_edges: SemanticEdgeResult,
}
