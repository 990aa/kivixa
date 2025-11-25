import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/markdown/advanced_markdown_editor.dart';

void main() {
  group('AdvancedMarkdownEditor Widget Tests', () {
    testWidgets('should render with three tabs (Edit, Preview, Split)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Should have a tab bar with three tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
    });

    testWidgets('should display code editor in edit tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Edit tab should be active by default with CodeField
      expect(find.byType(CodeField), findsOneWidget);
    });

    testWidgets('should switch to preview tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Initially on Edit tab
      expect(find.byType(CodeField), findsOneWidget);

      // Tap on Preview tab
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // CodeField should not be visible in preview, SmoothMarkdown should be
      expect(find.byType(CodeField), findsNothing);
      expect(find.byType(SmoothMarkdown), findsOneWidget);
    });

    testWidgets('should show split view with both editor and preview', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Tap on Split tab
      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();

      // Both CodeField and SmoothMarkdown should be visible
      expect(find.byType(CodeField), findsOneWidget);
      expect(find.byType(SmoothMarkdown), findsOneWidget);
    });

    testWidgets('should display filename in title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/my-note')),
      );

      await tester.pumpAndSettle();

      // Should show the filename
      expect(find.text('my-note'), findsOneWidget);
    });

    testWidgets('should show default filename for null path', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor()),
      );

      await tester.pumpAndSettle();

      // Should show 'Untitled' as default
      expect(find.text('Untitled'), findsOneWidget);
    });
  });

  group('AdvancedMarkdownEditor Toolbar Tests', () {
    testWidgets('should display formatting toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Should have bold button with tooltip
      expect(find.byTooltip('Bold (Ctrl+B)'), findsOneWidget);
      // Should have italic button
      expect(find.byTooltip('Italic (Ctrl+I)'), findsOneWidget);
      // Should have strikethrough button
      expect(find.byTooltip('Strikethrough'), findsOneWidget);
      // Should have inline code button
      expect(find.byTooltip('Inline Code'), findsOneWidget);
      // Should have quote button
      expect(find.byTooltip('Quote'), findsOneWidget);
      // Should have link button
      expect(find.byTooltip('Link (Ctrl+K)'), findsOneWidget);
      // Should have image button
      expect(find.byTooltip('Image'), findsOneWidget);
      // Should have bullet list button
      expect(find.byTooltip('Bullet List'), findsOneWidget);
      // Should have numbered list button
      expect(find.byTooltip('Numbered List'), findsOneWidget);
      // Should have task list button
      expect(find.byTooltip('Task List'), findsOneWidget);
      // Should have code block button
      expect(find.byTooltip('Code Block'), findsOneWidget);
      // Should have table button
      expect(find.byTooltip('Table'), findsOneWidget);
      // Should have horizontal rule button
      expect(find.byTooltip('Horizontal Rule'), findsOneWidget);
    });

    testWidgets('should have heading dropdown menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Should have heading dropdown
      expect(find.byTooltip('Insert Heading'), findsOneWidget);

      // Open the dropdown
      await tester.tap(find.byTooltip('Insert Heading'));
      await tester.pumpAndSettle();

      // Should show heading options
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Heading 2'), findsOneWidget);
      expect(find.text('Heading 3'), findsOneWidget);
      expect(find.text('Heading 4'), findsOneWidget);
      expect(find.text('Heading 5'), findsOneWidget);
      expect(find.text('Heading 6'), findsOneWidget);
    });

    testWidgets('should have save button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      expect(find.byTooltip('Save'), findsOneWidget);
    });
  });

  group('AdvancedMarkdownEditor Status Bar Tests', () {
    testWidgets('should display word and character count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Should show word count
      expect(find.textContaining('Words:'), findsOneWidget);
      // Should show character count
      expect(find.textContaining('Characters:'), findsOneWidget);
      // Should show file type
      expect(find.text('Markdown'), findsOneWidget);
    });

    testWidgets('should show zero counts for empty content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      expect(find.text('Words: 0'), findsOneWidget);
      expect(find.text('Characters: 0'), findsOneWidget);
    });
  });

  group('AdvancedMarkdownEditor Dialog Tests', () {
    testWidgets('should open link dialog when link button pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // First tap on the code field to give it focus
      await tester.tap(find.byType(CodeField));
      await tester.pumpAndSettle();

      // Tap link button
      await tester.tap(find.byTooltip('Link (Ctrl+K)'));
      await tester.pumpAndSettle();

      // Should show link dialog
      expect(find.text('Insert Link'), findsOneWidget);
      expect(find.text('Link Text'), findsOneWidget);
      expect(find.text('URL'), findsOneWidget);
      expect(find.text('Insert'), findsOneWidget);
    });

    testWidgets('should close link dialog on cancel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // First tap on the code field to give it focus
      await tester.tap(find.byType(CodeField));
      await tester.pumpAndSettle();

      // Open link dialog
      await tester.tap(find.byTooltip('Link (Ctrl+K)'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.textContaining('Cancel').first);
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Insert Link'), findsNothing);
    });

    testWidgets('should open image dialog when image button pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // First tap on the code field to give it focus
      await tester.tap(find.byType(CodeField));
      await tester.pumpAndSettle();

      // Tap image button
      await tester.tap(find.byTooltip('Image'));
      await tester.pumpAndSettle();

      // Should show image dialog
      expect(find.text('Insert Image'), findsOneWidget);
      expect(find.text('Alt Text'), findsOneWidget);
      expect(find.text('Image URL'), findsOneWidget);
    });
  });

  group('AdvancedMarkdownEditor Title Editing Tests', () {
    testWidgets('should show edit icon next to filename', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Should have edit icon (Icons.edit with size 16)
      expect(find.byIcon(Icons.edit), findsWidgets);
      // Should have document icon
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('title should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Find the title InkWell
      expect(find.byType(InkWell), findsWidgets);
    });
  });

  group('AdvancedMarkdownEditor Theme Support Tests', () {
    testWidgets('should render correctly in light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const AdvancedMarkdownEditor(filePath: '/test'),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(AdvancedMarkdownEditor), findsOneWidget);
      expect(find.byType(CodeField), findsOneWidget);
    });

    testWidgets('should render correctly in dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const AdvancedMarkdownEditor(filePath: '/test'),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(AdvancedMarkdownEditor), findsOneWidget);
      expect(find.byType(CodeField), findsOneWidget);
    });
  });

  group('AdvancedMarkdownEditor View Mode Tests', () {
    testWidgets('edit mode should be default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      // Edit mode should show CodeField, not SmoothMarkdown
      expect(find.byType(CodeField), findsOneWidget);
      expect(find.byType(SmoothMarkdown), findsNothing);
    });

    testWidgets('preview mode should hide editor', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.byType(CodeField), findsNothing);
      expect(find.byType(SmoothMarkdown), findsOneWidget);
    });

    testWidgets('split mode should show both', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedMarkdownEditor(filePath: '/test')),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();

      expect(find.byType(CodeField), findsOneWidget);
      expect(find.byType(SmoothMarkdown), findsOneWidget);
    });
  });

  group('AdvancedMarkdownEditor Extension Tests', () {
    test('should have correct file extension', () {
      expect(AdvancedMarkdownEditor.extension, equals('.md'));
    });
  });

  group('EditorViewMode Enum Tests', () {
    test('should have three modes', () {
      expect(EditorViewMode.values.length, equals(3));
      expect(EditorViewMode.values, contains(EditorViewMode.edit));
      expect(EditorViewMode.values, contains(EditorViewMode.preview));
      expect(EditorViewMode.values, contains(EditorViewMode.split));
    });
  });
}
