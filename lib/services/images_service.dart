import 'package:sqflite/sqflite.dart';

class ImagesService {
  final Database db;
  ImagesService(this.db);

  Future<void> addImage(
    int layerId,
    String filePath,
    String hash,
    int width,
    int height,
  ) async {
    await db.insert('images', {
      'layer_id': layerId,
      'uri': filePath,
      'hash': hash,
      'width': width,
      'height': height,
    });
  }

  Future<List<Map<String, dynamic>>> findDuplicates(String hash) async {
    return await db.query('images', where: 'hash = ?', whereArgs: [hash]);
  }

  // Transformation, lasso, and thumbnail APIs to be implemented
}
