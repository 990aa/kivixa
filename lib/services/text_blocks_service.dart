import 'package:sqflite/sqflite.dart';

class TextBlocksService {
  final Database db;
  TextBlocksService(this.db);

  Future<void> saveTextBlock(
    int layerId,
    String jsonContent,
    String plainText,
  ) async {
    await db.insert('text_blocks', {
      'layer_id': layerId,
      'content': jsonContent,
      'plain_text': plainText,
    });
  }

  Future<List<Map<String, dynamic>>> searchText(String query) async {
    return await db.query(
      'text_blocks',
      where: 'plain_text LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Selection/caret APIs and delta update logic to be integrated with Flutter text editing
}
