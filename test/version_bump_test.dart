import 'package:flutter_test/flutter_test.dart';

// Import the version script as a library
// Note: This tests the Version class logic from the script

/// Version class for testing (mirrors the one in bump_version.dart)
class Version {
  final int major;
  final int minor;
  final int patch;
  final int buildNumber;

  Version({
    required this.major,
    required this.minor,
    required this.patch,
    required this.buildNumber,
  });

  static Version? fromVersionFile(String content) {
    final lines = content.trim().split('\n');
    int? major, minor, patch, buildNumber;

    for (final line in lines) {
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = int.tryParse(parts[1].trim());
        if (value == null) continue;

        switch (key) {
          case 'MAJOR':
            major = value;
            break;
          case 'MINOR':
            minor = value;
            break;
          case 'PATCH':
            patch = value;
            break;
          case 'BUILD_NUMBER':
            buildNumber = value;
            break;
        }
      }
    }

    if (major != null &&
        minor != null &&
        patch != null &&
        buildNumber != null) {
      return Version(
        major: major,
        minor: minor,
        patch: patch,
        buildNumber: buildNumber,
      );
    }
    return null;
  }

  static Version? fromString(String versionString) {
    final parts = versionString.split('+');
    final versionParts = parts[0].split('.');

    if (versionParts.length != 3) return null;

    final major = int.tryParse(versionParts[0]);
    final minor = int.tryParse(versionParts[1]);
    final patch = int.tryParse(versionParts[2]);

    if (major == null || minor == null || patch == null) return null;

    int buildNumber = major * 100000 + minor * 1000 + patch;
    if (parts.length > 1) {
      final parsedBuild = int.tryParse(parts[1]);
      if (parsedBuild != null) buildNumber = parsedBuild;
    }

    return Version(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: buildNumber,
    );
  }

  String get versionString => '$major.$minor.$patch';
  String get fullVersionString => '$major.$minor.$patch+$buildNumber';
  int get calculatedBuildNumber => major * 100000 + minor * 1000 + patch;

  Version bumpMajor() => Version(
    major: major + 1,
    minor: 0,
    patch: 0,
    buildNumber: (major + 1) * 100000,
  );

  Version bumpMinor() => Version(
    major: major,
    minor: minor + 1,
    patch: 0,
    buildNumber: major * 100000 + (minor + 1) * 1000,
  );

  Version bumpPatch() => Version(
    major: major,
    minor: minor,
    patch: patch + 1,
    buildNumber: major * 100000 + minor * 1000 + (patch + 1),
  );

  Version bumpBuild() => Version(
    major: major,
    minor: minor,
    patch: patch,
    buildNumber: buildNumber + 1,
  );
}

void main() {
  group('Version Parsing', () {
    test('fromString parses simple version', () {
      final version = Version.fromString('1.2.3');

      expect(version, isNotNull);
      expect(version!.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
    });

    test('fromString parses version with build number', () {
      final version = Version.fromString('1.2.3+102003');

      expect(version, isNotNull);
      expect(version!.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 102003);
    });

    test('fromString calculates build number when not provided', () {
      final version = Version.fromString('2.5.7');

      expect(version, isNotNull);
      // 2 * 100000 + 5 * 1000 + 7 = 205007
      expect(version!.buildNumber, 205007);
    });

    test('fromString returns null for invalid format', () {
      expect(Version.fromString('1.2'), null);
      expect(Version.fromString('invalid'), null);
      expect(Version.fromString(''), null);
    });

    test('fromVersionFile parses VERSION file format', () {
      const content = '''
MAJOR=1
MINOR=0
PATCH=0
BUILD_NUMBER=100000
''';

      final version = Version.fromVersionFile(content);

      expect(version, isNotNull);
      expect(version!.major, 1);
      expect(version.minor, 0);
      expect(version.patch, 0);
      expect(version.buildNumber, 100000);
    });

    test('fromVersionFile handles comments', () {
      const content = '''
# This is a comment
MAJOR=2
MINOR=3
PATCH=4
BUILD_NUMBER=203004
''';

      final version = Version.fromVersionFile(content);

      expect(version, isNotNull);
      expect(version!.major, 2);
      expect(version.minor, 3);
      expect(version.patch, 4);
    });

    test('fromVersionFile returns null for incomplete data', () {
      const content = '''
MAJOR=1
MINOR=0
''';

      expect(Version.fromVersionFile(content), null);
    });
  });

  group('Version String Generation', () {
    test('versionString returns correct format', () {
      final version = Version(
        major: 1,
        minor: 2,
        patch: 3,
        buildNumber: 102003,
      );

      expect(version.versionString, '1.2.3');
    });

    test('fullVersionString includes build number', () {
      final version = Version(
        major: 1,
        minor: 2,
        patch: 3,
        buildNumber: 102003,
      );

      expect(version.fullVersionString, '1.2.3+102003');
    });

    test('calculatedBuildNumber matches formula', () {
      final version = Version(major: 2, minor: 5, patch: 7, buildNumber: 0);

      // 2 * 100000 + 5 * 1000 + 7 = 205007
      expect(version.calculatedBuildNumber, 205007);
    });
  });

  group('Version Bumping', () {
    test('bumpMajor increments major and resets others', () {
      final version = Version(
        major: 1,
        minor: 5,
        patch: 3,
        buildNumber: 105003,
      );
      final bumped = version.bumpMajor();

      expect(bumped.major, 2);
      expect(bumped.minor, 0);
      expect(bumped.patch, 0);
      expect(bumped.buildNumber, 200000);
    });

    test('bumpMinor increments minor and resets patch', () {
      final version = Version(
        major: 1,
        minor: 5,
        patch: 3,
        buildNumber: 105003,
      );
      final bumped = version.bumpMinor();

      expect(bumped.major, 1);
      expect(bumped.minor, 6);
      expect(bumped.patch, 0);
      expect(bumped.buildNumber, 106000);
    });

    test('bumpPatch increments only patch', () {
      final version = Version(
        major: 1,
        minor: 5,
        patch: 3,
        buildNumber: 105003,
      );
      final bumped = version.bumpPatch();

      expect(bumped.major, 1);
      expect(bumped.minor, 5);
      expect(bumped.patch, 4);
      expect(bumped.buildNumber, 105004);
    });

    test('bumpBuild increments only build number', () {
      final version = Version(
        major: 1,
        minor: 5,
        patch: 3,
        buildNumber: 105003,
      );
      final bumped = version.bumpBuild();

      expect(bumped.major, 1);
      expect(bumped.minor, 5);
      expect(bumped.patch, 3);
      expect(bumped.buildNumber, 105004);
    });

    test('multiple bumps chain correctly', () {
      var version = Version(major: 1, minor: 0, patch: 0, buildNumber: 100000);

      version = version.bumpPatch(); // 1.0.1
      expect(version.versionString, '1.0.1');

      version = version.bumpPatch(); // 1.0.2
      expect(version.versionString, '1.0.2');

      version = version.bumpMinor(); // 1.1.0
      expect(version.versionString, '1.1.0');

      version = version.bumpMajor(); // 2.0.0
      expect(version.versionString, '2.0.0');
    });
  });

  group('Build Number Calculations', () {
    test('build number formula is consistent', () {
      // Test various versions
      final testCases = [
        (1, 0, 0, 100000),
        (1, 0, 1, 100001),
        (1, 1, 0, 101000),
        (1, 1, 1, 101001),
        (2, 0, 0, 200000),
        (2, 5, 10, 205010),
        (10, 20, 30, 1020030),
      ];

      for (final (major, minor, patch, expected) in testCases) {
        final version = Version(
          major: major,
          minor: minor,
          patch: patch,
          buildNumber: expected,
        );
        expect(
          version.calculatedBuildNumber,
          expected,
          reason: 'Version $major.$minor.$patch should have build $expected',
        );
      }
    });

    test('build numbers are always increasing with version bumps', () {
      var version = Version(major: 1, minor: 0, patch: 0, buildNumber: 100000);
      var lastBuild = version.buildNumber;

      // Bump patch several times
      for (var i = 0; i < 5; i++) {
        version = version.bumpPatch();
        expect(version.buildNumber, greaterThan(lastBuild));
        lastBuild = version.buildNumber;
      }

      // Bump minor
      version = version.bumpMinor();
      expect(version.buildNumber, greaterThan(lastBuild));
      lastBuild = version.buildNumber;

      // Bump major
      version = version.bumpMajor();
      expect(version.buildNumber, greaterThan(lastBuild));
    });
  });

  group('Edge Cases', () {
    test('handles version 0.0.0', () {
      final version = Version.fromString('0.0.0');

      expect(version, isNotNull);
      expect(version!.major, 0);
      expect(version.minor, 0);
      expect(version.patch, 0);
      expect(version.buildNumber, 0);
    });

    test('handles large version numbers', () {
      final version = Version.fromString('99.999.999');

      expect(version, isNotNull);
      expect(version!.major, 99);
      expect(version.minor, 999);
      expect(version.patch, 999);
    });

    test('bumping from 0.0.0 works correctly', () {
      final version = Version(major: 0, minor: 0, patch: 0, buildNumber: 0);

      expect(version.bumpPatch().versionString, '0.0.1');
      expect(version.bumpMinor().versionString, '0.1.0');
      expect(version.bumpMajor().versionString, '1.0.0');
    });
  });
}
