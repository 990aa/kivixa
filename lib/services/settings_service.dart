
import 'dart:async';

import '../data/repository.dart';

// Manages user-specific settings with an in-memory cache and debounced writes.
class SettingsService {
  final Repository _repo;
  final String _userId;
  final Map<String, dynamic> _cache = {};
  Timer? _debounce;

  SettingsService(this._repo, this._userId);

  // Retrieves a setting value, preferring cache over a database read.
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T? ?? defaultValue;
    }

    final settings = await _repo.listUserSettings(userId: _userId, limit: 1);
    if (settings.isNotEmpty) {
      final setting = settings.first;
      _cache[key] = setting['value'];
      return setting['value'] as T? ?? defaultValue;
    }

    return defaultValue;
  }

  // Updates a setting value, debouncing the database write.
  void set<T>(String key, T value) {
    _cache[key] = value;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _repo.updateUserSetting(_userId, key, {'value': value});
    });
  }
}
