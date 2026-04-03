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
      'kivixa_folder_color_service_',
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

  group('FolderColorService rename behavior', () {
    test('preserves folder color mapping after rename', () async {
      final unique = DateTime.now().microsecondsSinceEpoch;
      final oldPath = '/old_$unique';
      final newPath = '/new_$unique';

      await FolderColorService.instance.setColor(oldPath, Colors.red);
      await FolderColorService.instance.renameFolder(oldPath, newPath);

      expect(FolderColorService.instance.getColor(oldPath), isNull);
      expect(
        FolderColorService.instance.getColor(newPath)?.toARGB32(),
        Colors.red.toARGB32(),
      );
    });

    test('supports explicit color reset after rename', () async {
      final unique = DateTime.now().microsecondsSinceEpoch;
      final oldPath = '/reset_old_$unique';
      final newPath = '/reset_new_$unique';

      await FolderColorService.instance.setColor(oldPath, Colors.blue);
      await FolderColorService.instance.renameFolder(oldPath, newPath);
      await FolderColorService.instance.setColor(newPath, null);

      expect(FolderColorService.instance.getColor(oldPath), isNull);
      expect(FolderColorService.instance.getColor(newPath), isNull);
    });
  });
}
