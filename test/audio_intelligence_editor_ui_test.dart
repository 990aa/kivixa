import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/markdown/advanced_markdown_editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('text editor exposes dictation and read-aloud controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TextFileEditor()),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Dictate into document'), findsOneWidget);
    expect(find.byTooltip('Read document aloud'), findsWidgets);
  });

  testWidgets('markdown editor exposes dictation and read-aloud controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdvancedMarkdownEditor()),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Dictate into markdown'), findsOneWidget);
    expect(find.byTooltip('Read document aloud'), findsWidgets);
  });
}
