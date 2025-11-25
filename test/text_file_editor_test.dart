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
}
