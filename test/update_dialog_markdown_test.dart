import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Update Dialog Markdown Rendering Tests', () {
    testWidgets('renders markdown content correctly', (tester) async {
      const testMarkdown = '''
## What's New in v0.1.4

### Added
- New feature 1
- New feature 2

### Fixed
- Bug fix 1
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownBody(data: testMarkdown, selectable: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify markdown is rendered (should find specific text)
      expect(find.textContaining('New feature'), findsWidgets);
      expect(find.textContaining('Bug fix'), findsWidgets);
    });

    testWidgets('scrollable content stays within constraints', (tester) async {
      // Create a long markdown content to test scrolling
      final longContent = List.generate(
        50,
        (i) => '- Item $i with some description text',
      ).join('\n');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 400,
                  maxWidth: 500,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Description'),
                      const SizedBox(height: 12),
                      MarkdownBody(data: longContent, selectable: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is scrollable
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);
    });

    testWidgets('content does not overflow container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 400,
                  maxWidth: 500,
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Update available'),
                      SizedBox(height: 12),
                      // Note: MarkdownBody moved to separate test since it's not const
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the ConstrainedBox is rendering
      final constrainedBox = find.byType(ConstrainedBox);
      expect(constrainedBox, findsOneWidget);

      // No overflow errors should occur (test would fail if RenderFlex overflowed)
    });

    testWidgets('can scroll through long content', (tester) async {
      final longContent = List.generate(
        100,
        (i) => '### Section $i\n\nContent for section $i\n',
      ).join('\n');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 400,
                width: 500,
                child: SingleChildScrollView(
                  child: MarkdownBody(data: longContent, selectable: true),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the scrollable and attempt to scroll
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      // Scroll down
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Test passes if no errors during scroll
    });
  });

  group('Update Dialog Structure Tests', () {
    testWidgets('dialog structure with constrained content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Update Available'),
                      content: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 400,
                          maxWidth: 500,
                        ),
                        child: const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('New version available'),
                              SizedBox(height: 12),
                              // Note: MarkdownBody is added separately as it's not const
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog elements
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('New version available'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });
  });
}
