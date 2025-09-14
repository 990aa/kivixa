import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database.dart'; // Contains ProviderConfigs table definition

part 'provider_config_service.g.dart'; // Will contain the Drift-generated ProviderConfig data class

@DriftDatabase(tables: [ProviderConfigs, JobQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

class ProviderConfigService {
  final AppDatabase _db;

  ProviderConfigService(this._db);

  // Changed return type to CustomProviderConfig?
  Future<CustomProviderConfig?> getProviderConfig(String provider) async {
    // The 'result' here will be of type ProviderConfig (Drift-generated)
    final query = _db.select(_db.providerConfigs)..where((tbl) => tbl.provider.equals(provider));
    final result = await query.getSingleOrNull(); // result is of type ProviderConfig (Drift-generated)
    if (result != null) {
      // Call the factory on the renamed CustomProviderConfig class
      return CustomProviderConfig.fromData(result);
    }
    return null;
  }

  // Changed parameter type to CustomProviderConfig
  Future<void> saveProviderConfig(CustomProviderConfig config) {
    return _db.into(_db.providerConfigs).insert(
      ProviderConfigsCompanion.insert( // This Companion is generated for the ProviderConfigs table
        provider: config.provider,
        baseUrl: Value(config.baseUrl),
        modelName: Value(config.modelName),
        options: Value(config.options),
      ),
      mode: InsertMode.replace
    );
  }
}

// Renamed from ProviderConfig to CustomProviderConfig
class CustomProviderConfig {
  final String provider;
  final String? baseUrl;
  final String? modelName;
  final String? options;

  CustomProviderConfig({required this.provider, this.baseUrl, this.modelName, this.options});

  // Factory method updated:
  // 1. Parameter type changed from 'ProviderConfigData' to 'ProviderConfig' (the Drift-generated class)
  // 2. Returns an instance of 'CustomProviderConfig'
  factory CustomProviderConfig.fromData(ProviderConfig data) { // 'data' is the Drift-generated ProviderConfig
    return CustomProviderConfig(
      provider: data.provider,
      baseUrl: data.baseUrl,
      modelName: data.modelName,
      options: data.options,
      // The Drift-generated 'ProviderConfig data' object also has an 'id' field (data.id).
      // If CustomProviderConfig needed to store this, it would need an 'id' field and
      // 'id: data.id' would be added here.
    );
  }
}
