// Audio Neural Engine Service
//
// Central singleton service managing all audio intelligence features.
// Provides STT, TTS, VAD, and streaming audio processing through the Rust backend.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'package:kivixa/src/rust_audio/api.dart' as audio_api;
import 'package:kivixa/src/rust_audio/frb_generated.dart';

/// Audio engine state enum
enum AudioEngineState {
  /// Engine is not initialized
  uninitialized,

  /// Engine is initializing
  initializing,

  /// Engine is ready but idle
  idle,

  /// Listening for voice input (STT active)
  listening,

  /// Processing audio (VAD/STT working)
  processing,

  /// Speaking output (TTS active)
  speaking,

  /// Engine encountered an error
  error,
}

/// VAD state enum (mirrors Rust)
enum VadState { silence, speechPending, speech, silencePending }

/// Speech recognition result
class SpeechRecognitionResult {
  /// Recognized text
  final String text;

  /// Confidence level (0.0 - 1.0)
  final double confidence;

  /// Whether this is the final result
  final bool isFinal;

  /// Start time in seconds
  final double startTime;

  /// End time in seconds
  final double endTime;

  /// Detected language
  final String? language;

  const SpeechRecognitionResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
    required this.startTime,
    required this.endTime,
    this.language,
  });

  @override
  String toString() =>
      'SpeechRecognitionResult(text: "$text", '
      'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
      'isFinal: $isFinal)';
}

/// TTS synthesis result
class SynthesisResult {
  /// Audio samples (f32 normalized)
  final Float32List samples;

  /// Sample rate in Hz
  final int sampleRate;

  /// Duration in seconds
  final double duration;

  const SynthesisResult({
    required this.samples,
    required this.sampleRate,
    required this.duration,
  });
}

/// Voice style configuration
class VoiceStyle {
  /// Unique identifier
  final String id;

  /// Display name
  final String name;

  /// Description
  final String description;

  /// Speaking rate (0.5 - 2.0)
  final double rate;

  /// Pitch adjustment (-12 to +12 semitones)
  final double pitch;

  const VoiceStyle({
    required this.id,
    required this.name,
    required this.description,
    this.rate = 1.0,
    this.pitch = 0.0,
  });

  factory VoiceStyle.fromDart(audio_api.DartVoiceStyle style) {
    return VoiceStyle(
      id: style.id,
      name: style.name,
      description: style.description,
      rate: style.rate,
      pitch: style.pitch,
    );
  }
}

/// Audio visualizer data for waveform rendering
class AudioVisualizerData {
  /// RMS (Root Mean Square) amplitude level (0.0 - 1.0)
  final double rmsLevel;

  /// Peak amplitude level (0.0 - 1.0)
  final double peakLevel;

  /// Frequency bands for spectrum visualization (typically 32 bands)
  final List<double> frequencyBands;

  /// Whether voice is currently detected
  final bool voiceDetected;

  const AudioVisualizerData({
    required this.rmsLevel,
    required this.peakLevel,
    required this.frequencyBands,
    required this.voiceDetected,
  });

  /// Empty visualizer data
  static const empty = AudioVisualizerData(
    rmsLevel: 0.0,
    peakLevel: 0.0,
    frequencyBands: [],
    voiceDetected: false,
  );
}

/// Audio Neural Engine - Central service for audio intelligence
class AudioNeuralEngine {
  // Singleton instance
  static final _instance = AudioNeuralEngine._internal();
  factory AudioNeuralEngine() => _instance;
  AudioNeuralEngine._internal();

  // State management
  final _stateNotifier = ValueNotifier<AudioEngineState>(
    AudioEngineState.uninitialized,
  );
  final _vadStateNotifier = ValueNotifier<VadState>(VadState.silence);
  final _visualizerNotifier = ValueNotifier<AudioVisualizerData>(
    AudioVisualizerData.empty,
  );

  // Stream controllers for real-time data
  final _transcriptionController =
      StreamController<SpeechRecognitionResult>.broadcast();
  final _visualizerController =
      StreamController<AudioVisualizerData>.broadcast();
  final _speechProbabilityController = StreamController<double>.broadcast();
  final _vadController = StreamController<bool>.broadcast();

  // Internal state
  var _isInitialized = false;
  var _initializationFailed = false;
  String? _initializationError;
  var _recordingStartTime = 0.0;
  Timer? _processingTimer;

  // Configuration
  var _vadThreshold = 0.5;
  var _selectedVoiceId = 'default';
  var _speechRate = 1.0;

  /// Current engine state
  ValueListenable<AudioEngineState> get state => _stateNotifier;

  /// Current VAD state
  ValueListenable<VadState> get vadState => _vadStateNotifier;

  /// Current visualizer data
  ValueListenable<AudioVisualizerData> get visualizerData =>
      _visualizerNotifier;

  /// Stream of transcription results
  Stream<SpeechRecognitionResult> get transcriptionStream =>
      _transcriptionController.stream;

  /// Stream of visualizer data (60 FPS target)
  Stream<AudioVisualizerData> get visualizerStream =>
      _visualizerController.stream;

  /// Stream of speech probability values
  Stream<double> get speechProbabilityStream =>
      _speechProbabilityController.stream;

  /// Stream of VAD state (true = speech detected)
  Stream<bool> get vadStream => _vadController.stream;

  /// Whether the engine is initialized
  bool get isInitialized => _isInitialized;

  /// Whether initialization failed
  bool get initializationFailed => _initializationFailed;

  /// Error message if initialization failed
  String? get initializationError => _initializationError;

  /// Current VAD threshold
  double get vadThreshold => _vadThreshold;

  /// Selected voice ID
  String get selectedVoiceId => _selectedVoiceId;

  /// Speech rate
  double get speechRate => _speechRate;

  /// Initialize the audio neural engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_initializationFailed) return false;

    _stateNotifier.value = AudioEngineState.initializing;

    try {
      // Initialize the Rust audio library
      await _initializeRustLib();

      // Initialize all audio subsystems
      await audio_api.audioInitializeAll();

      _isInitialized = true;
      _stateNotifier.value = AudioEngineState.idle;
      debugPrint('AudioNeuralEngine: Initialized successfully');
      return true;
    } catch (e, stack) {
      _initializationFailed = true;
      _initializationError = e.toString();
      _stateNotifier.value = AudioEngineState.error;
      debugPrint('AudioNeuralEngine: Initialization failed: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  /// Initialize the Rust library with platform-specific handling
  Future<void> _initializeRustLib() async {
    try {
      if (Platform.isWindows) {
        // Try multiple locations for the DLL
        final possiblePaths = [
          'native_audio/target/release/kivixa_audio.dll',
          'kivixa_audio.dll',
          'rust_builder/windows/kivixa_audio.dll',
        ];

        ExternalLibrary? lib;
        for (final path in possiblePaths) {
          final file = File(path);
          if (file.existsSync()) {
            lib = ExternalLibrary.open(path);
            debugPrint('AudioNeuralEngine: Loaded library from $path');
            break;
          }
        }

        if (lib != null) {
          await AudioRustLib.init(externalLibrary: lib);
        } else {
          await AudioRustLib.init();
        }
      } else if (Platform.isAndroid) {
        // Android loads from jniLibs automatically
        await AudioRustLib.init();
      } else {
        await AudioRustLib.init();
      }
    } catch (e) {
      debugPrint('AudioNeuralEngine: Failed to load native library: $e');
      rethrow;
    }
  }

  /// Process raw audio bytes (PCM 16-bit LE)
  Future<void> processAudioBytes(Uint8List bytes) async {
    if (!_isInitialized) return;

    try {
      final result = await audio_api.processStreamingAudio(
        bytes: bytes.toList(),
        startTime: _recordingStartTime,
        forceTranscribe: false,
      );

      // Update VAD state
      _updateVadState(result.vad);

      // Update visualizer data
      _updateVisualizerFromVad(result.vad);

      // Emit speech probability
      _speechProbabilityController.add(result.vad.speechProbability);

      // Process transcription if available
      if (result.transcriptionAttempted && result.transcription != null) {
        _processTranscription(result.transcription!);
      }
    } catch (e) {
      debugPrint('AudioNeuralEngine: Error processing audio: $e');
    }
  }

  /// Process f32 audio samples
  Future<void> processAudioSamples(List<double> samples) async {
    if (!_isInitialized) return;

    try {
      // Write samples to buffer
      audio_api.audioBufferWriteSamples(samples: samples);

      // Process VAD
      final vadResult = audio_api.vadProcess(samples: samples);
      _updateVadState(vadResult);
      _updateVisualizerFromVad(vadResult);
      _speechProbabilityController.add(vadResult.speechProbability);

      // Check if we should transcribe
      if (vadResult.isSpeech && audio_api.audioBufferHasFullChunk()) {
        final transcription = await audio_api.sttProcessBuffer(
          startTime: _recordingStartTime,
        );
        _processTranscription(transcription);
      }
    } catch (e) {
      debugPrint('AudioNeuralEngine: Error processing samples: $e');
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    _stateNotifier.value = AudioEngineState.listening;
    _recordingStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Reset audio subsystems
    audio_api.audioBufferClear();
    audio_api.vadReset();
    audio_api.sttReset();
  }

  /// Stop listening
  Future<SpeechRecognitionResult?> stopListening() async {
    if (_stateNotifier.value != AudioEngineState.listening) return null;

    _stateNotifier.value = AudioEngineState.processing;

    try {
      // Force final transcription
      final transcription = await audio_api.sttProcessBuffer(
        startTime: _recordingStartTime,
      );

      _stateNotifier.value = AudioEngineState.idle;

      if (transcription.fullText.isNotEmpty) {
        return SpeechRecognitionResult(
          text: transcription.fullText,
          confidence: transcription.segments.isNotEmpty
              ? transcription.segments.first.confidence
              : 0.8,
          isFinal: true,
          startTime: 0.0,
          endTime: transcription.duration,
          language: transcription.language,
        );
      }
    } catch (e) {
      debugPrint('AudioNeuralEngine: Error stopping listening: $e');
      _stateNotifier.value = AudioEngineState.idle;
    }

    return null;
  }

  /// Synthesize text to speech
  Future<SynthesisResult?> synthesize(String text, {String? voiceId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    _stateNotifier.value = AudioEngineState.speaking;

    try {
      final audio_api.DartSynthesizedAudio result;

      if (voiceId != null) {
        result = await audio_api.ttsSynthesizeWithVoice(
          text: text,
          voiceId: voiceId,
        );
      } else {
        result = await audio_api.ttsSynthesize(text: text);
      }

      _stateNotifier.value = AudioEngineState.idle;

      return SynthesisResult(
        samples: result.samples,
        sampleRate: result.sampleRate,
        duration: result.duration,
      );
    } catch (e) {
      debugPrint('AudioNeuralEngine: Error synthesizing speech: $e');
      _stateNotifier.value = AudioEngineState.idle;
      return null;
    }
  }

  /// Synthesize text to PCM bytes (16-bit LE)
  Future<Uint8List?> synthesizeToBytes(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    _stateNotifier.value = AudioEngineState.speaking;

    try {
      final bytes = await audio_api.ttsSynthesizeToBytes(text: text);
      _stateNotifier.value = AudioEngineState.idle;
      return bytes;
    } catch (e) {
      debugPrint('AudioNeuralEngine: Error synthesizing to bytes: $e');
      _stateNotifier.value = AudioEngineState.idle;
      return null;
    }
  }

  /// Get available voices
  List<VoiceStyle> getAvailableVoices() {
    if (!_isInitialized) return [];

    try {
      return audio_api
          .ttsAvailableVoices()
          .map((v) => VoiceStyle.fromDart(v))
          .toList();
    } catch (e) {
      debugPrint('AudioNeuralEngine: Error getting voices: $e');
      return [];
    }
  }

  /// Set VAD threshold
  void setVadThreshold(double threshold) {
    _vadThreshold = threshold.clamp(0.0, 1.0);
    if (_isInitialized) {
      audio_api.vadSetThreshold(threshold: _vadThreshold);
    }
  }

  /// Set selected voice
  void setSelectedVoice(String voiceId) {
    _selectedVoiceId = voiceId;
  }

  /// Set speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 2.0);
  }

  /// Get engine version
  String getVersion() {
    if (!_isInitialized) return 'Not initialized';
    return audio_api.audioModuleVersion();
  }

  /// Health check
  bool healthCheck() {
    if (!_isInitialized) return false;
    return audio_api.audioModuleHealthCheck();
  }

  /// Reset all audio subsystems
  void reset() {
    if (_isInitialized) {
      audio_api.audioResetAll();
    }
    _stateNotifier.value = AudioEngineState.idle;
    _vadStateNotifier.value = VadState.silence;
    _visualizerNotifier.value = AudioVisualizerData.empty;
  }

  /// Dispose resources
  void dispose() {
    _processingTimer?.cancel();
    _transcriptionController.close();
    _visualizerController.close();
    _speechProbabilityController.close();
    _stateNotifier.dispose();
    _vadStateNotifier.dispose();
    _visualizerNotifier.dispose();
  }

  // Private helpers

  void _updateVadState(audio_api.DartVadResult result) {
    final vadState = switch (result.state) {
      0 => VadState.silence,
      1 => VadState.speechPending,
      2 => VadState.speech,
      3 => VadState.silencePending,
      _ => VadState.silence,
    };
    final previousState = _vadStateNotifier.value;
    _vadStateNotifier.value = vadState;

    // Emit speech boolean to vadStream
    final isSpeaking =
        vadState == VadState.speech || vadState == VadState.speechPending;
    final wasNotSpeaking =
        previousState == VadState.silence ||
        previousState == VadState.silencePending;
    if (isSpeaking != !wasNotSpeaking) {
      _vadController.add(isSpeaking);
    }
  }

  void _updateVisualizerFromVad(audio_api.DartVadResult result) {
    // Calculate RMS from speech probability (approximation)
    final rms = result.speechProbability * 0.8;

    _visualizerNotifier.value = AudioVisualizerData(
      rmsLevel: rms,
      peakLevel: rms * 1.2,
      frequencyBands: List.generate(32, (i) => rms * (1.0 - i / 64.0)),
      voiceDetected: result.isSpeech,
    );

    _visualizerController.add(_visualizerNotifier.value);
  }

  void _processTranscription(audio_api.DartTranscription transcription) {
    for (final segment in transcription.segments) {
      final result = SpeechRecognitionResult(
        text: segment.text,
        confidence: segment.confidence,
        isFinal: segment.isFinal,
        startTime: segment.startTime,
        endTime: segment.endTime,
        language: segment.language,
      );
      _transcriptionController.add(result);
    }
  }
}
