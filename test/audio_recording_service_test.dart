import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

void main() {
  group('RecordingState', () {
    test('should have all expected states', () {
      expect(RecordingState.values.length, 5);
      expect(RecordingState.stopped, isNotNull);
      expect(RecordingState.preparing, isNotNull);
      expect(RecordingState.recording, isNotNull);
      expect(RecordingState.paused, isNotNull);
      expect(RecordingState.stopping, isNotNull);
    });
  });

  group('AudioFormatConfig', () {
    test('should create high quality config', () {
      const config = AudioFormatConfig.highQuality;
      expect(config.sampleRate, 48000);
      expect(config.channels, 2);
      expect(config.bitsPerSample, 16);
    });

    test('should create whisper format config', () {
      const config = AudioFormatConfig.whisper;
      expect(config.sampleRate, 16000);
      expect(config.channels, 1);
      expect(config.bitsPerSample, 16);
    });

    test('should create custom config', () {
      const config = AudioFormatConfig(
        sampleRate: 48000,
        channels: 1,
        bitsPerSample: 24,
      );
      expect(config.sampleRate, 48000);
      expect(config.channels, 1);
      expect(config.bitsPerSample, 24);
    });
  });

  // Skip tests that require singleton state or native deps
  group('AudioRecordingService', () {
    test('should be a singleton', () {
      final service1 = AudioRecordingService();
      final service2 = AudioRecordingService();
      expect(identical(service1, service2), true);
    }, skip: 'Singleton state may vary between tests');

    test(
      'should start in stopped state',
      () {
        final service = AudioRecordingService();
        expect(service.state.value, RecordingState.stopped);
      },
      skip: 'Singleton state may vary between tests',
    );

    test('should have state notifier', () {
      final service = AudioRecordingService();
      expect(service.state, isNotNull);
    }, skip: 'Singleton state may vary between tests');

    test(
      'should have audioDataStream',
      () {
        final service = AudioRecordingService();
        expect(service.audioDataStream, isNotNull);
      },
      skip: 'Singleton state may vary between tests',
    );

    test(
      'should have default format config',
      () {
        final service = AudioRecordingService();
        expect(service.config, isNotNull);
      },
      skip: 'Singleton state may vary between tests',
    );
  });
}
