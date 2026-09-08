import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('Android Handwritten Note Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupMockPathProvider();
    SharedPreferences.setMockInitialValues({});
    FlavorConfig.setup();

    late Directory tempDocumentsDir;

    setUpAll(() {
      stows.customDataDir.removeListener(FileManager.migrateDataDir);
    });

    setUp(() async {
      tempDocumentsDir = await Directory.systemTemp.createTemp('kivixa_hw_test_');
      await FileManager.init(
        documentsDirectory: tempDocumentsDir.path,
        shouldWatchRootDirectory: false,
      );
      FileManager.documentsDirectory = tempDocumentsDir.path;
      FileManager.shouldUseRawFilePath = false;
      stows.recentFiles.value = <String>[];
    });

    tearDown(() async {
      if (tempDocumentsDir.existsSync()) {
        await tempDocumentsDir.delete(recursive: true);
      }
    });

    test('Editor extension and extensionOldJson are distinct', () {
      expect(Editor.extension, equals('.kvx'));
      expect(Editor.extensionOldJson, equals('.kvx1'));
      expect(Editor.extension, isNot(equals(Editor.extensionOldJson)));
    });

    test('Writing new handwritten note preserves .kvx file without self-deletion', () async {
      const filePath = '/26-09-08 Untitled.kvx';
      final content = utf8.encode('handwritten note bson content');

      await FileManager.writeFile(filePath, content, awaitWrite: true);

      // Verify the .kvx file exists on disk
      expect(FileManager.doesFileExist(filePath), isTrue);

      final readBytes = await FileManager.readFile(filePath);
      expect(readBytes, isNotNull);
      expect(utf8.decode(readBytes!), equals('handwritten note bson content'));

      // Verify the note is in recentFiles
      expect(stows.recentFiles.value, contains(filePath));
    });

    test('Writing .kvx note cleans up legacy .kvx1 without deleting the new .kvx note', () async {
      const legacyPath = '/test_note.kvx1';
      const newPath = '/test_note.kvx';

      // Pre-create the legacy file
      final legacyFile = File('${FileManager.documentsDirectory}$legacyPath');
      await legacyFile.create(recursive: true);
      await legacyFile.writeAsString('old json content');
      expect(legacyFile.existsSync(), isTrue);

      // Now save new note
      final newContent = utf8.encode('new bson content');
      await FileManager.writeFile(newPath, newContent, awaitWrite: true);

      // Legacy file must be deleted
      expect(FileManager.doesFileExist(legacyPath), isFalse);

      // New file must exist and be readable
      expect(FileManager.doesFileExist(newPath), isTrue);
      final readBytes = await FileManager.readFile(newPath);
      expect(readBytes, isNotNull);
      expect(utf8.decode(readBytes!), equals('new bson content'));
    });

    test('DirectoryChildren detects .kvx and .kvx1 as handwritten file type', () async {
      const kvxPath = '/note_a.kvx';
      const kvx1Path = '/note_b.kvx1';

      await FileManager.writeFile(kvxPath, utf8.encode('a'), awaitWrite: true);

      final kvx1File = File('${FileManager.documentsDirectory}$kvx1Path');
      await kvx1File.create(recursive: true);
      await kvx1File.writeAsString('b');

      final children = await FileManager.getChildrenOfDirectory('/');
      expect(children, isNotNull);
      expect(children!.files, containsAll(['note_a', 'note_b']));
      expect(children.getFileType('note_a'), equals(KivixaFileType.handwritten));
      expect(children.getFileType('note_b'), equals(KivixaFileType.handwritten));
    });
  });
}
