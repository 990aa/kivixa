import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/settings/settings_search_matcher.dart';

void main() {
  group('settings search matcher', () {
    test('empty query always matches', () {
      final matched = matchesSettingsQuery(
        query: '   ',
        category: 'General',
        description: 'Theme and layout settings',
        keywords: const ['theme', 'layout'],
      );

      expect(matched, isTrue);
    });

    test('matches by category name (case-insensitive)', () {
      final matched = matchesSettingsQuery(
        query: 'productivity timer',
        category: 'Productivity Timer',
      );

      expect(matched, isTrue);
    });

    test('matches by keywords', () {
      final matched = matchesSettingsQuery(
        query: 'lead time',
        category: 'Notifications',
        keywords: const ['calendar', 'lead time', 'sound'],
      );

      expect(matched, isTrue);
    });

    test('matches by description text', () {
      final matched = matchesSettingsQuery(
        query: 'speech-to-text',
        category: 'Audio Intelligence',
        description: 'Speech-to-text and text-to-speech controls',
      );

      expect(matched, isTrue);
    });

    test('returns false when query is unrelated', () {
      final matched = matchesSettingsQuery(
        query: 'vpn proxy',
        category: 'General',
        description: 'Theme and layout settings',
        keywords: const ['theme', 'layout'],
      );

      expect(matched, isFalse);
    });
  });
}
