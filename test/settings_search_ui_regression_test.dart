import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings search UI regression', () {
    test('settings page contains compact search bar and section filtering', () {
      final source = File('lib/pages/home/settings.dart').readAsStringSync();

      expect(source, contains('Search settings'));
      expect(source, contains('_buildSettingsSearchBar(context)'));
      expect(source, contains('matchesSettingsQuery('));
      expect(source, contains('Notifications & Sound'));
    });
  });
}
