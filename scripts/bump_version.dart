#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// Version Bump Script for Kivixa
///
/// This script reads the current version from VERSION file and updates
/// all necessary files to ensure consistent versioning across the project.
///
/// Usage:
///   dart run scripts/bump_version.dart [options]
///
/// Options:
///   --help, -h     Show this help message
///   --major        Bump major version (x.0.0)
///   --minor        Bump minor version (0.x.0)
///   --patch        Bump patch version (0.0.x)
///   --build        Bump build number only
///   --set          Set specific version (e.g., --set 2.0.0)
///   --dry-run      Show what would change without making changes
///
/// Examples:
///   dart run scripts/bump_version.dart --patch
///   dart run scripts/bump_version.dart --minor
///   dart run scripts/bump_version.dart --set 2.0.0
///   dart run scripts/bump_version.dart --build --dry-run

import 'dart:io';

/// Version data structure
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

  /// Parse version from VERSION file
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

  /// Parse version string like "1.2.3" or "1.2.3+100000"
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

  /// Get version string without build number
  String get versionString => '$major.$minor.$patch';

  /// Get full version string with build number
  String get fullVersionString => '$major.$minor.$patch+$buildNumber';

  /// Calculate build number from version
  int get calculatedBuildNumber => major * 100000 + minor * 1000 + patch;

  /// Bump major version
  Version bumpMajor() => Version(
    major: major + 1,
    minor: 0,
    patch: 0,
    buildNumber: (major + 1) * 100000,
  );

  /// Bump minor version
  Version bumpMinor() => Version(
    major: major,
    minor: minor + 1,
    patch: 0,
    buildNumber: major * 100000 + (minor + 1) * 1000,
  );

  /// Bump patch version
  Version bumpPatch() => Version(
    major: major,
    minor: minor,
    patch: patch + 1,
    buildNumber: major * 100000 + minor * 1000 + (patch + 1),
  );

  /// Bump build number only
  Version bumpBuild() => Version(
    major: major,
    minor: minor,
    patch: patch,
    buildNumber: buildNumber + 1,
  );

  /// Generate VERSION file content
  String toVersionFileContent() =>
      '''
# Kivixa Version File
# This file maintains the single source of truth for version numbers.
# Run `dart run scripts/bump_version.dart` to update all version references.

MAJOR=$major
MINOR=$minor
PATCH=$patch
BUILD_NUMBER=$buildNumber
''';

  @override
  String toString() => 'Version($versionString+$buildNumber)';
}

/// Files that need to be updated
class VersionUpdater {
  final Version version;
  final bool dryRun;
  final List<String> updatedFiles = [];
  final List<String> errors = [];

  VersionUpdater({required this.version, this.dryRun = false});

  /// Update pubspec.yaml
  Future<bool> updatePubspec() async {
    const filePath = 'pubspec.yaml';
    final file = File(filePath);

    if (!await file.exists()) {
      errors.add('$filePath not found');
      return false;
    }

    var content = await file.readAsString();
    final pattern = RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+');
    final newVersion = 'version: ${version.fullVersionString}';

    if (!pattern.hasMatch(content)) {
      errors.add('$filePath: Could not find version pattern');
      return false;
    }

    content = content.replaceFirst(pattern, newVersion);

    if (!dryRun) {
      await file.writeAsString(content);
    }
    updatedFiles.add(filePath);
    return true;
  }

  /// Update lib/data/version.dart
  Future<bool> updateVersionDart() async {
    const filePath = 'lib/data/version.dart';
    final file = File(filePath);

    final newContent =
        '''
// This file is generated by the bump_version script.
// Run `dart run scripts/bump_version.dart --help` for more information.

import 'package:kivixa/data/kivixa_version.dart';

/// The current app version as an ordinal number.
const buildNumber = ${version.buildNumber};

/// The current app version as a string.
const buildName = '${version.versionString}';

/// The year in which the current version was released.
const buildYear = ${DateTime.now().year};

/// The current app version as a KivixaVersion object.
final kivixaVersion = KivixaVersion.fromNumber(buildNumber);
''';

    if (!dryRun) {
      await file.writeAsString(newContent);
    }
    updatedFiles.add(filePath);
    return true;
  }

  /// Update VERSION file
  Future<bool> updateVersionFile() async {
    const filePath = 'VERSION';
    final file = File(filePath);

    if (!dryRun) {
      await file.writeAsString(version.toVersionFileContent());
    }
    updatedFiles.add(filePath);
    return true;
  }

  /// Update Android build.gradle.kts (if version is hardcoded there)
  Future<bool> updateAndroidBuildGradle() async {
    const filePath = 'android/app/build.gradle.kts';
    final file = File(filePath);

    if (!await file.exists()) {
      // Not an error, might be using different config
      return true;
    }

    var content = await file.readAsString();
    var modified = false;

    // Update versionCode if present
    final versionCodePattern = RegExp(r'versionCode\s*=\s*\d+');
    if (versionCodePattern.hasMatch(content)) {
      content = content.replaceFirst(
        versionCodePattern,
        'versionCode = ${version.buildNumber}',
      );
      modified = true;
    }

    // Update versionName if present
    final versionNamePattern = RegExp(r'versionName\s*=\s*"[^"]*"');
    if (versionNamePattern.hasMatch(content)) {
      content = content.replaceFirst(
        versionNamePattern,
        'versionName = "${version.versionString}"',
      );
      modified = true;
    }

    if (modified) {
      if (!dryRun) {
        await file.writeAsString(content);
      }
      updatedFiles.add(filePath);
    }
    return true;
  }

  /// Update iOS Info.plist files
  Future<bool> updateIOSPlist() async {
    const filePaths = ['ios/Runner/Info.plist', 'macos/Runner/Info.plist'];

    for (final filePath in filePaths) {
      final file = File(filePath);
      if (!await file.exists()) continue;

      var content = await file.readAsString();
      var modified = false;

      // Update CFBundleShortVersionString
      final shortVersionPattern = RegExp(
        r'<key>CFBundleShortVersionString</key>\s*<string>[^<]*</string>',
      );
      if (shortVersionPattern.hasMatch(content)) {
        content = content.replaceFirst(
          shortVersionPattern,
          '<key>CFBundleShortVersionString</key>\n\t<string>${version.versionString}</string>',
        );
        modified = true;
      }

      // Update CFBundleVersion (build number)
      final bundleVersionPattern = RegExp(
        r'<key>CFBundleVersion</key>\s*<string>[^<]*</string>',
      );
      if (bundleVersionPattern.hasMatch(content)) {
        content = content.replaceFirst(
          bundleVersionPattern,
          '<key>CFBundleVersion</key>\n\t<string>${version.buildNumber}</string>',
        );
        modified = true;
      }

      if (modified) {
        if (!dryRun) {
          await file.writeAsString(content);
        }
        updatedFiles.add(filePath);
      }
    }
    return true;
  }

  /// Update Windows runner
  Future<bool> updateWindowsRunner() async {
    const filePath = 'windows/runner/Runner.rc';
    final file = File(filePath);

    if (!await file.exists()) return true;

    var content = await file.readAsString();
    var modified = false;

    // Update FILEVERSION
    final fileVersionPattern = RegExp(r'FILEVERSION\s+\d+,\d+,\d+,\d+');
    if (fileVersionPattern.hasMatch(content)) {
      content = content.replaceFirst(
        fileVersionPattern,
        'FILEVERSION ${version.major},${version.minor},${version.patch},0',
      );
      modified = true;
    }

    // Update PRODUCTVERSION
    final productVersionPattern = RegExp(r'PRODUCTVERSION\s+\d+,\d+,\d+,\d+');
    if (productVersionPattern.hasMatch(content)) {
      content = content.replaceFirst(
        productVersionPattern,
        'PRODUCTVERSION ${version.major},${version.minor},${version.patch},0',
      );
      modified = true;
    }

    // Update FileVersion value
    final fileVersionValuePattern = RegExp(r'VALUE "FileVersion", "[^"]*"');
    if (fileVersionValuePattern.hasMatch(content)) {
      content = content.replaceFirst(
        fileVersionValuePattern,
        'VALUE "FileVersion", "${version.versionString}.0"',
      );
      modified = true;
    }

    // Update ProductVersion value
    final productVersionValuePattern = RegExp(
      r'VALUE "ProductVersion", "[^"]*"',
    );
    if (productVersionValuePattern.hasMatch(content)) {
      content = content.replaceFirst(
        productVersionValuePattern,
        'VALUE "ProductVersion", "${version.versionString}.0"',
      );
      modified = true;
    }

    if (modified) {
      if (!dryRun) {
        await file.writeAsString(content);
      }
      updatedFiles.add(filePath);
    }
    return true;
  }

  /// Run all updates
  Future<void> runAll() async {
    print('Updating to version ${version.fullVersionString}...\n');

    await updateVersionFile();
    await updatePubspec();
    await updateVersionDart();
    await updateAndroidBuildGradle();
    await updateIOSPlist();
    await updateWindowsRunner();

    if (dryRun) {
      print('DRY RUN - No files were modified.\n');
    }

    if (updatedFiles.isNotEmpty) {
      print('${dryRun ? 'Would update' : 'Updated'} files:');
      for (final file in updatedFiles) {
        print('  ✓ $file');
      }
    }

    if (errors.isNotEmpty) {
      print('\nErrors:');
      for (final error in errors) {
        print('  ✗ $error');
      }
    }

    print('\nVersion: ${version.fullVersionString}');
    print('Build Number: ${version.buildNumber}');
  }
}

void printHelp() {
  print('''
Kivixa Version Bump Script

Usage:
  dart run scripts/bump_version.dart [options]

Options:
  --help, -h     Show this help message
  --major        Bump major version (x.0.0)
  --minor        Bump minor version (0.x.0)  
  --patch        Bump patch version (0.0.x)
  --build        Bump build number only
  --set <ver>    Set specific version (e.g., --set 2.0.0)
  --dry-run      Show what would change without making changes
  --current      Show current version

Examples:
  dart run scripts/bump_version.dart --patch
  dart run scripts/bump_version.dart --minor --dry-run
  dart run scripts/bump_version.dart --set 2.0.0
  dart run scripts/bump_version.dart --current

Files Updated:
  • VERSION                         - Source of truth for version
  • pubspec.yaml                    - Flutter project version
  • lib/data/version.dart           - Dart version constants
  • android/app/build.gradle.kts    - Android version (if hardcoded)
  • ios/Runner/Info.plist           - iOS version
  • macos/Runner/Info.plist         - macOS version
  • windows/runner/Runner.rc        - Windows version
''');
}

Future<Version?> getCurrentVersion() async {
  // Try to read from VERSION file first
  final versionFile = File('VERSION');
  if (await versionFile.exists()) {
    final content = await versionFile.readAsString();
    final version = Version.fromVersionFile(content);
    if (version != null) return version;
  }

  // Fall back to pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    final match = RegExp(
      r'version:\s*(\d+\.\d+\.\d+\+\d+)',
    ).firstMatch(content);
    if (match != null) {
      return Version.fromString(match.group(1)!);
    }
  }

  return null;
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printHelp();
    return;
  }

  final currentVersion = await getCurrentVersion();

  if (args.contains('--current')) {
    if (currentVersion != null) {
      print('Current version: ${currentVersion.fullVersionString}');
      print('  Major: ${currentVersion.major}');
      print('  Minor: ${currentVersion.minor}');
      print('  Patch: ${currentVersion.patch}');
      print('  Build Number: ${currentVersion.buildNumber}');
    } else {
      print('Could not determine current version.');
      print('Create a VERSION file or ensure pubspec.yaml has a version.');
    }
    return;
  }

  if (currentVersion == null) {
    print('Error: Could not determine current version.');
    print('Creating VERSION file with default version 1.0.0...');

    final defaultVersion = Version(
      major: 1,
      minor: 0,
      patch: 0,
      buildNumber: 100000,
    );

    await File('VERSION').writeAsString(defaultVersion.toVersionFileContent());
    print('VERSION file created. Run the script again to bump version.');
    return;
  }

  final dryRun = args.contains('--dry-run');
  Version newVersion;

  if (args.contains('--major')) {
    newVersion = currentVersion.bumpMajor();
  } else if (args.contains('--minor')) {
    newVersion = currentVersion.bumpMinor();
  } else if (args.contains('--patch')) {
    newVersion = currentVersion.bumpPatch();
  } else if (args.contains('--build')) {
    newVersion = currentVersion.bumpBuild();
  } else if (args.contains('--set')) {
    final setIndex = args.indexOf('--set');
    if (setIndex + 1 >= args.length) {
      print('Error: --set requires a version argument (e.g., --set 2.0.0)');
      exit(1);
    }
    final setVersion = Version.fromString(args[setIndex + 1]);
    if (setVersion == null) {
      print('Error: Invalid version format. Use format like 2.0.0');
      exit(1);
    }
    newVersion = setVersion;
  } else {
    print('Current version: ${currentVersion.fullVersionString}');
    print('');
    print('Use one of the following options to bump the version:');
    print('  --major   -> ${currentVersion.bumpMajor().fullVersionString}');
    print('  --minor   -> ${currentVersion.bumpMinor().fullVersionString}');
    print('  --patch   -> ${currentVersion.bumpPatch().fullVersionString}');
    print('  --build   -> ${currentVersion.bumpBuild().fullVersionString}');
    print('  --set X.Y.Z  Set specific version');
    print('');
    print('Add --dry-run to see changes without modifying files.');
    return;
  }

  print(
    'Bumping version: ${currentVersion.fullVersionString} -> ${newVersion.fullVersionString}',
  );
  print('');

  final updater = VersionUpdater(version: newVersion, dryRun: dryRun);
  await updater.runAll();

  if (!dryRun) {
    print('\n✓ Version bump complete!');
    print('\nNext steps:');
    print('  1. Run `flutter pub get` to refresh dependencies');
    print('  2. Test the app to ensure everything works');
    print('  3. Commit the version changes');
    print('  4. Create a git tag: git tag v${newVersion.versionString}');
  }
}
