import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

void main() {
  group('TextFileEditor extensions', () {
    test('should have correct internal extension', () {
      expect(TextFileEditor.internalExtension, equals('.kvtx'));
    });

    test('should have correct export extension', () {
      expect(TextFileEditor.extension, equals('.docx'));
    });
  });

  group('TextFileEditor font size sanitization', () {
    test('normalizeQuillFontSize handles legacy px values', () {
      expect(normalizeQuillFontSize('16px'), '16');
      expect(normalizeQuillFontSize('18.5PX'), '18.5');
    });

    test('normalizeQuillFontSize keeps valid values and rejects invalid', () {
      expect(normalizeQuillFontSize('14'), '14');
      expect(normalizeQuillFontSize('huge'), 'huge');
      expect(normalizeQuillFontSize('invalid-size'), isNull);
      expect(normalizeQuillFontSize(null), isNull);
    });

    test(
      'sanitizeQuillDocumentOps normalizes and removes invalid size attrs',
      () {
        final rawOps = <dynamic>[
          {
            'insert': 'Hello',
            'attributes': {'size': '18px', 'bold': true},
          },
          {
            'insert': ' world',
            'attributes': {'size': 'huge'},
          },
          {
            'insert': '!',
            'attributes': {'size': 'not-a-size', 'italic': true},
          },
          {'insert': '\n'},
        ];

        final sanitized = sanitizeQuillDocumentOps(rawOps);

        expect(
          (sanitized[0]['attributes'] as Map<String, dynamic>)['size'],
          '18',
        );
        expect(
          (sanitized[0]['attributes'] as Map<String, dynamic>)['bold'],
          true,
        );
        expect(
          (sanitized[1]['attributes'] as Map<String, dynamic>)['size'],
          'huge',
        );
        expect(
          (sanitized[2]['attributes'] as Map<String, dynamic>).containsKey(
            'size',
          ),
          isFalse,
        );
        expect(
          (sanitized[2]['attributes'] as Map<String, dynamic>)['italic'],
          true,
        );

        // Ensure original input is not mutated.
        expect(
          (rawOps[0]['attributes'] as Map<String, dynamic>)['size'],
          '18px',
        );
      },
    );
  });
}
