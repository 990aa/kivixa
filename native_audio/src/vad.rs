//! Voice Activity Detection (VAD) Module
//!
//! Implements Silero-style VAD for efficient speech detection.
//! This allows the system to skip processing silent audio chunks,
//! saving CPU and battery on mobile devices.

use parking_lot::RwLock;
use std::sync::Arc;

/// VAD configuration parameters
#[derive(Debug, Clone)]
pub struct VadConfig {
    /// Sample rate (must be 16000 for this implementation)
    pub sample_rate: u32,
    /// Threshold for speech detection (0.0 to 1.0)
    pub threshold: f32,
    /// Minimum speech duration in seconds to trigger detection
    pub min_speech_duration: f32,
    /// Minimum silence duration in seconds to end speech
    pub min_silence_duration: f32,
    /// Window size for energy calculation
    pub window_size: usize,
    /// Number of windows to average for smoothing
    pub smoothing_windows: usize,
}

impl Default for VadConfig {
    fn default() -> Self {
        Self {
            sample_rate: 16000,
            threshold: 0.5,
            min_speech_duration: 0.25,
            min_silence_duration: 0.5,
            window_size: 512,
            smoothing_windows: 3,
        }
    }
}

/// Voice Activity Detection state
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VadState {
    /// No speech detected
    Silence,
    /// Possible speech starting (not yet confirmed)
    SpeechPending,
    /// Active speech detected
    Speech,
    /// Speech ending (silence detected but waiting for confirmation)
    SilencePending,
}

/// VAD detection result
#[derive(Debug, Clone)]
pub struct VadResult {
    /// Current state of VAD
    pub state: VadState,
    /// Speech probability (0.0 to 1.0)
    pub speech_probability: f32,
    /// Whether speech is currently active
    pub is_speech: bool,
    /// Duration of current state in seconds
    pub state_duration: f32,
}

/// Energy-based Voice Activity Detector
///
/// Uses a combination of energy levels and zero-crossing rate
/// to detect speech vs silence. This is a lightweight approach
/// suitable for filtering audio before expensive STT processing.
#[derive(Debug)]
pub struct VoiceActivityDetector {
    config: VadConfig,
    /// Current state
    state: VadState,
    /// Samples processed in current state
    state_samples: usize,
    /// Rolling energy history for smoothing
    energy_history: Vec<f32>,
    /// Adaptive threshold based on noise floor
    noise_floor: f32,
    /// Number of samples processed
    total_samples: u64,
    /// Calibration mode flag
    is_calibrating: bool,
    /// Calibration samples collected
    calibration_energies: Vec<f32>,
}

impl VoiceActivityDetector {
    /// Create a new VAD with default configuration
    pub fn new() -> Self {
        Self::with_config(VadConfig::default())
    }

    /// Create a new VAD with custom configuration
    pub fn with_config(config: VadConfig) -> Self {
        Self {
            config,
            state: VadState::Silence,
            state_samples: 0,
            energy_history: Vec::with_capacity(10),
            noise_floor: 0.01,
            total_samples: 0,
            is_calibrating: true,
            calibration_energies: Vec::new(),
        }
    }

    /// Process audio samples and detect voice activity
    ///
    /// # Arguments
    /// * `samples` - Audio samples (f32, normalized -1.0 to 1.0)
    ///
    /// # Returns
    /// VAD result with current speech state
    pub fn process(&mut self, samples: &[f32]) -> VadResult {
        if samples.is_empty() {
            return VadResult {
                state: self.state,
                speech_probability: 0.0,
                is_speech: matches!(self.state, VadState::Speech | VadState::SilencePending),
                state_duration: self.state_duration(),
            };
        }

        // Calculate energy and zero-crossing rate
        let energy = self.calculate_energy(samples);
        let zcr = self.calculate_zcr(samples);

        // Update energy history for smoothing
        self.energy_history.push(energy);
        if self.energy_history.len() > self.config.smoothing_windows {
            self.energy_history.remove(0);
        }

        // Calculate smoothed energy
        let smoothed_energy =
            self.energy_history.iter().sum::<f32>() / self.energy_history.len() as f32;

        // Calibration phase - learn noise floor
        if self.is_calibrating {
            self.calibration_energies.push(energy);
            if self.calibration_energies.len() >= 20 {
                // Calculate noise floor as median of calibration energies
                let mut sorted = self.calibration_energies.clone();
                sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
                self.noise_floor = sorted[sorted.len() / 2] * 2.0 + 0.001;
                self.is_calibrating = false;
            }
        }

        // Calculate speech probability
        let energy_ratio = (smoothed_energy / self.noise_floor).min(10.0);
        let energy_prob = (energy_ratio - 1.0).max(0.0) / 9.0;

        // ZCR contribution (speech typically has moderate ZCR)
        let zcr_prob = if zcr > 0.1 && zcr < 0.5 { 0.3 } else { 0.0 };

        let speech_probability = (energy_prob * 0.7 + zcr_prob).min(1.0);
        let is_speech = speech_probability > self.config.threshold;

        // State machine transitions
        self.update_state(is_speech, samples.len());
        self.total_samples += samples.len() as u64;

        VadResult {
            state: self.state,
            speech_probability,
            is_speech: matches!(self.state, VadState::Speech | VadState::SilencePending),
            state_duration: self.state_duration(),
        }
    }

    /// Calculate RMS energy of samples
    fn calculate_energy(&self, samples: &[f32]) -> f32 {
        if samples.is_empty() {
            return 0.0;
        }
        let sum_squares: f32 = samples.iter().map(|s| s * s).sum();
        (sum_squares / samples.len() as f32).sqrt()
    }

    /// Calculate zero-crossing rate
    fn calculate_zcr(&self, samples: &[f32]) -> f32 {
        if samples.len() < 2 {
            return 0.0;
        }
        let crossings: usize = samples
            .windows(2)
            .filter(|w| (w[0] >= 0.0 && w[1] < 0.0) || (w[0] < 0.0 && w[1] >= 0.0))
            .count();
        crossings as f32 / (samples.len() - 1) as f32
    }

    /// Update state machine based on speech detection
    fn update_state(&mut self, is_speech: bool, num_samples: usize) {
        let min_speech_samples =
            (self.config.min_speech_duration * self.config.sample_rate as f32) as usize;
        let min_silence_samples =
            (self.config.min_silence_duration * self.config.sample_rate as f32) as usize;

        match self.state {
            VadState::Silence => {
                if is_speech {
                    self.state = VadState::SpeechPending;
                    self.state_samples = num_samples;
                }
            }
            VadState::SpeechPending => {
                self.state_samples += num_samples;
                if is_speech {
                    if self.state_samples >= min_speech_samples {
                        self.state = VadState::Speech;
                        self.state_samples = 0;
                    }
                } else {
                    self.state = VadState::Silence;
                    self.state_samples = 0;
                }
            }
            VadState::Speech => {
                if !is_speech {
                    self.state = VadState::SilencePending;
                    self.state_samples = num_samples;
                } else {
                    self.state_samples += num_samples;
                }
            }
            VadState::SilencePending => {
                self.state_samples += num_samples;
                if is_speech {
                    self.state = VadState::Speech;
                    self.state_samples = 0;
                } else if self.state_samples >= min_silence_samples {
                    self.state = VadState::Silence;
                    self.state_samples = 0;
                }
            }
        }
    }

    /// Get duration of current state in seconds
    fn state_duration(&self) -> f32 {
        self.state_samples as f32 / self.config.sample_rate as f32
    }

    /// Reset the VAD state
    pub fn reset(&mut self) {
        self.state = VadState::Silence;
        self.state_samples = 0;
        self.energy_history.clear();
        self.total_samples = 0;
        self.is_calibrating = true;
        self.calibration_energies.clear();
    }

    /// Get the current state
    pub fn current_state(&self) -> VadState {
        self.state
    }

    /// Check if currently in speech
    pub fn is_speech(&self) -> bool {
        matches!(self.state, VadState::Speech | VadState::SilencePending)
    }

    /// Get the noise floor level
    pub fn noise_floor(&self) -> f32 {
        self.noise_floor
    }

    /// Set the speech threshold
    pub fn set_threshold(&mut self, threshold: f32) {
        self.config.threshold = threshold.clamp(0.0, 1.0);
    }

    /// Check if VAD is still in calibration mode
    pub fn is_calibrating(&self) -> bool {
        self.is_calibrating
    }

    /// Get current configuration (for testing)
    pub fn config(&self) -> &VadConfig {
        &self.config
    }

    /// Force calibration complete (for testing)
    #[cfg(test)]
    pub fn force_calibration_complete(&mut self, noise_floor: f32) {
        self.is_calibrating = false;
        self.noise_floor = noise_floor;
    }
}

impl Default for VoiceActivityDetector {
    fn default() -> Self {
        Self::new()
    }
}

/// Thread-safe VAD wrapper
#[derive(Debug, Clone)]
pub struct SharedVad {
    inner: Arc<RwLock<VoiceActivityDetector>>,
}

impl SharedVad {
    /// Create a new shared VAD
    pub fn new() -> Self {
        Self {
            inner: Arc::new(RwLock::new(VoiceActivityDetector::new())),
        }
    }

    /// Create with custom config
    pub fn with_config(config: VadConfig) -> Self {
        Self {
            inner: Arc::new(RwLock::new(VoiceActivityDetector::with_config(config))),
        }
    }

    /// Process samples (thread-safe)
    pub fn process(&self, samples: &[f32]) -> VadResult {
        self.inner.write().process(samples)
    }

    /// Reset state (thread-safe)
    pub fn reset(&self) {
        self.inner.write().reset()
    }

    /// Check if speech (thread-safe)
    pub fn is_speech(&self) -> bool {
        self.inner.read().is_speech()
    }

    /// Get current state (thread-safe)
    pub fn current_state(&self) -> VadState {
        self.inner.read().current_state()
    }

    /// Set threshold (thread-safe)
    pub fn set_threshold(&self, threshold: f32) {
        self.inner.write().set_threshold(threshold)
    }
}

impl Default for SharedVad {
    fn default() -> Self {
        Self::new()
    }
}

/// Speech segment with timing information
#[derive(Debug, Clone)]
pub struct SpeechSegment {
    /// Start time in seconds
    pub start_time: f32,
    /// End time in seconds  
    pub end_time: f32,
    /// The audio samples
    pub samples: Vec<f32>,
    /// Average speech probability during this segment
    pub confidence: f32,
}

impl SpeechSegment {
    /// Get duration in seconds
    pub fn duration(&self) -> f32 {
        self.end_time - self.start_time
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vad_silence() {
        let mut vad = VoiceActivityDetector::new();

        // Silent audio (very low amplitude)
        let silence: Vec<f32> = vec![0.001; 16000];

        // Process multiple times to complete calibration
        for _ in 0..25 {
            let result = vad.process(&silence[..640]);
        }

        let result = vad.process(&silence[..640]);
        assert!(!result.is_speech);
    }

    #[test]
    fn test_vad_speech() {
        let mut vad = VoiceActivityDetector::new();
        vad.is_calibrating = false;
        vad.noise_floor = 0.01;

        // Simulated speech (higher energy with variation)
        let speech: Vec<f32> = (0..8000).map(|i| (i as f32 * 0.1).sin() * 0.5).collect();

        // Process enough to trigger speech state
        for _ in 0..20 {
            vad.process(&speech[..640]);
        }

        let result = vad.process(&speech[..640]);
        assert!(result.speech_probability > 0.0);
    }

    #[test]
    fn test_vad_config() {
        let config = VadConfig {
            threshold: 0.3,
            min_speech_duration: 0.1,
            ..Default::default()
        };

        let vad = VoiceActivityDetector::with_config(config);
        assert_eq!(vad.config.threshold, 0.3);
    }

    #[test]
    fn test_vad_reset() {
        let mut vad = VoiceActivityDetector::new();

        let samples: Vec<f32> = vec![0.5; 1000];
        vad.process(&samples);

        vad.reset();
        assert_eq!(vad.current_state(), VadState::Silence);
        assert!(vad.is_calibrating);
    }

    #[test]
    fn test_energy_calculation() {
        let vad = VoiceActivityDetector::new();

        // Constant amplitude should give that amplitude as energy
        let samples: Vec<f32> = vec![0.5; 100];
        let energy = vad.calculate_energy(&samples);
        assert!((energy - 0.5).abs() < 0.01);
    }

    #[test]
    fn test_zcr_calculation() {
        let vad = VoiceActivityDetector::new();

        // Alternating positive/negative should give high ZCR
        let samples: Vec<f32> = (0..100)
            .map(|i| if i % 2 == 0 { 0.5 } else { -0.5 })
            .collect();
        let zcr = vad.calculate_zcr(&samples);
        assert!(zcr > 0.9);
    }

    #[test]
    fn test_shared_vad() {
        let vad = SharedVad::new();

        let samples: Vec<f32> = vec![0.001; 640];
        for _ in 0..25 {
            vad.process(&samples);
        }

        let result = vad.process(&samples);
        assert_eq!(result.state, VadState::Silence);
    }

    #[test]
    fn test_speech_segment() {
        let segment = SpeechSegment {
            start_time: 1.0,
            end_time: 3.5,
            samples: vec![0.0; 40000],
            confidence: 0.8,
        };

        assert!((segment.duration() - 2.5).abs() < 0.001);
    }
}
