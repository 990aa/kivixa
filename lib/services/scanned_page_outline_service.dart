import 'package:sqflite/sqflite.dart';

class ScannedPageOutlineService {
  final Database db;
  ScannedPageOutlineService(this.db);

  Future<void> addOutline(int pageId, String label) async {
    await db.insert('scanned_page_outlines', {
      'page_id': pageId,
      'label': label,
    });
  }

  // Outline navigation and anchor APIs to be implemented
}
