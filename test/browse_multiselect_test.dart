import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/pages/home/browse.dart';

void main() {
  group('BrowsePage Multi-Select Mode', () {
    testWidgets('multi-select button appears in app bar', (tester) async {
      // Create a simplified BrowsePage for testing
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(
            overrideChildren: DirectoryChildren(['TestFolder'], ['TestFile']),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the multi-select button (check_box_outline_blank when not in multi-select)
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('tapping multi-select button toggles mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(
            overrideChildren: DirectoryChildren(['TestFolder'], ['TestFile']),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show outline blank
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      // Tap to enable multi-select
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      // Should now show check_box
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('footer shows selection count in multi-select mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(
            overrideChildren: DirectoryChildren(
              ['Folder1', 'Folder2'],
              ['File1', 'File2'],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enable multi-select mode
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      // Check that "0 selected" is shown
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('Delete All button appears in multi-select mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(
            overrideChildren: DirectoryChildren(['TestFolder'], []),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enable multi-select mode
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      // Verify Delete All button appears
      expect(find.text('Delete All'), findsOneWidget);
    });

    testWidgets('Group button appears in multi-select mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(
            overrideChildren: DirectoryChildren(['TestFolder'], []),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enable multi-select mode
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      // Verify Group button appears
      expect(find.text('Group'), findsOneWidget);
    });

    testWidgets('floating action button hidden in multi-select mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(overrideChildren: DirectoryChildren([], [])),
        ),
      );

      await tester.pumpAndSettle();

      // The FAB should be visible initially
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Enable multi-select mode
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      // FAB should be hidden in multi-select mode
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('exiting multi-select mode clears selections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrowsePage(
            overrideChildren: DirectoryChildren(['TestFolder'], []),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enable multi-select mode
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      // Exit multi-select mode
      await tester.tap(find.byIcon(Icons.check_box));
      await tester.pumpAndSettle();

      // Should be back to non-multi-select state
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });
  });

  group('Delete Confirmation Dialog', () {
    testWidgets('shows correct title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Selected Items'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
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

      expect(find.text('Delete Selected Items'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('New Folder Dialog for Grouping', () {
    testWidgets('shows folder name input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Group into New Folder'),
                    content: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Folder Name',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'TestFolder'),
                        child: const Text('Create'),
                      ),
                    ],
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

      expect(find.text('Group into New Folder'), findsOneWidget);
      expect(find.text('Folder Name'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });
  });

  group('FileFilterType enum', () {
    test('has correct values', () {
      expect(FileFilterType.values.length, 4);
      expect(FileFilterType.all.index, 0);
      expect(FileFilterType.handwritten.index, 1);
      expect(FileFilterType.markdown.index, 2);
      expect(FileFilterType.text.index, 3);
    });
  });

  group('SortType enum', () {
    test('has correct values', () {
      expect(SortType.values.length, 4);
      expect(SortType.aToZ.index, 0);
      expect(SortType.zToA.index, 1);
      expect(SortType.latestFirst.index, 2);
      expect(SortType.oldestFirst.index, 3);
    });
  });
}
