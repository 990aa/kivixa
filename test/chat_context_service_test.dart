import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/services/ai/chat_context_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});
  });

  group('NotesActivityContextGateway', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('kivixa_context_test_');
      FileManager.shouldUseRawFilePath = false;
      await FileManager.init(
        documentsDirectory: tempRoot.path,
        shouldWatchRootDirectory: false,
      );
    });

    tearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('builds context with folders, markdown, and kvtx content', () async {
      final markdownFile = File('${tempRoot.path}/team/meeting.md');
      await markdownFile.parent.create(recursive: true);
      await markdownFile.writeAsString('# Meeting\n- Decision: ship v1');

      final kvtxFile = File('${tempRoot.path}/journal/daily.kvtx');
      await kvtxFile.parent.create(recursive: true);
      await kvtxFile.writeAsString(
        jsonEncode({
          'document': [
            {'insert': 'Daily note line one\n'},
            {'insert': 'Action item line two\n'},
          ],
          'fileName': 'daily',
          'version': 1,
        }),
      );

      const gateway = NotesActivityContextGateway(
        maxNotes: 5,
        maxCharsPerNote: 500,
        maxTotalChars: 5000,
      );

      final context = await gateway.buildContextSnapshot();

      expect(context, contains('### Folder Structure'));
      expect(context, contains('/team/'));
      expect(context, contains('/journal/'));
      expect(context, contains('#### /team/meeting.md'));
      expect(context, contains('Decision: ship v1'));
      expect(context, contains('#### /journal/daily.kvtx'));
      expect(context, contains('Action item line two'));
    });

    test('returns empty string when no markdown or kvtx notes exist', () async {
      const gateway = NotesActivityContextGateway();
      final context = await gateway.buildContextSnapshot();
      expect(context, isEmpty);
    });
  });
}
