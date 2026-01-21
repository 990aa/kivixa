//! Multi-Model Inference Engine
//!
//! Provides GPU-accelerated inference using llama.cpp bindings.
//! Supports multiple models (Phi-4, Qwen, Functionary) with automatic
//! chat template selection based on model type.
//! Supports text generation and embedding extraction.

use anyhow::{anyhow, Result};
use llama_cpp_2::context::params::LlamaContextParams;
use llama_cpp_2::llama_backend::LlamaBackend;
use llama_cpp_2::llama_batch::LlamaBatch;
use llama_cpp_2::model::params::LlamaModelParams;
use llama_cpp_2::model::{AddBos, LlamaModel, Special};
use llama_cpp_2::token::data_array::LlamaTokenDataArray;
use parking_lot::Mutex;
use std::num::NonZeroU32;
use std::path::Path;
use std::sync::Arc;

/// Supported model types with different chat templates
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModelType {
    /// Microsoft Phi-4 Mini - uses <|system|>, <|user|>, <|assistant|>, <|end|> format
    Phi4,
    /// Qwen 2.5 - uses <|im_start|>, <|im_end|> ChatML format
    Qwen,
    /// Functionary models - uses function calling format with <|from|> tags
    Functionary,
}

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
    /// Model type for chat template selection
    pub model_type: ModelType,
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
            model_type: ModelType::Phi4, // Default to Phi-4 for compatibility
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

/// Detect model type from the model filename
fn detect_model_type(model_path: &str) -> ModelType {
    let lower_path = model_path.to_lowercase();
    if lower_path.contains("qwen") {
        ModelType::Qwen
    } else if lower_path.contains("functionary") || lower_path.contains("function-gemma") {
        ModelType::Functionary
    } else {
        // Default to Phi-4 format
        ModelType::Phi4
    }
}

/// Initialize the AI model from the given path (model-agnostic)
///
/// # Arguments
/// * `model_path` - Full path to the GGUF model file
/// * `config` - Optional inference configuration (model_type auto-detected if not specified)
///
/// # Returns
/// * `Ok(())` if model loaded successfully
/// * `Err(...)` if loading failed
pub fn init_model(model_path: String, config: Option<InferenceConfig>) -> Result<()> {
    let mut config = config.unwrap_or_default();
    
    // Auto-detect model type from filename if not explicitly set
    let detected_type = detect_model_type(&model_path);
    config.model_type = detected_type;

    log::info!("Initializing model from: {} (type: {:?})", model_path, config.model_type);

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

/// Get the currently loaded model type
pub fn get_model_type() -> Option<ModelType> {
    AI_STATE.lock().as_ref().map(|s| s.config.model_type)
}

/// Initialize the Phi-4 model (backward-compatible alias for init_model)
///
/// # Arguments
/// * `model_path` - Full path to the GGUF model file
/// * `config` - Optional inference configuration
///
/// # Returns
/// * `Ok(())` if model loaded successfully
/// * `Err(...)` if loading failed
#[deprecated(since = "0.2.0", note = "Use init_model instead for multi-model support")]
pub fn init_phi4(model_path: String, config: Option<InferenceConfig>) -> Result<()> {
    // Set model type explicitly to Phi4 for backward compatibility
    let mut config = config.unwrap_or_default();
    config.model_type = ModelType::Phi4;
    init_model(model_path, Some(config))
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
/// Automatically selects the appropriate chat template based on the loaded model type.
///
/// # Arguments
/// * `messages` - List of (role, content) pairs where role is "system", "user", or "assistant"
/// * `max_tokens` - Maximum tokens to generate
///
/// # Returns
/// * Assistant's response
pub fn chat_completion(messages: Vec<(String, String)>, max_tokens: Option<u32>) -> Result<String> {
    let guard = AI_STATE.lock();
    let state = guard.as_ref().ok_or_else(|| anyhow!("Model not loaded"))?;
    let model_type = state.config.model_type;
    drop(guard); // Release lock before generation
    
    let prompt = format_chat_prompt(&messages, model_type);
    generate_text(prompt, max_tokens)
}

/// Format messages into a chat prompt based on model type
fn format_chat_prompt(messages: &[(String, String)], model_type: ModelType) -> String {
    match model_type {
        ModelType::Phi4 => format_phi4_prompt(messages),
        ModelType::Qwen => format_qwen_prompt(messages),
        ModelType::Functionary => format_functionary_prompt(messages),
    }
}

/// Format messages using Phi-4 chat template
/// Uses: <|system|>, <|user|>, <|assistant|>, <|end|>
fn format_phi4_prompt(messages: &[(String, String)]) -> String {
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
    prompt
}

/// Format messages using Qwen ChatML template
/// Uses: <|im_start|>, <|im_end|>
fn format_qwen_prompt(messages: &[(String, String)]) -> String {
    let mut prompt = String::new();

    for (role, content) in messages {
        match role.as_str() {
            "system" | "user" | "assistant" => {
                prompt.push_str(&format!("<|im_start|>{}\n{}<|im_end|>\n", role, content));
            }
            _ => {
                log::warn!("Unknown role: {}", role);
            }
        }
    }

    // Add assistant prompt to generate response
    prompt.push_str("<|im_start|>assistant\n");
    prompt
}

/// Format messages using Functionary/Function-Gemma template
/// Uses: <|from|>, <|recipient|> for function calling support
fn format_functionary_prompt(messages: &[(String, String)]) -> String {
    let mut prompt = String::new();

    for (role, content) in messages {
        match role.as_str() {
            "system" => {
                prompt.push_str(&format!("<|from|>system\n<|recipient|>all\n<|content|>{}\n", content));
            }
            "user" => {
                prompt.push_str(&format!("<|from|>user\n<|recipient|>all\n<|content|>{}\n", content));
            }
            "assistant" => {
                prompt.push_str(&format!("<|from|>assistant\n<|recipient|>all\n<|content|>{}\n", content));
            }
            "function" => {
                // Function call results
                prompt.push_str(&format!("<|from|>function\n<|recipient|>assistant\n<|content|>{}\n", content));
            }
            _ => {
                log::warn!("Unknown role: {}", role);
            }
        }
    }

    // Add assistant prompt to generate response
    prompt.push_str("<|from|>assistant\n<|recipient|>all\n<|content|>");
    prompt
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
        assert_eq!(config.model_type, ModelType::Phi4);
    }

    #[test]
    fn test_model_not_loaded() {
        assert!(!is_model_loaded());
        assert!(get_model_type().is_none());
    }

    #[test]
    fn test_detect_model_type() {
        assert_eq!(detect_model_type("/path/to/phi-4-mini.gguf"), ModelType::Phi4);
        assert_eq!(detect_model_type("/path/to/Phi4-Mini-Q4.gguf"), ModelType::Phi4);
        assert_eq!(detect_model_type("/path/to/qwen2.5-3b.gguf"), ModelType::Qwen);
        assert_eq!(detect_model_type("/path/to/Qwen2.5-Coder.gguf"), ModelType::Qwen);
        assert_eq!(detect_model_type("/path/to/functionary-v2.gguf"), ModelType::Functionary);
        assert_eq!(detect_model_type("/path/to/function-gemma-2b.gguf"), ModelType::Functionary);
        assert_eq!(detect_model_type("/path/to/some-model.gguf"), ModelType::Phi4); // Default
    }

    #[test]
    fn test_phi4_prompt_format() {
        let messages = vec![
            ("system".to_string(), "You are a helpful assistant.".to_string()),
            ("user".to_string(), "Hello!".to_string()),
        ];
        let prompt = format_phi4_prompt(&messages);
        assert!(prompt.contains("<|system|>\nYou are a helpful assistant.<|end|>"));
        assert!(prompt.contains("<|user|>\nHello!<|end|>"));
        assert!(prompt.ends_with("<|assistant|>\n"));
    }

    #[test]
    fn test_qwen_prompt_format() {
        let messages = vec![
            ("system".to_string(), "You are a helpful assistant.".to_string()),
            ("user".to_string(), "Hello!".to_string()),
        ];
        let prompt = format_qwen_prompt(&messages);
        assert!(prompt.contains("<|im_start|>system\nYou are a helpful assistant.<|im_end|>"));
        assert!(prompt.contains("<|im_start|>user\nHello!<|im_end|>"));
        assert!(prompt.ends_with("<|im_start|>assistant\n"));
    }

    #[test]
    fn test_functionary_prompt_format() {
        let messages = vec![
            ("system".to_string(), "You are a helpful assistant.".to_string()),
            ("user".to_string(), "Hello!".to_string()),
        ];
        let prompt = format_functionary_prompt(&messages);
        assert!(prompt.contains("<|from|>system\n<|recipient|>all\n<|content|>You are a helpful assistant."));
        assert!(prompt.contains("<|from|>user\n<|recipient|>all\n<|content|>Hello!"));
        assert!(prompt.ends_with("<|from|>assistant\n<|recipient|>all\n<|content|>"));
    }
}
