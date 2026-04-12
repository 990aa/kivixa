import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/voice_preference_utils.dart';

void main() {
  VoiceStyle voice(String id, String name, String description) {
    return VoiceStyle(id: id, name: name, description: description);
  }

  group('voice classification', () {
    test('identifies female and male character voices by id patterns', () {
      final heart = voice('af_heart', 'Heart', 'Warm female voice');
      final adam = voice('am_adam', 'Adam', 'Calm male voice');

      expect(isFemaleVoice(heart), isTrue);
      expect(isMaleVoice(heart), isFalse);
      expect(isMaleVoice(adam), isTrue);
      expect(isFemaleVoice(adam), isFalse);
    });

    test('falls back to semantic name matching for classification', () {
      final female = voice('voice_a', 'Olivia', 'Studio female narration');
      final male = voice('voice_b', 'James', 'Studio male narration');

      expect(isFemaleVoice(female), isTrue);
      expect(isMaleVoice(male), isTrue);
    });

    test('infers locale from Kokoro-style voice id prefixes', () {
      expect(inferVoiceLocaleFromId('af_heart'), 'en-US');
      expect(inferVoiceLocaleFromId('bm_george'), 'en-GB');
      expect(inferVoiceLocaleFromId('custom_voice'), isNull);
    });
  });

  group('selectPreferredVoiceId', () {
    final voices = <VoiceStyle>[
      voice('af_heart', 'Heart', 'Warm female voice'),
      voice('am_adam', 'Adam', 'Calm male voice'),
      voice('bf_emma', 'Emma', 'British female voice'),
    ];

    test('prefers female profile voices', () {
      final selected = selectPreferredVoiceId(voices, AudioVoiceProfile.female);
      expect(selected, 'af_heart');
    });

    test('prefers male profile voices', () {
      final selected = selectPreferredVoiceId(voices, AudioVoiceProfile.male);
      expect(selected, 'am_adam');
    });

    test('honors explicit custom voice when present', () {
      final selected = selectPreferredVoiceId(
        voices,
        AudioVoiceProfile.custom,
        customVoiceId: 'bf_emma',
      );
      expect(selected, 'bf_emma');
    });

    test('falls back to first voice when custom id is missing', () {
      final selected = selectPreferredVoiceId(
        voices,
        AudioVoiceProfile.custom,
        customVoiceId: 'missing',
      );
      expect(selected, 'af_heart');
    });
  });

  group('audioVoiceProfileFromPref', () {
    test('maps integer preferences to enum values', () {
      expect(audioVoiceProfileFromPref(0), AudioVoiceProfile.female);
      expect(audioVoiceProfileFromPref(1), AudioVoiceProfile.male);
      expect(audioVoiceProfileFromPref(2), AudioVoiceProfile.custom);
      expect(audioVoiceProfileFromPref(99), AudioVoiceProfile.custom);
    });
  });
}
