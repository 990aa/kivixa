import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/services/media_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProvider(this.tempPath);
  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('media_service_test');
    PathProviderPlatform.instance = MockPathProvider(tempDir.path);
    await MediaService.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MediaService Optimization Tests', () {
    test('clearWebCache deletes all files', () async {
      final cacheDir = Directory(
        p.join(tempDir.path, 'kivixa/assets/web_cache'),
      );
      await cacheDir.create(recursive: true);
      await File(p.join(cacheDir.path, 'f1.cache')).writeAsString('test');
      await File(p.join(cacheDir.path, 'f2.cache')).writeAsString('test');

      await MediaService.instance.clearWebCache();
      expect(cacheDir.listSync().isEmpty, isTrue);
    });

    test('getWebCacheSize returns correct total size', () async {
      final cacheDir = Directory(
        p.join(tempDir.path, 'kivixa/assets/web_cache'),
      );
      await cacheDir.create(recursive: true);
      await File(
        p.join(cacheDir.path, 'f1.cache'),
      ).writeAsBytes(List.filled(100, 0));
      await File(
        p.join(cacheDir.path, 'f2.cache'),
      ).writeAsBytes(List.filled(200, 0));

      final size = await MediaService.instance.getWebCacheSize();
      expect(size, 300);
    });
  });

  group('MediaService Original Tests', () {
    test('service instance is not null', () {
      expect(MediaService.instance, isNotNull);
    });

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

    test('detects image types from extension', () {
      expect(
        MediaElement(path: 'test.jpg', mediaType: MediaType.image).isImage,
        isTrue,
      );
      expect(
        MediaElement(path: 'test.png', mediaType: MediaType.image).isImage,
        isTrue,
      );
    });

    test('detects video types from extension', () {
      expect(
        MediaElement(path: 'test.mp4', mediaType: MediaType.video).isVideo,
        isTrue,
      );
    });
  });
}
