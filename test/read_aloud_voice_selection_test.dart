import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/read_aloud.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';

void main() {
  VoiceStyle voice(String id, String name) {
    return VoiceStyle(id: id, name: name, description: 'voice $name');
  }

  group('selectPreferredVoiceId', () {
    test('returns null when no voices are available', () {
      final selected = selectPreferredVoiceId(
        const <VoiceStyle>[],
        AudioVoiceProfile.female,
      );

      expect(selected, isNull);
    });

    test('prefers female voices for female profile', () {
      final voices = <VoiceStyle>[
        voice('am_adam', 'Adam Male'),
        voice('af_heart', 'Heart Female'),
      ];

      final selected = selectPreferredVoiceId(voices, AudioVoiceProfile.female);

      expect(selected, 'af_heart');
    });

    test('prefers male voices for male profile', () {
      final voices = <VoiceStyle>[
        voice('af_sky', 'Sky Female'),
        voice('bm_george', 'George Male'),
      ];

      final selected = selectPreferredVoiceId(voices, AudioVoiceProfile.male);

      expect(selected, 'bm_george');
    });

    test('uses custom voice when it exists', () {
      final voices = <VoiceStyle>[
        voice('af_heart', 'Heart Female'),
        voice('custom_voice', 'Custom Voice'),
      ];

      final selected = selectPreferredVoiceId(
        voices,
        AudioVoiceProfile.custom,
        customVoiceId: 'custom_voice',
      );

      expect(selected, 'custom_voice');
    });

    test('falls back to first voice when profile match is unavailable', () {
      final voices = <VoiceStyle>[
        voice('neutral', 'Neutral'),
        voice('voice2', 'Other'),
      ];

      final selected = selectPreferredVoiceId(voices, AudioVoiceProfile.male);

      expect(selected, 'neutral');
    });
  });

  group('audioVoiceProfileFromPref', () {
    test('maps known values to voice profiles', () {
      expect(audioVoiceProfileFromPref(0), AudioVoiceProfile.female);
      expect(audioVoiceProfileFromPref(1), AudioVoiceProfile.male);
      expect(audioVoiceProfileFromPref(2), AudioVoiceProfile.custom);
    });

    test('maps unknown values to custom', () {
      expect(audioVoiceProfileFromPref(99), AudioVoiceProfile.custom);
    });
  });
}
