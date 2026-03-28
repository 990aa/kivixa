// Audio Recording Service
//
// Handles microphone access and audio capture for the Audio Neural Engine.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';

/// Audio format configuration
class AudioFormatConfig {
  /// Sample rate in Hz
  final int sampleRate;

  /// Number of channels (1 = mono, 2 = stereo)
  final int channels;

  /// Bits per sample
  final int bitsPerSample;

  const AudioFormatConfig({
    this.sampleRate = 16000,
    this.channels = 1,
    this.bitsPerSample = 16,
  });

  /// Standard Whisper format (16kHz, mono, 16-bit)
  static const whisper = AudioFormatConfig(
    sampleRate: 16000,
    channels: 1,
    bitsPerSample: 16,
  );

  /// High quality recording (48kHz, stereo, 16-bit)
  static const highQuality = AudioFormatConfig(
    sampleRate: 48000,
    channels: 2,
    bitsPerSample: 16,
  );
}

/// Recording state
enum RecordingState {
  /// Not recording
  stopped,

  /// Preparing to record
  preparing,

  /// Currently recording
  recording,

  /// Paused
  paused,

  /// Stopping
  stopping,
}

/// Audio Recording Service
class AudioRecordingService {
  static final _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final _stateNotifier = ValueNotifier<RecordingState>(RecordingState.stopped);
  final _audioDataController = StreamController<Uint8List>.broadcast();
  final _durationNotifier = ValueNotifier<Duration>(Duration.zero);

  Timer? _durationTimer;
  DateTime? _recordingStartTime;
  AudioFormatConfig _config = AudioFormatConfig.whisper;

  /// Current recording state
  ValueListenable<RecordingState> get state => _stateNotifier;

  /// Stream of raw audio data
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;

  /// Current recording duration
  ValueListenable<Duration> get duration => _durationNotifier;

  /// Current audio format configuration
  AudioFormatConfig get config => _config;

  /// Whether currently recording
  bool get isRecording => _stateNotifier.value == RecordingState.recording;

  /// Start recording with optional custom format
  Future<bool> startRecording({AudioFormatConfig? format}) async {
    if (_stateNotifier.value == RecordingState.recording) {
      return true; // Already recording
    }

    _stateNotifier.value = RecordingState.preparing;
    _config = format ?? AudioFormatConfig.whisper;

    try {
      // In a real implementation, this would initialize platform audio capture
      // For now, we'll simulate with a placeholder

      _recordingStartTime = DateTime.now();
      _stateNotifier.value = RecordingState.recording;

      // Start duration timer
      _durationTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateDuration(),
      );

      debugPrint(
        'AudioRecordingService: Started recording at ${_config.sampleRate}Hz',
      );
      return true;
    } catch (e) {
      debugPrint('AudioRecordingService: Failed to start recording: $e');
      _stateNotifier.value = RecordingState.stopped;
      return false;
    }
  }

  /// Stop recording and return the final audio data
  Future<Uint8List?> stopRecording() async {
    if (_stateNotifier.value != RecordingState.recording) {
      return null;
    }

    _stateNotifier.value = RecordingState.stopping;

    try {
      _durationTimer?.cancel();
      _durationTimer = null;

      // In a real implementation, this would stop platform audio capture
      // and return the recorded audio data

      _stateNotifier.value = RecordingState.stopped;
      _durationNotifier.value = Duration.zero;
      _recordingStartTime = null;

      debugPrint('AudioRecordingService: Stopped recording');
      return Uint8List(0); // Placeholder
    } catch (e) {
      debugPrint('AudioRecordingService: Failed to stop recording: $e');
      _stateNotifier.value = RecordingState.stopped;
      return null;
    }
  }

  /// Pause recording
  void pauseRecording() {
    if (_stateNotifier.value == RecordingState.recording) {
      _stateNotifier.value = RecordingState.paused;
      _durationTimer?.cancel();
      debugPrint('AudioRecordingService: Paused recording');
    }
  }

  /// Resume recording
  void resumeRecording() {
    if (_stateNotifier.value == RecordingState.paused) {
      _stateNotifier.value = RecordingState.recording;
      _durationTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateDuration(),
      );
      debugPrint('AudioRecordingService: Resumed recording');
    }
  }

  /// Feed audio data manually (for testing or external sources)
  void feedAudioData(Uint8List data) {
    if (_stateNotifier.value == RecordingState.recording) {
      _audioDataController.add(data);

      // Also send to neural engine for processing
      AudioNeuralEngine().processAudioBytes(data);
    }
  }

  /// Get the current recording duration
  Duration get currentDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    _audioDataController.close();
    _stateNotifier.dispose();
    _durationNotifier.dispose();
  }

  void _updateDuration() {
    if (_recordingStartTime != null) {
      _durationNotifier.value = DateTime.now().difference(_recordingStartTime!);
    }
  }
}
