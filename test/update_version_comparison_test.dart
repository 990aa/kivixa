import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/kivixa_version.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/version.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Example current build number.
/// See [buildNumber] in [lib/data/version.dart].
const v = 5000;

void main() => group('Update manager:', () {
  FlavorConfig.setup();
  SharedPreferences.setMockInitialValues({});

  group('Semantic version comparison:', () {
    test('Major version takes precedence', () {
      // 2.0.0 > 1.9.9
      final v1 = KivixaVersion(1, 9, 9, 0);
      final v2 = KivixaVersion(2, 0, 0, 0);
      expect(UpdateManager.compareVersions(v1, v2), lessThan(0));
      expect(UpdateManager.compareVersions(v2, v1), greaterThan(0));
    });

    test('Minor version comparison when major is equal', () {
      // 1.2.0 > 1.1.9
      final v1 = KivixaVersion(1, 1, 9, 0);
      final v2 = KivixaVersion(1, 2, 0, 0);
      expect(UpdateManager.compareVersions(v1, v2), lessThan(0));
      expect(UpdateManager.compareVersions(v2, v1), greaterThan(0));
    });

    test('Patch version comparison when major and minor are equal', () {
      // 1.1.2 > 1.1.1
      final v1 = KivixaVersion(1, 1, 1, 0);
      final v2 = KivixaVersion(1, 1, 2, 0);
      expect(UpdateManager.compareVersions(v1, v2), lessThan(0));
      expect(UpdateManager.compareVersions(v2, v1), greaterThan(0));
    });

    test('Equal versions compare as zero', () {
      final v1 = KivixaVersion(1, 2, 3, 0);
      final v2 = KivixaVersion(1, 2, 3, 0);
      expect(UpdateManager.compareVersions(v1, v2), equals(0));
    });

    test('Revision is ignored in comparison', () {
      // Revisions differ but major.minor.patch are the same
      // Note: revision must be 0-9 per KivixaVersion constraints
      final v1 = KivixaVersion(1, 2, 3, 0);
      final v2 = KivixaVersion(1, 2, 3, 9);
      expect(UpdateManager.compareVersions(v1, v2), equals(0));
    });
  });

  test('Test version comparison (release mode)', () {
    stows.shouldAlwaysAlertForUpdates.value = false;

    expect(UpdateManager.getUpdateStatus(v, v - 10), UpdateStatus.upToDate);
    expect(UpdateManager.getUpdateStatus(v, v - 1), UpdateStatus.upToDate);
    expect(UpdateManager.getUpdateStatus(v, v), UpdateStatus.upToDate);
    expect(UpdateManager.getUpdateStatus(v, v + 1), UpdateStatus.upToDate);
    expect(UpdateManager.getUpdateStatus(v, v + 9), UpdateStatus.upToDate);

    expect(
      UpdateManager.getUpdateStatus(v, v + 10),
      UpdateStatus.updateOptional,
    );
    expect(
      UpdateManager.getUpdateStatus(v, v + 11),
      UpdateStatus.updateOptional,
    );
    expect(
      UpdateManager.getUpdateStatus(v, v + 19),
      UpdateStatus.updateOptional,
    );

    expect(
      UpdateManager.getUpdateStatus(v, v + 20),
      UpdateStatus.updateRecommended,
    );
    expect(
      UpdateManager.getUpdateStatus(v, v + 100),
      UpdateStatus.updateRecommended,
    );
  });

  test('Test version comparison (debug mode)', () {
    stows.shouldAlwaysAlertForUpdates.value = true;

    expect(UpdateManager.getUpdateStatus(v, v), UpdateStatus.upToDate);
    expect(UpdateManager.getUpdateStatus(v, v + 1), UpdateStatus.upToDate);
    expect(UpdateManager.getUpdateStatus(v, v + 9), UpdateStatus.upToDate);
    expect(
      UpdateManager.getUpdateStatus(v, v + 10),
      UpdateStatus.updateRecommended,
    );
  });

  test(
    'Test that the latest version can be parsed from version.dart',
    () async {
      // load local file from lib/data/version.dart
      final latestVersionFile = await File(
        'lib/data/version.dart',
      ).readAsString();
      expect(
        latestVersionFile.isNotEmpty,
        true,
        reason: 'Failed to load local version.dart file',
      );

      final int? parsedVersion = await UpdateManager.getNewestVersion(
        latestVersionFile,
      );
      expect(
        parsedVersion,
        isNotNull,
        reason: 'Could not parse version number from version.dart file',
      );
      expect(
        parsedVersion,
        buildNumber,
        reason: 'Incorrect version number parsed from version.dart file',
      );
    },
  );

  group('GitHub releases API parsing:', () {
    test('Parse version from GitHub releases API', () async {
      final fileContents = await File(
        'test/samples/github_releases_api.json',
      ).readAsString();
      final int? newestVersion = await UpdateManager.getNewestVersion(
        fileContents,
      );

      expect(
        newestVersion,
        isNotNull,
        reason: 'Could not parse version number from GitHub',
      );
      // The version should be parsed as 100000 from "v1.0.0"
      expect(
        newestVersion,
        equals(100000),
        reason: 'Incorrect version number parsed from GitHub',
      );
    });

    test(
      'fetchLatestVersionFromGitHub returns tuple with version info',
      () async {
        final fileContents = await File(
          'test/samples/github_releases_api.json',
        ).readAsString();
        final (buildNum, versionName, releaseBody) =
            await UpdateManager.fetchLatestVersionFromGitHub(fileContents);

        expect(buildNum, equals(100000));
        expect(versionName, equals('1.0.0'));
        expect(releaseBody, contains("What's New"));
      },
    );

    test('Parse version with build suffix (v1.2.3+4)', () async {
      const json = '''
      {
        "tag_name": "v1.2.3+4",
        "name": "Release v1.2.3",
        "body": "Test release"
      }
      ''';
      final (buildNum, versionName, _) =
          await UpdateManager.fetchLatestVersionFromGitHub(json);

      // 1*100000 + 2*1000 + 3*10 + 4 = 102034
      // Note: revision must be 0-9 per KivixaVersion constraints
      expect(buildNum, equals(102034));
      expect(versionName, equals('1.2.3'));
    });

    test('Parse version without v prefix (1.2.3)', () async {
      const json = '''
      {
        "tag_name": "1.2.3",
        "name": "Release 1.2.3",
        "body": "Test release"
      }
      ''';
      final (buildNum, versionName, _) =
          await UpdateManager.fetchLatestVersionFromGitHub(json);

      // 1*100000 + 2*1000 + 3*10 + 0 = 102030
      expect(buildNum, equals(102030));
      expect(versionName, equals('1.2.3'));
    });

    test('Returns null for invalid tag_name', () async {
      const json = '''
      {
        "tag_name": "invalid-tag",
        "name": "Bad release"
      }
      ''';
      final (buildNum, versionName, releaseBody) =
          await UpdateManager.fetchLatestVersionFromGitHub(json);

      expect(buildNum, isNull);
      expect(versionName, isNull);
      expect(releaseBody, isNull);
    });

    test('Returns null when tag_name is missing', () async {
      const json = '''
      {
        "name": "Release without tag"
      }
      ''';
      final (buildNum, _, _) = await UpdateManager.fetchLatestVersionFromGitHub(
        json,
      );

      expect(buildNum, isNull);
    });
  });

  group('BackgroundUpdateState enum:', () {
    test('BackgroundUpdateState has correct values', () {
      expect(BackgroundUpdateState.values.length, equals(5));
      expect(
        BackgroundUpdateState.values,
        contains(BackgroundUpdateState.idle),
      );
      expect(
        BackgroundUpdateState.values,
        contains(BackgroundUpdateState.downloading),
      );
      expect(
        BackgroundUpdateState.values,
        contains(BackgroundUpdateState.readyToInstall),
      );
      expect(
        BackgroundUpdateState.values,
        contains(BackgroundUpdateState.installing),
      );
      expect(
        BackgroundUpdateState.values,
        contains(BackgroundUpdateState.error),
      );
    });
  });
});
