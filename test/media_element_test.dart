import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/media_element.dart';

void main() {
  group('MediaElement', () {
    group('fromMarkdownSyntax', () {
      test('parses simple image markdown', () {
        const markdown = '![Alt Text](https://example.com/image.png)';
        final element = MediaElement.fromMarkdownSyntax(markdown);

        expect(element, isNotNull);
        expect(element!.altText, equals('Alt Text'));
        expect(element.path, equals('https://example.com/image.png'));
        expect(element.sourceType, equals(MediaSourceType.web));
        expect(element.mediaType, equals(MediaType.image));
      });

      test('parses extended markdown with width and height', () {
        const markdown = '![Image|width=300,height=200](path/to/image.jpg)';
        final element = MediaElement.fromMarkdownSyntax(markdown);

        expect(element, isNotNull);
        expect(element!.altText, equals('Image'));
        expect(element.width, equals(300));
        expect(element.height, equals(200));
        expect(element.path, equals('path/to/image.jpg'));
      });

      test('parses markdown with rotation and position', () {
        const markdown = '![Rotated|rotation=45.0,x=10.5,y=20.3](image.png)';
        final element = MediaElement.fromMarkdownSyntax(markdown);

        expect(element, isNotNull);
        expect(element!.rotation, equals(45.0));
        expect(element.posX, equals(10.5));
        expect(element.posY, equals(20.3));
      });

      test('parses markdown with comment', () {
        const markdown = '![Image|comment=Hello%20World](image.png)';
        final element = MediaElement.fromMarkdownSyntax(markdown);

        expect(element, isNotNull);
        expect(element!.comment, equals('Hello World'));
      });

      test('parses markdown with preview mode', () {
        const markdown =
            '![Large|preview=true,pw=200,ph=150,sx=10,sy=20](big.jpg)';
        final element = MediaElement.fromMarkdownSyntax(markdown);

        expect(element, isNotNull);
        expect(element!.isPreviewMode, isTrue);
        expect(element.previewWidth, equals(200));
        expect(element.previewHeight, equals(150));
        expect(element.scrollOffsetX, equals(10));
        expect(element.scrollOffsetY, equals(20));
      });

      test('detects video files', () {
        const markdown = '![Video](path/to/video.mp4)';
        final element = MediaElement.fromMarkdownSyntax(markdown);

        expect(element, isNotNull);
        expect(element!.mediaType, equals(MediaType.video));
        expect(element.isVideo, isTrue);
      });

      test('detects local vs web paths', () {
        final localElement = MediaElement.fromMarkdownSyntax(
          '![Local](/path/to/image.jpg)',
        );
        final webElement = MediaElement.fromMarkdownSyntax(
          '![Web](https://example.com/image.jpg)',
        );

        expect(localElement!.isLocal, isTrue);
        expect(localElement.isFromWeb, isFalse);
        expect(webElement!.isFromWeb, isTrue);
        expect(webElement.isLocal, isFalse);
      });

      test('returns null for invalid markdown', () {
        expect(MediaElement.fromMarkdownSyntax('not markdown'), isNull);
        expect(MediaElement.fromMarkdownSyntax('[link](url)'), isNull);
      });
    });

    group('toMarkdownSyntax', () {
      test('generates simple markdown', () {
        final element = MediaElement(
          path: 'https://example.com/image.png',
          mediaType: MediaType.image,
          altText: 'Alt Text',
        );

        expect(
          element.toMarkdownSyntax(),
          equals('![Alt Text](https://example.com/image.png)'),
        );
      });

      test('generates markdown with dimensions', () {
        final element = MediaElement(
          path: 'image.jpg',
          mediaType: MediaType.image,
          altText: 'Image',
          width: 300,
          height: 200,
        );

        final markdown = element.toMarkdownSyntax();
        expect(markdown, contains('width=300'));
        expect(markdown, contains('height=200'));
      });

      test('generates markdown with rotation', () {
        final element = MediaElement(
          path: 'image.jpg',
          mediaType: MediaType.image,
          altText: 'Image',
          rotation: 90.0,
        );

        expect(element.toMarkdownSyntax(), contains('rotation=90.0'));
      });

      test('URL encodes comment', () {
        final element = MediaElement(
          path: 'image.jpg',
          mediaType: MediaType.image,
          altText: 'Image',
          comment: 'Hello World',
        );

        expect(element.toMarkdownSyntax(), contains('comment=Hello%20World'));
      });

      test('round-trips through markdown syntax', () {
        final original = MediaElement(
          path: 'https://example.com/image.png',
          mediaType: MediaType.image,
          altText: 'Test Image',
          width: 400,
          height: 300,
          rotation: 45.0,
          posX: 10.0,
          posY: 20.0,
          comment: 'A test comment',
        );

        final markdown = original.toMarkdownSyntax();
        final parsed = MediaElement.fromMarkdownSyntax(markdown);

        expect(parsed, isNotNull);
        expect(parsed!.path, equals(original.path));
        expect(parsed.altText, equals(original.altText));
        expect(parsed.width, equals(original.width));
        expect(parsed.height, equals(original.height));
        expect(parsed.rotation, equals(original.rotation));
        expect(parsed.posX, equals(original.posX));
        expect(parsed.posY, equals(original.posY));
        expect(parsed.comment, equals(original.comment));
      });
    });

    group('JSON serialization', () {
      test('serializes to JSON', () {
        final element = MediaElement(
          path: '/path/to/image.png',
          mediaType: MediaType.image,
          sourceType: MediaSourceType.local,
          altText: 'Test',
          width: 300,
          height: 200,
        );

        final json = element.toJson();

        expect(json['path'], equals('/path/to/image.png'));
        expect(json['mediaType'], equals('image'));
        expect(json['sourceType'], equals('local'));
        expect(json['altText'], equals('Test'));
        expect(json['width'], equals(300));
        expect(json['height'], equals(200));
      });

      test('deserializes from JSON', () {
        final json = {
          'path': '/path/to/video.mp4',
          'mediaType': 'video',
          'sourceType': 'local',
          'altText': 'Video',
          'width': 640,
          'height': 480,
          'rotation': 0.0,
        };

        final element = MediaElement.fromJson(json);

        expect(element.path, equals('/path/to/video.mp4'));
        expect(element.mediaType, equals(MediaType.video));
        expect(element.sourceType, equals(MediaSourceType.local));
        expect(element.width, equals(640));
        expect(element.height, equals(480));
      });

      test('round-trips through JSON', () {
        final original = MediaElement(
          path: 'https://example.com/image.png',
          mediaType: MediaType.image,
          sourceType: MediaSourceType.web,
          altText: 'Test Image',
          width: 400,
          height: 300,
          rotation: 45.0,
          posX: 10.0,
          posY: 20.0,
          comment: 'A test comment',
          isPreviewMode: true,
          previewWidth: 200,
          previewHeight: 150,
        );

        final jsonString = original.toJsonString();
        final parsed = MediaElement.fromJsonString(jsonString);

        expect(parsed.path, equals(original.path));
        expect(parsed.mediaType, equals(original.mediaType));
        expect(parsed.sourceType, equals(original.sourceType));
        expect(parsed.width, equals(original.width));
        expect(parsed.height, equals(original.height));
        expect(parsed.rotation, equals(original.rotation));
        expect(parsed.isPreviewMode, equals(original.isPreviewMode));
      });
    });

    group('copyWith', () {
      test('creates a copy with modified fields', () {
        final original = MediaElement(
          path: 'image.png',
          mediaType: MediaType.image,
          width: 100,
          height: 100,
        );

        final modified = original.copyWith(width: 200, height: 150);

        expect(modified.path, equals(original.path));
        expect(modified.width, equals(200));
        expect(modified.height, equals(150));
      });
    });

    group('getters', () {
      test('hasCustomDimensions', () {
        expect(
          MediaElement(
            path: 'a.png',
            mediaType: MediaType.image,
          ).hasCustomDimensions,
          isFalse,
        );
        expect(
          MediaElement(
            path: 'a.png',
            mediaType: MediaType.image,
            width: 100,
          ).hasCustomDimensions,
          isTrue,
        );
      });

      test('hasRotation', () {
        expect(
          MediaElement(path: 'a.png', mediaType: MediaType.image).hasRotation,
          isFalse,
        );
        expect(
          MediaElement(
            path: 'a.png',
            mediaType: MediaType.image,
            rotation: 45,
          ).hasRotation,
          isTrue,
        );
      });

      test('hasComment', () {
        expect(
          MediaElement(path: 'a.png', mediaType: MediaType.image).hasComment,
          isFalse,
        );
        expect(
          MediaElement(
            path: 'a.png',
            mediaType: MediaType.image,
            comment: 'test',
          ).hasComment,
          isTrue,
        );
      });
    });
  });
}
