import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Asset cleanup regression', () {
    test('pen modal points to existing svg assets', () {
      final content = File(
        'lib/components/toolbar/pen_modal.dart',
      ).readAsStringSync();

      expect(content, contains("'assets/images/fountain.svg'"));
      expect(content, contains("'assets/images/pen.svg'"));
      expect(content, isNot(contains('scribble_fountain.svg')));
      expect(content, isNot(contains('scribble_ballpoint.svg')));
    });

    test('browse and recent pages no longer use home background svg', () {
      final browse = File('lib/pages/home/browse.dart').readAsStringSync();
      final recent = File(
        'lib/pages/home/recent_notes.dart',
      ).readAsStringSync();

      expect(browse, isNot(contains('home_page.svg')));
      expect(recent, isNot(contains('home_page.svg')));
    });

    test('removed assets are absent and required image assets remain', () {
      expect(File('assets/images/home_page.svg').existsSync(), isFalse);
      expect(File('assets/icon/icon.bmp').existsSync(), isFalse);

      expect(File('assets/images/fountain.svg').existsSync(), isTrue);
      expect(File('assets/images/pen.svg').existsSync(), isTrue);
    });
  });

  group('Font setting cleanup regression', () {
    test(
      'hyperlegible setting is removed from settings, prefs and theme wiring',
      () {
        final settings = File(
          'lib/pages/home/settings.dart',
        ).readAsStringSync();
        final prefs = File('lib/data/prefs.dart').readAsStringSync();
        final theme = File(
          'lib/components/theming/kivixa_theme.dart',
        ).readAsStringSync();
        final dynamicApp = File(
          'lib/components/theming/dynamic_material_app.dart',
        ).readAsStringSync();

        expect(settings, isNot(contains('hyperlegibleFont')));
        expect(prefs, isNot(contains('hyperlegibleFont')));
        expect(theme, isNot(contains('AtkinsonHyperlegibleNext')));
        expect(dynamicApp, isNot(contains('hyperlegibleFont')));
      },
    );

    test('pubspec no longer declares Atkinson Hyperlegible assets', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, isNot(contains('Atkinson_Hyperlegible_Next')));
      expect(pubspec, isNot(contains('family: AtkinsonHyperlegibleNext')));
    });
  });
}
