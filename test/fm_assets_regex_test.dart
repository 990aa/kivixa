import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';

void main() {
  group('assetFileRegex', () {
    test('matches files ending with a number', () {
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.0'), true);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.0'), true);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.1'), true);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.1'), true);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.10'), true);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.10'), true);
      expect(FileManager.assetFileRegex.hasMatch('2023.11.30.kvx.0'), true);
    });
    test('doesn\'t match files containing a number in the middle', () {
      expect(FileManager.assetFileRegex.hasMatch('name.0.kvx'), false);
      expect(FileManager.assetFileRegex.hasMatch('name.1.kvx'), false);
      expect(FileManager.assetFileRegex.hasMatch('name.10.kvx'), false);
      expect(FileManager.assetFileRegex.hasMatch('2023.11.30.kvx'), false);
    });
    test('doesn\'t match files without an extension', () {
      expect(FileManager.assetFileRegex.hasMatch('name.0'), false);
      expect(FileManager.assetFileRegex.hasMatch('name.1'), false);
      expect(FileManager.assetFileRegex.hasMatch('name.10'), false);
      expect(FileManager.assetFileRegex.hasMatch('2023.11.30'), false);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx3.0'), false);
    });
    test('matches previews', () {
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.p'), true);
      expect(FileManager.assetFileRegex.hasMatch('name.kvx.p'), true);
    });
  });
}
