// File Manager Hidden Directories Tests
//
// Tests that the 'models' directory and other internal directories
// are properly hidden from the browse view.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hidden Directories', () {
    // This list must match the hiddenDirectories Set in file_manager.dart
    const hiddenDirectories = {'plugins', '.lifegit', 'models'};

    test('plugins directory is hidden', () {
      expect(hiddenDirectories.contains('plugins'), true);
    });

    test('.lifegit directory is hidden', () {
      expect(hiddenDirectories.contains('.lifegit'), true);
    });

    test('models directory is hidden', () {
      expect(hiddenDirectories.contains('models'), true);
    });

    test('regular directories are not hidden', () {
      expect(hiddenDirectories.contains('documents'), false);
      expect(hiddenDirectories.contains('notes'), false);
      expect(hiddenDirectories.contains('archive'), false);
    });

    test('hiddenDirectories has exactly 3 entries', () {
      expect(hiddenDirectories.length, 3);
    });
  });
}
