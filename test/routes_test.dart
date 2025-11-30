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

    test('splitScreen should be /split-screen', () {
      expect(RoutePaths.splitScreen, '/split-screen');
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

    group('splitScreenPath', () {
      test('returns base path when no files specified', () {
        final path = RoutePaths.splitScreenPath();
        expect(path, '/split-screen');
      });

      test('includes left path when specified', () {
        final path = RoutePaths.splitScreenPath(leftPath: '/my-note');
        expect(path, contains('/split-screen'));
        expect(path, contains('left='));
        expect(path, contains(Uri.encodeQueryComponent('/my-note')));
      });

      test('includes right path when specified', () {
        final path = RoutePaths.splitScreenPath(rightPath: '/other-note');
        expect(path, contains('/split-screen'));
        expect(path, contains('right='));
        expect(path, contains(Uri.encodeQueryComponent('/other-note')));
      });

      test('includes both paths when specified', () {
        final path = RoutePaths.splitScreenPath(
          leftPath: '/left-note',
          rightPath: '/right-note',
        );
        expect(path, contains('/split-screen'));
        expect(path, contains('left='));
        expect(path, contains('right='));
        expect(path, contains('&'));
      });

      test('properly encodes special characters in paths', () {
        final path = RoutePaths.splitScreenPath(
          leftPath: '/folder/my note',
          rightPath: '/folder/another note',
        );
        // Should be URL encoded (space becomes %20 or +)
        expect(path, contains('%20').or(contains('+')));
      });
    });
  });
}

// Custom matcher for or condition
extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
