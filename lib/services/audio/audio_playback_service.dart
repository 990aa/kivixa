// Audio Playback Service
//
// Handles audio playback for synthesized speech and voice notes.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';

enum _PlaybackBackend { none, mediaKit, flutterTts }

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
  final _tts = FlutterTts();
  Player? _player;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;

  // Current playback info
  Float32List? _currentSamples;
  var _currentSampleRate = 24000;
  var _currentPosition = 0;
  var _backend = _PlaybackBackend.none;
  var _pausedBackend = _PlaybackBackend.none;
  var _ttsConfigured = false;
  String? _currentTempWavPath;
  String _lastSpokenText = '';
  DateTime? _ttsStartedAt;

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
    stop();

    _currentSamples = synthesis.samples;
    _currentSampleRate = synthesis.sampleRate;
    _currentPosition = 0;

    _durationNotifier.value = Duration(
      milliseconds: (synthesis.duration * 1000).round(),
    );
    _positionNotifier.value = Duration.zero;
    _positionController.add(Duration.zero);
    _stateNotifier.value = PlaybackState.loading;

    final pcmBytes = _floatSamplesToPcm16Bytes(synthesis.samples);

    try {
      await _playPcm16(
        pcmBytes,
        sampleRate: synthesis.sampleRate,
        channels: 1,
      );
      debugPrint('AudioPlaybackService: Playing ${synthesis.duration}s of audio');
    } catch (e) {
      debugPrint('AudioPlaybackService: Failed to play synthesis: $e');
      _stateNotifier.value = PlaybackState.stopped;
    }
  }

  /// Play raw PCM bytes
  Future<void> playBytes(Uint8List bytes, {int sampleRate = 24000}) async {
    stop();

    _stateNotifier.value = PlaybackState.loading;

    try {
      await _playPcm16(bytes, sampleRate: sampleRate, channels: 1);

      final durationSeconds = bytes.length / (sampleRate * 2);
      debugPrint('AudioPlaybackService: Playing ${durationSeconds}s of audio');
    } catch (e) {
      debugPrint('AudioPlaybackService: Failed to play raw audio: $e');
      _stateNotifier.value = PlaybackState.stopped;
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text, {String? voiceId}) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }

    _applyConfiguredAudioPreferences();
    _stateNotifier.value = PlaybackState.loading;
    _lastSpokenText = normalizedText;

    final engine = AudioNeuralEngine();
    await engine.initialize();
    final resolvedVoiceId = _resolveVoiceId(engine, voiceId);

    try {
      final synthesis = await engine.synthesize(
        normalizedText,
        voiceId: resolvedVoiceId,
      );

      if (synthesis != null && !_isMostlySilent(synthesis.samples)) {
        await playSynthesis(synthesis);
        return;
      }
    } catch (e) {
      debugPrint('AudioPlaybackService: Native synthesis failed, using fallback: $e');
    }

    try {
      await _speakWithPlatformTts(normalizedText, voiceId: resolvedVoiceId);
    } catch (e) {
      debugPrint('AudioPlaybackService: Failed to speak: $e');
      _stateNotifier.value = PlaybackState.stopped;
      _backend = _PlaybackBackend.none;
      _pausedBackend = _PlaybackBackend.none;
    }
  }

  Future<void> _playPcm16(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) async {
    await _ensurePlayerInitialized();

    _backend = _PlaybackBackend.mediaKit;
    _pausedBackend = _PlaybackBackend.none;

    final durationSeconds = (pcmBytes.length / (2 * channels)) / sampleRate;
    _durationNotifier.value = Duration(
      milliseconds: (durationSeconds * 1000).round(),
    );
    _positionNotifier.value = Duration.zero;
    _positionController.add(Duration.zero);

    final wavBytes = _buildWavFromPcm16(
      pcmBytes,
      sampleRate: sampleRate,
      channels: channels,
    );
    final wavFile = await _writeTemporaryWavFile(wavBytes);

    _deleteTemporaryWavFile(_currentTempWavPath);
    _currentTempWavPath = wavFile.path;

    await _player!.setRate(_speedNotifier.value);
    await _player!.setVolume(_volumeNotifier.value * 100.0);
    await _player!.open(Media(wavFile.path), play: true);
    _stateNotifier.value = PlaybackState.playing;
  }

  Future<void> _speakWithPlatformTts(String text, {String? voiceId}) async {
    await _ensureTtsConfigured();

    stop();
    _backend = _PlaybackBackend.flutterTts;
    _pausedBackend = _PlaybackBackend.none;
    _stateNotifier.value = PlaybackState.playing;
    _positionNotifier.value = Duration.zero;
    _positionController.add(Duration.zero);
    _durationNotifier.value = _estimateTtsDuration(text, _speedNotifier.value);
    _ttsStartedAt = DateTime.now();

    if (voiceId != null && voiceId.isNotEmpty) {
      try {
        await _tts.setVoice({'name': voiceId});
      } catch (e) {
        debugPrint('AudioPlaybackService: Voice selection warning: $e');
      }
    }

    await _tts.setVolume(_volumeNotifier.value);
    await _tts.setSpeechRate(_toFlutterTtsRate(_speedNotifier.value));
    await _tts.speak(text);
  }

  Future<void> _ensurePlayerInitialized() async {
    if (_player != null) {
      return;
    }

    _player = Player();

    _positionSubscription = _player!.stream.position.listen((position) {
      if (_backend != _PlaybackBackend.mediaKit) {
        return;
      }
      _positionNotifier.value = position;
      _positionController.add(position);
    });

    _durationSubscription = _player!.stream.duration.listen((duration) {
      if (_backend != _PlaybackBackend.mediaKit) {
        return;
      }
      _durationNotifier.value = duration;
    });

    _playingSubscription = _player!.stream.playing.listen((playing) {
      if (_backend != _PlaybackBackend.mediaKit) {
        return;
      }

      if (playing) {
        _stateNotifier.value = PlaybackState.playing;
        return;
      }

      if (_stateNotifier.value == PlaybackState.paused) {
        return;
      }

      if (_stateNotifier.value != PlaybackState.stopped) {
        _stateNotifier.value = PlaybackState.stopped;
        _positionNotifier.value = _durationNotifier.value;
        _positionController.add(_positionNotifier.value);
        _backend = _PlaybackBackend.none;
        _deleteTemporaryWavFile(_currentTempWavPath);
        _currentTempWavPath = null;
      }
    });
  }

  Future<void> _ensureTtsConfigured() async {
    if (_ttsConfigured) {
      return;
    }

    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Some platforms ignore await-speak-completion; handlers below still keep state coherent.
    }

    _tts.setStartHandler(() {
      if (_backend == _PlaybackBackend.flutterTts) {
        _stateNotifier.value = PlaybackState.playing;
        _ttsStartedAt ??= DateTime.now();
      }
    });

    _tts.setCompletionHandler(() {
      if (_backend == _PlaybackBackend.flutterTts) {
        if (_durationNotifier.value == Duration.zero && _ttsStartedAt != null) {
          _durationNotifier.value = DateTime.now().difference(_ttsStartedAt!);
        }
        _positionNotifier.value = _durationNotifier.value;
        _positionController.add(_positionNotifier.value);
        _stateNotifier.value = PlaybackState.stopped;
        _backend = _PlaybackBackend.none;
        _pausedBackend = _PlaybackBackend.none;
      }
    });

    _tts.setErrorHandler((message) {
      if (_backend == _PlaybackBackend.flutterTts) {
        debugPrint('AudioPlaybackService: Platform TTS error: $message');
        _stateNotifier.value = PlaybackState.stopped;
        _backend = _PlaybackBackend.none;
        _pausedBackend = _PlaybackBackend.none;
      }
    });

    _ttsConfigured = true;
  }

  /// Pause playback
  void pause() {
    if (_stateNotifier.value == PlaybackState.playing) {
      _pausedBackend = _backend;
      if (_backend == _PlaybackBackend.mediaKit && _player != null) {
        unawaited(_player!.pause());
      } else if (_backend == _PlaybackBackend.flutterTts) {
        unawaited(_tts.stop());
        _backend = _PlaybackBackend.none;
      }

      _stateNotifier.value = PlaybackState.paused;
      debugPrint('AudioPlaybackService: Paused');
    }
  }

  /// Resume playback
  void resume() {
    if (_stateNotifier.value == PlaybackState.paused) {
      if (_pausedBackend == _PlaybackBackend.mediaKit && _player != null) {
        _backend = _PlaybackBackend.mediaKit;
        unawaited(_player!.play());
        _stateNotifier.value = PlaybackState.playing;
      } else if (_pausedBackend == _PlaybackBackend.flutterTts &&
          _lastSpokenText.isNotEmpty) {
        unawaited(_speakWithPlatformTts(_lastSpokenText));
      } else {
        _stateNotifier.value = PlaybackState.stopped;
      }

      _stateNotifier.value = PlaybackState.playing;
      debugPrint('AudioPlaybackService: Resumed');
    }
  }

  /// Stop playback
  void stop() {
    final activeBackend = _backend;

    _stateNotifier.value = PlaybackState.stopped;
    _pausedBackend = _PlaybackBackend.none;
    _backend = _PlaybackBackend.none;

    if (activeBackend == _PlaybackBackend.mediaKit && _player != null) {
      unawaited(_player!.stop());
    } else if (activeBackend == _PlaybackBackend.flutterTts) {
      unawaited(_tts.stop());
    }

    _deleteTemporaryWavFile(_currentTempWavPath);
    _currentTempWavPath = null;
    _positionNotifier.value = Duration.zero;
    _positionController.add(Duration.zero);
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

    if (_backend == _PlaybackBackend.mediaKit && _player != null) {
      unawaited(_player!.seek(position));
    }

    _positionNotifier.value = position;
    _positionController.add(position);
    debugPrint('AudioPlaybackService: Seeked to ${position.inSeconds}s');
  }

  /// Set volume
  void setVolume(double volume) {
    _volumeNotifier.value = volume.clamp(0.0, 1.0);

    if (_backend == _PlaybackBackend.mediaKit && _player != null) {
      unawaited(_player!.setVolume(_volumeNotifier.value * 100.0));
    } else if (_backend == _PlaybackBackend.flutterTts) {
      unawaited(_tts.setVolume(_volumeNotifier.value));
    }
  }

  /// Set playback speed
  void setSpeed(double speed) {
    _speedNotifier.value = speed.clamp(0.5, 2.0);

    if (_backend == _PlaybackBackend.mediaKit && _player != null) {
      unawaited(_player!.setRate(_speedNotifier.value));
    } else if (_backend == _PlaybackBackend.flutterTts) {
      unawaited(_tts.setSpeechRate(_toFlutterTtsRate(_speedNotifier.value)));
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _positionSubscription = null;
    _durationSubscription = null;
    _playingSubscription = null;
    try {
      _player?.dispose();
    } catch (_) {
      // Ignore disposal issues during teardown.
    }
    _player = null;
    _positionController.close();
    _stateNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _volumeNotifier.dispose();
    _speedNotifier.dispose();
  }

  Uint8List _floatSamplesToPcm16Bytes(Float32List samples) {
    final bytes = Uint8List(samples.length * 2);
    final byteData = ByteData.sublistView(bytes);

    for (var i = 0; i < samples.length; i++) {
      final value = (samples[i].clamp(-1.0, 1.0) as double);
      final pcm = (value * 32767.0).round();
      byteData.setInt16(i * 2, pcm, Endian.little);
    }

    return bytes;
  }

  Uint8List _buildWavFromPcm16(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) {
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;
    final dataLength = pcmBytes.length;
    final fileLength = 36 + dataLength;

    final header = ByteData(44);
    _writeAscii(header, 0, 'RIFF');
    header.setUint32(4, fileLength, Endian.little);
    _writeAscii(header, 8, 'WAVE');
    _writeAscii(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little);
    _writeAscii(header, 36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    return Uint8List.fromList(<int>[...header.buffer.asUint8List(), ...pcmBytes]);
  }

  void _writeAscii(ByteData data, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  Future<File> _writeTemporaryWavFile(Uint8List wavBytes) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'kivixa_tts_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(wavBytes, flush: true);
    return file;
  }

  void _deleteTemporaryWavFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    unawaited(
      file.delete().catchError((_) {
        // Ignore cleanup failures for temporary files.
      }),
    );
  }

  bool _isMostlySilent(Float32List samples) {
    if (samples.isEmpty) {
      return true;
    }

    var peak = 0.0;
    for (final sample in samples) {
      final magnitude = sample.abs();
      if (magnitude > peak) {
        peak = magnitude;
      }
    }
    return peak < 0.0005;
  }

  Duration _estimateTtsDuration(String text, double speed) {
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
    final wordsPerMinute = 170.0 * speed.clamp(0.5, 2.0);
    final minutes = wordCount / wordsPerMinute;
    return Duration(milliseconds: (minutes * 60 * 1000).round());
  }

  double _toFlutterTtsRate(double speed) {
    // flutter_tts expects a platform-specific normalized rate; 0.0-1.0 is broadly safe.
    return (speed / 2.0).clamp(0.2, 1.0);
  }

  void _applyConfiguredAudioPreferences() {
    final preferredSpeed = _readAudioPref(
      () => stows.audioTtsSpeed.value,
      _speedNotifier.value,
    );
    setSpeed(preferredSpeed);
  }

  String? _resolveVoiceId(AudioNeuralEngine engine, String? explicitVoiceId) {
    if (explicitVoiceId != null && explicitVoiceId.trim().isNotEmpty) {
      return explicitVoiceId.trim();
    }

    final voices = engine.getAvailableVoices();
    if (voices.isEmpty) {
      return null;
    }

    final profile = _readAudioPref(() => stows.audioVoiceProfile.value, 0);
    final customVoiceId = _readAudioPref(() => stows.audioCustomVoiceId.value, null);

    if (profile == 2 && customVoiceId != null && customVoiceId.isNotEmpty) {
      if (voices.any((voice) => voice.id == customVoiceId)) {
        return customVoiceId;
      }
    }

    bool isMaleVoice(VoiceStyle voice) {
      final id = voice.id.toLowerCase();
      final name = voice.name.toLowerCase();
      final malePattern = RegExp(r'(^|[^a-z])male([^a-z]|$)');
      return id.startsWith('am_') ||
          id.startsWith('bm_') ||
          malePattern.hasMatch(id) ||
          malePattern.hasMatch(name);
    }

    bool isFemaleVoice(VoiceStyle voice) {
      final id = voice.id.toLowerCase();
      final name = voice.name.toLowerCase();
      final femalePattern = RegExp(r'(^|[^a-z])female([^a-z]|$)');
      return id.startsWith('af_') ||
          id.startsWith('bf_') ||
          femalePattern.hasMatch(id) ||
          femalePattern.hasMatch(name);
    }

    final preferred = profile == 1
        ? voices.where(isMaleVoice)
        : voices.where(isFemaleVoice);

    if (preferred.isNotEmpty) {
      return preferred.first.id;
    }

    return voices.first.id;
  }

  T _readAudioPref<T>(T Function() reader, T fallback) {
    try {
      return reader();
    } catch (_) {
      return fallback;
    }
  }
}
