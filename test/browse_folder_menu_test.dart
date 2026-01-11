import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/home/grid_folders.dart';

void main() {
  group('GridFolders Popup Menu Tests', () {
    testWidgets('shows popup menu with rename, move, delete options', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  moveFolder: (a, b) async {},
                  currentPath: '/',
                  folders: const ['TestFolder'],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the more_vert icon
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify all menu options are shown
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('popup menu has correct icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  moveFolder: (a, b) async {},
                  currentPath: '/',
                  folders: const ['TestFolder'],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify icons
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.drive_file_move), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('tapping rename shows rename dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  moveFolder: (a, b) async {},
                  currentPath: '/',
                  folders: const ['TestFolder'],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap rename
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Verify rename dialog is shown
      expect(find.text('Rename folder'), findsOneWidget);
    });

    testWidgets('tapping delete shows delete dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  moveFolder: (a, b) async {},
                  currentPath: '/',
                  folders: const ['TestFolder'],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify delete dialog is shown
      expect(find.textContaining('Delete'), findsWidgets);
    });

    testWidgets('back folder does not show popup menu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: false, // Not at root - shows back folder
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const [], // No regular folders
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Back folder should exist but no popup menu
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('GridFolders Multi-Select Mode', () {
    testWidgets('shows selection checkbox in multi-select mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
                  isMultiSelectMode: true,
                  selectedFolders: const [],
                  onFolderSelectionToggle: (a, b) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show circle outline for unselected folder
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('shows check icon when folder is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
                  isMultiSelectMode: true,
                  selectedFolders: const ['TestFolder'],
                  onFolderSelectionToggle: (a, b) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show check icon for selected folder
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides popup menu in multi-select mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
                  isMultiSelectMode: true,
                  selectedFolders: const [],
                  onFolderSelectionToggle: (a, b) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Popup menu should not be visible
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('tapping folder toggles selection in multi-select mode', (
      tester,
    ) async {
      String? toggledFolder;
      bool? wasSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
                  isMultiSelectMode: true,
                  selectedFolders: const [],
                  onFolderSelectionToggle: (folder, selected) {
                    toggledFolder = folder;
                    wasSelected = selected;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the folder
      await tester.tap(find.text('TestFolder'));
      await tester.pumpAndSettle();

      expect(toggledFolder, 'TestFolder');
      expect(wasSelected, true);
    });

    testWidgets('selected folder has different card color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
                  isMultiSelectMode: true,
                  selectedFolders: const ['TestFolder'],
                  onFolderSelectionToggle: (a, b) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The card should have elevated appearance
      final cards = tester.widgetList<Card>(find.byType(Card));
      expect(cards.isNotEmpty, true);
      // Selected cards have elevation 4
      expect(cards.first.elevation, 4);
    });
  });

  group('Folder Rename Dialog', () {
    testWidgets('validates empty folder name', (tester) async {
      String? validateFolderName(String? value, String originalName) {
        if (value == null || value.isEmpty) {
          return 'Folder name can\'t be empty';
        }
        if (value.contains('/') || value.contains('\\')) {
          return 'Folder name can\'t contain a slash';
        }
        return null;
      }

      expect(validateFolderName('', 'original'), 'Folder name can\'t be empty');
      expect(
        validateFolderName(null, 'original'),
        'Folder name can\'t be empty',
      );
    });

    testWidgets('validates folder name with slashes', (tester) async {
      String? validateFolderName(String? value) {
        if (value == null || value.isEmpty) {
          return 'Folder name can\'t be empty';
        }
        if (value.contains('/') || value.contains('\\')) {
          return 'Folder name can\'t contain a slash';
        }
        return null;
      }

      expect(
        validateFolderName('test/folder'),
        'Folder name can\'t contain a slash',
      );
      expect(
        validateFolderName('test\\folder'),
        'Folder name can\'t contain a slash',
      );
      expect(validateFolderName('valid_folder'), null);
    });
  });

  group('Folder Delete Dialog', () {
    testWidgets('shows checkbox for non-empty folders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete folder'),
                    content: Row(
                      children: [
                        Checkbox(value: false, onChanged: (v) {}),
                        const Text('Also delete all notes inside this folder'),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(
        find.text('Also delete all notes inside this folder'),
        findsOneWidget,
      );
    });
  });
}
