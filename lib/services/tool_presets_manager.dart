import 'package:sqflite/sqflite.dart';

class ToolPresetsManager {
  final Database db;
  Map<String, Map<String, dynamic>> _presetCache = {};
  ToolPresetsManager(this.db);

  Future<void> savePreset(String tool, Map<String, dynamic> config) async {
    await db.insert('tool_presets', {
      'tool': tool,
      'config': config.toString(),
    });
    _presetCache[tool] = config;
  }

  Future<Map<String, dynamic>?> loadPreset(String tool) async {
    if (_presetCache.containsKey(tool)) return _presetCache[tool];
    final result = await db.query(
      'tool_presets',
      where: 'tool = ?',
      whereArgs: [tool],
    );
    if (result.isNotEmpty) {
      // Parse config from string
      // ...
      return {};
    }
    return null;
  }

  Future<void> importPresets(List<Map<String, dynamic>> presets) async {
    for (var preset in presets) {
      await savePreset(preset['tool'], preset['config']);
    }
  }

  Future<List<Map<String, dynamic>>> exportPresets() async {
    return await db.query('tool_presets');
  }

  void switchTool(String tool) {
    // Use _presetCache for real-time switching
  }
}
