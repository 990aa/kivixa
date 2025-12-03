//! Vector Embeddings and Similarity Search
//!
//! Provides utilities for working with embeddings:
//! - Cosine similarity calculation
//! - Batch embedding operations
//! - Semantic search across vectors

use anyhow::Result;
use serde::{Deserialize, Serialize};

use crate::inference;

/// A stored embedding with metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingEntry {
    /// Unique identifier (e.g., note path)
    pub id: String,
    /// The embedding vector
    pub vector: Vec<f32>,
    /// Optional text preview
    pub text_preview: Option<String>,
}

/// Result of a similarity search
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimilarityResult {
    /// ID of the matched entry
    pub id: String,
    /// Similarity score (0.0 to 1.0 for cosine similarity)
    pub score: f32,
    /// Optional text preview
    pub text_preview: Option<String>,
}

/// Compute cosine similarity between two vectors
///
/// Both vectors should be normalized (unit vectors) for accurate cosine similarity.
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.len() != b.len() {
        return 0.0;
    }

    let dot_product: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();

    // If vectors are already normalized, dot product = cosine similarity
    // Otherwise we need to normalize:
    let norm_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();

    if norm_a == 0.0 || norm_b == 0.0 {
        return 0.0;
    }

    dot_product / (norm_a * norm_b)
}

/// Compute embeddings for multiple texts
pub fn batch_embed(texts: Vec<String>) -> Result<Vec<EmbeddingEntry>> {
    let mut results = Vec::with_capacity(texts.len());

    for (i, text) in texts.iter().enumerate() {
        let vector = inference::get_embedding(text.clone())?;
        let preview = if text.len() > 100 {
            Some(format!("{}...", &text[..100]))
        } else {
            Some(text.clone())
        };

        results.push(EmbeddingEntry {
            id: format!("batch_{}", i),
            vector,
            text_preview: preview,
        });
    }

    Ok(results)
}

/// Find most similar entries to a query embedding
///
/// # Arguments
/// * `query` - The query embedding vector
/// * `entries` - List of entries to search
/// * `top_k` - Number of results to return
/// * `threshold` - Minimum similarity score (0.0 to 1.0)
///
/// # Returns
/// * List of similarity results, sorted by score descending
pub fn find_similar(
    query: &[f32],
    entries: &[EmbeddingEntry],
    top_k: usize,
    threshold: f32,
) -> Vec<SimilarityResult> {
    let mut results: Vec<SimilarityResult> = entries
        .iter()
        .map(|entry| {
            let score = cosine_similarity(query, &entry.vector);
            SimilarityResult {
                id: entry.id.clone(),
                score,
                text_preview: entry.text_preview.clone(),
            }
        })
        .filter(|r| r.score >= threshold)
        .collect();

    // Sort by score descending
    results.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));

    // Take top-k
    results.truncate(top_k);

    results
}

/// Semantic search: embed query text and find similar entries
///
/// # Arguments
/// * `query_text` - The search query text
/// * `entries` - List of entries to search
/// * `top_k` - Number of results to return
///
/// # Returns
/// * List of similarity results
pub fn semantic_search(
    query_text: String,
    entries: &[EmbeddingEntry],
    top_k: usize,
) -> Result<Vec<SimilarityResult>> {
    // Embed the query
    let query_embedding = inference::get_embedding(query_text)?;

    // Find similar
    Ok(find_similar(&query_embedding, entries, top_k, 0.5))
}

/// Cluster embeddings by similarity
///
/// Simple clustering: group embeddings that are above threshold similarity
pub fn cluster_embeddings(
    entries: &[EmbeddingEntry],
    threshold: f32,
) -> Vec<Vec<String>> {
    let n = entries.len();
    let mut visited = vec![false; n];
    let mut clusters = Vec::new();

    for i in 0..n {
        if visited[i] {
            continue;
        }

        let mut cluster = vec![entries[i].id.clone()];
        visited[i] = true;

        for j in (i + 1)..n {
            if visited[j] {
                continue;
            }

            let sim = cosine_similarity(&entries[i].vector, &entries[j].vector);
            if sim >= threshold {
                cluster.push(entries[j].id.clone());
                visited[j] = true;
            }
        }

        clusters.push(cluster);
    }

    clusters
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cosine_similarity_identical() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![1.0, 0.0, 0.0];
        let sim = cosine_similarity(&a, &b);
        assert!((sim - 1.0).abs() < 0.001);
    }

    #[test]
    fn test_cosine_similarity_orthogonal() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![0.0, 1.0, 0.0];
        let sim = cosine_similarity(&a, &b);
        assert!(sim.abs() < 0.001);
    }

    #[test]
    fn test_cosine_similarity_opposite() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![-1.0, 0.0, 0.0];
        let sim = cosine_similarity(&a, &b);
        assert!((sim + 1.0).abs() < 0.001);
    }

    #[test]
    fn test_find_similar() {
        let entries = vec![
            EmbeddingEntry {
                id: "a".to_string(),
                vector: vec![1.0, 0.0, 0.0],
                text_preview: None,
            },
            EmbeddingEntry {
                id: "b".to_string(),
                vector: vec![0.9, 0.1, 0.0],
                text_preview: None,
            },
            EmbeddingEntry {
                id: "c".to_string(),
                vector: vec![0.0, 1.0, 0.0],
                text_preview: None,
            },
        ];

        let query = vec![1.0, 0.0, 0.0];
        let results = find_similar(&query, &entries, 2, 0.5);

        assert_eq!(results.len(), 2);
        assert_eq!(results[0].id, "a");
        assert_eq!(results[1].id, "b");
    }

    #[test]
    fn test_cluster_embeddings() {
        let entries = vec![
            EmbeddingEntry {
                id: "a".to_string(),
                vector: vec![1.0, 0.0],
                text_preview: None,
            },
            EmbeddingEntry {
                id: "b".to_string(),
                vector: vec![0.95, 0.05],
                text_preview: None,
            },
            EmbeddingEntry {
                id: "c".to_string(),
                vector: vec![0.0, 1.0],
                text_preview: None,
            },
        ];

        let clusters = cluster_embeddings(&entries, 0.9);

        // a and b should be clustered, c alone
        assert_eq!(clusters.len(), 2);
    }
}
