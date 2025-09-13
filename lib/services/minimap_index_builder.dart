import 'dart:convert';
import 'dart:ui';

import '../data/repository.dart';

class MinimapData {
  final List<Rect> rectangles;
  final List<Point> navigationPoints;

  MinimapData(this.rectangles, this.navigationPoints);
}

class MinimapIndexBuilder {
  final Repository _repo;

  MinimapIndexBuilder(this._repo);

  Future<void> buildIndex(int tileId) async {
    // This is a conceptual implementation. A real implementation would need to load
    // all the content of the tile (strokes, shapes, text blocks, etc.) and calculate
    // their bounding boxes.

    // For now, we'll just create a dummy index.
    final indexData = {
      'rectangles': [
        {'left': 10, 'top': 10, 'right': 50, 'bottom': 50},
        {'left': 60, 'top': 60, 'right': 100, 'bottom': 100},
      ],
      'navigationPoints': [
        {'x': 30, 'y': 30},
        {'x': 80, 'y': 80},
      ],
    };

    await _repo.updateMinimapTileIndex(tileId, {'index_data': jsonEncode(indexData)});
  }

  Future<MinimapData?> getMinimapData(int tileId) async {
    final tile = await _repo.getMinimapTile(tileId);
    if (tile != null && tile['index_data'] != null) {
      final indexData = jsonDecode(tile['index_data']);
      final rectangles = (indexData['rectangles'] as List)
          .map((r) => Rect.fromLTRB(r['left'], r['top'], r['right'], r['bottom']))
          .toList();
      final navigationPoints = (indexData['navigationPoints'] as List)
          .map((p) => Point(p['x'], p['y']))
          .toList();
      return MinimapData(rectangles, navigationPoints);
    }
    return null;
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}