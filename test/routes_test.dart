import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/routes.dart';

void main() {
  test('Test that browseFilePath returns the browse page', () {
    final url = HomeRoutes.browseFilePath('/');
    expect(url.startsWith('/home/browse'), true);
  });

  group('RoutePaths', () {
    test('textFile should be /textfile', () {
      expect(RoutePaths.textFile, '/textfile');
    });

    test('textFilePath should encode path correctly', () {
      final path = RoutePaths.textFilePath('/my-document');
      expect(path, contains('/textfile'));
      expect(path, contains('path='));
    });

    test('textFilePath should handle special characters', () {
      final path = RoutePaths.textFilePath('/folder/my document');
      expect(path, contains('/textfile'));
      expect(path, contains('path='));
      // Should be URL encoded
      expect(path, contains('%20').or(contains('+')));
    });

    test('markdownFilePath should encode path correctly', () {
      final path = RoutePaths.markdownFilePath('/my-note');
      expect(path, contains('/markdown'));
      expect(path, contains('path='));
    });

    test('editFilePath should encode path correctly', () {
      final path = RoutePaths.editFilePath('/my-note');
      expect(path, contains('/edit'));
      expect(path, contains('path='));
    });
  });
}

// Custom matcher for or condition
extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
