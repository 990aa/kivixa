import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/chat_attachment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatAttachmentService', () {
    test('extracts text content for text attachments', () async {
      final tempDir = await Directory.systemTemp.createTemp('kivixa_att_text_');
      final file = File('${tempDir.path}/note.txt');
      await file.writeAsString('alpha\nbeta\ngamma');

      final attachment = await ChatAttachmentService.fromFilePath(file.path);

      expect(attachment, isNotNull);
      expect(attachment!.fileName, 'note.txt');
      expect(attachment.hasExtractedText, isTrue);
      expect(attachment.extractedText, contains('alpha'));
      expect(attachment.binaryPreviewBase64, isNull);

      await tempDir.delete(recursive: true);
    });

    test(
      'provides binary preview when text extraction is unavailable',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'kivixa_att_binary_',
        );
        final file = File('${tempDir.path}/blob.bin');
        await file.writeAsBytes(
          List<int>.generate(256, (index) => (index * 13) % 256),
        );

        final attachment = await ChatAttachmentService.fromFilePath(file.path);

        expect(attachment, isNotNull);
        expect(attachment!.hasExtractedText, isFalse);
        expect(attachment.binaryPreviewBase64, isNotNull);

        final decoded = base64Decode(attachment.binaryPreviewBase64!);
        expect(decoded, isNotEmpty);

        await tempDir.delete(recursive: true);
      },
    );

    test('builds attachment prompt context for model consumption', () {
      const attachment = ChatAttachment(
        id: 'ctx-1',
        filePath: '/tmp/context.md',
        fileName: 'context.md',
        sizeBytes: 48,
        mediaType: 'text/plain',
        extractedText: 'Context body marker',
      );

      final context = ChatAttachmentService.buildPromptContext(const [
        attachment,
      ]);

      expect(context, contains('[Attached files]'));
      expect(context, contains('context.md'));
      expect(context, contains('Context body marker'));
    });
  });
}
