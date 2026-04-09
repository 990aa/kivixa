// Audio Recording Service
//
// Handles microphone access and audio capture for the Audio Neural Engine.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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
  final _recorder = AudioRecorder();

  Timer? _durationTimer;
  StreamSubscription<Uint8List>? _recordingSubscription;
  DateTime? _recordingStartTime;
  AudioFormatConfig _config = AudioFormatConfig.whisper;
  var _recordedBytes = BytesBuilder(copy: false);
  var _isVirtualRecording = false;

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
    _recordedBytes = BytesBuilder(copy: false);

    try {
      _isVirtualRecording = AudioNeuralEngine().usesPlatformSpeechRecognition;

      if (!_isVirtualRecording) {
        final hasPermission = await _ensureMicrophonePermission();
        if (!hasPermission) {
          throw StateError('Microphone permission not granted');
        }

        final stream = await _recorder.startStream(
          RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _config.sampleRate,
            numChannels: _config.channels,
          ),
        );

        _recordingSubscription = stream.listen(
          (chunk) {
            if (_stateNotifier.value != RecordingState.recording) {
              return;
            }

            _recordedBytes.add(chunk);
            _audioDataController.add(chunk);
            unawaited(AudioNeuralEngine().processAudioBytes(chunk));
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('AudioRecordingService: Stream error: $error');
            debugPrint('Stack trace: $stackTrace');
            _stateNotifier.value = RecordingState.stopped;
          },
          cancelOnError: true,
        );
      }

      _recordingStartTime = DateTime.now();
      _stateNotifier.value = RecordingState.recording;

      // Start duration timer
      _durationTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateDuration(),
      );

      debugPrint(
        'AudioRecordingService: Started recording at ${_config.sampleRate}Hz '
        '(virtual: $_isVirtualRecording)',
      );
      return true;
    } catch (e) {
      debugPrint('AudioRecordingService: Failed to start recording: $e');
      _isVirtualRecording = false;
      _stateNotifier.value = RecordingState.stopped;
      return false;
    }
  }

  /// Stop recording and return the final audio data
  Future<Uint8List?> stopRecording() async {
    if (_stateNotifier.value != RecordingState.recording &&
        _stateNotifier.value != RecordingState.paused) {
      return null;
    }

    _stateNotifier.value = RecordingState.stopping;

    try {
      _durationTimer?.cancel();
      _durationTimer = null;

      if (!_isVirtualRecording) {
        await _recordingSubscription?.cancel();
        _recordingSubscription = null;

        try {
          await _recorder.stop();
        } catch (e) {
          debugPrint('AudioRecordingService: Recorder stop warning: $e');
        }
      }

      final data = Uint8List.fromList(_recordedBytes.takeBytes());

      _stateNotifier.value = RecordingState.stopped;
      _durationNotifier.value = Duration.zero;
      _recordingStartTime = null;
      _isVirtualRecording = false;

      debugPrint('AudioRecordingService: Stopped recording');
      return data;
    } catch (e) {
      debugPrint('AudioRecordingService: Failed to stop recording: $e');
      _stateNotifier.value = RecordingState.stopped;
      _isVirtualRecording = false;
      return null;
    }
  }

  /// Pause recording
  void pauseRecording() {
    if (_stateNotifier.value == RecordingState.recording) {
      _stateNotifier.value = RecordingState.paused;
      _durationTimer?.cancel();
      if (!_isVirtualRecording) {
        unawaited(_pauseNativeRecording());
      }
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
      if (!_isVirtualRecording) {
        unawaited(_resumeNativeRecording());
      }
      debugPrint('AudioRecordingService: Resumed recording');
    }
  }

  /// Feed audio data manually (for testing or external sources)
  void feedAudioData(Uint8List data) {
    if (_stateNotifier.value == RecordingState.recording) {
      _recordedBytes.add(data);
      _audioDataController.add(data);

      // Also send to neural engine for processing
      unawaited(AudioNeuralEngine().processAudioBytes(data));
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
    unawaited(_recordingSubscription?.cancel());
    _recordingSubscription = null;
    try {
      _recorder.dispose();
    } catch (_) {
      // Ignore recorder disposal errors during shutdown.
    }
    _audioDataController.close();
    _stateNotifier.dispose();
    _durationNotifier.dispose();
  }

  Future<void> _pauseNativeRecording() async {
    try {
      await _recorder.pause();
    } catch (e) {
      debugPrint('AudioRecordingService: Native pause unavailable: $e');
    }
  }

  Future<void> _resumeNativeRecording() async {
    try {
      await _recorder.resume();
    } catch (e) {
      debugPrint('AudioRecordingService: Native resume unavailable: $e');
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        final permission = await Permission.microphone.request();
        if (!permission.isGranted) {
          return false;
        }
      }
    } catch (e) {
      debugPrint('AudioRecordingService: Permission request warning: $e');
    }

    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('AudioRecordingService: Permission probe warning: $e');
      return true;
    }
  }

  void _updateDuration() {
    if (_recordingStartTime != null) {
      _durationNotifier.value = DateTime.now().difference(_recordingStartTime!);
    }
  }
}
