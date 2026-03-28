//! Text-to-Speech (TTS) Module
//!
//! Implements neural TTS using the Kokoro architecture.
//! Provides high-quality speech synthesis entirely offline.

use anyhow::{anyhow, Result};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use crate::phonemizer::{Phoneme, PhonemeSequence, Phonemizer};

/// TTS model variants
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[derive(Default)]
pub enum TtsModel {
    /// Kokoro small (~80MB, fast)
    #[default]
    KokoroSmall,
    /// Kokoro medium (~150MB, better quality)
    KokoroMedium,
}

impl TtsModel {
    /// Get approximate model size in bytes
    pub fn size_bytes(&self) -> u64 {
        match self {
            TtsModel::KokoroSmall => 80_000_000,
            TtsModel::KokoroMedium => 150_000_000,
        }
    }
}


/// Voice style parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoiceStyle {
    /// Unique identifier for this voice
    pub id: String,
    /// Display name
    pub name: String,
    /// Description of the voice
    pub description: String,
    /// Speaking rate multiplier (0.5 to 2.0)
    pub rate: f32,
    /// Pitch shift in semitones (-12 to +12)
    pub pitch: f32,
    /// Voice embedding vector (256-dim for Kokoro)
    pub embedding: Vec<f32>,
}

impl VoiceStyle {
    /// Create a default neutral voice
    pub fn default_neutral() -> Self {
        Self {
            id: "neutral".to_string(),
            name: "Neutral".to_string(),
            description: "A balanced, neutral voice".to_string(),
            rate: 1.0,
            pitch: 0.0,
            embedding: vec![0.0; 256],
        }
    }

    /// Create a female voice style
    pub fn female() -> Self {
        let mut embedding = vec![0.0; 256];
        // Simple differentiating pattern
        for item in embedding.iter_mut().take(128) {
            *item = 0.5;
        }
        Self {
            id: "female".to_string(),
            name: "Female".to_string(),
            description: "A female voice".to_string(),
            rate: 1.0,
            pitch: 2.0,
            embedding,
        }
    }

    /// Create a male voice style
    pub fn male() -> Self {
        let mut embedding = vec![0.0; 256];
        // Simple differentiating pattern
        for item in embedding.iter_mut().skip(128) {
            *item = 0.5;
        }
        Self {
            id: "male".to_string(),
            name: "Male".to_string(),
            description: "A male voice".to_string(),
            rate: 1.0,
            pitch: -2.0,
            embedding,
        }
    }
}

impl Default for VoiceStyle {
    fn default() -> Self {
        Self::default_neutral()
    }
}

/// TTS configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TtsConfig {
    /// Which model to use
    pub model: TtsModel,
    /// Output sample rate
    pub sample_rate: u32,
    /// Voice style to use
    pub voice: VoiceStyle,
    /// Path to model files
    pub model_path: Option<PathBuf>,
    /// Whether to apply post-processing
    pub post_process: bool,
}

impl Default for TtsConfig {
    fn default() -> Self {
        Self {
            model: TtsModel::default(),
            sample_rate: 24000, // Kokoro default
            voice: VoiceStyle::default(),
            model_path: None,
            post_process: true,
        }
    }
}

/// Synthesized audio result
#[derive(Debug, Clone)]
pub struct SynthesizedAudio {
    /// Audio samples (f32, normalized)
    pub samples: Vec<f32>,
    /// Sample rate
    pub sample_rate: u32,
    /// Duration in seconds
    pub duration: f32,
    /// Word boundaries with timestamps
    pub word_boundaries: Vec<WordBoundary>,
}

impl SynthesizedAudio {
    /// Create empty result
    pub fn empty(sample_rate: u32) -> Self {
        Self {
            samples: Vec::new(),
            sample_rate,
            duration: 0.0,
            word_boundaries: Vec::new(),
        }
    }

    /// Create from samples
    pub fn from_samples(samples: Vec<f32>, sample_rate: u32) -> Self {
        let duration = samples.len() as f32 / sample_rate as f32;
        Self {
            samples,
            sample_rate,
            duration,
            word_boundaries: Vec::new(),
        }
    }

    /// Convert to i16 PCM
    pub fn to_i16(&self) -> Vec<i16> {
        self.samples
            .iter()
            .map(|&s| (s.clamp(-1.0, 1.0) * 32767.0) as i16)
            .collect()
    }

    /// Convert to bytes (16-bit LE PCM)
    pub fn to_bytes(&self) -> Vec<u8> {
        self.to_i16().iter().flat_map(|s| s.to_le_bytes()).collect()
    }
}

/// Word boundary information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WordBoundary {
    /// The word text
    pub word: String,
    /// Start time in seconds
    pub start_time: f32,
    /// End time in seconds
    pub end_time: f32,
}

impl WordBoundary {
    /// Get duration
    pub fn duration(&self) -> f32 {
        self.end_time - self.start_time
    }
}

/// TTS engine state
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TtsState {
    /// Not initialized
    Uninitialized,
    /// Loading model
    Loading,
    /// Ready to synthesize
    Ready,
    /// Currently synthesizing
    Synthesizing,
    /// Error state
    Error,
}

/// Text-to-Speech Engine
///
/// Provides neural speech synthesis using Kokoro models.
#[derive(Debug)]
pub struct TtsEngine {
    config: TtsConfig,
    state: TtsState,
    phonemizer: Phonemizer,
    /// Available voice styles
    voices: HashMap<String, VoiceStyle>,
}

impl TtsEngine {
    /// Create a new TTS engine with default configuration
    pub fn new() -> Self {
        Self::with_config(TtsConfig::default())
    }

    /// Create with custom configuration
    pub fn with_config(config: TtsConfig) -> Self {
        let mut voices = HashMap::new();
        voices.insert("neutral".to_string(), VoiceStyle::default_neutral());
        voices.insert("female".to_string(), VoiceStyle::female());
        voices.insert("male".to_string(), VoiceStyle::male());

        Self {
            config,
            state: TtsState::Uninitialized,
            phonemizer: Phonemizer::new(),
            voices,
        }
    }

    /// Initialize the TTS engine
    pub fn initialize(&mut self) -> Result<()> {
        self.state = TtsState::Loading;

        // In full implementation, this would load model weights
        // For now, just mark as ready

        self.state = TtsState::Ready;
        Ok(())
    }

    /// Synthesize speech from text
    ///
    /// # Arguments
    /// * `text` - The text to synthesize
    ///
    /// # Returns
    /// Synthesized audio with samples and metadata
    pub fn synthesize(&mut self, text: &str) -> Result<SynthesizedAudio> {
        if self.state != TtsState::Ready {
            return Err(anyhow!("TTS engine not ready (state: {:?})", self.state));
        }

        self.state = TtsState::Synthesizing;

        // Step 1: Phonemize the text
        let phoneme_sequences = self.phonemizer.phonemize(text)?;

        // Step 2: Convert phonemes to model input
        let phoneme_ids = self.encode_phonemes(&phoneme_sequences);

        // Step 3: Generate mel spectrogram (placeholder - would use actual model)
        let mel_spec = self.generate_mel_spectrogram(&phoneme_ids)?;

        // Step 4: Vocoder to generate audio (placeholder)
        let samples = self.vocode(&mel_spec)?;

        // Step 5: Post-process if enabled
        let final_samples = if self.config.post_process {
            self.post_process(&samples)
        } else {
            samples
        };

        // Step 6: Calculate word boundaries and duration before moving samples
        let word_boundaries =
            self.calculate_word_boundaries(&phoneme_sequences, final_samples.len());
        let duration = final_samples.len() as f32 / self.config.sample_rate as f32;

        self.state = TtsState::Ready;

        Ok(SynthesizedAudio {
            samples: final_samples,
            sample_rate: self.config.sample_rate,
            duration,
            word_boundaries,
        })
    }

    /// Synthesize speech with a specific voice
    pub fn synthesize_with_voice(
        &mut self,
        text: &str,
        voice_id: &str,
    ) -> Result<SynthesizedAudio> {
        if let Some(voice) = self.voices.get(voice_id) {
            let original_voice = self.config.voice.clone();
            self.config.voice = voice.clone();
            let result = self.synthesize(text);
            self.config.voice = original_voice;
            result
        } else {
            Err(anyhow!("Voice not found: {}", voice_id))
        }
    }

    /// Encode phonemes to model input IDs
    fn encode_phonemes(&self, sequences: &[PhonemeSequence]) -> Vec<i64> {
        let mut ids = Vec::new();

        for seq in sequences {
            for phoneme in &seq.phonemes {
                // Map phonemes to IDs (simplified)
                let id = match phoneme {
                    Phoneme::SIL => 0,
                    Phoneme::SP => 1,
                    Phoneme::SPACE => 2,
                    Phoneme::AA => 3,
                    Phoneme::AE => 4,
                    Phoneme::AH => 5,
                    Phoneme::AO => 6,
                    Phoneme::AW => 7,
                    Phoneme::AY => 8,
                    Phoneme::B => 9,
                    Phoneme::CH => 10,
                    Phoneme::D => 11,
                    Phoneme::DH => 12,
                    Phoneme::EH => 13,
                    Phoneme::ER => 14,
                    Phoneme::EY => 15,
                    Phoneme::F => 16,
                    Phoneme::G => 17,
                    Phoneme::HH => 18,
                    Phoneme::IH => 19,
                    Phoneme::IY => 20,
                    Phoneme::JH => 21,
                    Phoneme::K => 22,
                    Phoneme::L => 23,
                    Phoneme::M => 24,
                    Phoneme::N => 25,
                    Phoneme::NG => 26,
                    Phoneme::OW => 27,
                    Phoneme::OY => 28,
                    Phoneme::P => 29,
                    Phoneme::R => 30,
                    Phoneme::S => 31,
                    Phoneme::SH => 32,
                    Phoneme::T => 33,
                    Phoneme::TH => 34,
                    Phoneme::UH => 35,
                    Phoneme::UW => 36,
                    Phoneme::V => 37,
                    Phoneme::W => 38,
                    Phoneme::Y => 39,
                    Phoneme::Z => 40,
                    Phoneme::ZH => 41,
                };
                ids.push(id);
            }
        }

        ids
    }

    /// Generate mel spectrogram from phoneme IDs (placeholder)
    fn generate_mel_spectrogram(&self, phoneme_ids: &[i64]) -> Result<Vec<f32>> {
        // In full implementation, this would:
        // 1. Create phoneme embedding tensor
        // 2. Add voice style embedding
        // 3. Run through encoder-decoder
        // 4. Output mel spectrogram

        // Placeholder: generate dummy mel frames
        let n_mels = 80;
        let frames_per_phoneme = 10; // ~100ms per phoneme at 100 frames/sec
        let n_frames = phoneme_ids.len() * frames_per_phoneme;

        let mel_spec = vec![0.0_f32; n_frames * n_mels];
        Ok(mel_spec)
    }

    /// Convert mel spectrogram to audio samples (vocoder)
    fn vocode(&self, mel_spec: &[f32]) -> Result<Vec<f32>> {
        // In full implementation, this would run HiFi-GAN or similar vocoder
        // to convert mel spectrogram to waveform

        // Placeholder: generate silence of appropriate length
        let n_mels = 80;
        let n_frames = mel_spec.len() / n_mels;
        let hop_length = 256; // Typical vocoder hop length
        let n_samples = n_frames * hop_length;

        let samples = vec![0.0_f32; n_samples];
        Ok(samples)
    }

    /// Post-process audio (denoising, normalization)
    fn post_process(&self, samples: &[f32]) -> Vec<f32> {
        let mut output = samples.to_vec();

        // Apply rate adjustment
        if (self.config.voice.rate - 1.0).abs() > 0.01 {
            output = self.adjust_rate(&output, self.config.voice.rate);
        }

        // Normalize
        let max_val = output.iter().map(|s| s.abs()).fold(0.0_f32, f32::max);
        if max_val > 0.01 {
            let scale = 0.95 / max_val;
            for sample in &mut output {
                *sample *= scale;
            }
        }

        output
    }

    /// Adjust playback rate (simple resampling)
    fn adjust_rate(&self, samples: &[f32], rate: f32) -> Vec<f32> {
        if (rate - 1.0).abs() < 0.01 {
            return samples.to_vec();
        }

        let new_len = (samples.len() as f32 / rate) as usize;
        let mut output = Vec::with_capacity(new_len);

        for i in 0..new_len {
            let src_pos = i as f32 * rate;
            let src_idx = src_pos as usize;
            let frac = src_pos - src_idx as f32;

            let sample = if src_idx + 1 < samples.len() {
                samples[src_idx] * (1.0 - frac) + samples[src_idx + 1] * frac
            } else if src_idx < samples.len() {
                samples[src_idx]
            } else {
                0.0
            };

            output.push(sample);
        }

        output
    }

    /// Calculate word boundaries from phoneme sequences
    fn calculate_word_boundaries(
        &self,
        sequences: &[PhonemeSequence],
        total_samples: usize,
    ) -> Vec<WordBoundary> {
        let mut boundaries = Vec::new();
        let duration = total_samples as f32 / self.config.sample_rate as f32;

        // Simple estimation: divide time equally among words
        let words: Vec<&PhonemeSequence> = sequences
            .iter()
            .filter(|s| {
                !s.phonemes.is_empty()
                    && !matches!(s.phonemes[0], Phoneme::SIL | Phoneme::SP | Phoneme::SPACE)
            })
            .collect();

        if words.is_empty() {
            return boundaries;
        }

        let time_per_word = duration / words.len() as f32;
        let mut current_time = 0.0_f32;

        for word_seq in words {
            boundaries.push(WordBoundary {
                word: word_seq.text.clone(),
                start_time: current_time,
                end_time: current_time + time_per_word,
            });
            current_time += time_per_word;
        }

        boundaries
    }

    /// Get available voices
    pub fn available_voices(&self) -> Vec<&VoiceStyle> {
        self.voices.values().collect()
    }

    /// Add a custom voice
    pub fn add_voice(&mut self, voice: VoiceStyle) {
        self.voices.insert(voice.id.clone(), voice);
    }

    /// Get current state
    pub fn state(&self) -> TtsState {
        self.state
    }

    /// Check if ready
    pub fn is_ready(&self) -> bool {
        self.state == TtsState::Ready
    }

    /// Get configuration
    pub fn config(&self) -> &TtsConfig {
        &self.config
    }

    /// Reset the engine
    pub fn reset(&mut self) {
        self.state = TtsState::Uninitialized;
    }
}

impl Default for TtsEngine {
    fn default() -> Self {
        Self::new()
    }
}

/// Thread-safe TTS engine wrapper
#[derive(Debug, Clone)]
pub struct SharedTtsEngine {
    inner: Arc<RwLock<TtsEngine>>,
}

impl SharedTtsEngine {
    /// Create a new shared TTS engine
    pub fn new() -> Self {
        Self {
            inner: Arc::new(RwLock::new(TtsEngine::new())),
        }
    }

    /// Create with custom config
    pub fn with_config(config: TtsConfig) -> Self {
        Self {
            inner: Arc::new(RwLock::new(TtsEngine::with_config(config))),
        }
    }

    /// Initialize (thread-safe)
    pub fn initialize(&self) -> Result<()> {
        self.inner.write().initialize()
    }

    /// Synthesize (thread-safe)
    pub fn synthesize(&self, text: &str) -> Result<SynthesizedAudio> {
        self.inner.write().synthesize(text)
    }

    /// Synthesize with voice (thread-safe)
    pub fn synthesize_with_voice(&self, text: &str, voice_id: &str) -> Result<SynthesizedAudio> {
        self.inner.write().synthesize_with_voice(text, voice_id)
    }

    /// Get state (thread-safe)
    pub fn state(&self) -> TtsState {
        self.inner.read().state()
    }

    /// Check if ready (thread-safe)
    pub fn is_ready(&self) -> bool {
        self.inner.read().is_ready()
    }

    /// Get available voices (thread-safe)
    pub fn available_voices(&self) -> Vec<VoiceStyle> {
        self.inner.read().voices.values().cloned().collect()
    }

    /// Add voice (thread-safe)
    pub fn add_voice(&self, voice: VoiceStyle) {
        self.inner.write().add_voice(voice)
    }
}

impl Default for SharedTtsEngine {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tts_model_sizes() {
        assert!(TtsModel::KokoroSmall.size_bytes() < TtsModel::KokoroMedium.size_bytes());
    }

    #[test]
    fn test_voice_style_default() {
        let voice = VoiceStyle::default();
        assert_eq!(voice.rate, 1.0);
        assert_eq!(voice.pitch, 0.0);
        assert_eq!(voice.embedding.len(), 256);
    }

    #[test]
    fn test_voice_styles() {
        let female = VoiceStyle::female();
        let male = VoiceStyle::male();

        assert_eq!(female.id, "female");
        assert_eq!(male.id, "male");
        assert!(female.pitch > male.pitch);
    }

    #[test]
    fn test_tts_config_default() {
        let config = TtsConfig::default();
        assert_eq!(config.sample_rate, 24000);
        assert!(config.post_process);
    }

    #[test]
    fn test_synthesized_audio_empty() {
        let audio = SynthesizedAudio::empty(24000);
        assert!(audio.samples.is_empty());
        assert_eq!(audio.duration, 0.0);
    }

    #[test]
    fn test_synthesized_audio_from_samples() {
        let samples = vec![0.5_f32; 24000]; // 1 second
        let audio = SynthesizedAudio::from_samples(samples, 24000);
        assert!((audio.duration - 1.0).abs() < 0.01);
    }

    #[test]
    fn test_synthesized_audio_to_i16() {
        let samples = vec![0.5_f32, -0.5, 1.0, -1.0];
        let audio = SynthesizedAudio::from_samples(samples, 24000);
        let i16_samples = audio.to_i16();

        assert_eq!(i16_samples.len(), 4);
        assert!(i16_samples[0] > 0);
        assert!(i16_samples[1] < 0);
        assert_eq!(i16_samples[2], 32767);
        assert_eq!(i16_samples[3], -32767);
    }

    #[test]
    fn test_word_boundary() {
        let boundary = WordBoundary {
            word: "hello".to_string(),
            start_time: 0.0,
            end_time: 0.5,
        };
        assert!((boundary.duration() - 0.5).abs() < 0.001);
    }

    #[test]
    fn test_tts_engine_creation() {
        let engine = TtsEngine::new();
        assert_eq!(engine.state(), TtsState::Uninitialized);
    }

    #[test]
    fn test_tts_engine_initialize() {
        let mut engine = TtsEngine::new();
        let result = engine.initialize();
        assert!(result.is_ok());
        assert_eq!(engine.state(), TtsState::Ready);
    }

    #[test]
    fn test_tts_engine_available_voices() {
        let engine = TtsEngine::new();
        let voices = engine.available_voices();
        assert!(!voices.is_empty());
        assert!(voices.iter().any(|v| v.id == "neutral"));
    }

    #[test]
    fn test_tts_engine_add_voice() {
        let mut engine = TtsEngine::new();
        let custom = VoiceStyle {
            id: "custom".to_string(),
            name: "Custom".to_string(),
            description: "A custom voice".to_string(),
            rate: 1.2,
            pitch: 1.0,
            embedding: vec![0.1; 256],
        };
        engine.add_voice(custom);

        let voices = engine.available_voices();
        assert!(voices.iter().any(|v| v.id == "custom"));
    }

    #[test]
    fn test_tts_engine_synthesize() {
        let mut engine = TtsEngine::new();
        engine.initialize().unwrap();

        let result = engine.synthesize("hello world");
        assert!(result.is_ok());

        let audio = result.unwrap();
        assert!(audio.sample_rate > 0);
    }

    #[test]
    fn test_rate_adjustment() {
        let engine = TtsEngine::new();
        let samples: Vec<f32> = (0..1000).map(|i| (i as f32 / 100.0).sin()).collect();

        // Slow down by 2x
        let slow = engine.adjust_rate(&samples, 0.5);
        assert!(slow.len() > samples.len());

        // Speed up by 2x
        let fast = engine.adjust_rate(&samples, 2.0);
        assert!(fast.len() < samples.len());
    }

    #[test]
    fn test_shared_tts_engine() {
        let engine = SharedTtsEngine::new();
        assert_eq!(engine.state(), TtsState::Uninitialized);

        engine.initialize().unwrap();
        assert!(engine.is_ready());
    }

    #[test]
    fn test_phoneme_encoding() {
        let engine = TtsEngine::new();
        let seq = PhonemeSequence::new(
            "test".to_string(),
            vec![Phoneme::T, Phoneme::EH, Phoneme::S, Phoneme::T],
        );

        let ids = engine.encode_phonemes(&[seq]);
        assert_eq!(ids.len(), 4);
    }
}
