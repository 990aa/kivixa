//! AI-Powered K-Means Clustering for Knowledge Graph
//!
//! Automatically groups notes into clusters based on embedding similarity.
//! Uses an in-crate deterministic K-Means implementation.
//!
//! Features:
//! - Automatic cluster discovery from note embeddings
//! - Color assignment for visual grouping
//! - Semantic edge detection for hidden connections

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};

use crate::embeddings::{cosine_similarity, EmbeddingEntry};

/// Cluster assignment result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClusterAssignment {
    /// Note/node ID
    pub id: String,
    /// Assigned cluster ID (0-based)
    pub cluster_id: usize,
    /// Cluster color (hex string)
    pub color: String,
}

/// Semantic edge discovered through embedding similarity
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticEdge {
    /// Source node ID
    pub source: String,
    /// Target node ID
    pub target: String,
    /// Similarity score (0.0 to 1.0)
    pub similarity: f32,
    /// Whether this is a "ghost" edge (no hard link exists)
    pub is_ghost: bool,
}

/// Cluster metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClusterInfo {
    /// Cluster ID
    pub id: usize,
    /// Number of nodes in cluster
    pub size: usize,
    /// Representative color
    pub color: String,
    /// Centroid position (if computed)
    pub centroid: Option<Vec<f32>>,
}

/// Result of clustering operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClusteringResult {
    /// Individual node assignments
    pub assignments: Vec<ClusterAssignment>,
    /// Cluster metadata
    pub clusters: Vec<ClusterInfo>,
    /// Number of clusters
    pub k: usize,
}

/// Result of semantic edge discovery
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticEdgeResult {
    /// Discovered semantic edges
    pub edges: Vec<SemanticEdge>,
    /// Total edges found
    pub count: usize,
}

/// Predefined cluster colors (vibrant, distinguishable)
const CLUSTER_COLORS: &[&str] = &[
    "#FF6B6B", // Red - Coral
    "#4ECDC4", // Teal - Cyan
    "#45B7D1", // Blue - Sky
    "#96CEB4", // Green - Sage
    "#FFEAA7", // Yellow - Cream
    "#DDA0DD", // Purple - Plum
    "#FF8C42", // Orange - Tangerine
    "#98D8C8", // Mint - Seafoam
    "#F7DC6F", // Gold - Mustard
    "#BB8FCE", // Violet - Lavender
    "#85C1E9", // Light Blue
    "#82E0AA", // Light Green
    "#F8B500", // Amber
    "#E74C3C", // Crimson
    "#3498DB", // Bright Blue
    "#2ECC71", // Emerald
];

/// Get color for a cluster index
fn get_cluster_color(cluster_id: usize) -> String {
    CLUSTER_COLORS[cluster_id % CLUSTER_COLORS.len()].to_string()
}

fn squared_euclidean(a: &[f32], b: &[f32]) -> f32 {
    a.iter()
        .zip(b.iter())
        .map(|(x, y)| {
            let diff = x - y;
            diff * diff
        })
        .sum()
}

fn initialize_centroids(entries: &[EmbeddingEntry], k: usize) -> Vec<Vec<f32>> {
    let n = entries.len();
    let step = (n as f32 / k as f32).max(1.0);

    (0..k)
        .map(|i| {
            let idx = ((i as f32 * step).floor() as usize).min(n - 1);
            entries[idx].vector.clone()
        })
        .collect()
}

fn assign_to_centroids(entries: &[EmbeddingEntry], centroids: &[Vec<f32>]) -> Vec<usize> {
    let mut assignments = Vec::with_capacity(entries.len());

    for entry in entries {
        let mut best_cluster = 0usize;
        let mut best_distance = f32::INFINITY;

        for (cluster_id, centroid) in centroids.iter().enumerate() {
            let distance = squared_euclidean(&entry.vector, centroid);
            if distance < best_distance {
                best_distance = distance;
                best_cluster = cluster_id;
            }
        }

        assignments.push(best_cluster);
    }

    assignments
}

fn recompute_centroids(
    entries: &[EmbeddingEntry],
    assignments: &[usize],
    previous_centroids: &[Vec<f32>],
    k: usize,
) -> Result<Vec<Vec<f32>>> {
    let dim = entries[0].vector.len();
    for entry in entries.iter() {
        if entry.vector.len() != dim {
            return Err(anyhow!(
                "inconsistent embedding dimensions: expected {}, got {} for entry {}",
                dim,
                entry.vector.len(),
                entry.id
            ));
        }
    }

    let mut sums = vec![vec![0.0f32; dim]; k];
    let mut counts = vec![0usize; k];

    for (entry, &cluster_id) in entries.iter().zip(assignments.iter()) {
        counts[cluster_id] += 1;
        for (j, value) in entry.vector.iter().enumerate() {
            sums[cluster_id][j] += *value;
        }
    }

    let mut centroids = Vec::with_capacity(k);
    for cluster_id in 0..k {
        if counts[cluster_id] == 0 {
            // Keep the previous centroid for empty clusters.
            centroids.push(previous_centroids[cluster_id].clone());
            continue;
        }

        let inv_count = 1.0 / counts[cluster_id] as f32;
        for value in &mut sums[cluster_id] {
            *value *= inv_count;
        }
        centroids.push(sums[cluster_id].clone());
    }

    Ok(centroids)
}

fn max_centroid_shift(previous: &[Vec<f32>], current: &[Vec<f32>]) -> f32 {
    previous
        .iter()
        .zip(current.iter())
        .map(|(old_centroid, new_centroid)| squared_euclidean(old_centroid, new_centroid).sqrt())
        .fold(0.0, f32::max)
}

/// Run K-Means clustering on embedding vectors
///
/// # Arguments
/// * `entries` - List of embedding entries to cluster
/// * `k` - Number of clusters (if None, auto-detect based on data size)
/// * `max_iterations` - Maximum K-Means iterations (default: 100)
///
/// # Returns
/// * Clustering result with assignments and metadata
pub fn cluster_embeddings_kmeans(
    entries: &[EmbeddingEntry],
    k: Option<usize>,
    max_iterations: Option<usize>,
) -> Result<ClusteringResult> {
    if entries.is_empty() {
        return Ok(ClusteringResult {
            assignments: vec![],
            clusters: vec![],
            k: 0,
        });
    }

    if entries.len() == 1 {
        return Ok(ClusteringResult {
            assignments: vec![ClusterAssignment {
                id: entries[0].id.clone(),
                cluster_id: 0,
                color: get_cluster_color(0),
            }],
            clusters: vec![ClusterInfo {
                id: 0,
                size: 1,
                color: get_cluster_color(0),
                centroid: Some(entries[0].vector.clone()),
            }],
            k: 1,
        });
    }

    // Determine optimal K
    let k = match k {
        Some(0) => anyhow::bail!("k must be at least 1"),
        Some(requested_k) => requested_k.min(entries.len()).min(16), // Max 16 clusters
        None => {
            // Rule of thumb: sqrt(n/2), clamped to reasonable range
            let auto_k = ((entries.len() as f64 / 2.0).sqrt().ceil() as usize).max(2);
            auto_k.min(entries.len()).min(16) // Max 16 clusters
        }
    };

    let max_iter = max_iterations.unwrap_or(100).max(1);

    let n_samples = entries.len();
    let mut centroids = initialize_centroids(entries, k);
    let mut assignments = assign_to_centroids(entries, &centroids);

    for _ in 0..max_iter {
        let updated_centroids =
            recompute_centroids(entries, &assignments, &centroids, k)?;
        let updated_assignments = assign_to_centroids(entries, &updated_centroids);
        let shift = max_centroid_shift(&centroids, &updated_centroids);

        centroids = updated_centroids;
        let converged = updated_assignments == assignments || shift <= 1e-4;
        assignments = updated_assignments;

        if converged {
            break;
        }
    }

    // Build assignments
    let mut assignment_items = Vec::with_capacity(n_samples);
    let mut cluster_counts = vec![0usize; k];

    for (entry, &cluster_id) in entries.iter().zip(assignments.iter()) {
        cluster_counts[cluster_id] += 1;
        assignment_items.push(ClusterAssignment {
            id: entry.id.clone(),
            cluster_id,
            color: get_cluster_color(cluster_id),
        });
    }

    // Build cluster info
    let mut clusters = Vec::with_capacity(k);

    for cluster_id in 0..k {
        let size = cluster_counts[cluster_id];
        let centroid = centroids[cluster_id].clone();

        clusters.push(ClusterInfo {
            id: cluster_id,
            size,
            color: get_cluster_color(cluster_id),
            centroid: Some(centroid),
        });
    }

    Ok(ClusteringResult {
        assignments: assignment_items,
        clusters,
        k,
    })
}

/// Discover semantic edges between notes based on embedding similarity
///
/// # Arguments
/// * `entries` - List of embedding entries
/// * `threshold` - Minimum similarity for edge creation (default: 0.85)
/// * `existing_links` - Set of existing hard links (source->target pairs)
///
/// # Returns
/// * Semantic edges with similarity scores
pub fn discover_semantic_edges(
    entries: &[EmbeddingEntry],
    threshold: Option<f32>,
    existing_links: Option<&[(String, String)]>,
) -> SemanticEdgeResult {
    let threshold = threshold.unwrap_or(0.85);
    let mut edges = Vec::new();

    // Build set of existing links for O(1) lookup
    let existing_set: std::collections::HashSet<(String, String)> = existing_links
        .map(|links| {
            links
                .iter()
                .flat_map(|(s, t)| {
                    // Both directions
                    vec![(s.clone(), t.clone()), (t.clone(), s.clone())]
                })
                .collect()
        })
        .unwrap_or_default();

    // Compare all pairs (O(n²) but necessary for similarity)
    for i in 0..entries.len() {
        for j in (i + 1)..entries.len() {
            let similarity = cosine_similarity(&entries[i].vector, &entries[j].vector);

            if similarity >= threshold {
                let source = entries[i].id.clone();
                let target = entries[j].id.clone();

                // Check if hard link exists
                let is_ghost = !existing_set.contains(&(source.clone(), target.clone()));

                edges.push(SemanticEdge {
                    source,
                    target,
                    similarity,
                    is_ghost,
                });
            }
        }
    }

    // Sort by similarity descending
    edges.sort_by(|a, b| {
        b.similarity
            .partial_cmp(&a.similarity)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    let count = edges.len();
    SemanticEdgeResult { edges, count }
}

/// Batch process: cluster and find semantic edges in one pass
///
/// More efficient than calling both functions separately
pub fn analyze_knowledge_graph(
    entries: &[EmbeddingEntry],
    k: Option<usize>,
    similarity_threshold: Option<f32>,
    existing_links: Option<&[(String, String)]>,
) -> Result<(ClusteringResult, SemanticEdgeResult)> {
    let clustering = cluster_embeddings_kmeans(entries, k, None)?;
    let edges = discover_semantic_edges(entries, similarity_threshold, existing_links);

    Ok((clustering, edges))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_entry(id: &str, vector: Vec<f32>) -> EmbeddingEntry {
        EmbeddingEntry {
            id: id.to_string(),
            vector,
            text_preview: None,
        }
    }

    #[test]
    fn test_cluster_empty() {
        let result = cluster_embeddings_kmeans(&[], None, None).unwrap();
        assert_eq!(result.k, 0);
        assert!(result.assignments.is_empty());
    }

    #[test]
    fn test_cluster_single() {
        let entries = vec![make_entry("a", vec![1.0, 0.0, 0.0])];
        let result = cluster_embeddings_kmeans(&entries, None, None).unwrap();
        assert_eq!(result.k, 1);
        assert_eq!(result.assignments.len(), 1);
    }

    #[test]
    fn test_cluster_two_groups() {
        // Two distinct groups
        let entries = vec![
            // Group 1: similar vectors
            make_entry("a1", vec![1.0, 0.0, 0.0]),
            make_entry("a2", vec![0.9, 0.1, 0.0]),
            make_entry("a3", vec![0.95, 0.05, 0.0]),
            // Group 2: different vectors
            make_entry("b1", vec![0.0, 1.0, 0.0]),
            make_entry("b2", vec![0.1, 0.9, 0.0]),
            make_entry("b3", vec![0.05, 0.95, 0.0]),
        ];

        let result = cluster_embeddings_kmeans(&entries, Some(2), None).unwrap();
        assert_eq!(result.k, 2);
        assert_eq!(result.assignments.len(), 6);

        // Check that similar items are in same cluster
        let a1_cluster = result
            .assignments
            .iter()
            .find(|a| a.id == "a1")
            .unwrap()
            .cluster_id;
        let a2_cluster = result
            .assignments
            .iter()
            .find(|a| a.id == "a2")
            .unwrap()
            .cluster_id;
        let b1_cluster = result
            .assignments
            .iter()
            .find(|a| a.id == "b1")
            .unwrap()
            .cluster_id;

        assert_eq!(a1_cluster, a2_cluster);
        assert_ne!(a1_cluster, b1_cluster);
    }

    #[test]
    fn test_semantic_edges() {
        let entries = vec![
            make_entry("a", vec![1.0, 0.0, 0.0]),
            make_entry("b", vec![0.99, 0.01, 0.0]), // Very similar to a
            make_entry("c", vec![0.0, 1.0, 0.0]),   // Different
        ];

        let result = discover_semantic_edges(&entries, Some(0.95), None);

        // Should find edge between a and b
        assert!(!result.edges.is_empty());
        let ab_edge = result
            .edges
            .iter()
            .find(|e| (e.source == "a" && e.target == "b") || (e.source == "b" && e.target == "a"));
        assert!(ab_edge.is_some());
        assert!(ab_edge.unwrap().is_ghost); // No existing link

        // Should not find edge with c
        let ac_edge = result
            .edges
            .iter()
            .find(|e| (e.source == "a" && e.target == "c") || (e.source == "c" && e.target == "a"));
        assert!(ac_edge.is_none());
    }

    #[test]
    fn test_semantic_edges_with_existing() {
        let entries = vec![
            make_entry("a", vec![1.0, 0.0, 0.0]),
            make_entry("b", vec![0.99, 0.01, 0.0]),
        ];

        let existing = vec![("a".to_string(), "b".to_string())];
        let result = discover_semantic_edges(&entries, Some(0.95), Some(&existing));

        // Edge should exist but not be ghost
        assert!(!result.edges.is_empty());
        assert!(!result.edges[0].is_ghost);
    }

    #[test]
    fn test_color_assignment() {
        // Test that colors are assigned properly
        for i in 0..20 {
            let color = get_cluster_color(i);
            assert!(color.starts_with('#'));
            assert_eq!(color.len(), 7);
        }
    }
}
