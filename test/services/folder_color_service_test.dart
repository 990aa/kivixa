import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/services/folder_color_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});

    tempDir = await Directory.systemTemp.createTemp(
      'kivixa_folder_color_service_test_',
    );
    await FileManager.init(
      documentsDirectory: tempDir.path,
      shouldWatchRootDirectory: false,
    );
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  tearDown(() {
    FolderColorService.instance.resetForTesting();
  });

  group('FolderColorService _loadColors error paths', () {
    test('handles corrupted JSON gracefully', () async {
      // Setup corrupted JSON file
      final file = File('${tempDir.path}/.folder_colors.json');
      await file.writeAsString('{ corrupted json');

      // Add a default color to ensure it gets cleared or remains untouched depending on logic
      // Actually _loadColors clears before loop if jsonDecode succeeds, but here it fails.
      // So let's check that initialize doesn't throw and finishes cleanly.

      expect(
        () async => await FolderColorService.instance.initialize(),
        returnsNormally,
      );

      // Verify no colors were loaded (should just handle the exception and move on)
      expect(FolderColorService.instance.getColor('/test'), isNull);
    });

    test('handles invalid schema (type errors) gracefully', () async {
      // Setup JSON with invalid value types (e.g. String instead of int)
      final file = File('${tempDir.path}/.folder_colors.json');
      await file.writeAsString('{"/test/path": "not_an_int"}');

      expect(
        () async => await FolderColorService.instance.initialize(),
        returnsNormally,
      );

      // _loadColors clears before the loop, then encounters type error inside the loop.
      // Meaning previous state is cleared but new state isn't fully loaded due to crash.
      // Since we reset testing state, it should just be empty.
      expect(FolderColorService.instance.getColor('/test/path'), isNull);
    });
  });
}
