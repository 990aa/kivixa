// AssetsManager: manages large asset files, deduplication, and metadata.
// - Writes originals to assets_original/, thumbnails/raster to assets_cache/
// - Records file metadata (path, size, hash, mime) in assets table
// - Deduplicates by content hash

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../platform/storage_paths.dart';
import '../data/repository.dart';

class AssetsManager {
  final Repository repository;
  AssetsManager(this.repository);

  Future<String> _computeHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> addAsset(File file, {String? mime}) async {
    final hash = await _computeHash(file);
    final size = await file.length();
    final name = file.uri.pathSegments.last;
    final assetsDir = await StoragePaths.getAssetsOriginalDir();
    final destPath = '${assetsDir.path}/$hash-$name';
    final destFile = File(destPath);
    if (!await destFile.exists()) {
      await file.copy(destPath);
    }
    // Check for deduplication
    final existing = await repository.listAssets(hash: hash);
    if (existing.isNotEmpty) {
      return existing.first;
    }
    final asset = {
      'path': 'assets_original/$hash-$name', // relative path
      'size': size,
      'hash': hash,
      'mime': mime ?? '',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    final id = await repository.createAsset(asset);
    return {...asset, 'id': id};
  }

  // Add thumbnail or rasterized asset to cache
  Future<Map<String, dynamic>> addCacheAsset(File file, {String? mime}) async {
    final hash = await _computeHash(file);
    final size = await file.length();
    final name = file.uri.pathSegments.last;
    final cacheDir = await StoragePaths.getAssetsCacheDir();
    final destPath = '${cacheDir.path}/$hash-$name';
    final destFile = File(destPath);
    if (!await destFile.exists()) {
      await file.copy(destPath);
    }
    final asset = {
      'path': 'assets_cache/$hash-$name',
      'size': size,
      'hash': hash,
      'mime': mime ?? '',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    final id = await repository.createAsset(asset);
    return {...asset, 'id': id};
  }
}
