import 'dart:async';

import 'package:sqflite/sqflite.dart';

class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect(this.left, this.top, this.right, this.bottom);
}

class Tile {
  final int tileIndex;
  final int assetId;

  Tile(this.tileIndex, this.assetId);
}

class InfiniteCanvasModel {
  final Database db;
  final int tileSize;

  InfiniteCanvasModel(this.db, {this.tileSize = 256});

  Future<List<Tile>> getTilesInViewport(int pageId, Rect viewport) async {
    final int startX = (viewport.left / tileSize).floor();
    final int startY = (viewport.top / tileSize).floor();
    final int endX = (viewport.right / tileSize).ceil();
    final int endY = (viewport.bottom / tileSize).ceil();

    final List<int> tileIndices = [];
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        // This is a simplified 2D to 1D index conversion.
        // A more robust implementation might use a different indexing scheme.
        tileIndices.add(y * 10000 + x); // Assuming a max width of 10000 tiles
      }
    }

    if (tileIndices.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> results = await db.query(
      'minimap_tiles',
      where: 'page_id = ? AND tile_index IN (${tileIndices.map((_) => '?').join(',')})',
      whereArgs: [pageId, ...tileIndices],
    );

    return results.map((row) => Tile(row['tile_index'] as int, row['asset_id'] as int)).toList();
  }

  Future<List<Tile>> prefetchNeighboringTiles(int pageId, Rect viewport) async {
    final Rect prefetchViewport = Rect(
      viewport.left - tileSize,
      viewport.top - tileSize,
      viewport.right + tileSize,
      viewport.bottom + tileSize,
    );
    return getTilesInViewport(pageId, prefetchViewport);
  }
}