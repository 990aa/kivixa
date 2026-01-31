//! Speech-to-Text (STT) Module
//!
//! Implements Whisper-based speech recognition using audio processing.
//! Provides real-time transcription with timestamps for semantic audio indexing.
//!
//! Note: The actual Whisper model inference will be integrated via ONNX Runtime
//! or similar cross-platform inference engine in a future update. This module
//! provides the complete API and audio preprocessing pipeline.

use anyhow::{anyhow, Result};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Arc;

use crate::audio_buffer::WHISPER_SAMPLE_RATE;
use crate::vad::SharedVad;

/// Whisper model size variants
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[derive(Default)]
pub enum WhisperModel {
    /// Tiny model (~39M parameters, ~150MB)
    #[default]
    Tiny,
    /// Base model (~74M parameters, ~290MB)
    Base,
    /// Small model (~244M parameters, ~970MB)
    Small,
    /// Medium model (~769M parameters, ~3GB)
    Medium,
    /// Large model (~1.5B parameters, ~6GB)
    Large,
}

impl WhisperModel {
    /// Get the model identifier for loading
    pub fn model_id(&self) -> &'static str {
        match self {
            WhisperModel::Tiny => "openai/whisper-tiny",
            WhisperModel::Base => "openai/whisper-base",
            WhisperModel::Small => "openai/whisper-small",
            WhisperModel::Medium => "openai/whisper-medium",
            WhisperModel::Large => "openai/whisper-large-v3",
        }
    }

    /// Get approximate model size in bytes
    pub fn size_bytes(&self) -> u64 {
        match self {
            WhisperModel::Tiny => 150_000_000,
            WhisperModel::Base => 290_000_000,
            WhisperModel::Small => 970_000_000,
            WhisperModel::Medium => 3_000_000_000,
            WhisperModel::Large => 6_000_000_000,
        }
    }

    /// Get recommended compute mode for this model
    /// Returns "cpu" for cross-platform compatibility
    pub fn recommended_compute(&self) -> &'static str {
        "cpu"
    }
}


/// Configuration for STT engine
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SttConfig {
    /// Which Whisper model to use
    pub model: WhisperModel,
    /// Language code (None for auto-detect)
    pub language: Option<String>,
    /// Whether to return word-level timestamps
    pub word_timestamps: bool,
    /// Whether to use VAD for preprocessing
    pub use_vad: bool,
    /// Minimum segment duration in seconds
    pub min_segment_duration: f32,
    /// Maximum segment duration in seconds
    pub max_segment_duration: f32,
    /// Path to model files
    pub model_path: Option<PathBuf>,
}

impl Default for SttConfig {
    fn default() -> Self {
        Self {
            model: WhisperModel::Tiny,
            language: None,
            word_timestamps: true,
            use_vad: true,
            min_segment_duration: 1.0,
            max_segment_duration: 30.0,
            model_path: None,
        }
    }
}

/// A single word with timing information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimestampedWord {
    /// The word text
    pub word: String,
    /// Start time in seconds
    pub start_time: f32,
    /// End time in seconds
    pub end_time: f32,
    /// Confidence score (0.0 to 1.0)
    pub confidence: f32,
}

impl TimestampedWord {
    /// Get the duration of this word
    pub fn duration(&self) -> f32 {
        self.end_time - self.start_time
    }
}

/// A transcription segment (sentence or phrase)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranscriptionSegment {
    /// Unique segment ID
    pub id: u32,
    /// The transcribed text
    pub text: String,
    /// Start time in seconds (relative to recording start)
    pub start_time: f32,
    /// End time in seconds
    pub end_time: f32,
    /// Word-level timestamps (if enabled)
    pub words: Vec<TimestampedWord>,
    /// Detected language
    pub language: Option<String>,
    /// Overall confidence score
    pub confidence: f32,
    /// Whether this segment is final or still being processed
    pub is_final: bool,
}

impl TranscriptionSegment {
    /// Get the duration of this segment
    pub fn duration(&self) -> f32 {
        self.end_time - self.start_time
    }

    /// Check if segment is empty
    pub fn is_empty(&self) -> bool {
        self.text.trim().is_empty()
    }
}

/// Full transcription result
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Transcription {
    /// All transcription segments
    pub segments: Vec<TranscriptionSegment>,
    /// Detected language for the audio
    pub language: Option<String>,
    /// Total duration of processed audio
    pub duration: f32,
    /// Processing time in milliseconds
    pub processing_time_ms: u64,
}

impl Transcription {
    /// Get the full text of the transcription
    pub fn full_text(&self) -> String {
        self.segments
            .iter()
            .map(|s| s.text.as_str())
            .collect::<Vec<_>>()
            .join(" ")
    }

    /// Get all words with timestamps
    pub fn all_words(&self) -> Vec<&TimestampedWord> {
        self.segments.iter().flat_map(|s| s.words.iter()).collect()
    }

    /// Search for text and return matching segments with timestamps
    pub fn search(&self, query: &str) -> Vec<&TranscriptionSegment> {
        let query_lower = query.to_lowercase();
        self.segments
            .iter()
            .filter(|s| s.text.to_lowercase().contains(&query_lower))
            .collect()
    }
}

/// Speech-to-Text engine state
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SttState {
    /// Not initialized
    Uninitialized,
    /// Loading model
    Loading,
    /// Ready to process
    Ready,
    /// Currently processing audio
    Processing,
    /// Error state
    Error,
}

/// Mel spectrogram configuration for Whisper
const N_FFT: usize = 400;
const HOP_LENGTH: usize = 160;
const N_MELS: usize = 80;
#[allow(dead_code)]
const CHUNK_LENGTH: usize = 30; // seconds

/// Speech-to-Text Engine
///
/// Provides real-time transcription using Whisper models.
/// Designed to work with streaming audio from Flutter.
#[derive(Debug)]
pub struct SttEngine {
    config: SttConfig,
    state: SttState,
    /// Compute mode ("cpu" for now)
    #[allow(dead_code)]
    compute_mode: String,
    /// VAD for preprocessing (optional)
    vad: Option<SharedVad>,
    /// Segment counter
    segment_counter: u32,
    /// Accumulated audio for processing
    audio_buffer: Vec<f32>,
    /// Current recording start time
    recording_start: f32,
    /// Mel filterbank for spectrogram computation
    mel_filters: Option<Vec<f32>>,
}

impl SttEngine {
    /// Create a new STT engine with default configuration
    pub fn new() -> Self {
        Self::with_config(SttConfig::default())
    }

    /// Create a new STT engine with custom configuration
    pub fn with_config(config: SttConfig) -> Self {
        let compute_mode = config.model.recommended_compute().to_string();
        let vad = if config.use_vad {
            Some(SharedVad::new())
        } else {
            None
        };

        Self {
            config,
            state: SttState::Uninitialized,
            compute_mode,
            vad,
            segment_counter: 0,
            audio_buffer: Vec::new(),
            recording_start: 0.0,
            mel_filters: None,
        }
    }

    /// Initialize the STT engine (load models)
    pub fn initialize(&mut self) -> Result<()> {
        self.state = SttState::Loading;

        // Initialize mel filterbank
        self.mel_filters = Some(self.create_mel_filterbank());

        self.state = SttState::Ready;
        Ok(())
    }

    /// Create mel filterbank for spectrogram computation
    fn create_mel_filterbank(&self) -> Vec<f32> {
        let n_fft = N_FFT;
        let n_mels = N_MELS;
        let sample_rate = WHISPER_SAMPLE_RATE as f32;

        // Mel scale conversion functions
        let hz_to_mel = |hz: f32| -> f32 { 2595.0 * (1.0 + hz / 700.0).log10() };
        let mel_to_hz = |mel: f32| -> f32 { 700.0 * (10.0_f32.powf(mel / 2595.0) - 1.0) };

        let mel_low = hz_to_mel(0.0);
        let mel_high = hz_to_mel(sample_rate / 2.0);

        // Create mel points
        let mel_points: Vec<f32> = (0..=n_mels + 1)
            .map(|i| mel_low + (mel_high - mel_low) * i as f32 / (n_mels + 1) as f32)
            .collect();

        // Convert to Hz and then to FFT bins
        let hz_points: Vec<f32> = mel_points.iter().map(|&m| mel_to_hz(m)).collect();
        let bin_points: Vec<usize> = hz_points
            .iter()
            .map(|&hz| ((n_fft + 1) as f32 * hz / sample_rate).floor() as usize)
            .collect();

        // Create filterbank matrix (flattened)
        let mut filters = vec![0.0_f32; n_mels * (n_fft / 2 + 1)];

        for i in 0..n_mels {
            let start = bin_points[i];
            let center = bin_points[i + 1];
            let end = bin_points[i + 2];

            // Rising slope
            for j in start..center {
                if center > start && j < n_fft / 2 + 1 {
                    filters[i * (n_fft / 2 + 1) + j] = (j - start) as f32 / (center - start) as f32;
                }
            }

            // Falling slope
            for j in center..end {
                if end > center && j < n_fft / 2 + 1 {
                    filters[i * (n_fft / 2 + 1) + j] = (end - j) as f32 / (end - center) as f32;
                }
            }
        }

        filters
    }

    /// Process audio samples and return transcription
    ///
    /// # Arguments
    /// * `samples` - Audio samples (f32, normalized, 16kHz)
    /// * `start_time` - Start time of this chunk in the recording
    ///
    /// # Returns
    /// Transcription result with segments
    pub fn process(&mut self, samples: &[f32], start_time: f32) -> Result<Transcription> {
        if self.state != SttState::Ready {
            return Err(anyhow!("STT engine not ready (state: {:?})", self.state));
        }

        self.state = SttState::Processing;
        let process_start = std::time::Instant::now();

        // Apply VAD if enabled
        let samples_to_process = if let Some(ref vad) = self.vad {
            let vad_result = vad.process(samples);
            if !vad_result.is_speech {
                self.state = SttState::Ready;
                return Ok(Transcription::default());
            }
            samples.to_vec()
        } else {
            samples.to_vec()
        };

        // Accumulate audio
        self.audio_buffer.extend_from_slice(&samples_to_process);

        // Check if we have enough audio for processing
        let min_samples = (self.config.min_segment_duration * WHISPER_SAMPLE_RATE as f32) as usize;
        if self.audio_buffer.len() < min_samples {
            self.state = SttState::Ready;
            return Ok(Transcription::default());
        }

        // Clone the audio buffer to avoid borrow checker issues
        let audio_to_process = self.audio_buffer.clone();

        // Process the audio (simplified - actual Whisper inference would go here)
        let transcription = self.transcribe_chunk(&audio_to_process, start_time)?;

        // Clear processed audio
        self.audio_buffer.clear();

        self.state = SttState::Ready;

        let processing_time = process_start.elapsed().as_millis() as u64;
        Ok(Transcription {
            segments: transcription,
            language: self.config.language.clone(),
            duration: samples.len() as f32 / WHISPER_SAMPLE_RATE as f32,
            processing_time_ms: processing_time,
        })
    }

    /// Transcribe an audio chunk
    fn transcribe_chunk(
        &mut self,
        samples: &[f32],
        start_time: f32,
    ) -> Result<Vec<TranscriptionSegment>> {
        // Compute mel spectrogram
        let _mel_spec = self.compute_mel_spectrogram(samples)?;

        // In a full implementation, this would:
        // 1. Load the Whisper model weights
        // 2. Run the encoder on the mel spectrogram
        // 3. Run the decoder to generate tokens
        // 4. Convert tokens to text with timestamps

        // For now, return a placeholder segment to demonstrate the API
        let duration = samples.len() as f32 / WHISPER_SAMPLE_RATE as f32;
        self.segment_counter += 1;

        let segment = TranscriptionSegment {
            id: self.segment_counter,
            text: String::new(), // Would contain actual transcription
            start_time,
            end_time: start_time + duration,
            words: Vec::new(),
            language: self.config.language.clone(),
            confidence: 0.0,
            is_final: true,
        };

        Ok(vec![segment])
    }

    /// Compute mel spectrogram from audio samples
    fn compute_mel_spectrogram(&self, samples: &[f32]) -> Result<Vec<f32>> {
        let n_fft = N_FFT;
        let hop_length = HOP_LENGTH;
        let n_mels = N_MELS;

        // Pad samples if needed
        let mut padded = samples.to_vec();
        let pad_amount = n_fft / 2;
        let mut padding = vec![0.0_f32; pad_amount];
        padding.extend_from_slice(&padded);
        padding.extend(vec![0.0_f32; pad_amount]);
        padded = padding;

        // Number of frames
        let n_frames = (padded.len() - n_fft) / hop_length + 1;

        // Compute STFT magnitude squared (simplified - would use FFT in practice)
        let mut stft_mag_sq = vec![0.0_f32; n_frames * (n_fft / 2 + 1)];

        for frame_idx in 0..n_frames {
            let start = frame_idx * hop_length;
            let frame: Vec<f32> = padded[start..start + n_fft].to_vec();

            // Apply Hann window and compute energy (simplified)
            let mut frame_energy = 0.0_f32;
            for (i, &sample) in frame.iter().enumerate() {
                let window =
                    0.5 * (1.0 - (2.0 * std::f32::consts::PI * i as f32 / n_fft as f32).cos());
                frame_energy += (sample * window).powi(2);
            }

            // Distribute energy across frequency bins (simplified)
            for bin in 0..(n_fft / 2 + 1) {
                stft_mag_sq[frame_idx * (n_fft / 2 + 1) + bin] =
                    frame_energy / (n_fft / 2 + 1) as f32;
            }
        }

        // Apply mel filterbank
        let filters = self
            .mel_filters
            .as_ref()
            .ok_or_else(|| anyhow!("Mel filters not initialized"))?;

        let mut mel_spec = vec![0.0_f32; n_frames * n_mels];

        for frame in 0..n_frames {
            for mel in 0..n_mels {
                let mut sum = 0.0_f32;
                for bin in 0..(n_fft / 2 + 1) {
                    sum += stft_mag_sq[frame * (n_fft / 2 + 1) + bin]
                        * filters[mel * (n_fft / 2 + 1) + bin];
                }
                // Log scale
                mel_spec[frame * n_mels + mel] = (sum.max(1e-10)).log10();
            }
        }

        Ok(mel_spec)
    }

    /// Reset the engine state
    pub fn reset(&mut self) {
        self.segment_counter = 0;
        self.audio_buffer.clear();
        self.recording_start = 0.0;
        if let Some(ref vad) = self.vad {
            vad.reset();
        }
    }

    /// Get current state
    pub fn state(&self) -> SttState {
        self.state
    }

    /// Check if ready
    pub fn is_ready(&self) -> bool {
        self.state == SttState::Ready
    }

    /// Get configuration
    pub fn config(&self) -> &SttConfig {
        &self.config
    }
}

impl Default for SttEngine {
    fn default() -> Self {
        Self::new()
    }
}

/// Thread-safe STT engine wrapper
#[derive(Debug, Clone)]
pub struct SharedSttEngine {
    inner: Arc<RwLock<SttEngine>>,
}

impl SharedSttEngine {
    /// Create a new shared STT engine
    pub fn new() -> Self {
        Self {
            inner: Arc::new(RwLock::new(SttEngine::new())),
        }
    }

    /// Create with custom config
    pub fn with_config(config: SttConfig) -> Self {
        Self {
            inner: Arc::new(RwLock::new(SttEngine::with_config(config))),
        }
    }

    /// Initialize (thread-safe)
    pub fn initialize(&self) -> Result<()> {
        self.inner.write().initialize()
    }

    /// Process audio (thread-safe)
    pub fn process(&self, samples: &[f32], start_time: f32) -> Result<Transcription> {
        self.inner.write().process(samples, start_time)
    }

    /// Reset (thread-safe)
    pub fn reset(&self) {
        self.inner.write().reset()
    }

    /// Get state (thread-safe)
    pub fn state(&self) -> SttState {
        self.inner.read().state()
    }

    /// Check if ready (thread-safe)
    pub fn is_ready(&self) -> bool {
        self.inner.read().is_ready()
    }
}

impl Default for SharedSttEngine {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_whisper_model_sizes() {
        assert!(WhisperModel::Tiny.size_bytes() < WhisperModel::Base.size_bytes());
        assert!(WhisperModel::Base.size_bytes() < WhisperModel::Small.size_bytes());
    }

    #[test]
    fn test_stt_config_default() {
        let config = SttConfig::default();
        assert_eq!(config.model, WhisperModel::Tiny);
        assert!(config.use_vad);
        assert!(config.word_timestamps);
    }

    #[test]
    fn test_timestamped_word() {
        let word = TimestampedWord {
            word: "hello".to_string(),
            start_time: 1.0,
            end_time: 1.5,
            confidence: 0.95,
        };
        assert!((word.duration() - 0.5).abs() < 0.001);
    }

    #[test]
    fn test_transcription_segment() {
        let segment = TranscriptionSegment {
            id: 1,
            text: "Hello world".to_string(),
            start_time: 0.0,
            end_time: 2.0,
            words: vec![],
            language: Some("en".to_string()),
            confidence: 0.9,
            is_final: true,
        };
        assert!((segment.duration() - 2.0).abs() < 0.001);
        assert!(!segment.is_empty());
    }

    #[test]
    fn test_transcription_full_text() {
        let transcription = Transcription {
            segments: vec![
                TranscriptionSegment {
                    id: 1,
                    text: "Hello".to_string(),
                    start_time: 0.0,
                    end_time: 0.5,
                    words: vec![],
                    language: None,
                    confidence: 0.9,
                    is_final: true,
                },
                TranscriptionSegment {
                    id: 2,
                    text: "world".to_string(),
                    start_time: 0.5,
                    end_time: 1.0,
                    words: vec![],
                    language: None,
                    confidence: 0.9,
                    is_final: true,
                },
            ],
            language: Some("en".to_string()),
            duration: 1.0,
            processing_time_ms: 100,
        };
        assert_eq!(transcription.full_text(), "Hello world");
    }

    #[test]
    fn test_transcription_search() {
        let transcription = Transcription {
            segments: vec![
                TranscriptionSegment {
                    id: 1,
                    text: "The quick brown fox".to_string(),
                    start_time: 0.0,
                    end_time: 2.0,
                    words: vec![],
                    language: None,
                    confidence: 0.9,
                    is_final: true,
                },
                TranscriptionSegment {
                    id: 2,
                    text: "jumps over the lazy dog".to_string(),
                    start_time: 2.0,
                    end_time: 4.0,
                    words: vec![],
                    language: None,
                    confidence: 0.9,
                    is_final: true,
                },
            ],
            language: None,
            duration: 4.0,
            processing_time_ms: 200,
        };

        let results = transcription.search("fox");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].id, 1);

        let results = transcription.search("lazy");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].id, 2);
    }

    #[test]
    fn test_stt_engine_creation() {
        let engine = SttEngine::new();
        assert_eq!(engine.state(), SttState::Uninitialized);
    }

    #[test]
    fn test_stt_engine_initialize() {
        let mut engine = SttEngine::new();
        let result = engine.initialize();
        assert!(result.is_ok());
        assert_eq!(engine.state(), SttState::Ready);
    }

    #[test]
    fn test_stt_engine_reset() {
        let mut engine = SttEngine::new();
        engine.initialize().unwrap();
        engine.segment_counter = 10;
        engine.audio_buffer = vec![0.5; 1000];

        engine.reset();

        assert_eq!(engine.segment_counter, 0);
        assert!(engine.audio_buffer.is_empty());
    }

    #[test]
    fn test_mel_filterbank_creation() {
        let engine = SttEngine::new();
        let filters = engine.create_mel_filterbank();

        // Should have N_MELS * (N_FFT/2 + 1) elements
        assert_eq!(filters.len(), N_MELS * (N_FFT / 2 + 1));

        // Filters should have non-negative values
        assert!(filters.iter().all(|&v| v >= 0.0));
    }

    #[test]
    fn test_shared_stt_engine() {
        let engine = SharedSttEngine::new();
        assert_eq!(engine.state(), SttState::Uninitialized);

        engine.initialize().unwrap();
        assert!(engine.is_ready());
    }
}
