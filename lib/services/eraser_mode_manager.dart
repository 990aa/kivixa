import 'package:sqflite/sqflite.dart';

class EraserModeManager {
  final Database db;
  EraserModeManager(this.db);

  Future<void> setEraserMode(String mode) async {
    await db.insert('eraser_mode', {'mode': mode});
  }

  Future<String?> getEraserMode() async {
    final result = await db.query(
      'eraser_mode',
      orderBy: 'rowid DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['mode'] as String : null;
  }

  Future<void> eraseStroke(int strokeId) async {
    // Mark stroke as erased for undo/redo
    await db.insert('redo_log', {
      'action': 'erase_stroke',
      'stroke_id': strokeId,
    });
  }
}
