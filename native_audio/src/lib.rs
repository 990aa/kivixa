//! Kivixa Audio Native Rust Library
//!
//! This library provides the native Rust backend for Kivixa's Audio Intelligence features:
//! - Speech-to-Text (STT) using Whisper via candle ML framework
//! - Text-to-Speech (TTS) using Kokoro neural synthesis
//! - Voice Activity Detection (VAD) using Silero VAD
//! - Ring buffer for streaming audio capture
//! - Semantic audio indexing with timestamped transcriptions
//! - Real-time phonemization for TTS
//!
//! This module provides the "Ear" and "Voice" capabilities for Kivixa.

mod frb_generated;

pub mod api;
pub mod audio_buffer;
pub mod phonemizer;
pub mod stt;
pub mod tts;
pub mod vad;

#[cfg(test)]
mod tests;

pub use api::*;
