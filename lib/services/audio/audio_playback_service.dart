// Audio Playback Service
//
// Handles audio playback for synthesized speech and voice notes.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';

/// Playback state
enum PlaybackState {
  /// Not playing
  stopped,

  /// Loading audio
  loading,

  /// Currently playing
  playing,

  /// Paused
  paused,
}

/// Audio Playback Service
class AudioPlaybackService {
  static final _instance = AudioPlaybackService._internal();
  factory AudioPlaybackService() => _instance;
  AudioPlaybackService._internal();

  final _stateNotifier = ValueNotifier<PlaybackState>(PlaybackState.stopped);
  final _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final _durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final _volumeNotifier = ValueNotifier<double>(1.0);
  final _speedNotifier = ValueNotifier<double>(1.0);

  final _positionController = StreamController<Duration>.broadcast();
  Timer? _positionTimer;

  // Current playback info
  Float32List? _currentSamples;
  var _currentSampleRate = 24000;
  var _currentPosition = 0;

  /// Current playback state
  ValueListenable<PlaybackState> get state => _stateNotifier;

  /// Current playback position
  ValueListenable<Duration> get position => _positionNotifier;

  /// Total duration
  ValueListenable<Duration> get duration => _durationNotifier;

  /// Current volume (0.0 - 1.0)
  ValueListenable<double> get volume => _volumeNotifier;

  /// Current playback speed (0.5 - 2.0)
  ValueListenable<double> get speed => _speedNotifier;

  /// Stream of position updates
  Stream<Duration> get positionStream => _positionController.stream;

  /// Whether currently playing
  bool get isPlaying => _stateNotifier.value == PlaybackState.playing;

  /// Play synthesized audio
  Future<void> playSynthesis(SynthesisResult synthesis) async {
    _currentSamples = synthesis.samples;
    _currentSampleRate = synthesis.sampleRate;
    _currentPosition = 0;

    _durationNotifier.value = Duration(
      milliseconds: (synthesis.duration * 1000).round(),
    );
    _positionNotifier.value = Duration.zero;
    _stateNotifier.value = PlaybackState.playing;

    // In a real implementation, this would send audio to platform audio player
    // For now, simulate playback with a timer

    _startPositionTimer();
    debugPrint('AudioPlaybackService: Playing ${synthesis.duration}s of audio');
  }

  /// Play raw PCM bytes
  Future<void> playBytes(Uint8List bytes, {int sampleRate = 24000}) async {
    // Convert bytes to samples
    final samples = Float32List(bytes.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      final sample = bytes[i * 2] | (bytes[i * 2 + 1] << 8);
      samples[i] = sample / 32768.0;
    }

    _currentSamples = samples;
    _currentSampleRate = sampleRate;
    _currentPosition = 0;

    final durationSeconds = samples.length / sampleRate;
    _durationNotifier.value = Duration(
      milliseconds: (durationSeconds * 1000).round(),
    );
    _positionNotifier.value = Duration.zero;
    _stateNotifier.value = PlaybackState.playing;

    _startPositionTimer();
    debugPrint('AudioPlaybackService: Playing ${durationSeconds}s of audio');
  }

  /// Speak text using TTS
  Future<void> speak(String text, {String? voiceId}) async {
    _stateNotifier.value = PlaybackState.loading;

    try {
      final synthesis = await AudioNeuralEngine().synthesize(
        text,
        voiceId: voiceId,
      );

      if (synthesis != null) {
        await playSynthesis(synthesis);
      } else {
        _stateNotifier.value = PlaybackState.stopped;
      }
    } catch (e) {
      debugPrint('AudioPlaybackService: Failed to speak: $e');
      _stateNotifier.value = PlaybackState.stopped;
    }
  }

  /// Pause playback
  void pause() {
    if (_stateNotifier.value == PlaybackState.playing) {
      _stateNotifier.value = PlaybackState.paused;
      _stopPositionTimer();
      debugPrint('AudioPlaybackService: Paused');
    }
  }

  /// Resume playback
  void resume() {
    if (_stateNotifier.value == PlaybackState.paused) {
      _stateNotifier.value = PlaybackState.playing;
      _startPositionTimer();
      debugPrint('AudioPlaybackService: Resumed');
    }
  }

  /// Stop playback
  void stop() {
    _stateNotifier.value = PlaybackState.stopped;
    _stopPositionTimer();
    _positionNotifier.value = Duration.zero;
    _currentSamples = null;
    _currentPosition = 0;
    debugPrint('AudioPlaybackService: Stopped');
  }

  /// Seek to position
  void seek(Duration position) {
    if (_currentSamples == null) return;

    final seconds = position.inMilliseconds / 1000.0;
    _currentPosition = (seconds * _currentSampleRate).round();
    _currentPosition = _currentPosition.clamp(0, _currentSamples!.length);
    _positionNotifier.value = position;
    _positionController.add(position);
    debugPrint('AudioPlaybackService: Seeked to ${position.inSeconds}s');
  }

  /// Set volume
  void setVolume(double volume) {
    _volumeNotifier.value = volume.clamp(0.0, 1.0);
  }

  /// Set playback speed
  void setSpeed(double speed) {
    _speedNotifier.value = speed.clamp(0.5, 2.0);
  }

  /// Dispose resources
  void dispose() {
    _stopPositionTimer();
    _positionController.close();
    _stateNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _volumeNotifier.dispose();
    _speedNotifier.dispose();
  }

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _updatePosition(),
    );
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updatePosition() {
    if (_currentSamples == null ||
        _stateNotifier.value != PlaybackState.playing) {
      return;
    }

    // Simulate playback progress
    final increment = (_currentSampleRate * _speedNotifier.value * 0.05)
        .round();
    _currentPosition += increment;

    if (_currentPosition >= _currentSamples!.length) {
      // Playback finished
      stop();
      return;
    }

    final positionSeconds = _currentPosition / _currentSampleRate;
    _positionNotifier.value = Duration(
      milliseconds: (positionSeconds * 1000).round(),
    );
    _positionController.add(_positionNotifier.value);
  }
}
