//! Phi-4 Inference Engine
//!
//! Provides GPU-accelerated inference using llama.cpp bindings.
//! Supports text generation and embedding extraction.

use anyhow::{anyhow, Result};
use llama_cpp_2::context::params::LlamaContextParams;
use llama_cpp_2::context::LlamaContext;
use llama_cpp_2::llama_backend::LlamaBackend;
use llama_cpp_2::llama_batch::LlamaBatch;
use llama_cpp_2::model::params::LlamaModelParams;
use llama_cpp_2::model::{AddBos, LlamaModel, Special};
use llama_cpp_2::token::data_array::LlamaTokenDataArray;
use parking_lot::Mutex;
use std::num::NonZeroU32;
use std::path::Path;
use std::sync::Arc;

/// Configuration for inference
#[derive(Debug, Clone)]
pub struct InferenceConfig {
    /// Number of GPU layers to offload (99 = all possible)
    pub n_gpu_layers: u32,
    /// Context size (tokens)
    pub n_ctx: u32,
    /// Number of CPU threads for processing
    pub n_threads: i32,
    /// Temperature for sampling (0.0 = deterministic, 1.0 = creative)
    pub temperature: f32,
    /// Top-p sampling (nucleus sampling)
    pub top_p: f32,
    /// Maximum tokens to generate
    pub max_tokens: u32,
}

impl Default for InferenceConfig {
    fn default() -> Self {
        Self {
            n_gpu_layers: 99, // Offload everything to GPU
            n_ctx: 4096,      // Reasonable context for most tasks
            n_threads: 4,     // Use 4 CPU threads
            temperature: 0.7,
            top_p: 0.9,
            max_tokens: 512,
        }
    }
}

/// State of the AI model
struct ModelState {
    backend: LlamaBackend,
    model: LlamaModel,
    config: InferenceConfig,
}

/// Global AI state (singleton pattern)
static AI_STATE: Mutex<Option<Arc<ModelState>>> = Mutex::new(None);

/// Initialize the Phi-4 model from the given path
///
/// # Arguments
/// * `model_path` - Full path to the GGUF model file
/// * `config` - Optional inference configuration
///
/// # Returns
/// * `Ok(())` if model loaded successfully
/// * `Err(...)` if loading failed
pub fn init_phi4(model_path: String, config: Option<InferenceConfig>) -> Result<()> {
    let config = config.unwrap_or_default();

    log::info!("Initializing Phi-4 from: {}", model_path);

    // Initialize the llama.cpp backend
    let backend = LlamaBackend::init()?;

    // Configure model parameters for GPU acceleration
    let model_params = LlamaModelParams::default().with_n_gpu_layers(config.n_gpu_layers);

    // Load the model from file
    let model = LlamaModel::load_from_file(&backend, Path::new(&model_path), &model_params)
        .map_err(|e| anyhow!("Failed to load model: {:?}", e))?;

    log::info!(
        "Model loaded successfully. Vocabulary size: {}",
        model.n_vocab()
    );

    // Store state globally
    *AI_STATE.lock() = Some(Arc::new(ModelState {
        backend,
        model,
        config,
    }));

    Ok(())
}

/// Check if the model is loaded and ready
pub fn is_model_loaded() -> bool {
    AI_STATE.lock().is_some()
}

/// Unload the model and free resources
pub fn unload_model() {
    *AI_STATE.lock() = None;
    log::info!("Model unloaded");
}

/// Get the model's embedding dimension
pub fn get_embedding_dimension() -> Result<usize> {
    let guard = AI_STATE.lock();
    let state = guard.as_ref().ok_or_else(|| anyhow!("Model not loaded"))?;
    Ok(state.model.n_embd() as usize)
}

/// Generate text completion from a prompt
///
/// # Arguments
/// * `prompt` - The input prompt
/// * `max_tokens` - Optional override for max tokens to generate
///
/// # Returns
/// * Generated text completion
pub fn generate_text(prompt: String, max_tokens: Option<u32>) -> Result<String> {
    let guard = AI_STATE.lock();
    let state = guard.as_ref().ok_or_else(|| anyhow!("Model not loaded"))?;

    let max_tokens = max_tokens.unwrap_or(state.config.max_tokens);

    // Create context for this generation
    let ctx_params = LlamaContextParams::default()
        .with_n_ctx(NonZeroU32::new(state.config.n_ctx))
        .with_n_threads(state.config.n_threads)
        .with_n_threads_batch(state.config.n_threads);

    let mut ctx = state
        .model
        .new_context(&state.backend, ctx_params)
        .map_err(|e| anyhow!("Failed to create context: {:?}", e))?;

    // Tokenize the prompt
    let tokens = state
        .model
        .str_to_token(&prompt, AddBos::Always)
        .map_err(|e| anyhow!("Failed to tokenize: {:?}", e))?;

    log::debug!("Prompt tokenized to {} tokens", tokens.len());

    // Create batch and process prompt
    let mut batch = LlamaBatch::new(state.config.n_ctx as usize, 1);

    for (i, token) in tokens.iter().enumerate() {
        let is_last = i == tokens.len() - 1;
        batch.add(*token, i as i32, &[0], is_last)?;
    }

    ctx.decode(&mut batch)
        .map_err(|e| anyhow!("Failed to decode prompt: {:?}", e))?;

    // Generate tokens
    let mut output_tokens = Vec::new();
    let mut n_cur = tokens.len();

    // Use a simple random seed for sampling
    let mut rng_seed: u32 = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as u32;

    for _ in 0..max_tokens {
        // Sample next token
        let candidates = ctx.candidates_ith(batch.n_tokens() - 1);
        let mut candidates_array = LlamaTokenDataArray::from_iter(candidates, false);

        // Sample with random seed
        rng_seed = rng_seed.wrapping_mul(1103515245).wrapping_add(12345);
        let new_token = candidates_array.sample_token(rng_seed);

        // Check for end of generation
        if state.model.is_eog_token(new_token) {
            break;
        }

        output_tokens.push(new_token);

        // Prepare next batch
        batch.clear();
        batch.add(new_token, n_cur as i32, &[0], true)?;
        n_cur += 1;

        ctx.decode(&mut batch)
            .map_err(|e| anyhow!("Failed to decode: {:?}", e))?;
    }

    // Convert tokens back to text
    let output = output_tokens
        .iter()
        .map(|t| state.model.token_to_str(*t, Special::Tokenize))
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| anyhow!("Failed to detokenize: {:?}", e))?
        .join("");

    Ok(output)
}

/// Generate embeddings for text (for vector search)
///
/// # Arguments
/// * `text` - The text to embed
///
/// # Returns
/// * Vector of floats representing the embedding
pub fn get_embedding(text: String) -> Result<Vec<f32>> {
    let guard = AI_STATE.lock();
    let state = guard.as_ref().ok_or_else(|| anyhow!("Model not loaded"))?;

    // Create context optimized for embedding extraction
    let ctx_params = LlamaContextParams::default()
        .with_n_ctx(NonZeroU32::new(2048)) // Smaller context for embeddings
        .with_n_threads(state.config.n_threads)
        .with_n_threads_batch(state.config.n_threads)
        .with_embeddings(true); // Enable embedding extraction

    let mut ctx = state
        .model
        .new_context(&state.backend, ctx_params)
        .map_err(|e| anyhow!("Failed to create embedding context: {:?}", e))?;

    // Tokenize input
    let tokens = state
        .model
        .str_to_token(&text, AddBos::Always)
        .map_err(|e| anyhow!("Failed to tokenize: {:?}", e))?;

    // Create batch with all tokens
    let mut batch = LlamaBatch::new(2048, 1);
    for (i, token) in tokens.iter().enumerate() {
        let is_last = i == tokens.len() - 1;
        batch.add(*token, i as i32, &[0], is_last)?;
    }

    // Process
    ctx.decode(&mut batch)
        .map_err(|e| anyhow!("Failed to compute embeddings: {:?}", e))?;

    // Extract embeddings (mean pooling over all tokens)
    let n_embd = state.model.n_embd() as usize;
    let mut pooled_embedding = vec![0.0f32; n_embd];
    let n_tokens = tokens.len();

    for i in 0..n_tokens {
        let emb = ctx
            .embeddings_ith(i as i32)
            .map_err(|e| anyhow!("Failed to get embedding at position {}: {:?}", i, e))?;

        for (j, val) in emb.iter().enumerate() {
            pooled_embedding[j] += val;
        }
    }

    // Average (mean pooling)
    for val in &mut pooled_embedding {
        *val /= n_tokens as f32;
    }

    // L2 normalize for cosine similarity
    let norm: f32 = pooled_embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm > 0.0 {
        for val in &mut pooled_embedding {
            *val /= norm;
        }
    }

    Ok(pooled_embedding)
}

/// Chat completion with conversation history
///
/// # Arguments
/// * `messages` - List of (role, content) pairs where role is "system", "user", or "assistant"
/// * `max_tokens` - Maximum tokens to generate
///
/// # Returns
/// * Assistant's response
pub fn chat_completion(messages: Vec<(String, String)>, max_tokens: Option<u32>) -> Result<String> {
    // Format as Phi-4 chat template
    let mut prompt = String::new();

    for (role, content) in messages {
        match role.as_str() {
            "system" => {
                prompt.push_str(&format!("<|system|>\n{}<|end|>\n", content));
            }
            "user" => {
                prompt.push_str(&format!("<|user|>\n{}<|end|>\n", content));
            }
            "assistant" => {
                prompt.push_str(&format!("<|assistant|>\n{}<|end|>\n", content));
            }
            _ => {
                log::warn!("Unknown role: {}", role);
            }
        }
    }

    // Add assistant prompt to generate response
    prompt.push_str("<|assistant|>\n");

    generate_text(prompt, max_tokens)
}

/// Extract related topics from text using Phi-4
///
/// # Arguments
/// * `text` - The note content to analyze
/// * `num_topics` - Number of topics to extract (default: 3)
///
/// # Returns
/// * List of topic strings
pub fn extract_topics(text: String, num_topics: Option<u32>) -> Result<Vec<String>> {
    let num_topics = num_topics.unwrap_or(3);

    let system_prompt = "You are a helpful assistant that extracts key topics from text. \
        Always respond with a valid JSON array of strings, nothing else.";

    let user_prompt = format!(
        "Extract exactly {} distinct topic keywords from the following text. \
        Return only a JSON array of strings like [\"topic1\", \"topic2\", \"topic3\"]. \
        No explanations.\n\nText: {}",
        num_topics, text
    );

    let messages = vec![
        ("system".to_string(), system_prompt.to_string()),
        ("user".to_string(), user_prompt),
    ];

    let response = chat_completion(messages, Some(100))?;

    // Parse JSON response
    let topics: Vec<String> = serde_json::from_str(&response.trim()).map_err(|e| {
        anyhow!(
            "Failed to parse topics JSON: {}. Response was: {}",
            e,
            response
        )
    })?;

    Ok(topics)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = InferenceConfig::default();
        assert_eq!(config.n_gpu_layers, 99);
        assert_eq!(config.n_ctx, 4096);
        assert_eq!(config.n_threads, 4);
    }

    #[test]
    fn test_model_not_loaded() {
        assert!(!is_model_loaded());
    }
}
