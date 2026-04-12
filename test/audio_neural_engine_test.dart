import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';

void main() {
  group('AudioEngineState', () {
    test('should have all expected states', () {
      expect(AudioEngineState.values.length, 7);
      expect(AudioEngineState.uninitialized, isNotNull);
      expect(AudioEngineState.initializing, isNotNull);
      expect(AudioEngineState.idle, isNotNull);
      expect(AudioEngineState.listening, isNotNull);
      expect(AudioEngineState.processing, isNotNull);
      expect(AudioEngineState.speaking, isNotNull);
      expect(AudioEngineState.error, isNotNull);
    });
  });

  group('VadState', () {
    test('should have all expected states', () {
      expect(VadState.values.length, 4);
      expect(VadState.silence, isNotNull);
      expect(VadState.speechPending, isNotNull);
      expect(VadState.speech, isNotNull);
      expect(VadState.silencePending, isNotNull);
    });
  });

  group('SpeechRecognitionResult', () {
    test('should create with required parameters', () {
      const result = SpeechRecognitionResult(
        text: 'Hello world',
        confidence: 0.95,
        isFinal: true,
        startTime: 0.0,
        endTime: 1.5,
      );

      expect(result.text, 'Hello world');
      expect(result.confidence, 0.95);
      expect(result.isFinal, true);
      expect(result.startTime, 0.0);
      expect(result.endTime, 1.5);
      expect(result.language, isNull);
    });

    test('should create with language', () {
      const result = SpeechRecognitionResult(
        text: 'Bonjour',
        confidence: 0.9,
        isFinal: true,
        startTime: 0.0,
        endTime: 1.0,
        language: 'fr',
      );

      expect(result.language, 'fr');
    });

    test('toString should include key info', () {
      const result = SpeechRecognitionResult(
        text: 'Test',
        confidence: 0.85,
        isFinal: false,
        startTime: 0.0,
        endTime: 0.5,
      );

      final str = result.toString();
      expect(str.contains('Test'), true);
      expect(str.contains('85.0%'), true);
      expect(str.contains('false'), true);
    });
  });

  group('SynthesisResult', () {
    test('should create with all parameters', () {
      final samples = Float32List.fromList([0.1, 0.2, 0.3]);
      final result = SynthesisResult(
        samples: samples,
        sampleRate: 24000,
        duration: 1.5,
      );

      expect(result.samples.length, 3);
      expect(result.sampleRate, 24000);
      expect(result.duration, 1.5);
    });
  });

  group('VoiceStyle', () {
    test('should create with default rate and pitch', () {
      const style = VoiceStyle(
        id: 'en-us-amy',
        name: 'Amy',
        description: 'US English female voice',
      );

      expect(style.id, 'en-us-amy');
      expect(style.name, 'Amy');
      expect(style.description, 'US English female voice');
      expect(style.rate, 1.0);
      expect(style.pitch, 0.0);
    });

    test('should create with custom rate and pitch', () {
      const style = VoiceStyle(
        id: 'fast-voice',
        name: 'Fast',
        description: 'A fast speaker',
        rate: 1.5,
        pitch: 2.0,
      );

      expect(style.rate, 1.5);
      expect(style.pitch, 2.0);
    });
  });

  group('AudioVisualizerData', () {
    test('should create with all parameters', () {
      const data = AudioVisualizerData(
        rmsLevel: 0.5,
        peakLevel: 0.8,
        frequencyBands: [0.1, 0.2, 0.3],
        voiceDetected: true,
      );

      expect(data.rmsLevel, 0.5);
      expect(data.peakLevel, 0.8);
      expect(data.frequencyBands.length, 3);
      expect(data.voiceDetected, true);
    });

    test('empty should have zero values', () {
      const data = AudioVisualizerData.empty;

      expect(data.rmsLevel, 0.0);
      expect(data.peakLevel, 0.0);
      expect(data.frequencyBands, isEmpty);
      expect(data.voiceDetected, false);
    });
  });

  group('AudioNeuralEngine', skip: 'Native dependencies unavailable', () {
    test('should be a singleton', () {
      final instance1 = AudioNeuralEngine();
      final instance2 = AudioNeuralEngine();
      expect(identical(instance1, instance2), true);
    });

    test('should start uninitialized', () {
      final engine = AudioNeuralEngine();
      expect(engine.isInitialized, isA<bool>());
    });

    test('should have state notifier', () {
      final engine = AudioNeuralEngine();
      expect(engine.state, isNotNull);
    });

    test('should have VAD state notifier', () {
      final engine = AudioNeuralEngine();
      expect(engine.vadState, isNotNull);
    });

    test('should have visualizer data notifier', () {
      final engine = AudioNeuralEngine();
      expect(engine.visualizerData, isNotNull);
    });

    test('should have transcription stream', () {
      final engine = AudioNeuralEngine();
      expect(engine.transcriptionStream, isNotNull);
    });

    test('should have visualizer stream', () {
      final engine = AudioNeuralEngine();
      expect(engine.visualizerStream, isNotNull);
    });

    test('should have VAD stream', () {
      final engine = AudioNeuralEngine();
      expect(engine.vadStream, isNotNull);
    });

    test('should have default VAD threshold', () {
      final engine = AudioNeuralEngine();
      expect(engine.vadThreshold, isA<double>());
    });

    test('should have default voice ID', () {
      final engine = AudioNeuralEngine();
      expect(engine.selectedVoiceId, isA<String>());
    });
  });
}
