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

    test(
      'welcome, no-files, and logs no longer reference missing svg assets',
      () {
        final welcome = File(
          'lib/components/home/welcome.dart',
        ).readAsStringSync();
        final noFiles = File(
          'lib/components/home/no_files.dart',
        ).readAsStringSync();
        final logs = File('lib/pages/logs.dart').readAsStringSync();

        expect(welcome, isNot(contains('undraw_learning_sketching_nd4f.svg')));
        expect(noFiles, isNot(contains('undraw_researching_re_fuod.svg')));
        expect(logs, isNot(contains('undraw_detailed_analysis_re_tk6j.svg')));
      },
    );

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

    test('Neucha font is fully removed and handwriting defaults to Dekko', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final main = File('lib/main.dart').readAsStringSync();
      final fallbacks = File(
        'lib/components/theming/font_fallbacks.dart',
      ).readAsStringSync();
      final innerCanvas = File(
        'lib/components/canvas/inner_canvas.dart',
      ).readAsStringSync();

      expect(pubspec, isNot(contains('family: Neucha')));
      expect(pubspec, isNot(contains('assets/google_fonts/Neucha')));
      expect(main, isNot(contains('assets/google_fonts/Neucha/OFL.txt')));
      expect(fallbacks, isNot(contains("'Neucha'")));
      expect(innerCanvas, contains("fontFamily: 'Dekko'"));
      expect(
        File('assets/google_fonts/Neucha/Neucha-Regular.ttf').existsSync(),
        isFalse,
      );
      expect(File('assets/google_fonts/Neucha/OFL.txt').existsSync(), isFalse);
    });
  });
}
