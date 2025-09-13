import 'dart:async';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

class TiledThumbnailsService {
  final Database db;

  TiledThumbnailsService(this.db);

  Future<int?> getThumbnailAssetId(int pageId) async {
    final result = await db.query(
      'page_thumbnails',
      columns: ['asset_id'],
      where: 'page_id = ?',
      whereArgs: [pageId],
    );
    if (result.isNotEmpty) {
      return result.first['asset_id'] as int?;
    }
    return null;
  }

  Future<int> generateThumbnail(int pageId) async {
    // For now, we'll just create a placeholder thumbnail.
    // In a real implementation, this would involve rendering the page content.
    final Uint8List thumbnailData = Uint8List(0);

    final assetId = await db.transaction((txn) async {
      final asset = {
        'path': '',
        'size': thumbnailData.length,
        'hash': '',
        'mime': 'image/png',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      final assetId = await txn.insert('assets', asset);

      final thumbnail = {
        'page_id': pageId,
        'asset_id': assetId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      await txn.insert('page_thumbnails', thumbnail);

      return assetId;
    });

    return assetId;
  }

  Future<void> markStale(int pageId) async {
    await db.transaction((txn) async {
      final assetId = await getThumbnailAssetId(pageId);
      if (assetId != null) {
        await txn.delete('page_thumbnails', where: 'page_id = ?', whereArgs: [pageId]);
        await txn.delete('assets', where: 'id = ?', whereArgs: [assetId]);
      }
    });
  }

  Future<void> addPage(int documentId, int pageIndex) async {
    await db.transaction((txn) async {
      final page = {
        'document_id': documentId,
        'page_index': pageIndex,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      final pageId = await txn.insert('pages', page);
      await generateThumbnail(pageId);
    });
  }

  Future<void> deletePage(int pageId) async {
    await db.transaction((txn) async {
      await markStale(pageId);
      await txn.delete('pages', where: 'id = ?', whereArgs: [pageId]);
    });
  }

  Future<void> movePage(int pageId, int newDocumentId, int newPageIndex) async {
    await db.transaction((txn) async {
      await txn.update(
        'pages',
        {
          'document_id': newDocumentId,
          'page_index': newPageIndex,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [pageId],
      );
    });
  }

  Future<void> copyPage(int pageId, int newDocumentId, int newPageIndex) async {
    await db.transaction((txn) async {
      final page = await txn.query('pages', where: 'id = ?', whereArgs: [pageId]);
      if (page.isNotEmpty) {
        final newPage = Map<String, dynamic>.from(page.first);
        newPage.remove('id');
        newPage['document_id'] = newDocumentId;
        newPage['page_index'] = newPageIndex;
        newPage['created_at'] = DateTime.now().millisecondsSinceEpoch;
        newPage['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        final newPageId = await txn.insert('pages', newPage);

        // For now, we'll just generate a new thumbnail.
        // A real implementation might copy the page content and then generate a thumbnail.
        await generateThumbnail(newPageId);
      }
    });
  }
}