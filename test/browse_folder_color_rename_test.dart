import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/pages/home/browse.dart';
import 'package:kivixa/services/folder_color_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> _openRenameDialog(
    WidgetTester tester,
    String folderName,
  ) async {
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename folder'), findsOneWidget);
    expect(find.text(folderName), findsWidgets);
  }

  testWidgets('folder color is preserved after rename', (tester) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'kivixa_browse_rename_color_',
    );

    await FileManager.init(
      documentsDirectory: tempDir.path,
      shouldWatchRootDirectory: false,
    );

    final oldName = 'OldFolder';
    final newName = 'RenamedFolder';

    await FileManager.createFolder('/$oldName');
    await FolderColorService.instance.setColor('/$oldName', Colors.red);

    await tester.pumpWidget(
      MaterialApp(
        home: BrowsePage(
          overrideChildren: DirectoryChildren([oldName], []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openRenameDialog(tester, oldName);

    final dialog = find.byType(AlertDialog).first;
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)),
      newName,
    );
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(FolderColorService.instance.getColor('/$oldName'), isNull);
    expect(FolderColorService.instance.getColor('/$newName'), Colors.red);

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('rename dialog can reset folder color', (tester) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'kivixa_browse_rename_color_reset_',
    );

    await FileManager.init(
      documentsDirectory: tempDir.path,
      shouldWatchRootDirectory: false,
    );

    final oldName = 'ColorFolder';
    final newName = 'NoColorFolder';

    await FileManager.createFolder('/$oldName');
    await FolderColorService.instance.setColor('/$oldName', Colors.blue);

    await tester.pumpWidget(
      MaterialApp(
        home: BrowsePage(
          overrideChildren: DirectoryChildren([oldName], []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openRenameDialog(tester, oldName);

    final dialog = find.byType(AlertDialog).first;

    // Reset color to default from the rename dialog.
    await tester.tap(
      find.descendant(of: dialog, matching: find.byIcon(Icons.clear)).first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)),
      newName,
    );
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(FolderColorService.instance.getColor('/$oldName'), isNull);
    expect(FolderColorService.instance.getColor('/$newName'), isNull);

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });
}
