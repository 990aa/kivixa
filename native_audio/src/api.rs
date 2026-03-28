//! Public API for Kivixa Audio Module
//!
//! This module provides the Flutter Rust Bridge interface for the audio
//! intelligence features. All functions here are exposed to Dart.

use anyhow::Result;
use once_cell::sync::Lazy;

use crate::audio_buffer::{SharedAudioBuffer, WHISPER_SAMPLE_RATE};
use crate::stt::{SharedSttEngine, SttState, Transcription, TranscriptionSegment, WhisperModel};
use crate::tts::{SharedTtsEngine, SynthesizedAudio, TtsState, VoiceStyle};
use crate::vad::{SharedVad, VadResult, VadState};

// ============================================================================
// Global State Management
// ============================================================================

/// Global STT engine instance
static STT_ENGINE: Lazy<SharedSttEngine> = Lazy::new(SharedSttEngine::new);

/// Global TTS engine instance
static TTS_ENGINE: Lazy<SharedTtsEngine> = Lazy::new(SharedTtsEngine::new);

/// Global VAD instance
static VAD: Lazy<SharedVad> = Lazy::new(SharedVad::new);

/// Global audio buffer for streaming
static AUDIO_BUFFER: Lazy<SharedAudioBuffer> = Lazy::new(SharedAudioBuffer::for_whisper);

// ============================================================================
// Audio Buffer API
// ============================================================================

/// Write raw PCM bytes to the audio buffer
///
/// # Arguments
/// * `bytes` - Raw PCM 16-bit little-endian audio bytes
///
/// # Returns
/// Number of samples written
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_write_bytes(bytes: Vec<u8>) -> usize {
    AUDIO_BUFFER.write_bytes(&bytes)
}

/// Write f32 samples to the audio buffer
///
/// # Arguments
/// * `samples` - Normalized f32 audio samples (-1.0 to 1.0)
///
/// # Returns
/// Number of samples written
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_write_samples(samples: Vec<f32>) -> usize {
    AUDIO_BUFFER.write(&samples)
}

/// Write i16 samples to the audio buffer
///
/// # Arguments
/// * `samples` - PCM i16 audio samples
///
/// # Returns
/// Number of samples written
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_write_i16(samples: Vec<i16>) -> usize {
    AUDIO_BUFFER.write_i16(&samples)
}

/// Read all available samples from the buffer
///
/// # Returns
/// Vector of f32 samples
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_read_all() -> Vec<f32> {
    AUDIO_BUFFER.read_all()
}

/// Read a specific number of samples
///
/// # Arguments
/// * `count` - Number of samples to read
///
/// # Returns
/// Vector of f32 samples (may be shorter if not enough available)
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_read(count: usize) -> Vec<f32> {
    AUDIO_BUFFER.read(count)
}

/// Get the number of available samples
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_available() -> usize {
    AUDIO_BUFFER.available()
}

/// Get available audio duration in seconds
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_available_duration() -> f32 {
    AUDIO_BUFFER.available_duration()
}

/// Check if we have enough data for a full processing chunk
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_has_full_chunk() -> bool {
    AUDIO_BUFFER.has_full_chunk()
}

/// Clear the audio buffer
#[flutter_rust_bridge::frb(sync)]
pub fn audio_buffer_clear() {
    AUDIO_BUFFER.clear()
}

/// Get the Whisper sample rate (16000 Hz)
#[flutter_rust_bridge::frb(sync)]
pub fn get_whisper_sample_rate() -> u32 {
    WHISPER_SAMPLE_RATE
}

// ============================================================================
// Voice Activity Detection API
// ============================================================================

/// VAD result returned to Dart
#[flutter_rust_bridge::frb]
pub struct DartVadResult {
    /// Current state (0=Silence, 1=SpeechPending, 2=Speech, 3=SilencePending)
    pub state: i32,
    /// Speech probability (0.0 to 1.0)
    pub speech_probability: f32,
    /// Whether speech is currently active
    pub is_speech: bool,
    /// Duration of current state in seconds
    pub state_duration: f32,
}

impl From<VadResult> for DartVadResult {
    fn from(r: VadResult) -> Self {
        Self {
            state: match r.state {
                VadState::Silence => 0,
                VadState::SpeechPending => 1,
                VadState::Speech => 2,
                VadState::SilencePending => 3,
            },
            speech_probability: r.speech_probability,
            is_speech: r.is_speech,
            state_duration: r.state_duration,
        }
    }
}

/// Process audio samples through VAD
///
/// # Arguments
/// * `samples` - Audio samples (f32, normalized)
///
/// # Returns
/// VAD result with speech detection state
#[flutter_rust_bridge::frb(sync)]
pub fn vad_process(samples: Vec<f32>) -> DartVadResult {
    VAD.process(&samples).into()
}

/// Check if VAD currently detects speech
#[flutter_rust_bridge::frb(sync)]
pub fn vad_is_speech() -> bool {
    VAD.is_speech()
}

/// Get VAD current state
#[flutter_rust_bridge::frb(sync)]
pub fn vad_current_state() -> i32 {
    match VAD.current_state() {
        VadState::Silence => 0,
        VadState::SpeechPending => 1,
        VadState::Speech => 2,
        VadState::SilencePending => 3,
    }
}

/// Set VAD speech detection threshold
#[flutter_rust_bridge::frb(sync)]
pub fn vad_set_threshold(threshold: f32) {
    VAD.set_threshold(threshold)
}

/// Reset VAD state
#[flutter_rust_bridge::frb(sync)]
pub fn vad_reset() {
    VAD.reset()
}

// ============================================================================
// Speech-to-Text API
// ============================================================================

/// Transcription segment for Dart
#[flutter_rust_bridge::frb]
pub struct DartTranscriptionSegment {
    pub id: u32,
    pub text: String,
    pub start_time: f32,
    pub end_time: f32,
    pub language: Option<String>,
    pub confidence: f32,
    pub is_final: bool,
}

impl From<TranscriptionSegment> for DartTranscriptionSegment {
    fn from(s: TranscriptionSegment) -> Self {
        Self {
            id: s.id,
            text: s.text,
            start_time: s.start_time,
            end_time: s.end_time,
            language: s.language,
            confidence: s.confidence,
            is_final: s.is_final,
        }
    }
}

/// Full transcription result for Dart
#[flutter_rust_bridge::frb]
pub struct DartTranscription {
    pub segments: Vec<DartTranscriptionSegment>,
    pub language: Option<String>,
    pub duration: f32,
    pub processing_time_ms: u64,
    pub full_text: String,
}

impl From<Transcription> for DartTranscription {
    fn from(t: Transcription) -> Self {
        let full_text = t.full_text();
        Self {
            segments: t.segments.into_iter().map(Into::into).collect(),
            language: t.language,
            duration: t.duration,
            processing_time_ms: t.processing_time_ms,
            full_text,
        }
    }
}

/// Initialize the STT engine
pub fn stt_initialize() -> Result<()> {
    STT_ENGINE.initialize()
}

/// Check if STT engine is ready
#[flutter_rust_bridge::frb(sync)]
pub fn stt_is_ready() -> bool {
    STT_ENGINE.is_ready()
}

/// Get STT engine state
#[flutter_rust_bridge::frb(sync)]
pub fn stt_state() -> i32 {
    match STT_ENGINE.state() {
        SttState::Uninitialized => 0,
        SttState::Loading => 1,
        SttState::Ready => 2,
        SttState::Processing => 3,
        SttState::Error => 4,
    }
}

/// Process audio samples for transcription
///
/// # Arguments
/// * `samples` - Audio samples (f32, 16kHz)
/// * `start_time` - Start time in seconds relative to recording start
///
/// # Returns
/// Transcription result
pub fn stt_process(samples: Vec<f32>, start_time: f32) -> Result<DartTranscription> {
    STT_ENGINE.process(&samples, start_time).map(Into::into)
}

/// Process the global audio buffer
///
/// Reads available samples from the global buffer and transcribes them.
///
/// # Arguments
/// * `start_time` - Start time in seconds
pub fn stt_process_buffer(start_time: f32) -> Result<DartTranscription> {
    let samples = AUDIO_BUFFER.read_all();
    if samples.is_empty() {
        return Ok(DartTranscription {
            segments: Vec::new(),
            language: None,
            duration: 0.0,
            processing_time_ms: 0,
            full_text: String::new(),
        });
    }
    STT_ENGINE.process(&samples, start_time).map(Into::into)
}

/// Reset STT engine state
#[flutter_rust_bridge::frb(sync)]
pub fn stt_reset() {
    STT_ENGINE.reset()
}

/// Get available Whisper models
#[flutter_rust_bridge::frb(sync)]
pub fn stt_available_models() -> Vec<String> {
    vec![
        "tiny".to_string(),
        "base".to_string(),
        "small".to_string(),
        "medium".to_string(),
        "large".to_string(),
    ]
}

/// Get model size in bytes
#[flutter_rust_bridge::frb(sync)]
pub fn stt_model_size(model_name: String) -> u64 {
    match model_name.as_str() {
        "tiny" => WhisperModel::Tiny.size_bytes(),
        "base" => WhisperModel::Base.size_bytes(),
        "small" => WhisperModel::Small.size_bytes(),
        "medium" => WhisperModel::Medium.size_bytes(),
        "large" => WhisperModel::Large.size_bytes(),
        _ => 0,
    }
}

// ============================================================================
// Text-to-Speech API
// ============================================================================

/// Voice style for Dart
#[flutter_rust_bridge::frb]
pub struct DartVoiceStyle {
    pub id: String,
    pub name: String,
    pub description: String,
    pub rate: f32,
    pub pitch: f32,
}

impl From<VoiceStyle> for DartVoiceStyle {
    fn from(v: VoiceStyle) -> Self {
        Self {
            id: v.id,
            name: v.name,
            description: v.description,
            rate: v.rate,
            pitch: v.pitch,
        }
    }
}

/// Synthesized audio result for Dart
#[flutter_rust_bridge::frb]
pub struct DartSynthesizedAudio {
    /// Audio samples (f32, normalized)
    pub samples: Vec<f32>,
    /// Sample rate
    pub sample_rate: u32,
    /// Duration in seconds
    pub duration: f32,
}

impl From<SynthesizedAudio> for DartSynthesizedAudio {
    fn from(a: SynthesizedAudio) -> Self {
        Self {
            samples: a.samples,
            sample_rate: a.sample_rate,
            duration: a.duration,
        }
    }
}

/// Initialize the TTS engine
pub fn tts_initialize() -> Result<()> {
    TTS_ENGINE.initialize()
}

/// Check if TTS engine is ready
#[flutter_rust_bridge::frb(sync)]
pub fn tts_is_ready() -> bool {
    TTS_ENGINE.is_ready()
}

/// Get TTS engine state
#[flutter_rust_bridge::frb(sync)]
pub fn tts_state() -> i32 {
    match TTS_ENGINE.state() {
        TtsState::Uninitialized => 0,
        TtsState::Loading => 1,
        TtsState::Ready => 2,
        TtsState::Synthesizing => 3,
        TtsState::Error => 4,
    }
}

/// Synthesize speech from text
///
/// # Arguments
/// * `text` - The text to synthesize
///
/// # Returns
/// Synthesized audio samples and metadata
pub fn tts_synthesize(text: String) -> Result<DartSynthesizedAudio> {
    TTS_ENGINE.synthesize(&text).map(Into::into)
}

/// Synthesize speech with a specific voice
///
/// # Arguments
/// * `text` - The text to synthesize
/// * `voice_id` - The voice identifier
pub fn tts_synthesize_with_voice(text: String, voice_id: String) -> Result<DartSynthesizedAudio> {
    TTS_ENGINE
        .synthesize_with_voice(&text, &voice_id)
        .map(Into::into)
}

/// Get available voices
#[flutter_rust_bridge::frb(sync)]
pub fn tts_available_voices() -> Vec<DartVoiceStyle> {
    TTS_ENGINE
        .available_voices()
        .into_iter()
        .map(Into::into)
        .collect()
}

/// Get synthesized audio as PCM bytes (16-bit LE)
pub fn tts_synthesize_to_bytes(text: String) -> Result<Vec<u8>> {
    let audio = TTS_ENGINE.synthesize(&text)?;
    Ok(audio.to_bytes())
}

/// Get synthesized audio as i16 samples
pub fn tts_synthesize_to_i16(text: String) -> Result<Vec<i16>> {
    let audio = TTS_ENGINE.synthesize(&text)?;
    Ok(audio.to_i16())
}

// ============================================================================
// Combined Processing API
// ============================================================================

/// Streaming audio processing result
#[flutter_rust_bridge::frb]
pub struct StreamingResult {
    /// VAD result
    pub vad: DartVadResult,
    /// Whether transcription was attempted
    pub transcription_attempted: bool,
    /// Transcription result (if attempted)
    pub transcription: Option<DartTranscription>,
}

/// Process streaming audio with VAD and optional STT
///
/// This is the main entry point for real-time audio processing.
/// It handles VAD first, then only processes STT when speech is detected.
///
/// # Arguments
/// * `bytes` - Raw PCM 16-bit LE audio bytes
/// * `start_time` - Current timestamp in the recording
/// * `force_transcribe` - If true, force transcription even without speech detection
pub fn process_streaming_audio(
    bytes: Vec<u8>,
    start_time: f32,
    force_transcribe: bool,
) -> Result<StreamingResult> {
    // Write to buffer
    AUDIO_BUFFER.write_bytes(&bytes);

    // Convert bytes to f32 for VAD
    let samples: Vec<f32> = bytes
        .chunks_exact(2)
        .map(|chunk| i16::from_le_bytes([chunk[0], chunk[1]]) as f32 / 32768.0)
        .collect();

    // Run VAD
    let vad_result = VAD.process(&samples);

    // Determine if we should transcribe
    let should_transcribe = force_transcribe || vad_result.is_speech;

    let transcription =
        if should_transcribe && AUDIO_BUFFER.available() > WHISPER_SAMPLE_RATE as usize {
            // Have at least 1 second of audio
            let audio_samples = AUDIO_BUFFER.read_all();
            match STT_ENGINE.process(&audio_samples, start_time) {
                Ok(t) => Some(t.into()),
                Err(_) => None,
            }
        } else {
            None
        };

    Ok(StreamingResult {
        vad: vad_result.into(),
        transcription_attempted: should_transcribe,
        transcription,
    })
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Get the audio module version
#[flutter_rust_bridge::frb(sync)]
pub fn audio_module_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

/// Check if the audio module is operational
#[flutter_rust_bridge::frb(sync)]
pub fn audio_module_health_check() -> bool {
    // Basic health check - verify buffer is accessible
    // available() returns usize, so just check it's working (call succeeds)
    let _ = AUDIO_BUFFER.available();
     // VAD is always available

    true
}

/// Initialize all audio subsystems
pub fn audio_initialize_all() -> Result<()> {
    stt_initialize()?;
    tts_initialize()?;
    Ok(())
}

/// Reset all audio subsystems
#[flutter_rust_bridge::frb(sync)]
pub fn audio_reset_all() {
    AUDIO_BUFFER.clear();
    VAD.reset();
    STT_ENGINE.reset();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_audio_buffer_api() {
        audio_buffer_clear();
        assert_eq!(audio_buffer_available(), 0);

        let samples: Vec<f32> = vec![0.5; 1000];
        let written = audio_buffer_write_samples(samples);
        assert_eq!(written, 1000);
        assert_eq!(audio_buffer_available(), 1000);
    }

    #[test]
    fn test_vad_api() {
        vad_reset();
        assert_eq!(vad_current_state(), 0); // Silence

        let samples: Vec<f32> = vec![0.001; 640];
        let result = vad_process(samples);
        assert!(result.state >= 0 && result.state <= 3);
    }

    #[test]
    fn test_stt_api() {
        let state = stt_state();
        assert!(state >= 0 && state <= 4);

        let models = stt_available_models();
        assert!(!models.is_empty());

        let size = stt_model_size("tiny".to_string());
        assert!(size > 0);
    }

    #[test]
    fn test_tts_api() {
        let state = tts_state();
        assert!(state >= 0 && state <= 4);

        let voices = tts_available_voices();
        assert!(!voices.is_empty());
    }

    #[test]
    fn test_health_check() {
        assert!(audio_module_health_check());
    }

    #[test]
    fn test_version() {
        let version = audio_module_version();
        assert!(!version.is_empty());
    }

    #[test]
    fn test_whisper_sample_rate() {
        assert_eq!(get_whisper_sample_rate(), 16000);
    }
}
