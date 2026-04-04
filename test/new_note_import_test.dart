import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/home/new_note_button.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _buildDocxBytes(String documentXml) {
  final archive = Archive()
    ..addFile(
      ArchiveFile(
        'word/document.xml',
        documentXml.length,
        utf8.encode(documentXml),
      ),
    );

  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

void main() {
  setUpAll(() async {
    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});
  });

  group('Import note helpers', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('kivixa_import_test_');
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

    test('classifyImportedNoteType recognizes supported import formats', () {
      expect(
        classifyImportedNoteType('note.kvx'),
        ImportedNoteType.handwritten,
      );
      expect(
        classifyImportedNoteType('note.kvx1'),
        ImportedNoteType.handwritten,
      );
      expect(classifyImportedNoteType('paper.pdf'), ImportedNoteType.pdf);
      expect(classifyImportedNoteType('readme.md'), ImportedNoteType.markdown);
      expect(classifyImportedNoteType('plain.txt'), ImportedNoteType.text);
      expect(classifyImportedNoteType('report.docx'), ImportedNoteType.docx);
      expect(
        classifyImportedNoteType('archive.zip'),
        ImportedNoteType.unsupported,
      );
    });

    test('extractPlainTextFromDocxBytes keeps paragraph and tab content', () {
      const xml =
          '<w:document><w:body>'
          '<w:p><w:r><w:t>Hello</w:t></w:r></w:p>'
          '<w:p><w:r><w:t>World</w:t></w:r><w:tab/><w:r><w:t>Tab</w:t></w:r></w:p>'
          '</w:body></w:document>';

      final extracted = extractPlainTextFromDocxBytes(_buildDocxBytes(xml));

      expect(extracted, 'Hello\nWorld\tTab');
    });

    test(
      'importTextLikeNoteAsCopy imports txt as editable kvtx copy',
      () async {
        final source = File('${tempRoot.path}/external/source-note.txt');
        await source.parent.create(recursive: true);
        const sourceContent = 'Line one\nLine two';
        await source.writeAsString(sourceContent);

        final importedBasePath = await importTextLikeNoteAsCopy(
          sourcePath: source.path,
          destinationDir: '/imports/',
        );

        final importedFile = FileManager.getFile(
          '$importedBasePath${TextFileEditor.internalExtension}',
        );
        expect(importedFile.existsSync(), isTrue);
        expect(await source.readAsString(), sourceContent);

        final payload = json.decode(await importedFile.readAsString()) as Map;
        expect(payload['fileName'], 'source-note');

        final documentOps = payload['document'] as List;
        expect((documentOps.first as Map)['insert'], '$sourceContent\n');
      },
    );

    test(
      'markdown import creates a copied .md note with preserved content',
      () async {
        final source = File('${tempRoot.path}/external/outline.md');
        await source.parent.create(recursive: true);
        const sourceContent = '# Outline\n\n- Item A\n- Item B\n';
        await source.writeAsString(sourceContent);

        final importedBasePath = await FileManager.importFile(
          source.path,
          '/imports/',
          extension: '.md',
        );

        expect(importedBasePath, isNotNull);
        final copied = FileManager.getFile('$importedBasePath.md');
        expect(copied.existsSync(), isTrue);
        expect(await copied.readAsString(), sourceContent);
        expect(await source.readAsString(), sourceContent);
      },
    );

    test('importTextLikeNoteAsCopy imports docx text into kvtx copy', () async {
      const xml =
          '<w:document><w:body>'
          '<w:p><w:r><w:t>Agenda</w:t></w:r></w:p>'
          '<w:p><w:r><w:t>1. Intro</w:t></w:r><w:br/><w:r><w:t>2. Wrap-up</w:t></w:r></w:p>'
          '</w:body></w:document>';

      final source = File('${tempRoot.path}/external/meeting.docx');
      await source.parent.create(recursive: true);
      final sourceBytes = _buildDocxBytes(xml);
      await source.writeAsBytes(sourceBytes);

      final importedBasePath = await importTextLikeNoteAsCopy(
        sourcePath: source.path,
        destinationDir: '/imports/',
      );

      final importedFile = FileManager.getFile(
        '$importedBasePath${TextFileEditor.internalExtension}',
      );
      expect(importedFile.existsSync(), isTrue);
      expect(await source.readAsBytes(), sourceBytes);

      final payload = json.decode(await importedFile.readAsString()) as Map;
      final documentOps = payload['document'] as List;
      final importedText = (documentOps.first as Map)['insert'] as String;

      expect(importedText, contains('Agenda'));
      expect(importedText, contains('1. Intro'));
      expect(importedText, contains('2. Wrap-up'));
    });
  });
}
