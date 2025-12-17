import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for handling media upload, storage, caching, and web fetching.
///
/// Implements:
/// - Local media upload with unique naming
/// - Web image fetching with LRU caching
/// - Thumbnail generation for performance
/// - Orphaned media cleanup
class MediaService {
  MediaService._();

  static final instance = MediaService._();

  final _log = Logger('MediaService');

  /// LRU cache for loaded images (path -> bytes)
  final _imageCache = _LruCache<String, Uint8List>(maxSize: 100);

  /// Cache for decoded images for faster rendering
  final _decodedImageCache = _LruCache<String, ui.Image>(maxSize: 50);

  /// Directory for storing uploaded media
  Directory? _mediaDir;

  /// Directory for thumbnails
  Directory? _thumbnailDir;

  /// Directory for cached web images
  Directory? _webCacheDir;

  /// Initialize the media service directories
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDir = Directory('${appDir.path}/kivixa_assets/media');
    _thumbnailDir = Directory('${appDir.path}/kivixa_assets/thumbnails');
    _webCacheDir = Directory('${appDir.path}/kivixa_assets/web_cache');

    await _mediaDir!.create(recursive: true);
    await _thumbnailDir!.create(recursive: true);
    await _webCacheDir!.create(recursive: true);

    _log.info('MediaService initialized');
  }

  /// Get the media directory path
  String get mediaPath => _mediaDir?.path ?? '';

  /// Upload a local media file to the app's media directory
  /// Returns the new path within the app's storage
  Future<String> uploadMedia(String sourcePath) async {
    if (_mediaDir == null) await init();

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = path.basename(sourcePath);
    final ext = path.extension(originalName);
    final baseName = path.basenameWithoutExtension(originalName);
    final uniqueName = '${baseName}_$timestamp$ext';
    final destPath = '${_mediaDir!.path}/$uniqueName';

    // Copy file to media directory
    await sourceFile.copy(destPath);
    _log.info('Media uploaded: $destPath');

    return destPath;
  }

  /// Fetch an image from web URL
  /// Uses caching according to settings (download locally or fetch on demand)
  Future<Uint8List?> fetchWebImage(String url) async {
    // Check memory cache first
    final cached = _imageCache.get(url);
    if (cached != null) {
      _log.fine('Web image from memory cache: $url');
      return cached;
    }

    // Check if we should use local storage cache
    final webImageMode = stows.webImageMode.value;

    if (webImageMode == 0) {
      // Mode 0: Download locally
      return _fetchAndCacheLocally(url);
    } else {
      // Mode 1: Fetch on demand (memory cache only)
      return _fetchOnDemand(url);
    }
  }

  /// Fetch and cache image to local storage
  Future<Uint8List?> _fetchAndCacheLocally(String url) async {
    if (_webCacheDir == null) await init();

    // Generate cache filename from URL hash
    final cacheFileName = '${url.hashCode.toRadixString(16)}.cache';
    final cacheFile = File('${_webCacheDir!.path}/$cacheFileName');

    // Check local cache
    if (await cacheFile.exists()) {
      final bytes = await cacheFile.readAsBytes();
      _imageCache.put(url, bytes);
      _log.fine('Web image from local cache: $url');
      return bytes;
    }

    // Fetch from web
    final bytes = await _downloadImage(url);
    if (bytes != null) {
      // Save to local cache
      await cacheFile.writeAsBytes(bytes);
      _imageCache.put(url, bytes);
      _log.info('Web image cached locally: $url');
    }

    return bytes;
  }

  /// Fetch image on demand (memory cache only)
  Future<Uint8List?> _fetchOnDemand(String url) async {
    final bytes = await _downloadImage(url);
    if (bytes != null) {
      _imageCache.put(url, bytes);
      _log.fine('Web image fetched on demand: $url');
    }
    return bytes;
  }

  /// Download image from URL
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Kivixa/1.0'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        _log.warning('Failed to fetch image: ${response.statusCode} - $url');
        return null;
      }
    } catch (e) {
      _log.warning('Error fetching web image: $e');
      return null;
    }
  }

  /// Load a local image file
  Future<Uint8List?> loadLocalImage(String filePath) async {
    // Check memory cache first
    final cached = _imageCache.get(filePath);
    if (cached != null) {
      return cached;
    }

    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _imageCache.put(filePath, bytes);
        return bytes;
      }
    } catch (e) {
      _log.warning('Error loading local image: $e');
    }
    return null;
  }

  /// Resolve a path (local or URL) to bytes
  Future<Uint8List?> resolveMedia(MediaElement element) async {
    if (element.isFromWeb) {
      return fetchWebImage(element.path);
    } else {
      return loadLocalImage(element.path);
    }
  }

  /// Validate and resolve a local file path
  /// Returns true if the file exists and is accessible
  Future<bool> resolveLocalPath(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Generate a thumbnail for a large image
  /// Returns path to the thumbnail file
  Future<String?> getThumbnail(
    String originalPath, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    if (_thumbnailDir == null) await init();

    // Generate thumbnail filename
    final thumbName =
        '${originalPath.hashCode.toRadixString(16)}_${maxWidth}x$maxHeight.thumb';
    final thumbPath = '${_thumbnailDir!.path}/$thumbName';
    final thumbFile = File(thumbPath);

    // Check if thumbnail already exists
    if (await thumbFile.exists()) {
      return thumbPath;
    }

    // Load original image
    final bytes = await loadLocalImage(originalPath);
    if (bytes == null) return null;

    // Generate thumbnail in isolate for performance
    try {
      final thumbnailBytes = await compute(
        _generateThumbnailIsolate,
        _ThumbnailParams(bytes, maxWidth, maxHeight),
      );

      if (thumbnailBytes != null) {
        await thumbFile.writeAsBytes(thumbnailBytes);
        _log.info('Thumbnail generated: $thumbPath');
        return thumbPath;
      }
    } catch (e) {
      _log.warning('Error generating thumbnail: $e');
    }

    return null;
  }

  /// Clear the web image cache
  Future<void> clearWebCache() async {
    if (_webCacheDir == null) return;

    try {
      if (await _webCacheDir!.exists()) {
        await for (final entity in _webCacheDir!.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
        _log.info('Web cache cleared');
      }
    } catch (e) {
      _log.warning('Error clearing web cache: $e');
    }

    _imageCache.clear();
  }

  /// Get the size of the web cache in bytes
  Future<int> getWebCacheSize() async {
    if (_webCacheDir == null || !await _webCacheDir!.exists()) return 0;

    var size = 0;
    await for (final entity in _webCacheDir!.list()) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// Delete media associated with a deleted note
  /// Only deletes if deleteMediaWithNote setting is enabled
  Future<void> deleteOrphanedMedia(List<String> mediaPaths) async {
    if (!stows.deleteMediaWithNote.value) return;

    for (final mediaPath in mediaPaths) {
      try {
        // Only delete files within our media directory
        if (mediaPath.startsWith(_mediaDir?.path ?? '')) {
          final file = File(mediaPath);
          if (await file.exists()) {
            await file.delete();
            _log.info('Orphaned media deleted: $mediaPath');
          }
        }

        // Also delete thumbnail if exists
        final thumbName = '${mediaPath.hashCode.toRadixString(16)}*.thumb';
        if (_thumbnailDir != null && await _thumbnailDir!.exists()) {
          await for (final entity in _thumbnailDir!.list()) {
            if (entity is File && entity.path.contains(thumbName)) {
              await entity.delete();
            }
          }
        }
      } catch (e) {
        _log.warning('Error deleting orphaned media: $e');
      }
    }
  }

  /// Clear memory caches
  void clearMemoryCache() {
    _imageCache.clear();
    _decodedImageCache.clear();
  }

  /// Get decoded image from cache or decode it
  Future<ui.Image?> getDecodedImage(String pathOrUrl, Uint8List bytes) async {
    final cached = _decodedImageCache.get(pathOrUrl);
    if (cached != null) return cached;

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      _decodedImageCache.put(pathOrUrl, image);
      return image;
    } catch (e) {
      _log.warning('Error decoding image: $e');
      return null;
    }
  }
}

/// Parameters for thumbnail generation in isolate
class _ThumbnailParams {
  final Uint8List bytes;
  final int maxWidth;
  final int maxHeight;

  _ThumbnailParams(this.bytes, this.maxWidth, this.maxHeight);
}

/// Generate thumbnail in isolate
/// Note: This is a simplified version - actual implementation would use
/// image processing library like flutter_image_compress
Uint8List? _generateThumbnailIsolate(_ThumbnailParams params) {
  // For now, return the original bytes
  // In production, we'd use flutter_image_compress or similar
  // to actually resize the image
  return params.bytes;
}

/// Simple LRU cache implementation
class _LruCache<K, V> {
  final int maxSize;
  final _cache = <K, V>{};
  var _currentSize = 0;

  _LruCache({required this.maxSize});

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end (most recently used)
    }
    return value;
  }

  void put(K key, V value) {
    _cache.remove(key);
    _cache[key] = value;

    // Calculate size for Uint8List values
    if (value is Uint8List) {
      _currentSize += value.length;
    } else {
      _currentSize += 1; // Approximate size for other types
    }

    // Evict oldest entries if over size
    while (_currentSize > maxSize * 1024 * 1024 && _cache.isNotEmpty) {
      final oldest = _cache.keys.first;
      final removed = _cache.remove(oldest);
      if (removed is Uint8List) {
        _currentSize -= removed.length;
      } else {
        _currentSize -= 1;
      }
    }
  }

  void clear() {
    _cache.clear();
    _currentSize = 0;
  }

  int get size => _currentSize;
  int get length => _cache.length;
}
