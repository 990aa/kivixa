import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/media/embedded_media_renderer.dart';
import 'package:kivixa/data/models/media_element.dart';

void main() {
  group('MediaContentParser', () {
    group('parseMarkdown', () {
      test('parses simple image markdown', () {
        const content = 'Some text\n![Alt](image.png)\nMore text';
        final results = MediaContentParser.parseMarkdown(content);

        expect(results.length, equals(1));
        expect(results[0].element.path, equals('image.png'));
        expect(results[0].element.altText, equals('Alt'));
        expect(results[0].startIndex, equals(10));
        // endIndex is exclusive, matching Dart's substring behavior
        expect(results[0].endIndex, equals(27));
      });

      test('parses extended markdown with dimensions', () {
        const content = '![Image|width=300,height=200](photo.jpg)';
        final results = MediaContentParser.parseMarkdown(content);

        expect(results.length, equals(1));
        expect(results[0].element.width, equals(300));
        expect(results[0].element.height, equals(200));
      });

      test('parses multiple media elements', () {
        const content = '''
# Title
![First](image1.png)
Some paragraph
![Second|width=500](image2.jpg)
![Third](video.mp4)
''';
        final results = MediaContentParser.parseMarkdown(content);

        expect(results.length, equals(3));
        expect(results[0].element.path, equals('image1.png'));
        expect(results[1].element.path, equals('image2.jpg'));
        expect(results[1].element.width, equals(500));
        expect(results[2].element.path, equals('video.mp4'));
        expect(results[2].element.isVideo, isTrue);
      });

      test('parses web URLs correctly', () {
        const content = '![Web](https://example.com/image.png)';
        final results = MediaContentParser.parseMarkdown(content);

        expect(results.length, equals(1));
        expect(results[0].element.isFromWeb, isTrue);
        expect(results[0].element.sourceType, equals(MediaSourceType.web));
      });

      test('parses all extended parameters', () {
        const content =
            '![Test|width=400,height=300,rotation=45,x=10,y=20,comment=Hello%20World,preview=true,pw=200,ph=150](test.jpg)';
        final results = MediaContentParser.parseMarkdown(content);

        expect(results.length, equals(1));
        final element = results[0].element;
        expect(element.width, equals(400));
        expect(element.height, equals(300));
        expect(element.rotation, equals(45.0));
        expect(element.posX, equals(10.0));
        expect(element.posY, equals(20.0));
        expect(element.comment, equals('Hello World'));
        expect(element.isPreviewMode, isTrue);
        expect(element.previewWidth, equals(200));
        expect(element.previewHeight, equals(150));
      });

      test('returns empty list for content without media', () {
        const content = 'Just some plain text without any images';
        final results = MediaContentParser.parseMarkdown(content);

        expect(results, isEmpty);
      });

      test('handles empty content', () {
        final results = MediaContentParser.parseMarkdown('');
        expect(results, isEmpty);
      });
    });

    group('replaceElement', () {
      test('replaces element with updated syntax', () {
        const content = 'Before ![Image](photo.jpg) After';
        final results = MediaContentParser.parseMarkdown(content);

        final newElement = results[0].element.copyWith(width: 500, height: 300);
        final newContent = MediaContentParser.replaceElement(
          content,
          results[0],
          newElement,
        );

        expect(newContent, contains('width=500'));
        expect(newContent, contains('height=300'));
        expect(newContent, contains('Before'));
        expect(newContent, contains('After'));
      });

      test('preserves content before and after', () {
        const content = 'Start\n\n![Image](photo.jpg)\n\nEnd';
        final results = MediaContentParser.parseMarkdown(content);

        final newElement = results[0].element.copyWith(rotation: 90);
        final newContent = MediaContentParser.replaceElement(
          content,
          results[0],
          newElement,
        );

        expect(newContent, startsWith('Start'));
        expect(newContent, endsWith('End'));
        expect(newContent, contains('rotation=90'));
      });
    });

    group('deleteElement', () {
      test('removes element from content', () {
        const content = 'Before\n![Image](photo.jpg)\nAfter';
        final results = MediaContentParser.parseMarkdown(content);

        final newContent = MediaContentParser.deleteElement(
          content,
          results[0],
        );

        expect(newContent, isNot(contains('![Image]')));
        expect(newContent, isNot(contains('photo.jpg')));
        expect(newContent, contains('Before'));
        expect(newContent, contains('After'));
      });

      test('handles element at start of content', () {
        const content = '![Image](photo.jpg)\nText after';
        final results = MediaContentParser.parseMarkdown(content);

        final newContent = MediaContentParser.deleteElement(
          content,
          results[0],
        );

        expect(newContent, equals('Text after'));
      });

      test('handles element at end of content', () {
        const content = 'Text before\n![Image](photo.jpg)';
        final results = MediaContentParser.parseMarkdown(content);

        final newContent = MediaContentParser.deleteElement(
          content,
          results[0],
        );

        expect(newContent.trim(), equals('Text before'));
      });
    });

    group('extractLocalPaths', () {
      test('extracts Windows paths', () {
        const content = 'Look at this: C:\\Users\\photos\\image.png';
        final paths = MediaContentParser.extractLocalPaths(content);

        expect(paths.length, equals(1));
        expect(paths[0], contains('C:\\'));
        expect(paths[0], endsWith('.png'));
      });

      test('extracts Unix paths', () {
        const content = 'File at /home/user/photos/image.jpg';
        final paths = MediaContentParser.extractLocalPaths(content);

        expect(paths.length, equals(1));
        expect(paths[0], startsWith('/'));
        expect(paths[0], endsWith('.jpg'));
      });

      test('filters out non-media files', () {
        const content =
            '/path/to/document.pdf /path/to/image.png /path/to/text.txt';
        final paths = MediaContentParser.extractLocalPaths(content);

        expect(paths.length, equals(1));
        expect(paths[0], endsWith('.png'));
      });

      test('excludes URLs', () {
        const content = 'https://example.com/image.png /local/image.jpg';
        final paths = MediaContentParser.extractLocalPaths(content);

        // Should only include local path
        expect(paths, isNot(contains('https:')));
        for (final path in paths) {
          expect(path, isNot(startsWith('http')));
        }
      });
    });

    group('extractWebImageUrls', () {
      test('extracts http URLs', () {
        const content = 'Image: http://example.com/photo.jpg';
        final urls = MediaContentParser.extractWebImageUrls(content);

        expect(urls.length, equals(1));
        expect(urls[0], equals('http://example.com/photo.jpg'));
      });

      test('extracts https URLs', () {
        const content = 'Image: https://example.com/photo.png';
        final urls = MediaContentParser.extractWebImageUrls(content);

        expect(urls.length, equals(1));
        expect(urls[0], equals('https://example.com/photo.png'));
      });

      test('extracts multiple URLs', () {
        const content = '''
          First: https://example.com/img1.png
          Second: http://cdn.example.com/img2.jpg
          Third: https://another.com/photo.webp
        ''';
        final urls = MediaContentParser.extractWebImageUrls(content);

        expect(urls.length, equals(3));
        expect(urls[0], contains('img1.png'));
        expect(urls[1], contains('img2.jpg'));
        expect(urls[2], contains('photo.webp'));
      });

      test('handles various image extensions', () {
        const content = '''
          PNG: https://a.com/image.png
          JPG: https://b.com/image.jpg
          JPEG: https://c.com/image.jpeg
          GIF: https://d.com/image.gif
          WebP: https://e.com/image.webp
          BMP: https://f.com/image.bmp
          SVG: https://g.com/image.svg
        ''';
        final urls = MediaContentParser.extractWebImageUrls(content);

        expect(urls.length, equals(7));
      });

      test('is case insensitive for extensions', () {
        const content = 'https://example.com/PHOTO.PNG';
        final urls = MediaContentParser.extractWebImageUrls(content);

        expect(urls.length, equals(1));
      });

      test('returns empty for non-image URLs', () {
        const content = 'https://example.com/document.pdf';
        final urls = MediaContentParser.extractWebImageUrls(content);

        expect(urls, isEmpty);
      });
    });
  });

  group('MediaParseResult', () {
    test('contains correct element and indices', () {
      final element = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
      );

      final result = MediaParseResult(
        element: element,
        startIndex: 10,
        endIndex: 30,
        originalText: '![Alt](test.jpg)',
      );

      expect(result.element.path, equals('test.jpg'));
      expect(result.startIndex, equals(10));
      expect(result.endIndex, equals(30));
      expect(result.originalText, equals('![Alt](test.jpg)'));
    });
  });
}
