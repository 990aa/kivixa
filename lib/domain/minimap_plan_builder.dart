import 'dart:ui';

class MinimapTile {
  final int tileIndex;
  final Rect extent; // in page coordinates
  final String assetId;

  MinimapTile({required this.tileIndex, required this.extent, required this.assetId});
}

class Viewport {
  final Rect rect; // in page coordinates

  Viewport({required this.rect});
}

class MinimapPlan {
  final List<MinimapTile> visibleTiles;
  final Rect viewportRect; // in minimap coordinates

  MinimapPlan({required this.visibleTiles, required this.viewportRect});
}

class MinimapPlanBuilder {
  MinimapPlan build({
    required List<MinimapTile> allTiles,
    required Viewport viewport,
    required Size minimapSize,
    required Size pageSize,
  }) {
    final visibleTiles = allTiles.where((tile) => tile.extent.overlaps(viewport.rect)).toList();

    final scaleX = minimapSize.width / pageSize.width;
    final scaleY = minimapSize.height / pageSize.height;

    final viewportRect = Rect.fromLTWH(
      viewport.rect.left * scaleX,
      viewport.rect.top * scaleY,
      viewport.rect.width * scaleX,
      viewport.rect.height * scaleY,
    );

    return MinimapPlan(
      visibleTiles: visibleTiles,
      viewportRect: viewportRect,
    );
  }

  Offset jumpTo(Offset minimapPosition, Size minimapSize, Size pageSize) {
    final scaleX = pageSize.width / minimapSize.width;
    final scaleY = pageSize.height / minimapSize.height;

    return Offset(
      minimapPosition.dx * scaleX,
      minimapPosition.dy * scaleY,
    );
  }
}
