import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/home/preview_card.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('PreviewCard Operations', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupMockPathProvider();
    SharedPreferences.setMockInitialValues({});

    FlavorConfig.setup();

    late final String rootDir;
    setUpAll(() async {
      await FileManager.init();
      rootDir = FileManager.documentsDirectory;
    });

    testWidgets('Rename note file', (tester) async {
      const originalPath = '/test_rename_note';
      const newName = 'renamed_note';
      const content = '{"strokes":[],"background":"white"}';

      // Create a test note file
      final file = File('$rootDir$originalPath.kvx');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Create a preview file
      final previewFile = File('$rootDir$originalPath.p');
      await previewFile.writeAsBytes([1, 2, 3, 4]);

      // Wait to ensure files are written
      await Future.delayed(const Duration(milliseconds: 200));

      // Build the PreviewCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewCard(
              filePath: originalPath,
              toggleSelection: (path, selected) {},
              selected: false,
              isAnythingSelected: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the three-dot menu
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap the rename option
      final renameButton = find.text(t.common.rename);
      expect(renameButton, findsOneWidget);
      await tester.tap(renameButton);
      await tester.pumpAndSettle();

      // Enter new name in the dialog
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, newName);
      await tester.pumpAndSettle();

      // Tap the rename button in the dialog
      final confirmButton = find.text(t.common.rename).last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Wait for rename operation
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify the file was renamed
      final newFile = File('$rootDir/$newName.kvx');
      expect(newFile.existsSync(), true);

      // Verify the preview file was also renamed
      final newPreviewFile = File('$rootDir/$newName.p');
      expect(newPreviewFile.existsSync(), true);

      // Verify the old files don't exist
      expect(file.existsSync(), false);
      expect(previewFile.existsSync(), false);

      // Cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await FileManager.deleteFile('/$newName.kvx');
      } catch (e) {
        // Ignore deletion errors
      }
    });

    testWidgets('Rename markdown file', (tester) async {
      const originalPath = '/test_rename_md';
      const newName = 'renamed_md';
      const content = '# Test Markdown\n\nThis is a test.';

      // Create a test markdown file
      final file = File('$rootDir$originalPath.md');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Create a preview file
      final previewFile = File('$rootDir$originalPath.p');
      await previewFile.writeAsBytes([1, 2, 3, 4]);

      // Wait to ensure files are written
      await Future.delayed(const Duration(milliseconds: 200));

      // Build the PreviewCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewCard(
              filePath: originalPath,
              toggleSelection: (path, selected) {},
              selected: false,
              isAnythingSelected: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the three-dot menu
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap the rename option
      final renameButton = find.text(t.common.rename);
      expect(renameButton, findsOneWidget);
      await tester.tap(renameButton);
      await tester.pumpAndSettle();

      // Enter new name in the dialog
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, newName);
      await tester.pumpAndSettle();

      // Tap the rename button in the dialog
      final confirmButton = find.text(t.common.rename).last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Wait for rename operation
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify the file was renamed
      final newFile = File('$rootDir/$newName.md');
      expect(newFile.existsSync(), true);

      // Verify the preview file was also renamed
      final newPreviewFile = File('$rootDir/$newName.p');
      expect(newPreviewFile.existsSync(), true);

      // Verify the old files don't exist
      expect(file.existsSync(), false);
      expect(previewFile.existsSync(), false);

      // Cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await FileManager.deleteFile('/$newName.md');
      } catch (e) {
        // Ignore deletion errors
      }
    });

    testWidgets('Delete note file with preview', (tester) async {
      const filePath = '/test_delete_note';
      const content = '{"strokes":[],"background":"white"}';

      // Create a test note file
      final file = File('$rootDir$filePath.kvx');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Create a preview file
      final previewFile = File('$rootDir$filePath.p');
      await previewFile.writeAsBytes([1, 2, 3, 4]);

      // Wait to ensure files are written
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify files exist
      expect(file.existsSync(), true);
      expect(previewFile.existsSync(), true);

      // Build the PreviewCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewCard(
              filePath: filePath,
              toggleSelection: (path, selected) {},
              selected: false,
              isAnythingSelected: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the three-dot menu
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap the delete option
      final deleteButton = find.text(t.common.delete).last;
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      final confirmButton = find.text(t.common.delete).last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Wait for delete operation
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify both files were deleted
      expect(file.existsSync(), false);
      expect(previewFile.existsSync(), false);
    });

    testWidgets('Delete markdown file with preview', (tester) async {
      const filePath = '/test_delete_md';
      const content = '# Test Markdown\n\nThis will be deleted.';

      // Create a test markdown file
      final file = File('$rootDir$filePath.md');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Create a preview file
      final previewFile = File('$rootDir$filePath.p');
      await previewFile.writeAsBytes([1, 2, 3, 4]);

      // Wait to ensure files are written
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify files exist
      expect(file.existsSync(), true);
      expect(previewFile.existsSync(), true);

      // Build the PreviewCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewCard(
              filePath: filePath,
              toggleSelection: (path, selected) {},
              selected: false,
              isAnythingSelected: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the three-dot menu
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap the delete option
      final deleteButton = find.text(t.common.delete).last;
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      final confirmButton = find.text(t.common.delete).last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Wait for delete operation
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify both files were deleted
      expect(file.existsSync(), false);
      expect(previewFile.existsSync(), false);
    });

    testWidgets('Cancel rename operation', (tester) async {
      const filePath = '/test_cancel_rename';
      const content = '{"strokes":[],"background":"white"}';

      // Create a test note file
      final file = File('$rootDir$filePath.kvx');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Wait to ensure file is written
      await Future.delayed(const Duration(milliseconds: 200));

      // Build the PreviewCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewCard(
              filePath: filePath,
              toggleSelection: (path, selected) {},
              selected: false,
              isAnythingSelected: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the three-dot menu
      final menuButton = find.byIcon(Icons.more_vert);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap the rename option
      final renameButton = find.text(t.common.rename);
      await tester.tap(renameButton);
      await tester.pumpAndSettle();

      // Tap cancel
      final cancelButton = find.text(t.common.cancel);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify the file still exists with original name
      expect(file.existsSync(), true);

      // Cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await FileManager.deleteFile('$filePath.kvx');
      } catch (e) {
        // Ignore deletion errors
      }
    });

    testWidgets('Cancel delete operation', (tester) async {
      const filePath = '/test_cancel_delete';
      const content = '{"strokes":[],"background":"white"}';

      // Create a test note file
      final file = File('$rootDir$filePath.kvx');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Wait to ensure file is written
      await Future.delayed(const Duration(milliseconds: 200));

      // Build the PreviewCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewCard(
              filePath: filePath,
              toggleSelection: (path, selected) {},
              selected: false,
              isAnythingSelected: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the three-dot menu
      final menuButton = find.byIcon(Icons.more_vert);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap the delete option
      final deleteButton = find.text(t.common.delete).last;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Tap cancel
      final cancelButton = find.text(t.common.cancel);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify the file still exists
      expect(file.existsSync(), true);

      // Cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await FileManager.deleteFile('$filePath.kvx');
      } catch (e) {
        // Ignore deletion errors
      }
    });

    test('Delete file with assets', () async {
      const filePath = '/test_delete_with_assets';
      const content = '{"strokes":[],"background":"white"}';

      // Create a test note file
      final file = File('$rootDir$filePath.kvx');
      await file.create(recursive: true);
      await file.writeAsString(content);

      // Create preview and asset files
      final previewFile = File('$rootDir$filePath.p');
      await previewFile.writeAsBytes([1, 2, 3, 4]);

      final asset0 = File('$rootDir$filePath.0');
      await asset0.writeAsBytes([5, 6, 7, 8]);

      final asset1 = File('$rootDir$filePath.1');
      await asset1.writeAsBytes([9, 10, 11, 12]);

      // Wait to ensure files are written
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify all files exist
      expect(file.existsSync(), true);
      expect(previewFile.existsSync(), true);
      expect(asset0.existsSync(), true);
      expect(asset1.existsSync(), true);

      // Delete the file
      await FileManager.deleteFile('$filePath.kvx');

      // Wait for delete operation
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify all files were deleted
      expect(file.existsSync(), false);
      expect(previewFile.existsSync(), false);
      expect(asset0.existsSync(), false);
      expect(asset1.existsSync(), false);
    });
  });
}
