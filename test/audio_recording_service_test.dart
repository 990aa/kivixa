import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, (MethodCall call) async {
          switch (call.method) {
            case 'create':
              return null;
            case 'hasPermission':
              return true;
            default:
              return null;
          }
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, null);
  });

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

  group('AudioRecordingService', () {
    test('should be a singleton', () {
      final service1 = AudioRecordingService();
      final service2 = AudioRecordingService();
      expect(identical(service1, service2), true);
    });

    test('should expose a valid recording state', () {
      final service = AudioRecordingService();
      expect(RecordingState.values, contains(service.state.value));
    });

    test('should have state notifier', () {
      final service = AudioRecordingService();
      expect(service.state, isNotNull);
    });

    test('should have audioDataStream', () {
      final service = AudioRecordingService();
      expect(service.audioDataStream, isNotNull);
    });

    test('should have default format config', () {
      final service = AudioRecordingService();
      expect(service.config, isNotNull);
    });
  });
}
