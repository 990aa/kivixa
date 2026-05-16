import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Settings UI Restructure', () {
    test('Security section is moved to after General', () {
      final settingsFile = File(
        'lib/pages/home/settings.dart',
      ).readAsStringSync();

      // Find the position of General section and Security section
      final generalPos = settingsFile.indexOf('if (showGeneral) ...[');
      final securityPos = settingsFile.indexOf('if (showSecurity) ...[');
      final writingPos = settingsFile.indexOf('if (showWriting) ...[');

      // Security should appear before Writing (and after General)
      expect(
        generalPos < securityPos,
        isTrue,
        reason: 'General section should appear before Security',
      );
      expect(
        securityPos < writingPos,
        isTrue,
        reason:
            'Security section should appear before Writing/Handwritten sections',
      );
    });

    test(
      'Handwritten Settings section merges Writing, Handwritten Note, and Performance',
      () {
        final settingsFile = File(
          'lib/pages/home/settings.dart',
        ).readAsStringSync();

        // Check that the merged section title exists
        expect(
          settingsFile,
          contains("'Handwritten Settings'"),
          reason: 'Should have Handwritten Settings title',
        );

        // Verify that Writing, Handwritten, and Performance don't have their own section subtitles
        final writingStart = settingsFile.indexOf('if (showWriting) ...[');
        final writingSubtitleSection = settingsFile.substring(
          writingStart,
          writingStart + 300,
        );
        expect(
          writingSubtitleSection,
          isNot(
            contains(
              'SettingsSubtitle(subtitle: t.settings.prefCategories.writing)',
            ),
          ),
          reason:
              'Writing section should not have its own subtitle after merge',
        );

        final handwrittenStart = settingsFile.indexOf(
          'if (showHandwritten) ...[',
        );
        final handwrittenSubtitleSection = settingsFile.substring(
          handwrittenStart,
          handwrittenStart + 500,
        );
        expect(
          handwrittenSubtitleSection,
          isNot(
            contains("const SettingsSubtitle(subtitle: 'Handwritten Note')"),
          ),
          reason:
              'Handwritten Note section should not have its own subtitle after merge',
        );

        final performanceStart = settingsFile.indexOf(
          'if (showPerformance) ...[',
        );
        final performanceSubtitleSection = settingsFile.substring(
          performanceStart,
          performanceStart + 300,
        );
        expect(
          performanceSubtitleSection,
          isNot(
            contains(
              'SettingsSubtitle(\n                    subtitle: t.settings.prefCategories.performance,',
            ),
          ),
          reason:
              'Performance section should not have its own subtitle after merge',
        );
      },
    );

    test('Writing settings appear before Handwritten settings', () {
      final settingsFile = File(
        'lib/pages/home/settings.dart',
      ).readAsStringSync();

      final writingPos = settingsFile.indexOf('if (showWriting) ...[');
      final handwrittenPos = settingsFile.indexOf('if (showHandwritten) ...[');

      expect(
        writingPos < handwrittenPos,
        isTrue,
        reason:
            'Writing settings should appear before Handwritten settings within merged section',
      );
    });

    test('Handwritten settings appear before Performance settings', () {
      final settingsFile = File(
        'lib/pages/home/settings.dart',
      ).readAsStringSync();

      final handwrittenPos = settingsFile.indexOf('if (showHandwritten) ...[');
      final performancePos = settingsFile.indexOf('if (showPerformance) ...[');

      expect(
        handwrittenPos < performancePos,
        isTrue,
        reason:
            'Handwritten settings should appear before Performance settings within merged section',
      );
    });

    test(
      'Open Kivixa Folder button is moved from Advanced to Data Management',
      () {
        final settingsFile = File(
          'lib/pages/home/settings.dart',
        ).readAsStringSync();

        // Find Advanced section
        final advancedStart = settingsFile.indexOf('if (showAdvanced) ...[');
        final advancedEnd = settingsFile.indexOf('if (showExtensions) ...[');
        final advancedSection = settingsFile.substring(
          advancedStart,
          advancedEnd,
        );

        // Advanced section should not contain openDataDir
        expect(
          advancedSection,
          isNot(contains('t.settings.openDataDir')),
          reason: 'Open Kivixa Folder button should not be in Advanced section',
        );

        // Find Data Management section
        final dataManagementStart = settingsFile.indexOf(
          'if (showDataManagement) ...[',
        );
        final dataManagementEnd = settingsFile.length;
        final dataManagementSection = settingsFile.substring(
          dataManagementStart,
          dataManagementEnd,
        );

        // Data Management section should contain openDataDir for non-Android
        expect(
          dataManagementSection,
          contains('t.settings.openDataDir'),
          reason:
              'Open Kivixa Folder button should be in Data Management section',
        );

        // Verify it's only shown on Windows/Linux/macOS
        expect(
          dataManagementSection,
          contains('if (Platform.isWindows ||'),
          reason:
              'openDataDir should be conditionally shown for desktop platforms',
        );
      },
    );

    test('Advanced section only contains Android-specific content', () {
      final settingsFile = File(
        'lib/pages/home/settings.dart',
      ).readAsStringSync();

      final advancedStart = settingsFile.indexOf('if (showAdvanced) ...[');
      final advancedEnd = settingsFile.indexOf('if (showExtensions) ...[');
      final advancedSection = settingsFile.substring(
        advancedStart,
        advancedEnd,
      );

      // Advanced section should contain Android-specific customDataDir
      expect(
        advancedSection,
        contains('Platform.isAndroid'),
        reason: 'Advanced section should be Android-specific after restructure',
      );

      // Advanced should NOT have its own section title
      expect(
        advancedSection,
        isNot(
          contains(
            'SettingsSubtitle(\n                    subtitle: t.settings.prefCategories.advanced',
          ),
        ),
        reason: 'Advanced section title should be removed',
      );
    });

    test(
      'Settings layout order is correct: General -> Security -> Handwritten Settings',
      () {
        final settingsFile = File(
          'lib/pages/home/settings.dart',
        ).readAsStringSync();

        final generalPos = settingsFile.indexOf('if (showGeneral) ...[');
        final securityPos = settingsFile.indexOf('if (showSecurity) ...[');
        final handwrittenSettingsPos = settingsFile.indexOf(
          'if (showWriting || showHandwritten || showPerformance) ...[',
        );

        expect(generalPos < securityPos, isTrue);
        expect(securityPos < handwrittenSettingsPos, isTrue);
      },
    );

    test('showAdvanced flag is platform-gated to Android only', () {
      final settingsFile = File(
        'lib/pages/home/settings.dart',
      ).readAsStringSync();

      // Find the showAdvanced variable definition
      final showAdvancedDef = settingsFile.indexOf('final showAdvanced =');
      final showAdvancedEnd = settingsFile.indexOf(';', showAdvancedDef);
      final showAdvancedLine = settingsFile.substring(
        showAdvancedDef,
        showAdvancedEnd + 1,
      );

      expect(
        showAdvancedLine,
        contains('Platform.isAndroid'),
        reason: 'showAdvanced should be gated to Android platform only',
      );
    });
  });

  group('Font setting cleanup verification', () {
    test('Atkinson Hyperlegible font is fully removed from settings', () {
      final settings = File('lib/pages/home/settings.dart').readAsStringSync();

      expect(
        settings,
        isNot(contains('hyperlegibleFont')),
        reason:
            'Atkinson Hyperlegible font setting should be removed from settings',
      );
    });

    test('strings.g.dart no longer has hyperlegibleFont entries', () {
      final strings = File('lib/i18n/strings.g.dart').readAsStringSync();

      // Check that both label and description are removed
      expect(
        strings,
        isNot(contains('get hyperlegibleFont')),
        reason:
            'Atkinson Hyperlegible font label should be removed from strings',
      );
      expect(
        strings,
        isNot(contains("'Atkinson Hyperlegible font'")),
        reason:
            'Atkinson Hyperlegible font string should be removed from translations',
      );
    });

    test('asset cleanup test is updated', () {
      final testFile = File(
        'test/asset_cleanup_regression_test.dart',
      ).readAsStringSync();

      expect(
        testFile,
        isNot(
          contains("'pubspec no longer declares Atkinson Hyperlegible assets'"),
        ),
        reason:
            'Atkinson Hyperlegible test should be removed from asset cleanup',
      );
      expect(
        testFile,
        isNot(contains('Atkinson_Hyperlegible_Next')),
        reason: 'Atkinson Hyperlegible references should be removed from test',
      );
    });
  });

  group('Settings search keywords', () {
    test('Settings categories description is updated correctly', () {
      final settingsFile = File(
        'lib/pages/home/settings.dart',
      ).readAsStringSync();

      // Verify showAdvanced description mentions only Android
      expect(
        settingsFile,
        contains("'Custom data directory configuration'"),
        reason:
            'showAdvanced description should be updated for Android-only content',
      );
    });
  });
}
