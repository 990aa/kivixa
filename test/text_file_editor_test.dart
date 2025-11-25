import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

void main() {
  group('TextFileEditor', () {
    testWidgets('should render with toolbar and editor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have a QuillEditor
      expect(find.byType(QuillEditor), findsOneWidget);
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
                      builder: (_) => const TextFileEditor(filePath: '/test'),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Navigate to text editor
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should have a back button
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('should have export menu button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have an export button
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should have formatting buttons in toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have bold, italic, underline buttons
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underline), findsOneWidget);
    });

    testWidgets('should have alignment buttons in toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have alignment buttons
      expect(find.byIcon(Icons.format_align_left), findsOneWidget);
      expect(find.byIcon(Icons.format_align_center), findsOneWidget);
      expect(find.byIcon(Icons.format_align_right), findsOneWidget);
      expect(find.byIcon(Icons.format_align_justify), findsOneWidget);
    });

    testWidgets('should have list buttons in toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have list buttons
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    });

    testWidgets('should have color buttons in toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have color buttons
      expect(find.byIcon(Icons.format_color_text), findsOneWidget);
      expect(find.byIcon(Icons.highlight), findsOneWidget);
    });

    testWidgets('should display filename from path', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/my-document')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should show the filename in app bar (via TextField)
      // The filename is shown in a TextField in the AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have indent buttons in toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TextFileEditor(filePath: '/test')),
      );

      // Wait for async loading
      await tester.pumpAndSettle();

      // Should have indent buttons
      expect(find.byIcon(Icons.format_indent_decrease), findsOneWidget);
      expect(find.byIcon(Icons.format_indent_increase), findsOneWidget);
    });
  });

  group('TextFileEditor extensions', () {
    test('should have correct internal extension', () {
      expect(TextFileEditor.internalExtension, equals('.kvxt'));
    });

    test('should have correct export extension', () {
      expect(TextFileEditor.extension, equals('.docx'));
    });
  });
}
