import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';

void main() {
  group('PlaybackState', () {
    test('should have all expected states', () {
      expect(PlaybackState.values.length, 4);
      expect(PlaybackState.stopped, isNotNull);
      expect(PlaybackState.loading, isNotNull);
      expect(PlaybackState.playing, isNotNull);
      expect(PlaybackState.paused, isNotNull);
    });
  });

  group('AudioPlaybackService', () {
    test('should be a singleton', () {
      final instance1 = AudioPlaybackService();
      final instance2 = AudioPlaybackService();
      expect(identical(instance1, instance2), true);
    });

    test('should start in stopped state', () {
      final service = AudioPlaybackService();
      expect(service.state, isNotNull);
      expect(service.state.value, PlaybackState.stopped);
    });

    test('should have position notifier', () {
      final service = AudioPlaybackService();
      expect(service.position, isNotNull);
      expect(service.position.value, Duration.zero);
    });

    test('should have duration notifier', () {
      final service = AudioPlaybackService();
      expect(service.duration, isNotNull);
      expect(service.duration.value, Duration.zero);
    });

    test('should have volume notifier with default 1.0', () {
      final service = AudioPlaybackService();
      expect(service.volume, isNotNull);
      expect(service.volume.value, 1.0);
    });

    test('should have speed notifier with default 1.0', () {
      final service = AudioPlaybackService();
      expect(service.speed, isNotNull);
      expect(service.speed.value, 1.0);
    });

    test('should have position stream', () {
      final service = AudioPlaybackService();
      expect(service.positionStream, isNotNull);
    });

    test('isPlaying should be false initially', () {
      final service = AudioPlaybackService();
      expect(service.isPlaying, false);
    });

    test('setVolume should clamp values', () {
      final service = AudioPlaybackService();

      service.setVolume(0.5);
      expect(service.volume.value, 0.5);

      service.setVolume(-1.0);
      expect(service.volume.value, 0.0);

      service.setVolume(2.0);
      expect(service.volume.value, 1.0);
    });

    test('setSpeed should clamp values', () {
      final service = AudioPlaybackService();

      service.setSpeed(1.5);
      expect(service.speed.value, 1.5);

      service.setSpeed(0.1);
      expect(service.speed.value, 0.5);

      service.setSpeed(3.0);
      expect(service.speed.value, 2.0);
    });

    test('pause should do nothing if not playing', () {
      final service = AudioPlaybackService();
      service.pause();
      expect(service.state.value, PlaybackState.stopped);
    });

    test('resume should do nothing if not paused', () {
      final service = AudioPlaybackService();
      service.resume();
      expect(service.state.value, PlaybackState.stopped);
    });

    test('stop should reset state', () {
      final service = AudioPlaybackService();
      service.stop();
      expect(service.state.value, PlaybackState.stopped);
      expect(service.position.value, Duration.zero);
    });
  });
}
