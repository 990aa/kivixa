//! Audio Ring Buffer Implementation
//!
//! A high-performance ring buffer for streaming audio data.
//! Designed for real-time audio capture where data arrives from Flutter
//! and needs to be accumulated for Whisper's 30-second processing windows.

use parking_lot::RwLock;
use std::sync::Arc;

/// Default buffer duration in seconds (Whisper requires 30s chunks)
pub const DEFAULT_BUFFER_DURATION_SECS: f32 = 30.0;

/// Standard sample rate for Whisper models
pub const WHISPER_SAMPLE_RATE: u32 = 16000;

/// Audio ring buffer for streaming capture
///
/// This buffer accumulates raw PCM audio samples from Flutter and provides
/// them to the STT engine in the required chunk sizes.
#[derive(Debug)]
pub struct AudioRingBuffer {
    /// The underlying circular buffer
    buffer: Vec<f32>,
    /// Current write position
    write_pos: usize,
    /// Current read position
    read_pos: usize,
    /// Total samples written (may wrap)
    total_written: u64,
    /// Total samples read
    total_read: u64,
    /// Sample rate of the audio
    sample_rate: u32,
    /// Buffer capacity in samples
    capacity: usize,
}

impl AudioRingBuffer {
    /// Create a new ring buffer with the specified duration and sample rate
    pub fn new(duration_secs: f32, sample_rate: u32) -> Self {
        let capacity = (duration_secs * sample_rate as f32) as usize;
        Self {
            buffer: vec![0.0; capacity],
            write_pos: 0,
            read_pos: 0,
            total_written: 0,
            total_read: 0,
            sample_rate,
            capacity,
        }
    }

    /// Create a buffer for Whisper's default requirements
    pub fn for_whisper() -> Self {
        Self::new(DEFAULT_BUFFER_DURATION_SECS, WHISPER_SAMPLE_RATE)
    }

    /// Write PCM samples to the buffer
    ///
    /// # Arguments
    /// * `samples` - Raw PCM audio samples (f32, normalized -1.0 to 1.0)
    ///
    /// # Returns
    /// Number of samples actually written
    pub fn write(&mut self, samples: &[f32]) -> usize {
        let mut written = 0;
        for &sample in samples {
            self.buffer[self.write_pos] = sample;
            self.write_pos = (self.write_pos + 1) % self.capacity;
            written += 1;
            self.total_written += 1;
        }
        written
    }

    /// Write raw PCM i16 samples (common format from microphones)
    ///
    /// # Arguments
    /// * `samples` - Raw PCM audio samples (i16)
    ///
    /// # Returns
    /// Number of samples actually written
    pub fn write_i16(&mut self, samples: &[i16]) -> usize {
        let mut written = 0;
        for &sample in samples {
            // Convert i16 to f32 normalized
            let normalized = sample as f32 / 32768.0;
            self.buffer[self.write_pos] = normalized;
            self.write_pos = (self.write_pos + 1) % self.capacity;
            written += 1;
            self.total_written += 1;
        }
        written
    }

    /// Write raw bytes (PCM 16-bit little-endian)
    ///
    /// This is the format typically streamed from Flutter's audio capture
    ///
    /// # Arguments
    /// * `bytes` - Raw PCM bytes (16-bit LE)
    ///
    /// # Returns
    /// Number of samples (not bytes) written
    pub fn write_bytes(&mut self, bytes: &[u8]) -> usize {
        let mut written = 0;
        for chunk in bytes.chunks_exact(2) {
            let sample = i16::from_le_bytes([chunk[0], chunk[1]]);
            let normalized = sample as f32 / 32768.0;
            self.buffer[self.write_pos] = normalized;
            self.write_pos = (self.write_pos + 1) % self.capacity;
            written += 1;
            self.total_written += 1;
        }
        written
    }

    /// Read all available samples from the buffer
    ///
    /// This advances the read position to match the write position
    pub fn read_all(&mut self) -> Vec<f32> {
        let available = self.available();
        if available == 0 {
            return Vec::new();
        }

        let mut output = Vec::with_capacity(available);
        for _ in 0..available {
            output.push(self.buffer[self.read_pos]);
            self.read_pos = (self.read_pos + 1) % self.capacity;
            self.total_read += 1;
        }
        output
    }

    /// Read a specific number of samples
    ///
    /// # Arguments
    /// * `count` - Number of samples to read
    ///
    /// # Returns
    /// Vector of samples (may be shorter than requested if not enough available)
    pub fn read(&mut self, count: usize) -> Vec<f32> {
        let available = self.available().min(count);
        if available == 0 {
            return Vec::new();
        }

        let mut output = Vec::with_capacity(available);
        for _ in 0..available {
            output.push(self.buffer[self.read_pos]);
            self.read_pos = (self.read_pos + 1) % self.capacity;
            self.total_read += 1;
        }
        output
    }

    /// Peek at samples without advancing the read position
    ///
    /// # Arguments
    /// * `count` - Number of samples to peek
    pub fn peek(&self, count: usize) -> Vec<f32> {
        let available = self.available().min(count);
        if available == 0 {
            return Vec::new();
        }

        let mut output = Vec::with_capacity(available);
        let mut pos = self.read_pos;
        for _ in 0..available {
            output.push(self.buffer[pos]);
            pos = (pos + 1) % self.capacity;
        }
        output
    }

    /// Get the number of samples available for reading
    pub fn available(&self) -> usize {
        if self.total_written >= self.total_read {
            (self.total_written - self.total_read) as usize
        } else {
            0
        }
    }

    /// Get available duration in seconds
    pub fn available_duration(&self) -> f32 {
        self.available() as f32 / self.sample_rate as f32
    }

    /// Check if we have enough data for a full Whisper chunk
    pub fn has_full_chunk(&self) -> bool {
        self.available() >= self.capacity
    }

    /// Get the buffer's sample rate
    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    /// Get the buffer's capacity in samples
    pub fn capacity(&self) -> usize {
        self.capacity
    }

    /// Get duration capacity in seconds
    pub fn duration_capacity(&self) -> f32 {
        self.capacity as f32 / self.sample_rate as f32
    }

    /// Clear the buffer
    pub fn clear(&mut self) {
        self.buffer.fill(0.0);
        self.write_pos = 0;
        self.read_pos = 0;
        self.total_written = 0;
        self.total_read = 0;
    }

    /// Get timestamp for the current read position in the recording
    ///
    /// # Arguments
    /// * `recording_start_sample` - The global sample index when recording started
    pub fn current_timestamp(&self, recording_start_sample: u64) -> f32 {
        let global_sample = recording_start_sample + self.total_read;
        global_sample as f32 / self.sample_rate as f32
    }
}

/// Thread-safe wrapper for AudioRingBuffer
#[derive(Debug, Clone)]
pub struct SharedAudioBuffer {
    inner: Arc<RwLock<AudioRingBuffer>>,
}

impl SharedAudioBuffer {
    /// Create a new shared audio buffer
    pub fn new(duration_secs: f32, sample_rate: u32) -> Self {
        Self {
            inner: Arc::new(RwLock::new(AudioRingBuffer::new(
                duration_secs,
                sample_rate,
            ))),
        }
    }

    /// Create a shared buffer for Whisper
    pub fn for_whisper() -> Self {
        Self {
            inner: Arc::new(RwLock::new(AudioRingBuffer::for_whisper())),
        }
    }

    /// Write samples (thread-safe)
    pub fn write(&self, samples: &[f32]) -> usize {
        self.inner.write().write(samples)
    }

    /// Write i16 samples (thread-safe)
    pub fn write_i16(&self, samples: &[i16]) -> usize {
        self.inner.write().write_i16(samples)
    }

    /// Write bytes (thread-safe)
    pub fn write_bytes(&self, bytes: &[u8]) -> usize {
        self.inner.write().write_bytes(bytes)
    }

    /// Read all available (thread-safe)
    pub fn read_all(&self) -> Vec<f32> {
        self.inner.write().read_all()
    }

    /// Read specific count (thread-safe)
    pub fn read(&self, count: usize) -> Vec<f32> {
        self.inner.write().read(count)
    }

    /// Peek without advancing (thread-safe)
    pub fn peek(&self, count: usize) -> Vec<f32> {
        self.inner.read().peek(count)
    }

    /// Get available samples count (thread-safe)
    pub fn available(&self) -> usize {
        self.inner.read().available()
    }

    /// Get available duration (thread-safe)
    pub fn available_duration(&self) -> f32 {
        self.inner.read().available_duration()
    }

    /// Check if full chunk available (thread-safe)
    pub fn has_full_chunk(&self) -> bool {
        self.inner.read().has_full_chunk()
    }

    /// Clear the buffer (thread-safe)
    pub fn clear(&self) {
        self.inner.write().clear()
    }
}

/// Audio chunk with metadata for STT processing
#[derive(Debug, Clone)]
pub struct AudioChunk {
    /// The audio samples (f32, normalized)
    pub samples: Vec<f32>,
    /// Start timestamp in seconds (relative to recording start)
    pub start_time: f32,
    /// End timestamp in seconds
    pub end_time: f32,
    /// Sample rate
    pub sample_rate: u32,
}

impl AudioChunk {
    /// Create a new audio chunk
    pub fn new(samples: Vec<f32>, start_time: f32, sample_rate: u32) -> Self {
        let duration = samples.len() as f32 / sample_rate as f32;
        Self {
            samples,
            start_time,
            end_time: start_time + duration,
            sample_rate,
        }
    }

    /// Get the duration in seconds
    pub fn duration(&self) -> f32 {
        self.end_time - self.start_time
    }

    /// Check if chunk is empty
    pub fn is_empty(&self) -> bool {
        self.samples.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ring_buffer_basic() {
        let mut buffer = AudioRingBuffer::new(1.0, 16000);

        // Write some samples
        let samples: Vec<f32> = (0..1000).map(|i| i as f32 / 1000.0).collect();
        let written = buffer.write(&samples);
        assert_eq!(written, 1000);
        assert_eq!(buffer.available(), 1000);
    }

    #[test]
    fn test_ring_buffer_read() {
        let mut buffer = AudioRingBuffer::new(1.0, 16000);

        let samples: Vec<f32> = (0..500).map(|i| i as f32 / 500.0).collect();
        buffer.write(&samples);

        let read = buffer.read(250);
        assert_eq!(read.len(), 250);
        assert_eq!(buffer.available(), 250);
    }

    #[test]
    fn test_ring_buffer_wrap() {
        let mut buffer = AudioRingBuffer::new(0.1, 16000); // 1600 samples

        // Write more than capacity to trigger wrap
        let samples: Vec<f32> = vec![0.5; 2000];
        buffer.write(&samples);

        // Read all should give us the wrapped data
        let read = buffer.read_all();
        assert!(!read.is_empty());
    }

    #[test]
    fn test_ring_buffer_i16() {
        let mut buffer = AudioRingBuffer::new(1.0, 16000);

        let samples: Vec<i16> = (0..1000).map(|i| i as i16).collect();
        let written = buffer.write_i16(&samples);
        assert_eq!(written, 1000);

        let read = buffer.read(100);
        assert_eq!(read.len(), 100);
        // First sample should be 0.0 / 32768.0 = 0.0
        assert!((read[0] - 0.0).abs() < 0.0001);
    }

    #[test]
    fn test_ring_buffer_bytes() {
        let mut buffer = AudioRingBuffer::new(1.0, 16000);

        // Create bytes for a few samples
        let sample_values: Vec<i16> = vec![0, 1000, -1000, 32767];
        let bytes: Vec<u8> = sample_values.iter().flat_map(|s| s.to_le_bytes()).collect();

        let written = buffer.write_bytes(&bytes);
        assert_eq!(written, 4);
    }

    #[test]
    fn test_shared_buffer() {
        let buffer = SharedAudioBuffer::new(1.0, 16000);

        let samples: Vec<f32> = vec![0.5; 500];
        buffer.write(&samples);

        assert_eq!(buffer.available(), 500);

        let read = buffer.read(250);
        assert_eq!(read.len(), 250);
        assert_eq!(buffer.available(), 250);
    }

    #[test]
    fn test_audio_chunk() {
        let samples = vec![0.0; 16000]; // 1 second at 16kHz
        let chunk = AudioChunk::new(samples, 5.0, 16000);

        assert!((chunk.duration() - 1.0).abs() < 0.001);
        assert!((chunk.start_time - 5.0).abs() < 0.001);
        assert!((chunk.end_time - 6.0).abs() < 0.001);
    }

    #[test]
    fn test_buffer_clear() {
        let mut buffer = AudioRingBuffer::new(1.0, 16000);

        let samples: Vec<f32> = vec![0.5; 1000];
        buffer.write(&samples);
        assert_eq!(buffer.available(), 1000);

        buffer.clear();
        assert_eq!(buffer.available(), 0);
    }
}
