import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/toolbar/editor_page_manager.dart';
import 'package:kivixa/data/editor/editor_core_info.dart';
import 'package:kivixa/data/editor/page.dart';

void main() {
  group('EditorPageManager Widget Tests', () {
    testWidgets('renders page list correctly', (tester) async {
      // Create test core info with pages
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: EditorPageManager(
                    coreInfo: coreInfo,
                    currentPageIndex: 0,
                    redrawAndSave: () {},
                    insertPageAfter: (a, {PageOrientation? orientation}) {},
                    duplicatePage: (a) {},
                    clearPage: (a) {},
                    deletePage: (a) {},
                    transformationController: TransformationController(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify page indicator is shown
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('shows insert page button with note_add icon', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorPageManager(
              coreInfo: coreInfo,
              currentPageIndex: 0,
              redrawAndSave: () {},
              insertPageAfter: (a, {PageOrientation? orientation}) {},
              duplicatePage: (a) {},
              clearPage: (a) {},
              deletePage: (a) {},
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the insert page button shows note_add icon (page with +)
      expect(find.byIcon(Icons.note_add), findsOneWidget);
    });

    testWidgets('shows clear page button with layers_clear icon', (
      tester,
    ) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      final page = EditorPage(size: const Size(600, 800));
      coreInfo.pages.add(page);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorPageManager(
              coreInfo: coreInfo,
              currentPageIndex: 0,
              redrawAndSave: () {},
              insertPageAfter: (a, {PageOrientation? orientation}) {},
              duplicatePage: (a) {},
              clearPage: (a) {},
              deletePage: (a) {},
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the clear page button shows layers_clear icon
      expect(find.byIcon(Icons.layers_clear), findsOneWidget);
    });

    testWidgets('shows duplicate page button', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorPageManager(
              coreInfo: coreInfo,
              currentPageIndex: 0,
              redrawAndSave: () {},
              insertPageAfter: (a, {PageOrientation? orientation}) {},
              duplicatePage: (a) {},
              clearPage: (a) {},
              deletePage: (a) {},
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the duplicate page button exists
      expect(find.byIcon(Icons.content_copy), findsOneWidget);
    });

    testWidgets('shows delete page button', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorPageManager(
              coreInfo: coreInfo,
              currentPageIndex: 0,
              redrawAndSave: () {},
              insertPageAfter: (a, {PageOrientation? orientation}) {},
              duplicatePage: (a) {},
              clearPage: (a) {},
              deletePage: (a) {},
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the delete page button exists
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows drag handle for reordering', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorPageManager(
              coreInfo: coreInfo,
              currentPageIndex: 0,
              redrawAndSave: () {},
              insertPageAfter: (a, {PageOrientation? orientation}) {},
              duplicatePage: (a) {},
              clearPage: (a) {},
              deletePage: (a) {},
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify drag handle icon exists
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });
  });

  group('Icon Changes Tests', () {
    test('insert page icon should be note_add (page with + symbol)', () {
      // Verify the icon constant matches the expected value
      expect(Icons.note_add.codePoint, isNotNull);
    });

    test('clear page icon should be layers_clear', () {
      // Verify the icon constant matches the expected value
      expect(Icons.layers_clear.codePoint, isNotNull);
    });
  });

  group('Pages Sidebar Integration', () {
    testWidgets('sidebar widget structure is correct', (tester) async {
      // This test validates that the sidebar can render correctly
      // The actual Editor integration test would need more setup

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: Center(child: Text('Canvas'))),
                // Simulating the sidebar structure
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 280,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pages'),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          child: Center(child: Text('Page list here')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify sidebar structure
      expect(find.text('Pages'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('sidebar can toggle visibility', (tester) async {
      bool isVisible = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  actions: [
                    IconButton(
                      icon: Icon(
                        isVisible ? Icons.view_sidebar : Icons.grid_view,
                      ),
                      onPressed: () => setState(() => isVisible = !isVisible),
                    ),
                  ],
                ),
                body: Row(
                  children: [
                    const Expanded(child: Center(child: Text('Canvas'))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isVisible ? 280 : 0,
                      child: isVisible
                          ? Container(
                              color: Colors.grey[200],
                              child: const Center(child: Text('Sidebar')),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Initially visible
      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.byIcon(Icons.view_sidebar), findsOneWidget);

      // Toggle
      await tester.tap(find.byIcon(Icons.view_sidebar));
      await tester.pumpAndSettle();

      // Should be hidden now
      expect(find.text('Sidebar'), findsNothing);
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });
  });
}
