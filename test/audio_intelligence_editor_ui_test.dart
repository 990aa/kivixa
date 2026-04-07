import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/pages/markdown/advanced_markdown_editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});
    FileManager.shouldUseRawFilePath = true;
  });

  testWidgets('text editor exposes dictation and read-aloud controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TextFileEditor()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Dictate into document'), findsOneWidget);
    expect(find.byTooltip('Read document aloud'), findsWidgets);
  });

  testWidgets('markdown editor exposes dictation and read-aloud controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdvancedMarkdownEditor()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Dictate into markdown'), findsOneWidget);
    expect(find.byTooltip('Read document aloud'), findsWidgets);
  });
}
