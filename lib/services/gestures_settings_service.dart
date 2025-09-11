import 'package:sqflite/sqflite.dart';

class GesturesSettingsService {
  final Database db;
  GesturesSettingsService(this.db);

  Future<void> saveGesturePref(
    String gesture,
    Map<String, dynamic> config,
  ) async {
    await db.insert('gesture_prefs', {
      'gesture': gesture,
      'config': config.toString(),
    });
  }

  Future<Map<String, dynamic>?> getGesturePref(String gesture) async {
    final result = await db.query(
      'gesture_prefs',
      where: 'gesture = ?',
      whereArgs: [gesture],
    );
    if (result.isNotEmpty) {
      // Parse config from string
      return {};
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllGesturePrefs() async {
    return await db.query('gesture_prefs');
  }

  // FFI: gesture recognition, device detection, sensitivity config
}
