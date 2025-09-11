import 'package:sqflite/sqflite.dart';

class ShapesConfigService {
  final Database db;
  ShapesConfigService(this.db);

  Future<void> saveShapePreset(String name, Map<String, dynamic> config) async {
    await db.insert('shape_presets', {
      'name': name,
      'config': config.toString(),
    });
  }

  Future<Map<String, dynamic>?> getShapePreset(String name) async {
    final result = await db.query(
      'shape_presets',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      // Parse config from string
      return {};
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllShapePresets() async {
    return await db.query('shape_presets');
  }

  // FFI: auto-shape recognition, 3D geometry, etc.
}
