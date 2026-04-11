import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/audio_settings_page.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    stows.audioVoiceProfile.value = stows.audioVoiceProfile.defaultValue;
    stows.audioCustomVoiceId.value = stows.audioCustomVoiceId.defaultValue;
  });

  Widget wrapWidget(Widget child) {
    return MaterialApp(home: child);
  }

  VoiceStyle voiceFactory(String id, String name, String description) {
    return VoiceStyle(id: id, name: name, description: description);
  }

  testWidgets(
    'voices tab renders backend voices and persists preferred voice',
    (tester) async {
      final voices = <VoiceStyle>[
        voiceFactory(
          'af_heart',
          'Heart',
          'Warm and expressive American female voice.',
        ),
        voiceFactory(
          'am_adam',
          'Adam',
          'Calm and authoritative American male voice.',
        ),
      ];

      await tester.pumpWidget(
        wrapWidget(
          AudioSettingsPage(
            voiceLoader: () async => voices,
            voicePreviewHandler: (text, voiceId) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voices'));
      await tester.pumpAndSettle();

      expect(find.text('Heart'), findsOneWidget);
      expect(find.text('Adam'), findsOneWidget);

      await tester.tap(find.byKey(const Key('set-voice-am_adam')));
      await tester.pumpAndSettle();

      expect(stows.audioVoiceProfile.value, 2);
      expect(stows.audioCustomVoiceId.value, 'am_adam');
      expect(find.text('Preferred voice: am_adam'), findsOneWidget);
    },
  );

  testWidgets('voice preview button invokes provided preview handler', (
    tester,
  ) async {
    final voices = <VoiceStyle>[
      voiceFactory(
        'af_heart',
        'Heart',
        'Warm and expressive American female voice.',
      ),
    ];
    var previewText = '';
    var previewVoiceId = '';

    await tester.pumpWidget(
      wrapWidget(
        AudioSettingsPage(
          voiceLoader: () async => voices,
          voicePreviewHandler: (text, voiceId) async {
            previewText = text;
            previewVoiceId = voiceId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voices'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('preview-voice-af_heart')));
    await tester.pumpAndSettle();

    expect(previewVoiceId, 'af_heart');
    expect(previewText, contains('punctuation'));
  });
}
