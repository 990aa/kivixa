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
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
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
    fn build_voice(
        id: &str,
        name: &str,
        description: &str,
        rate: f32,
        pitch: f32,
        brightness: f32,
        warmth: f32,
        breathiness: f32,
    ) -> Self {
        let mut embedding = vec![0.0; 256];

        for item in embedding.iter_mut().take(64) {
            *item = brightness;
        }
        for item in embedding.iter_mut().skip(64).take(64) {
            *item = warmth;
        }
        for item in embedding.iter_mut().skip(128).take(64) {
            *item = breathiness;
        }
        for (index, item) in embedding.iter_mut().skip(192).enumerate() {
            *item = ((index as f32 / 64.0) * std::f32::consts::PI).sin() * 0.1;
        }

        Self {
            id: id.to_string(),
            name: name.to_string(),
            description: description.to_string(),
            rate,
            pitch,
            embedding,
        }
    }

    /// Create a default neutral voice
    pub fn default_neutral() -> Self {
        Self::build_voice(
            "neutral",
            "Neutral",
            "Balanced neutral narration voice.",
            1.0,
            0.0,
            0.5,
            0.5,
            0.25,
        )
    }

    /// Create a female voice style
    pub fn female() -> Self {
        Self::build_voice(
            "female",
            "Female",
            "Female presentation voice.",
            1.0,
            2.0,
            0.74,
            0.44,
            0.34,
        )
    }

    /// Create a male voice style
    pub fn male() -> Self {
        Self::build_voice(
            "male",
            "Male",
            "Male presentation voice.",
            0.98,
            -2.0,
            0.42,
            0.72,
            0.2,
        )
    }

    pub fn heart() -> Self {
        Self::build_voice(
            "af_heart",
            "Heart",
            "Warm and expressive American female voice.",
            1.0,
            2.5,
            0.76,
            0.58,
            0.28,
        )
    }

    pub fn sky() -> Self {
        Self::build_voice(
            "af_sky",
            "Sky",
            "Clear and professional American female voice.",
            1.02,
            2.2,
            0.82,
            0.38,
            0.22,
        )
    }

    pub fn adam() -> Self {
        Self::build_voice(
            "am_adam",
            "Adam",
            "Calm and authoritative American male voice.",
            0.96,
            -2.8,
            0.44,
            0.74,
            0.18,
        )
    }

    pub fn michael() -> Self {
        Self::build_voice(
            "am_michael",
            "Michael",
            "Energetic and engaging American male voice.",
            1.05,
            -1.8,
            0.52,
            0.64,
            0.16,
        )
    }

    pub fn emma() -> Self {
        Self::build_voice(
            "bf_emma",
            "Emma",
            "Sophisticated British female voice.",
            0.99,
            2.0,
            0.71,
            0.54,
            0.2,
        )
    }

    pub fn george() -> Self {
        Self::build_voice(
            "bm_george",
            "George",
            "Elegant British male voice.",
            0.97,
            -2.2,
            0.46,
            0.71,
            0.16,
        )
    }

    pub fn catalog() -> Vec<Self> {
        vec![
            Self::heart(),
            Self::sky(),
            Self::adam(),
            Self::michael(),
            Self::emma(),
            Self::george(),
            Self::female(),
            Self::male(),
            Self::default_neutral(),
        ]
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
        for voice in VoiceStyle::catalog() {
            voices.insert(voice.id.clone(), voice);
        }

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

        // Step 2: Generate waveform with voice-aware prosody and punctuation pauses.
        let samples = self.synthesize_waveform(&phoneme_sequences);

        // Step 3: Post-process for smoother playback.
        let final_samples = if self.config.post_process {
            self.post_process(&samples)
        } else {
            samples
        };

        // Step 4: Calculate word boundaries and duration before moving samples.
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

    fn synthesize_waveform(&self, sequences: &[PhonemeSequence]) -> Vec<f32> {
        if sequences.is_empty() {
            return Vec::new();
        }

        let sample_rate = self.config.sample_rate as f32;
        let utterance_ends_with_question = sequences.iter().rev().any(|s| s.text == "?");
        let utterance_ends_with_exclamation = sequences.iter().rev().any(|s| s.text == "!");

        let estimated_seconds: f32 = sequences
            .iter()
            .flat_map(|seq| {
                seq.phonemes
                    .iter()
                    .map(move |phoneme| self.phoneme_duration_seconds(&seq.text, *phoneme))
            })
            .sum();
        let estimated_total_samples =
            (estimated_seconds * sample_rate).max(sample_rate * 0.25) as usize;

        let mut output = Vec::with_capacity(estimated_total_samples);
        let mut global_index: usize = 0;

        for (seq_index, sequence) in sequences.iter().enumerate() {
            for (phoneme_index, phoneme) in sequence.phonemes.iter().enumerate() {
                let duration_seconds = self.phoneme_duration_seconds(&sequence.text, *phoneme);
                let sample_count = (duration_seconds * sample_rate).max(1.0).round() as usize;

                if matches!(phoneme, Phoneme::SIL | Phoneme::SP | Phoneme::SPACE) {
                    output.extend((0..sample_count).map(|_| 0.0_f32));
                    global_index += sample_count;
                    continue;
                }

                let voiced = phoneme.is_vowel() || Self::is_voiced_consonant(*phoneme);
                let mut local_phase = 0.0_f32;

                for i in 0..sample_count {
                    let utterance_progress =
                        (global_index + i) as f32 / estimated_total_samples as f32;
                    let relative_progress = i as f32 / sample_count as f32;

                    let envelope = if relative_progress < 0.08 {
                        relative_progress / 0.08
                    } else if relative_progress > 0.88 {
                        (1.0 - relative_progress) / 0.12
                    } else {
                        1.0
                    }
                    .clamp(0.0, 1.0);

                    let mut frequency = self.voice_base_frequency();
                    if utterance_ends_with_question && utterance_progress > 0.65 {
                        let rise = (utterance_progress - 0.65) / 0.35;
                        frequency *= 1.0 + 0.25 * rise;
                    } else if utterance_ends_with_exclamation && utterance_progress > 0.75 {
                        let lift = (utterance_progress - 0.75) / 0.25;
                        frequency *= 1.0 + 0.12 * lift;
                    }

                    let vibrato =
                        1.0 + 0.012 * (2.0 * std::f32::consts::PI * 5.2 * relative_progress).sin();
                    let step = 2.0 * std::f32::consts::PI * frequency * vibrato / sample_rate;
                    local_phase += step;

                    let seed = ((global_index + i) as u64)
                        .wrapping_mul(6364136223846793005)
                        .wrapping_add((seq_index as u64) * 8191)
                        .wrapping_add((phoneme_index as u64) * 131);
                    let noise = Self::pseudo_noise(seed);

                    let tonal = if voiced {
                        let (h2, h3) = Self::phoneme_harmonics(*phoneme);
                        let fundamental = local_phase.sin();
                        let second = (2.0 * local_phase + 0.15).sin() * h2;
                        let third = (3.0 * local_phase + 0.23).sin() * h3;
                        (fundamental * 0.7 + second + third) * 0.26
                    } else {
                        0.0
                    };

                    let unvoiced = if voiced {
                        0.0
                    } else {
                        noise * Self::unvoiced_gain(*phoneme)
                    };

                    let breath = noise * self.voice_breathiness() * 0.06 * (1.0 - envelope);
                    let sample = (tonal + unvoiced + breath) * envelope;
                    output.push(sample);
                }

                global_index += sample_count;
            }
        }

        Self::smooth_samples(&mut output);
        output
    }

    fn phoneme_duration_seconds(&self, token: &str, phoneme: Phoneme) -> f32 {
        let base = match phoneme {
            Phoneme::SIL => match token {
                "?" => 0.32,
                "!" => 0.28,
                "." => 0.24,
                _ => 0.20,
            },
            Phoneme::SP => 0.12,
            Phoneme::SPACE => 0.03,
            _ if phoneme.is_vowel() => 0.105,
            Phoneme::M | Phoneme::N | Phoneme::NG | Phoneme::L | Phoneme::R => 0.09,
            Phoneme::S | Phoneme::SH | Phoneme::F | Phoneme::TH | Phoneme::CH => 0.075,
            _ => 0.065,
        };

        (base / self.config.voice.rate.clamp(0.5, 2.0)).max(0.02)
    }

    fn voice_base_frequency(&self) -> f32 {
        let mut base = if self.config.voice.id.starts_with("af_") {
            210.0
        } else if self.config.voice.id.starts_with("am_") {
            128.0
        } else if self.config.voice.id.starts_with("bf_") {
            198.0
        } else if self.config.voice.id.starts_with("bm_") {
            122.0
        } else {
            170.0
        };

        let pitch_ratio = (2.0_f32).powf(self.config.voice.pitch / 12.0);
        base *= pitch_ratio;
        base.clamp(85.0, 320.0)
    }

    fn voice_breathiness(&self) -> f32 {
        self.config
            .voice
            .embedding
            .get(128)
            .copied()
            .unwrap_or(0.2)
            .clamp(0.0, 1.0)
    }

    fn is_voiced_consonant(phoneme: Phoneme) -> bool {
        matches!(
            phoneme,
            Phoneme::B
                | Phoneme::D
                | Phoneme::DH
                | Phoneme::G
                | Phoneme::JH
                | Phoneme::L
                | Phoneme::M
                | Phoneme::N
                | Phoneme::NG
                | Phoneme::R
                | Phoneme::V
                | Phoneme::W
                | Phoneme::Y
                | Phoneme::Z
                | Phoneme::ZH
        )
    }

    fn phoneme_harmonics(phoneme: Phoneme) -> (f32, f32) {
        match phoneme {
            Phoneme::IY | Phoneme::IH | Phoneme::EH | Phoneme::EY => (0.44, 0.28),
            Phoneme::UW | Phoneme::UH | Phoneme::OW | Phoneme::AO => (0.26, 0.14),
            Phoneme::AA | Phoneme::AH | Phoneme::AE | Phoneme::AW | Phoneme::AY => (0.34, 0.2),
            _ => (0.22, 0.12),
        }
    }

    fn unvoiced_gain(phoneme: Phoneme) -> f32 {
        match phoneme {
            Phoneme::S | Phoneme::SH | Phoneme::F | Phoneme::TH => 0.22,
            Phoneme::CH | Phoneme::T | Phoneme::K | Phoneme::P => 0.18,
            _ => 0.12,
        }
    }

    fn smooth_samples(samples: &mut [f32]) {
        if samples.len() < 3 {
            return;
        }

        let mut previous = samples[0];
        for sample in samples.iter_mut().skip(1) {
            let current = *sample;
            *sample = previous * 0.22 + current * 0.78;
            previous = *sample;
        }
    }

    fn pseudo_noise(seed: u64) -> f32 {
        let mut value = seed;
        value ^= value >> 13;
        value = value.wrapping_mul(0xff51afd7ed558ccd);
        value ^= value >> 33;
        value = value.wrapping_mul(0xc4ceb9fe1a85ec53);
        value ^= value >> 33;

        let normalized = (value as f64 / u64::MAX as f64) as f32;
        normalized * 2.0 - 1.0
    }

    fn voice_sort_rank(id: &str) -> usize {
        match id {
            "af_heart" => 0,
            "af_sky" => 1,
            "am_adam" => 2,
            "am_michael" => 3,
            "bf_emma" => 4,
            "bm_george" => 5,
            "female" => 6,
            "male" => 7,
            "neutral" => 8,
            _ => 100,
        }
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
        let mut voices: Vec<&VoiceStyle> = self.voices.values().collect();
        voices.sort_by_key(|voice| Self::voice_sort_rank(&voice.id));
        voices
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
        self.inner
            .read()
            .available_voices()
            .into_iter()
            .cloned()
            .collect()
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
        assert!(voices.iter().any(|v| v.id == "af_heart"));
        assert!(voices.iter().any(|v| v.id == "af_sky"));
        assert!(voices.iter().any(|v| v.id == "am_adam"));
        assert!(voices.iter().any(|v| v.id == "am_michael"));
        assert!(voices.iter().any(|v| v.id == "bf_emma"));
        assert!(voices.iter().any(|v| v.id == "bm_george"));
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
        assert!(audio.duration > 0.05);
        let peak = audio
            .samples
            .iter()
            .map(|s| s.abs())
            .fold(0.0_f32, f32::max);
        assert!(peak > 0.01, "synthesized waveform should be audible");
    }

    #[test]
    fn test_tts_punctuation_changes_duration() {
        let mut engine = TtsEngine::new();
        engine.initialize().unwrap();

        let plain = engine.synthesize("hello world").unwrap();
        let punctuated = engine.synthesize("hello world!").unwrap();

        assert!(
            punctuated.duration > plain.duration,
            "punctuation should add expressive pause duration"
        );
    }

    #[test]
    fn test_tts_voice_profiles_generate_distinct_waveforms() {
        let mut engine = TtsEngine::new();
        engine.initialize().unwrap();

        let heart = engine
            .synthesize_with_voice("kivixa voice test", "af_heart")
            .unwrap();
        let adam = engine
            .synthesize_with_voice("kivixa voice test", "am_adam")
            .unwrap();

        let compare_len = heart.samples.len().min(adam.samples.len()).min(4096);
        assert!(compare_len > 0);

        let difference: f32 = heart
            .samples
            .iter()
            .zip(adam.samples.iter())
            .take(compare_len)
            .map(|(a, b)| (a - b).abs())
            .sum::<f32>()
            / compare_len as f32;

        assert!(
            difference > 0.005,
            "different voice styles should produce distinct waveforms"
        );
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
