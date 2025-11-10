import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/markdown/markdown_editor.dart';

void main() {
  group('MarkdownEditor', () {
    testWidgets('should render with edit and preview tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have a tab bar with two tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('should display text field in edit tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Edit tab should be active by default with a TextField
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should switch between edit and preview tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Initially on Edit tab
      expect(find.byType(TextField), findsOneWidget);

      // Tap on Preview tab
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // TextField should not be visible in preview
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should have correct filename in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/my-note')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should show the filename in app bar
      expect(find.text('my-note'), findsOneWidget);
    });

    testWidgets('should handle empty content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/empty')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(MarkdownEditor), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should have back button in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarkdownEditor(filePath: '/test'),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Navigate to markdown editor
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should have a back button
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('MarkdownEditor content handling', () {
    testWidgets('should allow text entry', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      const testText = '# Test Heading';

      // Enter text in edit mode
      await tester.enterText(find.byType(TextField), testText);
      await tester.pump();

      // Text should be there
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(testText));
    });

    testWidgets('should switch to preview after entering text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), '**Bold**');
      await tester.pump();

      // Switch to preview
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Should be on preview tab
      expect(find.byType(TextField), findsNothing);
    });
  });
}
