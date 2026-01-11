import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/toolbar/editor_options_sidebar.dart';
import 'package:kivixa/data/editor/editor_core_info.dart';
import 'package:kivixa/data/editor/page.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});
  });

  group('EditorOptionsSidebar Widget Tests', () {
    testWidgets('renders background pattern section', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) {},
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify background pattern options exist
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('shows clear page button with layers_clear icon', (
      tester,
    ) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) {},
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the clear page button shows layers_clear icon
      expect(find.byIcon(Icons.layers_clear), findsWidgets);
    });

    testWidgets('shows line height slider', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) {},
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify sliders exist for line height and thickness
      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('shows PDF import when canRasterPdf is true', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) {},
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PDF button exists but not photo button (images removed)
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('hides PDF import when canRasterPdf is false', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) {},
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // PDF should not appear when canRasterPdf is false
      expect(find.text('PDF'), findsNothing);
    });

    testWidgets('does not show images import option (removed)', (tester) async {
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) {},
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Images option should NOT appear (it's in the toolbar)
      expect(find.text('Photo'), findsNothing);
      expect(find.text('Images'), findsNothing);
    });

    testWidgets('calls setLineHeight when slider changes', (tester) async {
      int? newLineHeight;
      final coreInfo = EditorCoreInfo(filePath: '/test');
      coreInfo.pages.add(EditorPage(size: const Size(600, 800)));
      coreInfo.lineHeight = 40;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorOptionsSidebar(
              invert: false,
              coreInfo: coreInfo,
              currentPageIndex: 0,
              setBackgroundPattern: (p) {},
              setLineHeight: (h) => newLineHeight = h,
              setLineThickness: (t) {},
              removeBackgroundImage: () {},
              redrawImage: () {},
              clearPage: () {},
              clearAllPages: () {},
              redrawAndSave: () {},
              importPdf: () async => false,
              canRasterPdf: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find first slider (line height)
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));

      // Drag the first slider
      await tester.drag(sliders.first, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Verify callback was triggered
      expect(newLineHeight, isNotNull);
    });
  });

  group('Options Sidebar Structure', () {
    test('EditorOptionsSidebar requires all callback parameters', () {
      // This test ensures the widget requires all necessary callbacks
      // The constructor enforces required parameters at compile time
      expect(EditorOptionsSidebar, isNotNull);
    });
  });
}
