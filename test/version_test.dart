import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/kivixa_version.dart';
import 'package:kivixa/data/version.dart' as version;

void main() {
  test('kivixaVersion fromName', () {
    final version = KivixaVersion.fromName('1.2.3');
    expect(version.major, 1);
    expect(version.minor, 2);
    expect(version.patch, 3);
    expect(version.revision, 0);
  });

  test('kivixaVersion fromNumber', () {
    final version = KivixaVersion.fromNumber(102030);
    expect(version.major, 1);
    expect(version.minor, 2);
    expect(version.patch, 3);
    expect(version.revision, 0);
  });

  test('kivixaVersion fromNumber with revision', () {
    final version = KivixaVersion.fromNumber(102034);
    expect(version.major, 1);
    expect(version.minor, 2);
    expect(version.patch, 3);
    expect(version.revision, 4);
  });

  test('kivixaVersion buildName', () {
    final version = KivixaVersion(1, 2, 3);
    expect(version.buildName, '1.2.3');
  });

  test('kivixaVersion buildNumber', () {
    final version = KivixaVersion(1, 2, 3);
    expect(version.buildNumber, 102030);
  });

  test('kivixaVersion buildNumber with revision', () {
    final version = KivixaVersion(1, 2, 3, 4);
    expect(version.buildNumber, 102034);
  });

  test('kivixaVersion bumpMajor', () {
    final version = KivixaVersion(1, 2, 3);
    final nextVersion = version.bumpMajor();
    expect(nextVersion.major, 2);
    expect(nextVersion.minor, 0);
    expect(nextVersion.patch, 0);
  });

  test('kivixaVersion bumpMinor', () {
    final version = KivixaVersion(1, 2, 3);
    final nextVersion = version.bumpMinor();
    expect(nextVersion.major, 1);
    expect(nextVersion.minor, 3);
    expect(nextVersion.patch, 0);
  });

  test('kivixaVersion bumpPatch', () {
    final version = KivixaVersion(1, 2, 3);
    final nextVersion = version.bumpPatch();
    expect(nextVersion.major, 1);
    expect(nextVersion.minor, 2);
    expect(nextVersion.patch, 4);
  });

  test('kivixaVersion copyWith', () {
    final version = KivixaVersion(1, 2, 3, 4);
    final nextVersion = version.copyWith(
      major: 5,
      minor: 6,
      patch: 7,
      revision: 8,
    );
    expect(nextVersion.major, 5);
    expect(nextVersion.minor, 6);
    expect(nextVersion.patch, 7);
    expect(nextVersion.revision, 8);
  });

  test('kivixaVersion equality', () {
    final version1 = KivixaVersion(1, 2, 3);
    final version2 = KivixaVersion(1, 2, 3);
    expect(version1, version2);
  });

  test('kivixaVersion inequality', () {
    final version1 = KivixaVersion(1, 2, 3);
    final version2 = KivixaVersion(1, 2, 4);
    expect(version1, isNot(version2));
  });

  test('kivixaVersion is not null', () {
    final versionObject = version.kivixaVersion;
    expect(versionObject, isNotNull);
  });
}
