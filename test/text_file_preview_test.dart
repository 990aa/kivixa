import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

void main() {
  group('TextFile preview card support', () {
    test('TextFileEditor internalExtension should be .kvxt', () {
      expect(TextFileEditor.internalExtension, '.kvxt');
    });

    test('TextFileEditor extension should be .docx', () {
      expect(TextFileEditor.extension, '.docx');
    });
  });
}
