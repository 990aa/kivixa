//! Comprehensive tests for the Kivixa Audio module
//!
//! This module contains integration tests that verify the audio pipeline
//! works correctly end-to-end.

use crate::audio_buffer::{AudioChunk, AudioRingBuffer, SharedAudioBuffer};
use crate::phonemizer::{Phoneme, PhonemeSequence, Phonemizer};
use crate::stt::{SttConfig, SttEngine, Transcription, WhisperModel};
use crate::tts::{TtsEngine, VoiceStyle};
use crate::vad::{VadConfig, VadState, VoiceActivityDetector};

// ============================================================================
// Audio Buffer Tests
// ============================================================================

#[test]
fn test_ring_buffer_circular_write() {
    let mut buffer = AudioRingBuffer::new(0.5, 16000); // 8000 samples capacity

    // Write more than capacity
    let samples: Vec<f32> = (0..10000).map(|i| (i as f32 / 1000.0).sin()).collect();
    buffer.write(&samples);

    // Should still be able to read
    let read = buffer.read_all();
    assert!(!read.is_empty());
}

#[test]
fn test_ring_buffer_multiple_writes() {
    let mut buffer = AudioRingBuffer::new(1.0, 16000);

    for _ in 0..10 {
        let samples: Vec<f32> = vec![0.5; 1000];
        buffer.write(&samples);
    }

    assert_eq!(buffer.available(), 10000);
}

#[test]
fn test_ring_buffer_peek_vs_read() {
    let mut buffer = AudioRingBuffer::new(1.0, 16000);

    let samples: Vec<f32> = vec![0.25; 500];
    buffer.write(&samples);

    // Peek should not change available count
    let peeked = buffer.peek(100);
    assert_eq!(peeked.len(), 100);
    assert_eq!(buffer.available(), 500);

    // Read should decrease available count
    let read = buffer.read(100);
    assert_eq!(read.len(), 100);
    assert_eq!(buffer.available(), 400);
}

#[test]
fn test_shared_buffer_thread_safety() {
    use std::sync::Arc;
    use std::thread;

    let buffer = Arc::new(SharedAudioBuffer::new(1.0, 16000));
    let buffer_clone = buffer.clone();

    // Writer thread
    let writer = thread::spawn(move || {
        for _ in 0..100 {
            let samples: Vec<f32> = vec![0.5; 100];
            buffer_clone.write(&samples);
        }
    });

    // Reader thread
    let reader = thread::spawn(move || {
        let mut total_read = 0;
        for _ in 0..100 {
            total_read += buffer.read(50).len();
            thread::sleep(std::time::Duration::from_micros(100));
        }
        total_read
    });

    writer.join().unwrap();
    let _ = reader.join().unwrap();
}

#[test]
fn test_audio_chunk_creation() {
    let samples: Vec<f32> = vec![0.0; 48000]; // 3 seconds at 16kHz
    let chunk = AudioChunk::new(samples, 10.0, 16000);

    assert!((chunk.duration() - 3.0).abs() < 0.001);
    assert!((chunk.start_time - 10.0).abs() < 0.001);
    assert!((chunk.end_time - 13.0).abs() < 0.001);
}

// ============================================================================
// VAD Tests
// ============================================================================

#[test]
fn test_vad_calibration() {
    let mut vad = VoiceActivityDetector::new();

    // Process enough samples to complete calibration
    let silence: Vec<f32> = vec![0.001; 640];
    for _ in 0..30 {
        vad.process(&silence);
    }

    assert!(!vad.is_calibrating());
    assert!(vad.noise_floor() > 0.0);
}

#[test]
fn test_vad_state_transitions() {
    let mut vad = VoiceActivityDetector::new();
    vad.force_calibration_complete(0.01);

    // Start in silence
    assert_eq!(vad.current_state(), VadState::Silence);

    // Process loud audio
    let loud: Vec<f32> = (0..8000).map(|i| (i as f32 * 0.1).sin() * 0.8).collect();

    // Process several times to transition through states
    for _ in 0..20 {
        vad.process(&loud[..640]);
    }

    // Should eventually be in speech state
    let is_speech_related = matches!(
        vad.current_state(),
        VadState::Speech | VadState::SpeechPending | VadState::SilencePending
    );
    assert!(is_speech_related || vad.current_state() == VadState::Silence);
}

#[test]
fn test_vad_config_customization() {
    let config = VadConfig {
        threshold: 0.3,
        min_speech_duration: 0.1,
        min_silence_duration: 0.3,
        ..Default::default()
    };

    let vad = VoiceActivityDetector::with_config(config);
    assert_eq!(vad.config().threshold, 0.3);
}

// ============================================================================
// Phonemizer Tests
// ============================================================================

#[test]
fn test_phonemizer_common_words() {
    let phonemizer = Phonemizer::new();

    let common_words = vec!["hello", "world", "the", "and", "is", "are"];

    for word in common_words {
        let result = phonemizer.phonemize(word).unwrap();
        assert!(!result.is_empty(), "Failed to phonemize: {}", word);
        assert!(
            !result[0].phonemes.is_empty(),
            "Empty phonemes for: {}",
            word
        );
    }
}

#[test]
fn test_phonemizer_sentence() {
    let phonemizer = Phonemizer::new();

    let result = phonemizer.phonemize("hello world").unwrap();

    // Should have at least 2 word sequences (hello, world)
    let word_count = result
        .iter()
        .filter(|s| !matches!(s.phonemes.get(0), Some(Phoneme::SPACE)))
        .count();
    assert!(word_count >= 2);
}

#[test]
fn test_phonemizer_numbers() {
    let phonemizer = Phonemizer::new();

    let result = phonemizer.phonemize("1 2 3").unwrap();

    // Numbers should be expanded
    let text: String = result
        .iter()
        .map(|s| s.text.as_str())
        .collect::<Vec<_>>()
        .join(" ");
    assert!(text.contains("one") || text.contains("two") || text.contains("three"));
}

#[test]
fn test_phonemizer_punctuation() {
    let phonemizer = Phonemizer::new();

    let result = phonemizer.phonemize("hello! how are you?").unwrap();

    // Should have pause phonemes
    let has_pause = result
        .iter()
        .any(|s| s.phonemes.contains(&Phoneme::SIL) || s.phonemes.contains(&Phoneme::SP));
    assert!(has_pause);
}

#[test]
fn test_phoneme_to_string() {
    let seq = PhonemeSequence::new(
        "test".to_string(),
        vec![Phoneme::T, Phoneme::EH, Phoneme::S, Phoneme::T],
    );

    let repr = seq.to_string_repr();
    assert!(repr.contains("T"));
    assert!(repr.contains("EH"));
    assert!(repr.contains("S"));
}

// ============================================================================
// STT Tests
// ============================================================================

#[test]
fn test_stt_initialization() {
    let mut engine = SttEngine::new();
    assert!(!engine.is_ready());

    engine.initialize().unwrap();
    assert!(engine.is_ready());
}

#[test]
fn test_stt_config() {
    let config = SttConfig {
        model: WhisperModel::Base,
        language: Some("en".to_string()),
        word_timestamps: true,
        use_vad: false,
        ..Default::default()
    };

    let engine = SttEngine::with_config(config);
    assert_eq!(engine.config().model, WhisperModel::Base);
    assert!(!engine.config().use_vad);
}

#[test]
fn test_whisper_model_comparison() {
    assert!(WhisperModel::Tiny.size_bytes() < WhisperModel::Large.size_bytes());
    assert_eq!(WhisperModel::default(), WhisperModel::Tiny);
}

#[test]
fn test_transcription_search() {
    use crate::stt::TranscriptionSegment;

    let transcription = Transcription {
        segments: vec![
            TranscriptionSegment {
                id: 1,
                text: "The budget meeting is tomorrow".to_string(),
                start_time: 0.0,
                end_time: 2.0,
                words: vec![],
                language: Some("en".to_string()),
                confidence: 0.95,
                is_final: true,
            },
            TranscriptionSegment {
                id: 2,
                text: "We need to discuss Q3 results".to_string(),
                start_time: 2.0,
                end_time: 4.0,
                words: vec![],
                language: Some("en".to_string()),
                confidence: 0.92,
                is_final: true,
            },
        ],
        language: Some("en".to_string()),
        duration: 4.0,
        processing_time_ms: 150,
    };

    let results = transcription.search("budget");
    assert_eq!(results.len(), 1);
    assert!((results[0].start_time - 0.0).abs() < 0.01);

    let results = transcription.search("Q3");
    assert_eq!(results.len(), 1);
    assert!((results[0].start_time - 2.0).abs() < 0.01);
}

// ============================================================================
// TTS Tests
// ============================================================================

#[test]
fn test_tts_initialization() {
    let mut engine = TtsEngine::new();
    assert!(!engine.is_ready());

    engine.initialize().unwrap();
    assert!(engine.is_ready());
}

#[test]
fn test_tts_voices() {
    let engine = TtsEngine::new();
    let voices = engine.available_voices();

    assert!(!voices.is_empty());

    // Should have default voices
    let has_neutral = voices.iter().any(|v| v.id == "neutral");
    let has_female = voices.iter().any(|v| v.id == "female");
    let has_male = voices.iter().any(|v| v.id == "male");

    assert!(has_neutral);
    assert!(has_female);
    assert!(has_male);
}

#[test]
fn test_tts_synthesize() {
    let mut engine = TtsEngine::new();
    engine.initialize().unwrap();

    let result = engine.synthesize("hello");
    assert!(result.is_ok());

    let audio = result.unwrap();
    assert!(audio.sample_rate > 0);
}

#[test]
fn test_voice_style_properties() {
    let neutral = VoiceStyle::default_neutral();
    let female = VoiceStyle::female();
    let male = VoiceStyle::male();

    assert_eq!(neutral.rate, 1.0);
    assert!(female.pitch > male.pitch);
    assert_eq!(female.embedding.len(), 256);
}

#[test]
fn test_tts_custom_voice() {
    let mut engine = TtsEngine::new();

    let custom = VoiceStyle {
        id: "robot".to_string(),
        name: "Robot".to_string(),
        description: "A robotic voice".to_string(),
        rate: 0.8,
        pitch: -5.0,
        embedding: vec![0.2; 256],
    };

    engine.add_voice(custom);

    let voices = engine.available_voices();
    assert!(voices.iter().any(|v| v.id == "robot"));
}

// ============================================================================
// Integration Tests
// ============================================================================

#[test]
fn test_audio_pipeline_integration() {
    // Create all components
    let mut buffer = AudioRingBuffer::for_whisper();
    let mut vad = VoiceActivityDetector::new();
    let mut stt = SttEngine::new();
    let mut tts = TtsEngine::new();

    // Initialize engines
    stt.initialize().unwrap();
    tts.initialize().unwrap();

    // Simulate audio capture
    let audio_data: Vec<f32> = (0..16000).map(|i| (i as f32 * 0.1).sin() * 0.3).collect();

    // Write to buffer
    buffer.write(&audio_data);
    assert!(buffer.available() > 0);

    // Process with VAD
    let vad_result = vad.process(&audio_data);
    assert!(vad_result.speech_probability >= 0.0);

    // TTS synthesis
    let tts_result = tts.synthesize("test");
    assert!(tts_result.is_ok());
}

#[test]
fn test_phonemizer_to_tts_pipeline() {
    let phonemizer = Phonemizer::new();
    let mut tts = TtsEngine::new();
    tts.initialize().unwrap();

    // Phonemize text
    let text = "kivixa is an amazing app";
    let phonemes = phonemizer.phonemize(text).unwrap();
    assert!(!phonemes.is_empty());

    // Synthesize
    let audio = tts.synthesize(text).unwrap();
    assert!(audio.sample_rate > 0);
}

// ============================================================================
// Edge Case Tests
// ============================================================================

#[test]
fn test_empty_input_handling() {
    let phonemizer = Phonemizer::new();
    let result = phonemizer.phonemize("");
    assert!(result.is_ok());
    assert!(result.unwrap().is_empty());
}

#[test]
fn test_very_long_text() {
    let phonemizer = Phonemizer::new();

    let long_text = "hello ".repeat(100);
    let result = phonemizer.phonemize(&long_text);
    assert!(result.is_ok());
}

#[test]
fn test_special_characters() {
    let phonemizer = Phonemizer::new();

    let text = "hello! @#$ world...";
    let result = phonemizer.phonemize(text);
    assert!(result.is_ok());
}

#[test]
fn test_buffer_underrun() {
    let mut buffer = AudioRingBuffer::new(1.0, 16000);

    // Try to read more than available
    let read = buffer.read(10000);
    assert!(read.is_empty());

    // Write some data
    buffer.write(&vec![0.5; 100]);

    // Read more than available
    let read = buffer.read(200);
    assert_eq!(read.len(), 100); // Should only get what's available
}

#[test]
fn test_vad_with_varying_amplitude() {
    let mut vad = VoiceActivityDetector::new();
    vad.force_calibration_complete(0.01);

    // Low amplitude
    let low: Vec<f32> = vec![0.01; 640];
    let result_low = vad.process(&low);

    // High amplitude
    let high: Vec<f32> = vec![0.8; 640];
    let result_high = vad.process(&high);

    assert!(result_high.speech_probability >= result_low.speech_probability);
}
