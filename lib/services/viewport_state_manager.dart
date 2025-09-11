import 'package:sqflite/sqflite.dart';

class ViewportStateManager {
  final Database db;
  ViewportStateManager(this.db);

  Future<void> saveViewportState(
    int pageId,
    double zoom,
    double scrollX,
    double scrollY,
  ) async {
    await db.insert('viewport_state', {
      'page_id': pageId,
      'zoom': zoom,
      'scroll_x': scrollX,
      'scroll_y': scrollY,
    });
  }

  Future<Map<String, dynamic>?> getViewportState(int pageId) async {
    final result = await db.query(
      'viewport_state',
      where: 'page_id = ?',
      whereArgs: [pageId],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
