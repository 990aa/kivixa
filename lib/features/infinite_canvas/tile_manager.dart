import 'package:flutter/material.dart';
import 'dart:math';

class TileManager extends ChangeNotifier {
  final double tileSize;
  final int _gridSize = 100;
  final Set<Point<int>> _visibleTiles = {};
  double _scale = 1.0;

  TileManager({this.tileSize = 256.0});

  Set<Point<int>> get visibleTiles => _visibleTiles;
  double get scale => _scale;

  void updateVisibleTiles(Rect visibleRect, double scale) {
    _scale = scale;
    final int startX = (visibleRect.left / tileSize).floor();
    final int startY = (visibleRect.top / tileSize).floor();
    final int endX = (visibleRect.right / tileSize).ceil();
    final int endY = (visibleRect.bottom / tileSize).ceil();

    final newTiles = <Point<int>>{};
    for (int x = startX; x < endX; x++) {
      for (int y = startY; y < endY; y++) {
        if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
          newTiles.add(Point(x, y));
        }
      }
    }

    if (!_areSetsEqual(newTiles, _visibleTiles)) {
      _visibleTiles.clear();
      _visibleTiles.addAll(newTiles);
      notifyListeners();
    }
  }

  bool _areSetsEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) {
      return false;
    }
    for (final item in set1) {
      if (!set2.contains(item)) {
        return false;
      }
    }
    return true;
  }
}
