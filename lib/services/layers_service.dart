import '../data/repository.dart';

class LayersService {
  final Repository _repository;

  LayersService(this._repository);

  /// Creates a new layer.
  Future<void> createLayer(int pageId, String layerName) async {
    await _repository.createLayer({'page_id': pageId, 'name': layerName});
  }

  /// Reorders the layers.
  Future<void> reorderLayers(int pageId, List<int> layerIds) async {
    await _repository.batchWrite([
      for (var i = 0; i < layerIds.length; i++)
        () => _repository.updateLayer(layerIds[i], {'z_order': i}),
    ]);
  }

  /// Renames a layer.
  Future<void> renameLayer(int layerId, String newName) async {
    await _repository.updateLayer(layerId, {'name': newName});
  }

  /// Toggles the visibility of a layer.
  Future<void> toggleLayerVisibility(int layerId) async {
    final layer = await _repository.getLayer(layerId);
    if (layer != null) {
      await _repository.updateLayer(layerId, {
        'visible': !(layer['visible'] as bool),
      });
    }
  }

  /// Reassigns selected items to a different layer.
  Future<void> reassignItemsToLayer(
    List<int> itemIds,
    int layerId,
    String itemType,
  ) async {
    await _repository.batchWrite([
      for (final itemId in itemIds)
        () => _updateItemLayer(itemId, layerId, itemType),
    ]);
  }

  Future<void> _updateItemLayer(
    int itemId,
    int layerId,
    String itemType,
  ) async {
    switch (itemType) {
      case 'stroke':
        // Stub: implement this when strokeChunks table is available in Drift schema
        return;
      case 'text_block':
        await _repository.updateTextBlock(itemId, {'layer_id': layerId});
        return;
      case 'image':
        await _repository.updateImage(itemId, {'layer_id': layerId});
        return;
      case 'shape':
        await _repository.updateShape(itemId, {'layer_id': layerId});
        return;
      default:
        throw Exception('Unknown item type: $itemType');
    }
  }

  /// Gets the computed z-order list.
  Future<List<int>> getZOrderList(int pageId) async {
    final layers = await _repository.listLayers(
      pageId: pageId,
      orderBy: 'z_order ASC',
    );
    return layers.map((l) => l['id'] as int).toList();
  }
}
