import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Settings advanced options regression', () {
    test(
      'advanced update toggles and logs button are removed from settings UI',
      () {
        final settings = File(
          'lib/pages/home/settings.dart',
        ).readAsStringSync();

        expect(
          settings,
          isNot(contains('t.settings.prefLabels.shouldCheckForUpdates')),
        );
        expect(
          settings,
          isNot(contains('t.settings.prefLabels.shouldAlwaysAlertForUpdates')),
        );
        expect(settings, isNot(contains('t.logs.viewLogs')));
      },
    );

    test('editor category is labeled Handwritten Note', () {
      final settings = File('lib/pages/home/settings.dart').readAsStringSync();
      expect(settings, contains("category: 'Handwritten Note'"));
    });
  });
}
