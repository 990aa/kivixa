import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';

class SettingsManager {
  final DatabaseProvider _provider = DatabaseProvider();
  final Map<String, dynamic> _cache = {};
  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();
  Timer? _debounce;

  Future<void> loadSettings() async {
    final db = await _provider.database;
    final result = await db.query('user_settings');
    for (final row in result) {
      _cache[row['key'] as String] = row['value'];
    }
    _controller.add(Map.from(_cache));
  }

  dynamic get(String key) => _cache[key];

  void set(String key, dynamic value) {
    _cache[key] = value;
    _controller.add(Map.from(_cache));
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _persist(key, value),
    );
  }

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> _persist(String key, dynamic value) async {
    final db = await _provider.database;
    await db.insert('user_settings', {
      'key': key,
      'value': value.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}
