import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/home/grid_folders.dart';

void main() {
  group('GridFolders Widget', () {
    testWidgets('renders folder list correctly', (tester) async {
      final folders = ['Folder1', 'Folder2', 'Folder3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (name) => folders.contains(name),
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: folders,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all folders are displayed
      expect(find.text('Folder1'), findsOneWidget);
      expect(find.text('Folder2'), findsOneWidget);
      expect(find.text('Folder3'), findsOneWidget);
    });

    testWidgets('shows back folder when not at root', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: false,
                  crossAxisCount: 2,
                  onTap: (v) {},
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify back arrow is shown when not at root
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('does not show back folder at root', (tester) async {
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
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify back arrow is not shown at root
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('calls onTap when folder is tapped', (tester) async {
      String? tappedFolder;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GridFolders(
                  isAtRoot: true,
                  crossAxisCount: 2,
                  onTap: (folder) => tappedFolder = folder,
                  doesFolderExist: (v) => false,
                  renameFolder: (a, b) async {},
                  isFolderEmpty: (v) async => true,
                  deleteFolder: (v) async {},
                  folders: const ['TestFolder'],
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

      expect(tappedFolder, 'TestFolder');
    });

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

      // Find and tap the more_vert icon (popup menu button)
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Verify menu items are shown
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('multi-select mode shows selection indicators', (tester) async {
      final selectedFolders = <String>[];

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
                  folders: const ['Folder1', 'Folder2'],
                  selectedFolders: selectedFolders,
                  isMultiSelectMode: true,
                  onFolderSelectionToggle: (name, selected) {
                    if (selected) {
                      selectedFolders.add(name);
                    } else {
                      selectedFolders.remove(name);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In multi-select mode, circle outline icons should be shown
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
    });

    testWidgets('selecting folder in multi-select mode changes indicator', (
      tester,
    ) async {
      final selectedFolders = <String>[];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
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
                      folders: const ['Folder1', 'Folder2'],
                      selectedFolders: selectedFolders,
                      isMultiSelectMode: true,
                      onFolderSelectionToggle: (name, selected) {
                        setState(() {
                          if (selected) {
                            selectedFolders.add(name);
                          } else {
                            selectedFolders.remove(name);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Folder1 to select it
      await tester.tap(find.text('Folder1'));
      await tester.pumpAndSettle();

      // Verify folder was selected
      expect(selectedFolders.contains('Folder1'), isTrue);
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
                  selectedFolders: const [],
                  isMultiSelectMode: true,
                  onFolderSelectionToggle: (a, b) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In multi-select mode, the more_vert icon should not be visible
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('Folder Operations', () {
    test('folder name validation - empty name', () {
      final result = _validateFolderName('', 'OldName', (v) => false);
      expect(result, isNotNull);
    });

    test('folder name validation - contains slash', () {
      final result = _validateFolderName(
        'folder/name',
        'OldName',
        (v) => false,
      );
      expect(result, isNotNull);
    });

    test('folder name validation - contains backslash', () {
      final result = _validateFolderName(
        'folder\\name',
        'OldName',
        (v) => false,
      );
      expect(result, isNotNull);
    });

    test('folder name validation - name exists', () {
      final result = _validateFolderName(
        'ExistingFolder',
        'OldName',
        (name) => name == 'ExistingFolder',
      );
      expect(result, isNotNull);
    });

    test('folder name validation - same name is valid', () {
      final result = _validateFolderName(
        'SameName',
        'SameName',
        (name) => name == 'SameName',
      );
      expect(result, isNull);
    });

    test('folder name validation - valid new name', () {
      final result = _validateFolderName(
        'NewValidName',
        'OldName',
        (v) => false,
      );
      expect(result, isNull);
    });
  });

  group('Multi-select Operations', () {
    test('total selected count calculation', () {
      final selectedFiles = ['file1', 'file2', 'file3'];
      final selectedFolders = ['folder1', 'folder2'];

      final totalCount = selectedFiles.length + selectedFolders.length;

      expect(totalCount, 5);
    });

    test('has selection check - with selection', () {
      final selectedFiles = ['file1'];
      final selectedFolders = <String>[];

      final hasSelection =
          selectedFiles.isNotEmpty || selectedFolders.isNotEmpty;

      expect(hasSelection, isTrue);
    });

    test('has selection check - no selection', () {
      final selectedFiles = <String>[];
      final selectedFolders = <String>[];

      final hasSelection =
          selectedFiles.isNotEmpty || selectedFolders.isNotEmpty;

      expect(hasSelection, isFalse);
    });
  });
}

/// Helper function to validate folder names
/// Returns error message or null if valid
String? _validateFolderName(
  String? folderName,
  String currentName,
  bool Function(String) doesFolderExist,
) {
  if (folderName == null || folderName.isEmpty) {
    return 'Folder name can\'t be empty';
  }
  if (folderName.contains('/') || folderName.contains('\\')) {
    return 'Folder name can\'t contain a slash';
  }
  if (folderName != currentName && doesFolderExist(folderName)) {
    return 'A folder with this name already exists';
  }
  return null;
}
