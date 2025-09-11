import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';

class ThumbnailManager {
  final DatabaseProvider _provider = DatabaseProvider();
  final Map<int, Uint8List> _memoryCache = {};

  Future<Uint8List> getThumbnail(
    int pageId,
    Future<Uint8List> Function() generator,
  ) async {
    if (_memoryCache.containsKey(pageId)) {
      return _memoryCache[pageId]!;
    }
    final db = await _provider.database;
    final result = await db.query(
      'page_thumbnails',
      where: 'page_id = ?',
      whereArgs: [pageId],
    );
    if (result.isNotEmpty) {
      final bytes = result.first['thumbnail'] as Uint8List;
      _memoryCache[pageId] = bytes;
      return bytes;
    }
    final bytes = await generator();
    await db.insert('page_thumbnails', {
      'page_id': pageId,
      'thumbnail': bytes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _memoryCache[pageId] = bytes;
    return bytes;
  }

  void invalidate(int pageId) {
    _memoryCache.remove(pageId);
  }
}
