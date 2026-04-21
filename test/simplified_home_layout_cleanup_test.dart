import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Simplified home layout cleanup', () {
    test(
      'startup cleanup removes deprecated simplifiedHomeLayout preference',
      () async {
        SharedPreferences.setMockInitialValues({
          'simplifiedHomeLayout': true,
          'keepMe': 'still-here',
        });

        await Stows.removeDeprecatedPreferences();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('simplifiedHomeLayout'), isFalse);
        expect(prefs.getString('keepMe'), 'still-here');
      },
    );

    test('settings and preference backend no longer expose the toggle', () {
      final settings = File('lib/pages/home/settings.dart').readAsStringSync();
      final prefs = File('lib/data/prefs.dart').readAsStringSync();
      final strings = File('lib/i18n/strings.g.dart').readAsStringSync();

      expect(settings, isNot(contains('prefLabels.simplifiedHomeLayout')));
      expect(
        settings,
        isNot(contains('prefDescriptions.simplifiedHomeLayout')),
      );
      expect(settings, isNot(contains('stows.simplifiedHomeLayout')));

      expect(prefs, isNot(contains('final simplifiedHomeLayout = PlainStow')));
      expect(strings, isNot(contains('String get simplifiedHomeLayout')));
    });

    test(
      'home list always uses masonry layout (equivalent to setting OFF)',
      () {
        final masonry = File(
          'lib/components/home/masonry_files.dart',
        ).readAsStringSync();

        expect(masonry, contains('SliverMasonryGrid.count('));
        expect(masonry, isNot(contains('SliverGrid.builder(')));
        expect(masonry, isNot(contains('stows.simplifiedHomeLayout')));
      },
    );
  });
}
