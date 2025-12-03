//! Streaming Graph Simulation
//!
//! Provides 60fps streaming of graph positions to Flutter.
//! Uses QuadTree for viewport culling to minimize data transfer.

use anyhow::Result;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::sync::mpsc;

use crate::quadtree::{Bounds, QuadTree, SpatialPoint};

/// Position data sent to Flutter (minimal for performance)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodePosition {
    pub id: String,
    pub x: f32,
    pub y: f32,
    pub radius: f32,
    pub color: u32,
    pub node_type: String,
}

/// Edge data for rendering
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EdgePosition {
    pub source_x: f32,
    pub source_y: f32,
    pub target_x: f32,
    pub target_y: f32,
}

/// Frame data sent to Flutter
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphFrame {
    /// Node positions within viewport
    pub nodes: Vec<NodePosition>,
    /// Edges where at least one endpoint is in viewport
    pub edges: Vec<EdgePosition>,
    /// Current simulation step
    pub frame_number: u64,
    /// Is simulation still running
    pub is_running: bool,
}

/// Viewport update from Flutter
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ViewportUpdate {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub scale: f32,
}

/// Internal viewport for culling
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Viewport {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub zoom: f32,
}

impl From<ViewportUpdate> for Viewport {
    fn from(update: ViewportUpdate) -> Self {
        Viewport {
            x: update.x,
            y: update.y,
            width: update.width,
            height: update.height,
            zoom: update.scale,
        }
    }
}

impl Viewport {
    pub fn to_bounds(&self) -> Bounds {
        let half_w = (self.width / 2.0) / self.zoom;
        let half_h = (self.height / 2.0) / self.zoom;
        Bounds::new(
            self.x - half_w,
            self.y - half_h,
            self.x + half_w,
            self.y + half_h,
        )
    }
}

/// Node metadata for streaming graph (separate from main graph)
#[derive(Debug, Clone)]
struct StreamNode {
    id: String,
    x: f32,
    y: f32,
    radius: f32,
    color: u32,
    pinned: bool,
}

/// Edge for streaming graph
#[derive(Debug, Clone)]
struct StreamEdge {
    from_id: String,
    to_id: String,
    strength: f32,
}

/// Streaming simulation state
struct SimulationState {
    is_running: AtomicBool,
    current_viewport: RwLock<Viewport>,
    frame_sender: RwLock<Option<mpsc::Sender<GraphFrame>>>,
    frame_number: RwLock<u64>,
    // Streaming graph data (separate from main graph)
    stream_nodes: RwLock<HashMap<String, StreamNode>>,
    stream_edges: RwLock<Vec<StreamEdge>>,
    // Last visible nodes for polling
    last_visible: RwLock<Vec<NodePosition>>,
}

static SIM_STATE: once_cell::sync::Lazy<Arc<SimulationState>> = once_cell::sync::Lazy::new(|| {
    Arc::new(SimulationState {
        is_running: AtomicBool::new(false),
        current_viewport: RwLock::new(Viewport {
            x: 0.0,
            y: 0.0,
            width: 1920.0,
            height: 1080.0,
            zoom: 1.0,
        }),
        frame_sender: RwLock::new(None),
        frame_number: RwLock::new(0),
        stream_nodes: RwLock::new(HashMap::new()),
        stream_edges: RwLock::new(Vec::new()),
        last_visible: RwLock::new(Vec::new()),
    })
});

// ============================================================================
// Public API (called from api.rs)
// ============================================================================

/// Start streaming graph simulation
pub fn start_stream() -> Result<()> {
    if SIM_STATE.is_running.load(Ordering::SeqCst) {
        return Ok(()); // Already running
    }

    let (tx, _rx) = mpsc::channel(2);
    *SIM_STATE.frame_sender.write() = Some(tx);
    SIM_STATE.is_running.store(true, Ordering::SeqCst);

    // Spawn simulation thread
    std::thread::spawn(move || {
        run_simulation_loop();
    });

    Ok(())
}

/// Stop the streaming simulation
pub fn stop_stream() {
    SIM_STATE.is_running.store(false, Ordering::SeqCst);
    *SIM_STATE.frame_sender.write() = None;
}

/// Check if simulation is running
pub fn is_stream_running() -> bool {
    SIM_STATE.is_running.load(Ordering::SeqCst)
}

/// Update the viewport (call when user pans/zooms)
pub fn update_viewport(update: ViewportUpdate) -> Result<()> {
    *SIM_STATE.current_viewport.write() = update.into();
    Ok(())
}

/// Get visible nodes within current viewport
pub fn get_visible_nodes() -> Vec<NodePosition> {
    SIM_STATE.last_visible.read().clone()
}

/// Add a node to the streaming graph
pub fn add_node(id: String, x: f32, y: f32, radius: f32, color: u32) -> Result<()> {
    let node = StreamNode {
        id: id.clone(),
        x,
        y,
        radius,
        color,
        pinned: false,
    };
    SIM_STATE.stream_nodes.write().insert(id, node);
    Ok(())
}

/// Remove a node from the streaming graph
pub fn remove_node(id: String) -> Result<()> {
    SIM_STATE.stream_nodes.write().remove(&id);
    // Also remove edges connected to this node
    SIM_STATE
        .stream_edges
        .write()
        .retain(|e| e.from_id != id && e.to_id != id);
    Ok(())
}

/// Add an edge to the streaming graph
pub fn add_edge(from_id: String, to_id: String, strength: f32) -> Result<()> {
    let edge = StreamEdge {
        from_id,
        to_id,
        strength,
    };
    SIM_STATE.stream_edges.write().push(edge);
    Ok(())
}

/// Remove an edge from the streaming graph
pub fn remove_edge(from_id: String, to_id: String) -> Result<()> {
    SIM_STATE
        .stream_edges
        .write()
        .retain(|e| !(e.from_id == from_id && e.to_id == to_id));
    Ok(())
}

/// Pin a node at its current position
pub fn pin_node(id: String, pinned: bool) -> Result<()> {
    if let Some(node) = SIM_STATE.stream_nodes.write().get_mut(&id) {
        node.pinned = pinned;
    }
    Ok(())
}

/// Set node position (for dragging)
pub fn set_node_position(id: String, x: f32, y: f32) -> Result<()> {
    if let Some(node) = SIM_STATE.stream_nodes.write().get_mut(&id) {
        node.x = x;
        node.y = y;
    }
    Ok(())
}

/// Clear all nodes and edges
pub fn clear_graph() {
    SIM_STATE.stream_nodes.write().clear();
    SIM_STATE.stream_edges.write().clear();
    SIM_STATE.last_visible.write().clear();
}

/// Get graph stats
pub fn get_stats() -> (usize, usize, usize) {
    let node_count = SIM_STATE.stream_nodes.read().len();
    let edge_count = SIM_STATE.stream_edges.read().len();
    let visible_count = SIM_STATE.last_visible.read().len();
    (node_count, edge_count, visible_count)
}

// ============================================================================
// Legacy API (for mpsc streaming)
// ============================================================================

/// Start streaming graph simulation with channel
pub fn start_simulation_stream() -> mpsc::Receiver<GraphFrame> {
    let (tx, rx) = mpsc::channel(2);

    *SIM_STATE.frame_sender.write() = Some(tx.clone());
    SIM_STATE.is_running.store(true, Ordering::SeqCst);

    std::thread::spawn(move || {
        run_simulation_loop();
    });

    rx
}

/// Stop the streaming simulation (legacy)
pub fn stop_simulation() {
    stop_stream();
}

/// Get the current viewport
pub fn get_viewport() -> Viewport {
    SIM_STATE.current_viewport.read().clone()
}

/// Check if simulation is running (legacy)
pub fn is_simulation_running() -> bool {
    is_stream_running()
}

// ============================================================================
// Simulation Loop
// ============================================================================

/// Main simulation loop (runs in separate thread)
fn run_simulation_loop() {
    let target_fps = 60;
    let frame_time = std::time::Duration::from_secs_f64(1.0 / target_fps as f64);

    while SIM_STATE.is_running.load(Ordering::SeqCst) {
        let start = std::time::Instant::now();

        // Run physics on stream nodes
        run_physics_step();

        // Update visible nodes cache
        update_visible_nodes();

        // Try to send frame if there's a listener
        let _ = send_frame();

        // Sleep to maintain target FPS
        let elapsed = start.elapsed();
        if elapsed < frame_time {
            std::thread::sleep(frame_time - elapsed);
        }
    }

    SIM_STATE.is_running.store(false, Ordering::SeqCst);
    log::info!("Simulation loop stopped");
}

/// Run one physics step on stream nodes
fn run_physics_step() {
    let edges = SIM_STATE.stream_edges.read().clone();
    let mut nodes = SIM_STATE.stream_nodes.write();

    // Simple spring-based physics
    let repulsion = 500.0;
    let attraction = 0.01;
    let damping = 0.9;

    // Calculate forces
    let mut forces: HashMap<String, (f32, f32)> = HashMap::new();
    for (id, _) in nodes.iter() {
        forces.insert(id.clone(), (0.0, 0.0));
    }

    // Repulsion between all nodes
    let node_ids: Vec<_> = nodes.keys().cloned().collect();
    for i in 0..node_ids.len() {
        for j in (i + 1)..node_ids.len() {
            let id_a = &node_ids[i];
            let id_b = &node_ids[j];

            if let (Some(a), Some(b)) = (nodes.get(id_a), nodes.get(id_b)) {
                let dx = a.x - b.x;
                let dy = a.y - b.y;
                let dist_sq = dx * dx + dy * dy + 1.0;
                let dist = dist_sq.sqrt();

                let force = repulsion / dist_sq;
                let fx = (dx / dist) * force;
                let fy = (dy / dist) * force;

                if let Some(f) = forces.get_mut(id_a) {
                    f.0 += fx;
                    f.1 += fy;
                }
                if let Some(f) = forces.get_mut(id_b) {
                    f.0 -= fx;
                    f.1 -= fy;
                }
            }
        }
    }

    // Attraction along edges
    for edge in &edges {
        if let (Some(from), Some(to)) = (nodes.get(&edge.from_id), nodes.get(&edge.to_id)) {
            let dx = to.x - from.x;
            let dy = to.y - from.y;
            let dist = (dx * dx + dy * dy).sqrt().max(1.0);

            let force = dist * attraction * edge.strength;
            let fx = (dx / dist) * force;
            let fy = (dy / dist) * force;

            if let Some(f) = forces.get_mut(&edge.from_id) {
                f.0 += fx;
                f.1 += fy;
            }
            if let Some(f) = forces.get_mut(&edge.to_id) {
                f.0 -= fx;
                f.1 -= fy;
            }
        }
    }

    // Apply forces
    for (id, node) in nodes.iter_mut() {
        if node.pinned {
            continue;
        }
        if let Some((fx, fy)) = forces.get(id) {
            node.x += fx * damping;
            node.y += fy * damping;
        }
    }
}

/// Update the visible nodes cache based on current viewport
fn update_visible_nodes() {
    let viewport = SIM_STATE.current_viewport.read().clone();
    let bounds = viewport.to_bounds();
    let nodes = SIM_STATE.stream_nodes.read();

    // Build QuadTree
    let points: Vec<_> = nodes
        .values()
        .map(|n| SpatialPoint {
            id: n.id.clone(),
            x: n.x,
            y: n.y,
        })
        .collect();
    let tree = QuadTree::from_points(points.into_iter());

    // Query visible
    let visible_ids: std::collections::HashSet<_> = tree
        .query_viewport(&bounds)
        .iter()
        .map(|p| p.id.clone())
        .collect();

    // Build visible positions
    let visible: Vec<NodePosition> = nodes
        .values()
        .filter(|n| visible_ids.contains(&n.id))
        .map(|n| NodePosition {
            id: n.id.clone(),
            x: n.x,
            y: n.y,
            radius: n.radius,
            color: n.color,
            node_type: "node".to_string(),
        })
        .collect();

    *SIM_STATE.last_visible.write() = visible;
}

/// Build and send a frame to channel listener
fn send_frame() -> Result<()> {
    let sender_guard = SIM_STATE.frame_sender.read();
    let sender = match sender_guard.as_ref() {
        Some(s) => s,
        None => return Ok(()), // No listener, that's fine
    };

    let visible = SIM_STATE.last_visible.read().clone();
    let nodes = SIM_STATE.stream_nodes.read();
    let edges = SIM_STATE.stream_edges.read();
    let viewport = SIM_STATE.current_viewport.read().clone();
    let _bounds = viewport.to_bounds();

    // Get visible IDs for edge filtering
    let visible_ids: std::collections::HashSet<_> = visible.iter().map(|n| n.id.clone()).collect();

    // Build edge positions
    let edge_positions: Vec<EdgePosition> = edges
        .iter()
        .filter(|e| visible_ids.contains(&e.from_id) || visible_ids.contains(&e.to_id))
        .filter_map(|e| {
            let from = nodes.get(&e.from_id)?;
            let to = nodes.get(&e.to_id)?;
            Some(EdgePosition {
                source_x: from.x,
                source_y: from.y,
                target_x: to.x,
                target_y: to.y,
            })
        })
        .collect();

    let frame_number = {
        let mut num = SIM_STATE.frame_number.write();
        *num += 1;
        *num
    };

    let frame = GraphFrame {
        nodes: visible,
        edges: edge_positions,
        frame_number,
        is_running: true,
    };

    sender.try_send(frame).map_err(|e| anyhow::anyhow!("{}", e))
}

/// Get a single frame (for non-streaming use)
pub fn get_current_frame() -> Result<GraphFrame> {
    update_visible_nodes();

    let visible = SIM_STATE.last_visible.read().clone();
    let nodes = SIM_STATE.stream_nodes.read();
    let edges = SIM_STATE.stream_edges.read();

    let visible_ids: std::collections::HashSet<_> = visible.iter().map(|n| n.id.clone()).collect();

    let edge_positions: Vec<EdgePosition> = edges
        .iter()
        .filter(|e| visible_ids.contains(&e.from_id) || visible_ids.contains(&e.to_id))
        .filter_map(|e| {
            let from = nodes.get(&e.from_id)?;
            let to = nodes.get(&e.to_id)?;
            Some(EdgePosition {
                source_x: from.x,
                source_y: from.y,
                target_x: to.x,
                target_y: to.y,
            })
        })
        .collect();

    Ok(GraphFrame {
        nodes: visible,
        edges: edge_positions,
        frame_number: *SIM_STATE.frame_number.read(),
        is_running: is_stream_running(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_viewport_to_bounds() {
        let viewport = Viewport {
            x: 100.0,
            y: 100.0,
            width: 800.0,
            height: 600.0,
            zoom: 1.0,
        };

        let bounds = viewport.to_bounds();
        assert_eq!(bounds.min_x, -300.0);
        assert_eq!(bounds.max_x, 500.0);
        assert_eq!(bounds.min_y, -200.0);
        assert_eq!(bounds.max_y, 400.0);
    }

    #[test]
    fn test_viewport_with_zoom() {
        let viewport = Viewport {
            x: 0.0,
            y: 0.0,
            width: 1000.0,
            height: 1000.0,
            zoom: 2.0,
        };

        let bounds = viewport.to_bounds();
        assert_eq!(bounds.min_x, -250.0);
        assert_eq!(bounds.max_x, 250.0);
    }

    #[test]
    fn test_add_remove_nodes() {
        clear_graph();

        add_node("n1".to_string(), 0.0, 0.0, 10.0, 0xFF0000).unwrap();
        add_node("n2".to_string(), 100.0, 100.0, 10.0, 0x00FF00).unwrap();

        let (nodes, edges, _) = get_stats();
        assert_eq!(nodes, 2);
        assert_eq!(edges, 0);

        remove_node("n1".to_string()).unwrap();
        let (nodes, _, _) = get_stats();
        assert_eq!(nodes, 1);

        clear_graph();
    }

    #[test]
    fn test_add_remove_edges() {
        clear_graph();

        add_node("a".to_string(), 0.0, 0.0, 10.0, 0xFF0000).unwrap();
        add_node("b".to_string(), 100.0, 0.0, 10.0, 0x00FF00).unwrap();
        add_edge("a".to_string(), "b".to_string(), 1.0).unwrap();

        let (_, edges, _) = get_stats();
        assert_eq!(edges, 1);

        remove_edge("a".to_string(), "b".to_string()).unwrap();
        let (_, edges, _) = get_stats();
        assert_eq!(edges, 0);

        clear_graph();
    }
}
