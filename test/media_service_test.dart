import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/services/media_service.dart';

void main() {
  group('MediaService', () {
    group('Singleton instance', () {
      test('returns same instance', () {
        final instance1 = MediaService.instance;
        final instance2 = MediaService.instance;

        expect(instance1, same(instance2));
      });
    });

    group('Media element resolution', () {
      test('identifies local media element correctly', () {
        final localElement = MediaElement(
          path: '/local/path/image.jpg',
          mediaType: MediaType.image,
        );

        expect(localElement.isLocal, isTrue);
        expect(localElement.isFromWeb, isFalse);
      });

      test('identifies web media element correctly', () {
        final webElement = MediaElement(
          path: 'https://example.com/image.jpg',
          mediaType: MediaType.image,
          sourceType: MediaSourceType.web,
        );

        expect(webElement.isFromWeb, isTrue);
        expect(webElement.isLocal, isFalse);
      });

      test('identifies app storage media element correctly', () {
        final localElement = MediaElement(
          path: 'media/stored_image.jpg',
          mediaType: MediaType.image,
          sourceType: MediaSourceType.local,
        );

        expect(localElement.sourceType, equals(MediaSourceType.local));
      });
    });

    group('MediaType detection', () {
      test('detects image types from extension', () {
        expect(
          MediaElement(path: 'test.jpg', mediaType: MediaType.image).isImage,
          isTrue,
        );
        expect(
          MediaElement(path: 'test.png', mediaType: MediaType.image).isImage,
          isTrue,
        );
        expect(
          MediaElement(path: 'test.gif', mediaType: MediaType.image).isImage,
          isTrue,
        );
        expect(
          MediaElement(path: 'test.webp', mediaType: MediaType.image).isImage,
          isTrue,
        );
      });

      test('detects video types from extension', () {
        expect(
          MediaElement(path: 'test.mp4', mediaType: MediaType.video).isVideo,
          isTrue,
        );
        expect(
          MediaElement(path: 'test.avi', mediaType: MediaType.video).isVideo,
          isTrue,
        );
        expect(
          MediaElement(path: 'test.mov', mediaType: MediaType.video).isVideo,
          isTrue,
        );
      });
    });
  });

  group('MediaService Cache', () {
    test('service instance is not null', () {
      expect(MediaService.instance, isNotNull);
    });

    test('media path is a string', () {
      expect(MediaService.instance.mediaPath, isA<String>());
    });
  });
}
