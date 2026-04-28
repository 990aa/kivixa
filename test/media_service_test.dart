import 'dart:io';

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

  group('MediaService clearWebCache', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kivixa_clear_cache_');
      await MediaService.instance.initWithDirectories(
        mediaDir: Directory('${tempDir.path}/media'),
        thumbnailDir: Directory('${tempDir.path}/thumbnails'),
        webCacheDir: Directory('${tempDir.path}/web_cache'),
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('deletes all files in cache directory', () async {
      final cacheDir = Directory('${tempDir.path}/web_cache');
      await File('${cacheDir.path}/file1.jpg').writeAsBytes([1, 2, 3]);
      await File('${cacheDir.path}/file2.jpg').writeAsBytes([4, 5, 6]);

      await MediaService.instance.clearWebCache();

      final remaining = cacheDir.listSync().whereType<File>().toList();
      expect(remaining, isEmpty);
    });

    test('completes without error on empty cache directory', () async {
      await expectLater(MediaService.instance.clearWebCache(), completes);
    });

    test('completes without error when cache directory does not exist',
        () async {
      final absentDir = Directory('${tempDir.path}/absent');
      await MediaService.instance.initWithDirectories(
        mediaDir: Directory('${tempDir.path}/media'),
        thumbnailDir: Directory('${tempDir.path}/thumbnails'),
        webCacheDir: absentDir,
      );
      // Remove the directory that initWithDirectories created.
      await absentDir.delete(recursive: true);

      await expectLater(MediaService.instance.clearWebCache(), completes);
    });
  });

  group('MediaService getWebCacheSize', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kivixa_cache_size_');
      await MediaService.instance.initWithDirectories(
        mediaDir: Directory('${tempDir.path}/media'),
        thumbnailDir: Directory('${tempDir.path}/thumbnails'),
        webCacheDir: Directory('${tempDir.path}/web_cache'),
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns 0 for empty cache directory', () async {
      final size = await MediaService.instance.getWebCacheSize();
      expect(size, 0);
    });

    test('returns total size of all files', () async {
      final cacheDir = Directory('${tempDir.path}/web_cache');
      await File('${cacheDir.path}/a.jpg').writeAsBytes(List.filled(100, 0));
      await File('${cacheDir.path}/b.jpg').writeAsBytes(List.filled(200, 0));

      final size = await MediaService.instance.getWebCacheSize();
      expect(size, 300);
    });

    test('returns size of only existing files when one has been deleted',
        () async {
      final cacheDir = Directory('${tempDir.path}/web_cache');
      final fileA = await File(
        '${cacheDir.path}/a.jpg',
      ).writeAsBytes(List.filled(150, 0));
      final fileB = File('${cacheDir.path}/b.jpg');
      await fileB.writeAsBytes(List.filled(50, 0));
      await fileB.delete();

      // fileB was created then deleted before the call; only fileA is counted.
      // Verifies the function does not return 0 for the whole cache.
      final size = await MediaService.instance.getWebCacheSize();
      expect(size, fileA.lengthSync());
    });

    test('returns 0 when cache directory does not exist', () async {
      final absentDir = Directory('${tempDir.path}/absent');
      await MediaService.instance.initWithDirectories(
        mediaDir: Directory('${tempDir.path}/media'),
        thumbnailDir: Directory('${tempDir.path}/thumbnails'),
        webCacheDir: absentDir,
      );
      await absentDir.delete(recursive: true);

      final size = await MediaService.instance.getWebCacheSize();
      expect(size, 0);
    });
  });
}
