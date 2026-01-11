import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late String originalDocsDir;

  setUpAll(() async {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});

    // Create a temporary directory for tests
    tempDir = await Directory.systemTemp.createTemp('kivixa_test_');

    // Initialize FileManager with temp dir directly for testing
    // We don't need to save original if it wasn't initialized
    try {
      originalDocsDir = FileManager.documentsDirectory;
    } catch (_) {
      originalDocsDir = tempDir.path;
    }

    FileManager.documentsDirectory = tempDir.path;
  });

  tearDownAll(() async {
    // Restore original documents directory
    FileManager.documentsDirectory = originalDocsDir;

    // Clean up temp directory
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // Clean up before each test
    final dir = Directory(tempDir.path);
    if (dir.existsSync()) {
      await for (final entity in dir.list()) {
        if (entity.path != tempDir.path) {
          await entity.delete(recursive: true);
        }
      }
    }
  });

  group('FileManager.moveDirectory', () {
    test('moves directory to new location', () async {
      // Create source directory with a file
      const sourcePath = '/TestFolder';
      await FileManager.createFolder(sourcePath);

      final file = File(p.join(tempDir.path, 'TestFolder', 'test.kvx'));
      await file.parent.create(recursive: true);
      await file.writeAsString('test content');

      // Create destination parent directory
      await FileManager.createFolder('/Destination');

      // Move the directory
      await FileManager.moveDirectory(sourcePath, '/Destination/TestFolder');

      // Verify source no longer exists
      expect(Directory(p.join(tempDir.path, 'TestFolder')).existsSync(), false);

      // Verify destination exists
      expect(
        Directory(
          p.join(tempDir.path, 'Destination', 'TestFolder'),
        ).existsSync(),
        true,
      );

      // Verify file was moved
      expect(
        File(
          p.join(tempDir.path, 'Destination', 'TestFolder', 'test.kvx'),
        ).existsSync(),
        true,
      );
    });

    test('moves directory with nested subdirectories', () async {
      // Create source directory structure
      const sourcePath = '/Parent';
      await FileManager.createFolder(sourcePath);
      await FileManager.createFolder('$sourcePath/Child');
      await FileManager.createFolder('$sourcePath/Child/GrandChild');

      // Create files at different levels
      await File(
        p.join(tempDir.path, 'Parent', 'file1.kvx'),
      ).writeAsString('content1');
      await File(
        p.join(tempDir.path, 'Parent', 'Child', 'file2.kvx'),
      ).writeAsString('content2');
      await File(
        p.join(tempDir.path, 'Parent', 'Child', 'GrandChild', 'file3.kvx'),
      ).writeAsString('content3');

      // Create destination
      await FileManager.createFolder('/NewLocation');

      // Move the directory
      await FileManager.moveDirectory('/Parent', '/NewLocation/Parent');

      // Verify all directories were moved
      expect(
        Directory(p.join(tempDir.path, 'NewLocation', 'Parent')).existsSync(),
        true,
      );
      expect(
        Directory(
          p.join(tempDir.path, 'NewLocation', 'Parent', 'Child'),
        ).existsSync(),
        true,
      );
      expect(
        Directory(
          p.join(tempDir.path, 'NewLocation', 'Parent', 'Child', 'GrandChild'),
        ).existsSync(),
        true,
      );

      // Verify all files were moved
      expect(
        File(
          p.join(tempDir.path, 'NewLocation', 'Parent', 'file1.kvx'),
        ).existsSync(),
        true,
      );
      expect(
        File(
          p.join(tempDir.path, 'NewLocation', 'Parent', 'Child', 'file2.kvx'),
        ).existsSync(),
        true,
      );
      expect(
        File(
          p.join(
            tempDir.path,
            'NewLocation',
            'Parent',
            'Child',
            'GrandChild',
            'file3.kvx',
          ),
        ).existsSync(),
        true,
      );

      // Verify source no longer exists
      expect(Directory(p.join(tempDir.path, 'Parent')).existsSync(), false);
    });

    test('does nothing when moving to same location', () async {
      // Create source directory
      const sourcePath = '/SameLocation';
      await FileManager.createFolder(sourcePath);

      final file = File(p.join(tempDir.path, 'SameLocation', 'test.kvx'));
      await file.writeAsString('test content');

      // Move to same location (should do nothing)
      await FileManager.moveDirectory(sourcePath, sourcePath);

      // Verify directory still exists
      expect(
        Directory(p.join(tempDir.path, 'SameLocation')).existsSync(),
        true,
      );
      expect(file.existsSync(), true);
    });

    test('handles non-existent source directory gracefully', () async {
      // Try to move a non-existent directory
      await FileManager.moveDirectory('/NonExistent', '/Destination');

      // Should not throw, just return
      expect(true, true);
    });

    test('creates parent directories if needed', () async {
      // Create source directory
      const sourcePath = '/Source';
      await FileManager.createFolder(sourcePath);

      final file = File(p.join(tempDir.path, 'Source', 'test.kvx'));
      await file.writeAsString('test content');

      // Move to a path where parents don't exist
      await FileManager.moveDirectory('/Source', '/A/B/C/Source');

      // Verify parent directories were created
      expect(
        Directory(p.join(tempDir.path, 'A', 'B', 'C', 'Source')).existsSync(),
        true,
      );
    });
  });

  group('FileManager.renameDirectory', () {
    test('renames directory correctly', () async {
      // Create source directory
      await FileManager.createFolder('/OldName');
      final file = File(p.join(tempDir.path, 'OldName', 'test.kvx'));
      await file.writeAsString('test content');

      // Rename the directory
      await FileManager.renameDirectory('/OldName', 'NewName');

      // Verify old directory is gone
      expect(Directory(p.join(tempDir.path, 'OldName')).existsSync(), false);

      // Verify new directory exists
      expect(Directory(p.join(tempDir.path, 'NewName')).existsSync(), true);

      // Verify file exists in renamed directory
      expect(
        File(p.join(tempDir.path, 'NewName', 'test.kvx')).existsSync(),
        true,
      );
    });

    test('handles nested directory rename', () async {
      // Create nested directory structure
      await FileManager.createFolder('/Parent/Child');
      final file = File(p.join(tempDir.path, 'Parent', 'Child', 'test.kvx'));
      await file.writeAsString('test content');

      // Rename the child directory
      await FileManager.renameDirectory('/Parent/Child', 'RenamedChild');

      // Verify old directory is gone
      expect(
        Directory(p.join(tempDir.path, 'Parent', 'Child')).existsSync(),
        false,
      );

      // Verify renamed directory exists
      expect(
        Directory(p.join(tempDir.path, 'Parent', 'RenamedChild')).existsSync(),
        true,
      );
    });
  });

  group('FileManager.deleteDirectory', () {
    test('deletes empty directory', () async {
      // Create empty directory
      await FileManager.createFolder('/EmptyFolder');

      // Delete the directory
      await FileManager.deleteDirectory('/EmptyFolder');

      // Verify directory is gone
      expect(
        Directory(p.join(tempDir.path, 'EmptyFolder')).existsSync(),
        false,
      );
    });

    test('deletes directory with contents recursively', () async {
      // Create directory with contents
      await FileManager.createFolder('/FolderWithContents');
      await File(
        p.join(tempDir.path, 'FolderWithContents', 'file.kvx'),
      ).writeAsString('content');
      await FileManager.createFolder('/FolderWithContents/SubFolder');
      await File(
        p.join(tempDir.path, 'FolderWithContents', 'SubFolder', 'file2.kvx'),
      ).writeAsString('content2');

      // Delete the directory recursively
      await FileManager.deleteDirectory('/FolderWithContents', true);

      // Verify directory is gone
      expect(
        Directory(p.join(tempDir.path, 'FolderWithContents')).existsSync(),
        false,
      );
    });
  });
}
