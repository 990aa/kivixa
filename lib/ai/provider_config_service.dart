
import 'dart:convert';

import 'package:kivixa/data/database.dart';

class ProviderConfigService {
  final AppDatabase _db;

  ProviderConfigService(this._db);

  Future<ProviderConfig> getProviderConfig(String providerId) async {
    final result = await (_db.select(_db.providerConfigs)
          ..where((tbl) => tbl.providerId.equals(providerId)))
        .getSingleOrNull();

    if (result != null) {
      return result;
    } else {
      // Return a default config if none is found
      return ProviderConfig(id: -1, providerId: providerId);
    }
  }

  Future<void> saveProviderConfig(ProviderConfig config) {
    return _db.into(_db.providerConfigs).insertOnConflictUpdate(config);
  }

  Map<String, dynamic> _sanitizeConfig(ProviderConfig config) {
    return {
      'providerId': config.providerId,
      'baseUrl': config.baseUrl,
      'modelName': config.modelName,
      'options': config.options != null ? jsonDecode(config.options!) : null,
    };
  }

  Future<Map<String, dynamic>> getSanitizedConfig(String providerId) async {
    final config = await getProviderConfig(providerId);
    return _sanitizeConfig(config);
  }
}
