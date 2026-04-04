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
use llama_cpp_2::model::{AddBos, LlamaChatMessage, LlamaModel, Special};
use llama_cpp_2::token::data_array::LlamaTokenDataArray;
use parking_lot::Mutex;
use std::fs;
use std::num::NonZeroU32;
use std::path::Path;
use std::sync::Arc;

#[cfg(feature = "mtmd")]
use llama_cpp_2::mtmd::{mtmd_default_marker, MtmdBitmap, MtmdContext, MtmdInputText};

/// Supported model types with different chat templates
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModelType {
    /// Microsoft Phi-4 Mini - uses <|system|>, <|user|>, <|assistant|>, <|end|> format
    Phi4,
    /// Qwen family (Qwen2.5/Qwen3.5) - uses <|im_start|>, <|im_end|> ChatML format
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
    model_hint: String,
    vision_capable: bool,
    mmproj_path: Option<String>,
}

/// Global AI state (singleton pattern)
static AI_STATE: Mutex<Option<Arc<ModelState>>> = Mutex::new(None);

/// Detect model type from the model filename
fn detect_model_type(model_path: &str) -> ModelType {
    let lower_path = model_path.to_lowercase();
    if lower_path.contains("qwen")
        || lower_path.contains("deepseek-r1-distill-qwen")
        || lower_path.contains("smollm2")
        || lower_path.contains("smollm3")
        || lower_path.contains("smolvlm")
    {
        ModelType::Qwen
    } else if lower_path.contains("functionary") || lower_path.contains("function-gemma") {
        ModelType::Functionary
    } else {
        // Default to Phi-4 format
        ModelType::Phi4
    }
}

fn is_vision_model_hint(model_path: &str) -> bool {
    let lower = model_path.to_lowercase();
    lower.contains("smolvlm")
        || lower.contains("llava")
        || lower.contains("qwen2vl")
        || lower.contains("qwen25vl")
        || lower.contains("vision")
}

fn detect_mmproj_path(model_path: &str) -> Option<String> {
    let model_file = Path::new(model_path);
    let parent = model_file.parent()?;
    let file_name = model_file
        .file_name()
        .map(|name| name.to_string_lossy().to_string())?;
    let stem = model_file
        .file_stem()
        .map(|stem| stem.to_string_lossy().to_string())?;

    let mut candidates = vec![
        format!("mmproj-{}", file_name),
        format!("mmproj-{}.gguf", stem),
        "mmproj-SmolVLM2-500M-Video-Instruct-Q8_0.gguf".to_string(),
        "mmproj-SmolVLM2-500M-Video-Instruct-f16.gguf".to_string(),
    ];

    candidates.dedup();

    for candidate in candidates {
        let candidate_path = parent.join(candidate);
        if candidate_path.exists() {
            return Some(candidate_path.to_string_lossy().to_string());
        }
    }

    let entries = fs::read_dir(parent).ok()?;
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_file() {
            continue;
        }

        let lower_name = path
            .file_name()
            .map(|name| name.to_string_lossy().to_lowercase())
            .unwrap_or_default();
        if lower_name.contains("mmproj") && lower_name.ends_with(".gguf") {
            return Some(path.to_string_lossy().to_string());
        }
    }

    None
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

    log::info!(
        "Initializing model from: {} (type: {:?})",
        model_path,
        config.model_type
    );

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

    let vision_capable = is_vision_model_hint(&model_path);
    let mmproj_path = if vision_capable {
        detect_mmproj_path(&model_path)
    } else {
        None
    };

    if vision_capable {
        if let Some(mmproj) = &mmproj_path {
            log::info!("Detected mmproj companion file: {}", mmproj);
        } else {
            log::warn!(
                "Model appears vision-capable but no mmproj companion was found near {}",
                model_path
            );
        }
    }

    // Store state globally
    *AI_STATE.lock() = Some(Arc::new(ModelState {
        backend,
        model,
        config,
        model_hint: model_path.to_lowercase(),
        vision_capable,
        mmproj_path,
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
#[deprecated(
    since = "0.2.0",
    note = "Use init_model instead for multi-model support"
)]
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
    let model_hint = state.model_hint.as_str();
    let max_tokens = max_tokens.unwrap_or(state.config.max_tokens);

    if state.vision_capable {
        if let Some(image_path) = find_image_attachment_path(&messages) {
            if let Some(mmproj_path) = state.mmproj_path.as_deref() {
                match chat_completion_with_vision(
                    state,
                    &messages,
                    &image_path,
                    mmproj_path,
                    max_tokens,
                ) {
                    Ok(response) => return Ok(response),
                    Err(error) => {
                        log::warn!(
                            "Vision inference failed for image '{}'; falling back to text-only path: {}",
                            image_path,
                            error
                        );
                    }
                }
            } else {
                log::warn!(
                    "Image attachment detected but mmproj companion is missing; using text fallback"
                );
            }
        }
    }

    // Prefer the model's own chat template (llama.cpp apply_chat_template path).
    // This gives much better compatibility for newer reasoning families and
    // template-specific token conventions.
    let prompt = match format_with_model_template(state, &messages) {
        Ok(prompt) => prompt,
        Err(error) => {
            log::warn!(
                "Falling back to legacy prompt formatter after template failure: {}",
                error
            );
            format_chat_prompt_fallback(&messages, model_type, model_hint)
        }
    };

    drop(guard); // Release lock before generation
    generate_text(prompt, Some(max_tokens))
}

fn find_image_attachment_path(messages: &[(String, String)]) -> Option<String> {
    for (role, content) in messages.iter().rev() {
        if role != "user" {
            continue;
        }

        let mut current_path: Option<String> = None;
        for line in content.lines() {
            let trimmed = line.trim();
            if let Some(path) = trimmed.strip_prefix("- Path: ") {
                current_path = Some(path.trim().to_string());
                continue;
            }

            if let Some(media_type) = trimmed.strip_prefix("- Media type: ") {
                let is_image = media_type.trim().to_lowercase().starts_with("image/");
                if is_image {
                    if let Some(path) = current_path.clone() {
                        if Path::new(&path).exists() {
                            return Some(path);
                        }
                    }
                }
            }
        }
    }

    None
}

fn vision_media_marker() -> &'static str {
    #[cfg(feature = "mtmd")]
    {
        mtmd_default_marker()
    }
    #[cfg(not(feature = "mtmd"))]
    {
        "<__media__>"
    }
}

fn inject_vision_marker(messages: &[(String, String)]) -> Vec<(String, String)> {
    let marker = vision_media_marker();
    let mut updated_messages = messages.to_vec();

    for (role, content) in updated_messages.iter_mut().rev() {
        if role != "user" {
            continue;
        }

        if !content.contains(marker) {
            content.push_str(&format!("\n\nAttached image:\n{}", marker));
        }
        break;
    }

    updated_messages
}

fn chat_completion_with_vision(
    state: &ModelState,
    messages: &[(String, String)],
    image_path: &str,
    mmproj_path: &str,
    max_tokens: u32,
) -> Result<String> {
    #[cfg(not(feature = "mtmd"))]
    {
        let _ = (state, messages, image_path, mmproj_path, max_tokens);
        return Err(anyhow!(
            "This binary was built without mtmd support for vision inference"
        ));
    }

    #[cfg(feature = "mtmd")]
    {
        let messages_with_marker = inject_vision_marker(messages);
        let model_type = state.config.model_type;
        let model_hint = state.model_hint.as_str();

        let prompt = match format_with_model_template(state, &messages_with_marker) {
            Ok(prompt) => prompt,
            Err(error) => {
                log::warn!(
                    "Falling back to legacy prompt formatter for vision path after template failure: {}",
                    error
                );
                format_chat_prompt_fallback(&messages_with_marker, model_type, model_hint)
            }
        };

        let ctx_params = LlamaContextParams::default()
            .with_n_ctx(NonZeroU32::new(state.config.n_ctx))
            .with_n_threads(state.config.n_threads)
            .with_n_threads_batch(state.config.n_threads);

        let mut ctx = state
            .model
            .new_context(&state.backend, ctx_params)
            .map_err(|e| anyhow!("Failed to create context for vision inference: {:?}", e))?;

        let mtmd_ctx = MtmdContext::init_from_file(mmproj_path, &state.model, &Default::default())
            .map_err(|e| anyhow!("Failed to initialize mtmd context: {}", e))?;

        if !mtmd_ctx.support_vision() {
            return Err(anyhow!("Loaded mtmd context does not support vision"));
        }

        let bitmap = MtmdBitmap::from_file(&mtmd_ctx, image_path)
            .map_err(|e| anyhow!("Failed to load image bitmap '{}': {}", image_path, e))?;

        let input_text = MtmdInputText {
            text: prompt,
            add_special: true,
            parse_special: true,
        };

        let chunks = mtmd_ctx
            .tokenize(input_text, &[&bitmap])
            .map_err(|e| anyhow!("Failed to tokenize multimodal prompt: {}", e))?;

        let n_past = chunks
            .eval_chunks(
                &mtmd_ctx,
                &ctx,
                0,
                0,
                state.config.n_ctx as i32,
                true,
            )
            .map_err(|e| anyhow!("Failed to evaluate multimodal chunks: {}", e))?;

        generate_from_context(state, &mut ctx, max_tokens, n_past.max(0) as usize)
    }
}

fn generate_from_context(
    state: &ModelState,
    ctx: &mut llama_cpp_2::context::LlamaContext<'_>,
    max_tokens: u32,
    mut n_cur: usize,
) -> Result<String> {
    let mut output_tokens = Vec::new();
    let mut batch = LlamaBatch::new(state.config.n_ctx as usize, 1);

    // Use a simple random seed for sampling
    let mut rng_seed: u32 = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as u32;

    for _ in 0..max_tokens {
        let candidates = ctx.candidates();
        let mut candidates_array = LlamaTokenDataArray::from_iter(candidates, false);

        rng_seed = rng_seed.wrapping_mul(1103515245).wrapping_add(12345);
        let new_token = candidates_array.sample_token(rng_seed);

        if state.model.is_eog_token(new_token) {
            break;
        }

        output_tokens.push(new_token);

        batch.clear();
        batch.add(new_token, n_cur as i32, &[0], true)?;
        n_cur += 1;

        ctx.decode(&mut batch)
            .map_err(|e| anyhow!("Failed to decode generated vision token: {:?}", e))?;
    }

    let output = output_tokens
        .iter()
        .map(|t| state.model.token_to_str(*t, Special::Tokenize))
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| anyhow!("Failed to detokenize vision response: {:?}", e))?
        .join("");

    Ok(output)
}

/// Format messages using the GGUF model's baked chat template via llama.cpp.
fn format_with_model_template(state: &ModelState, messages: &[(String, String)]) -> Result<String> {
    let template = state
        .model
        .chat_template(None)
        .map_err(|e| anyhow!("Failed to load model chat template: {}", e))?;

    let chat_messages = messages
        .iter()
        .map(|(role, content)| LlamaChatMessage::new(role.clone(), content.clone()))
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| anyhow!("Failed to build chat messages for template: {}", e))?;

    state
        .model
        .apply_chat_template(&template, &chat_messages, true)
        .map_err(|e| anyhow!("Failed to apply model chat template: {}", e))
}

/// Format messages into a chat prompt based on model type
fn format_chat_prompt(messages: &[(String, String)], model_type: ModelType) -> String {
    match model_type {
        ModelType::Phi4 => format_phi4_prompt(messages),
        ModelType::Qwen => format_qwen_prompt(messages),
        ModelType::Functionary => format_functionary_prompt(messages),
    }
}

/// Legacy formatter fallback that adds model-family heuristics for templates
/// not handled by the current llama.cpp template engine.
fn format_chat_prompt_fallback(
    messages: &[(String, String)],
    model_type: ModelType,
    model_hint: &str,
) -> String {
    let lower_hint = model_hint.to_lowercase();

    if lower_hint.contains("gemma-3") || lower_hint.contains("gemma3") {
        return format_gemma3_prompt(messages);
    }

    if lower_hint.contains("deepseek-r1-distill-qwen") || lower_hint.contains("smollm2") {
        return format_qwen_prompt(messages);
    }

    format_chat_prompt(messages, model_type)
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

/// Format messages using Gemma 3 template style
/// Uses: <start_of_turn>user/model ... <end_of_turn>
fn format_gemma3_prompt(messages: &[(String, String)]) -> String {
    let mut prompt = String::from("<bos>");

    for (role, content) in messages {
        match role.as_str() {
            "system" => {
                // Gemma 3 templates often treat system guidance as part of user turn.
                prompt.push_str(&format!(
                    "<start_of_turn>user\nSystem instructions:\n{}<end_of_turn>\n",
                    content
                ));
            }
            "user" => {
                prompt.push_str(&format!("<start_of_turn>user\n{}<end_of_turn>\n", content));
            }
            "assistant" => {
                prompt.push_str(&format!("<start_of_turn>model\n{}<end_of_turn>\n", content));
            }
            _ => {
                log::warn!("Unknown role: {}", role);
            }
        }
    }

    // Add model prompt to generate response
    prompt.push_str("<start_of_turn>model\n");
    prompt
}

/// Format messages using Functionary/Function-Gemma template
/// Uses: <|from|>, <|recipient|> for function calling support
fn format_functionary_prompt(messages: &[(String, String)]) -> String {
    let mut prompt = String::new();

    for (role, content) in messages {
        match role.as_str() {
            "system" => {
                prompt.push_str(&format!(
                    "<|from|>system\n<|recipient|>all\n<|content|>{}\n",
                    content
                ));
            }
            "user" => {
                prompt.push_str(&format!(
                    "<|from|>user\n<|recipient|>all\n<|content|>{}\n",
                    content
                ));
            }
            "assistant" => {
                prompt.push_str(&format!(
                    "<|from|>assistant\n<|recipient|>all\n<|content|>{}\n",
                    content
                ));
            }
            "function" => {
                // Function call results
                prompt.push_str(&format!(
                    "<|from|>function\n<|recipient|>assistant\n<|content|>{}\n",
                    content
                ));
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
        assert_eq!(
            detect_model_type("/path/to/phi-4-mini.gguf"),
            ModelType::Phi4
        );
        assert_eq!(
            detect_model_type("/path/to/Phi4-Mini-Q4.gguf"),
            ModelType::Phi4
        );
        assert_eq!(
            detect_model_type("/path/to/qwen2.5-3b.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/Qwen2.5-Coder.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/Qwen3.5-4B.Q4_K_M.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/Qwen3.5-2B.Q5_K_M.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/Qwen3.5-0.8B.Q5_K_M.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/functionary-v2.gguf"),
            ModelType::Functionary
        );
        assert_eq!(
            detect_model_type("/path/to/function-gemma-2b.gguf"),
            ModelType::Functionary
        );
        assert_eq!(
            detect_model_type("/path/to/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/SmolLM2-1.7B-Instruct-Q4_K_M.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/SmolLM3-Q4_K_M.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/SmolVLM2-500M-Video-Instruct-Q8_0.gguf"),
            ModelType::Qwen
        );
        assert_eq!(
            detect_model_type("/path/to/some-model.gguf"),
            ModelType::Phi4
        ); // Default
    }

    #[test]
    fn test_find_image_attachment_path() {
        let messages = vec![
            ("system".to_string(), "You are helpful".to_string()),
            (
                "user".to_string(),
                "Question\n\n[Attached files]\nAttachment 1: image.png\n- Path: C:/tmp/image.png\n- Media type: image/png\n- Size: 123 bytes"
                    .to_string(),
            ),
        ];

        // File existence is required; use a stable non-existent path and assert none.
        assert!(find_image_attachment_path(&messages).is_none());

        let cwd = std::env::current_dir().unwrap();
        let existing = cwd.join("Cargo.toml");
        let content = format!(
            "[Attached files]\nAttachment 1: test\n- Path: {}\n- Media type: image/png",
            existing.to_string_lossy()
        );
        let messages_existing = vec![("user".to_string(), content)];

        let detected = find_image_attachment_path(&messages_existing);
        assert_eq!(
            detected,
            Some(existing.to_string_lossy().to_string()),
            "should return the existing image attachment path"
        );
    }

    #[test]
    fn test_inject_vision_marker_on_latest_user_message() {
        let messages = vec![
            ("system".to_string(), "System".to_string()),
            ("user".to_string(), "First user message".to_string()),
            ("assistant".to_string(), "Assistant reply".to_string()),
            ("user".to_string(), "Last user message".to_string()),
        ];

        let updated = inject_vision_marker(&messages);
        let marker = vision_media_marker();

        assert!(updated[1].1 == "First user message");
        assert!(updated[3].1.contains(marker));
    }

    #[test]
    fn test_phi4_prompt_format() {
        let messages = vec![
            (
                "system".to_string(),
                "You are a helpful assistant.".to_string(),
            ),
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
            (
                "system".to_string(),
                "You are a helpful assistant.".to_string(),
            ),
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
            (
                "system".to_string(),
                "You are a helpful assistant.".to_string(),
            ),
            ("user".to_string(), "Hello!".to_string()),
        ];
        let prompt = format_functionary_prompt(&messages);
        assert!(prompt
            .contains("<|from|>system\n<|recipient|>all\n<|content|>You are a helpful assistant."));
        assert!(prompt.contains("<|from|>user\n<|recipient|>all\n<|content|>Hello!"));
        assert!(prompt.ends_with("<|from|>assistant\n<|recipient|>all\n<|content|>"));
    }

    #[test]
    fn test_gemma3_prompt_format() {
        let messages = vec![
            (
                "system".to_string(),
                "You are a helpful assistant.".to_string(),
            ),
            ("user".to_string(), "Hello!".to_string()),
        ];
        let prompt = format_gemma3_prompt(&messages);
        assert!(prompt.starts_with("<bos>"));
        assert!(prompt.contains(
            "<start_of_turn>user\nSystem instructions:\nYou are a helpful assistant.<end_of_turn>"
        ));
        assert!(prompt.contains("<start_of_turn>user\nHello!<end_of_turn>"));
        assert!(prompt.ends_with("<start_of_turn>model\n"));
    }

    #[test]
    fn test_fallback_uses_gemma3_formatter() {
        let messages = vec![("user".to_string(), "Test".to_string())];
        let prompt = format_chat_prompt_fallback(
            &messages,
            ModelType::Phi4,
            "google_gemma-3-4b-it-q4_k_m.gguf",
        );
        assert!(prompt.contains("<start_of_turn>user\nTest<end_of_turn>"));
    }
}
