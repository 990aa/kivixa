import 'package:sqflite/sqflite.dart';

class TitleBarActionsService {
  final Database db;
  TitleBarActionsService(this.db);

  Future<void> insertPage(int notebookId, int pageIndex) async {
    // Insert page and log action
    await db.insert('pages', {'notebook_id': notebookId, 'index': pageIndex});
    await db.insert('redo_log', {
      'action': 'insert_page',
      'notebook_id': notebookId,
      'page_index': pageIndex,
    });
  }

  Future<void> modifyTemplate(int pageId, String template) async {
    await db.update(
      'pages',
      {'template': template},
      where: 'id = ?',
      whereArgs: [pageId],
    );
    await db.insert('redo_log', {
      'action': 'modify_template',
      'page_id': pageId,
      'template': template,
    });
  }

  Future<void> export(int notebookId, String format) async {
    // Export logic placeholder
    await db.insert('redo_log', {
      'action': 'export',
      'notebook_id': notebookId,
      'format': format,
    });
  }

  Future<void> manageLayer(
    int pageId,
    String op,
    Map<String, dynamic> layerData,
  ) async {
    // Layer management logic placeholder
    await db.insert('redo_log', {
      'action': 'layer_management',
      'page_id': pageId,
      'op': op,
      'layer_data': layerData.toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getStateProjection(int notebookId) async {
    // Return a projection of the current state
    return await db.query(
      'pages',
      where: 'notebook_id = ?',
      whereArgs: [notebookId],
    );
  }

  Future<void> undo() async {
    // Undo logic using redo_log
  }

  Future<void> redo() async {
    // Redo logic using redo_log
  }
}
