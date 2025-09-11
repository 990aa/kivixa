import 'package:sqflite/sqflite.dart';

class LayersService {
  final Database db;
  LayersService(this.db);

  Future<void> createLayer(int pageId, String type, int zIndex) async {
    await db.insert('layers', {
      'page_id': pageId,
      'type': type,
      'z_index': zIndex,
    });
  }

  Future<void> reorderLayers(int pageId, List<int> layerOrder) async {
    // Efficient batch update for compositing order
  }

  // Rename, toggle, batch reassign, and visibility APIs to be implemented
}
