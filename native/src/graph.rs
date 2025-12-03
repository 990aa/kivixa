//! Knowledge Graph with Force-Directed Layout
//!
//! Implements a physics-based graph visualization where:
//! - Notes with similar topics gravitate toward topic hub nodes
//! - Related notes cluster naturally
//! - Layout is computed in Rust for performance

use anyhow::Result;
use fdg_sim::petgraph::graph::{NodeIndex, UnGraph};
use fdg_sim::petgraph::visit::EdgeRef;
use fdg_sim::{ForceGraph, ForceGraphHelper, Simulation, SimulationParameters};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;

/// A node in the knowledge graph
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphNode {
    /// Unique identifier
    pub id: String,
    /// Display label
    pub label: String,
    /// Node type: "note", "topic", or "hub"
    pub node_type: String,
    /// X position (computed by physics simulation)
    pub x: f32,
    /// Y position (computed by physics simulation)
    pub y: f32,
    /// Optional color (hex string)
    pub color: Option<String>,
    /// Additional metadata (JSON string)
    pub metadata: Option<String>,
}

/// An edge in the knowledge graph
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphEdge {
    /// Source node ID
    pub source: String,
    /// Target node ID
    pub target: String,
    /// Edge weight (affects attraction strength)
    pub weight: f32,
    /// Edge type: "topic", "link", or "similarity"
    pub edge_type: String,
}

/// The complete graph state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphState {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

/// Internal graph representation
struct InternalGraph {
    graph: ForceGraph<String, f32>,
    node_map: HashMap<String, NodeIndex>,
    nodes_data: HashMap<String, GraphNode>,
}

/// Global graph state
static GRAPH_STATE: RwLock<Option<Arc<InternalGraph>>> = RwLock::new(None);

/// Initialize a new empty graph
pub fn init_graph() {
    let internal = InternalGraph {
        graph: ForceGraph::default(),
        node_map: HashMap::new(),
        nodes_data: HashMap::new(),
    };
    *GRAPH_STATE.write() = Some(Arc::new(internal));
    log::info!("Knowledge graph initialized");
}

/// Add a node to the graph
pub fn add_node(node: GraphNode) -> Result<()> {
    let mut guard = GRAPH_STATE.write();
    let state = guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Graph not initialized"))?;

    // We need to clone and modify
    let state = Arc::make_mut(state);

    // Add to petgraph
    let idx = state.graph.add_force_node(node.id.clone(), ());
    state.node_map.insert(node.id.clone(), idx);
    state.nodes_data.insert(node.id.clone(), node);

    Ok(())
}

/// Add multiple nodes at once
pub fn add_nodes(nodes: Vec<GraphNode>) -> Result<()> {
    for node in nodes {
        add_node(node)?;
    }
    Ok(())
}

/// Remove a node from the graph
pub fn remove_node(node_id: String) -> Result<()> {
    let mut guard = GRAPH_STATE.write();
    let state = guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Graph not initialized"))?;

    let state = Arc::make_mut(state);

    if let Some(idx) = state.node_map.remove(&node_id) {
        state.graph.remove_node(idx);
        state.nodes_data.remove(&node_id);
    }

    Ok(())
}

/// Add an edge between two nodes
pub fn add_edge(edge: GraphEdge) -> Result<()> {
    let mut guard = GRAPH_STATE.write();
    let state = guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Graph not initialized"))?;

    let state = Arc::make_mut(state);

    let source_idx = state
        .node_map
        .get(&edge.source)
        .ok_or_else(|| anyhow::anyhow!("Source node not found: {}", edge.source))?;
    let target_idx = state
        .node_map
        .get(&edge.target)
        .ok_or_else(|| anyhow::anyhow!("Target node not found: {}", edge.target))?;

    state.graph.add_edge(*source_idx, *target_idx, edge.weight);

    Ok(())
}

/// Add multiple edges at once
pub fn add_edges(edges: Vec<GraphEdge>) -> Result<()> {
    for edge in edges {
        add_edge(edge)?;
    }
    Ok(())
}

/// Run physics simulation to compute layout
///
/// # Arguments
/// * `iterations` - Number of simulation steps (default: 100)
///
/// # Returns
/// * Updated graph state with computed positions
pub fn compute_layout(iterations: Option<u32>) -> Result<GraphState> {
    let iterations = iterations.unwrap_or(100);

    let mut guard = GRAPH_STATE.write();
    let state = guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Graph not initialized"))?;

    let state = Arc::make_mut(state);

    // Configure simulation parameters
    let params = SimulationParameters::default();

    // Create and run simulation
    let mut simulation = Simulation::from_graph(&state.graph, params);

    for _ in 0..iterations {
        simulation.update(0.016); // ~60fps timestep
    }

    // Extract positions and build output
    let mut nodes = Vec::new();
    let mut edges = Vec::new();

    for node_idx in state.graph.node_indices() {
        let id = state.graph.node_weight(node_idx).unwrap();
        let pos = simulation.get_graph().node_weight(node_idx).unwrap();

        if let Some(mut node_data) = state.nodes_data.get(id).cloned() {
            node_data.x = pos.location.x;
            node_data.y = pos.location.y;

            // Update stored position
            state.nodes_data.insert(id.clone(), node_data.clone());
            nodes.push(node_data);
        }
    }

    // Collect edges
    for edge in state.graph.edge_references() {
        let source_id = state.graph.node_weight(edge.source()).unwrap();
        let target_id = state.graph.node_weight(edge.target()).unwrap();

        edges.push(GraphEdge {
            source: source_id.clone(),
            target: target_id.clone(),
            weight: *edge.weight(),
            edge_type: "link".to_string(),
        });
    }

    Ok(GraphState { nodes, edges })
}

/// Get current graph state without running simulation
pub fn get_graph_state() -> Result<GraphState> {
    let guard = GRAPH_STATE.read();
    let state = guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("Graph not initialized"))?;

    let mut nodes = Vec::new();
    let mut edges = Vec::new();

    for (_, node_data) in state.nodes_data.iter() {
        nodes.push(node_data.clone());
    }

    for edge in state.graph.edge_references() {
        let source_id = state.graph.node_weight(edge.source()).unwrap();
        let target_id = state.graph.node_weight(edge.target()).unwrap();

        edges.push(GraphEdge {
            source: source_id.clone(),
            target: target_id.clone(),
            weight: *edge.weight(),
            edge_type: "link".to_string(),
        });
    }

    Ok(GraphState { nodes, edges })
}

/// Clear the graph
pub fn clear_graph() {
    init_graph();
    log::info!("Knowledge graph cleared");
}

/// Connect a note to its topic hubs
///
/// This creates edges between a note node and topic hub nodes,
/// causing them to attract in the physics simulation.
pub fn connect_note_to_topics(note_id: String, topic_ids: Vec<String>) -> Result<()> {
    for topic_id in topic_ids {
        add_edge(GraphEdge {
            source: note_id.clone(),
            target: topic_id,
            weight: 1.0,
            edge_type: "topic".to_string(),
        })?;
    }
    Ok(())
}

/// Get or create a topic hub node
pub fn get_or_create_topic_hub(topic: String) -> Result<String> {
    let hub_id = format!("hub_{}", topic.to_lowercase().replace(' ', "_"));

    let guard = GRAPH_STATE.read();
    if let Some(state) = guard.as_ref() {
        if state.node_map.contains_key(&hub_id) {
            return Ok(hub_id);
        }
    }
    drop(guard);

    // Create new hub node
    add_node(GraphNode {
        id: hub_id.clone(),
        label: topic,
        node_type: "hub".to_string(),
        x: 0.0,
        y: 0.0,
        color: Some("#6200EE".to_string()), // Material primary
        metadata: None,
    })?;

    Ok(hub_id)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init_graph() {
        init_graph();
        let state = get_graph_state().unwrap();
        assert!(state.nodes.is_empty());
        assert!(state.edges.is_empty());
    }

    #[test]
    fn test_add_node() {
        init_graph();
        add_node(GraphNode {
            id: "test1".to_string(),
            label: "Test Note".to_string(),
            node_type: "note".to_string(),
            x: 0.0,
            y: 0.0,
            color: None,
            metadata: None,
        })
        .unwrap();

        let state = get_graph_state().unwrap();
        assert_eq!(state.nodes.len(), 1);
    }

    #[test]
    fn test_add_edge() {
        init_graph();

        add_node(GraphNode {
            id: "a".to_string(),
            label: "A".to_string(),
            node_type: "note".to_string(),
            x: 0.0,
            y: 0.0,
            color: None,
            metadata: None,
        })
        .unwrap();

        add_node(GraphNode {
            id: "b".to_string(),
            label: "B".to_string(),
            node_type: "note".to_string(),
            x: 0.0,
            y: 0.0,
            color: None,
            metadata: None,
        })
        .unwrap();

        add_edge(GraphEdge {
            source: "a".to_string(),
            target: "b".to_string(),
            weight: 1.0,
            edge_type: "link".to_string(),
        })
        .unwrap();

        let state = get_graph_state().unwrap();
        assert_eq!(state.edges.len(), 1);
    }

    #[test]
    fn test_compute_layout() {
        init_graph();

        for i in 0..5 {
            add_node(GraphNode {
                id: format!("node_{}", i),
                label: format!("Node {}", i),
                node_type: "note".to_string(),
                x: 0.0,
                y: 0.0,
                color: None,
                metadata: None,
            })
            .unwrap();
        }

        // Connect in a chain
        for i in 0..4 {
            add_edge(GraphEdge {
                source: format!("node_{}", i),
                target: format!("node_{}", i + 1),
                weight: 1.0,
                edge_type: "link".to_string(),
            })
            .unwrap();
        }

        let state = compute_layout(Some(50)).unwrap();
        assert_eq!(state.nodes.len(), 5);

        // Nodes should have been moved from origin
        for node in &state.nodes {
            // After simulation, nodes should spread out
            // (not all at 0,0)
            println!("Node {} at ({}, {})", node.id, node.x, node.y);
        }
    }
}
