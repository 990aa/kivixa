import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database.dart';

part 'provider_config_service.g.dart';

@DriftDatabase(tables: [ProviderConfigs])
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

  Future<ProviderConfig?> getProviderConfig(String provider) async {
    final query = _db.select(_db.providerConfigs)..where((tbl) => tbl.provider.equals(provider));
    final result = await query.getSingleOrNull();
    if (result != null) {
      return ProviderConfig.fromData(result);
    }
    return null;
  }

  Future<void> saveProviderConfig(ProviderConfig config) {
    return _db.into(_db.providerConfigs).insert(
      ProviderConfigsCompanion.insert(
        provider: config.provider,
        baseUrl: Value(config.baseUrl),
        modelName: Value(config.modelName),
        options: Value(config.options),
      ),
      mode: InsertMode.replace
    );
  }
}

class ProviderConfig {
  final String provider;
  final String? baseUrl;
  final String? modelName;
  final String? options;

  ProviderConfig({required this.provider, this.baseUrl, this.modelName, this.options});

  factory ProviderConfig.fromData(ProviderConfigData data) {
    return ProviderConfig(
      provider: data.provider,
      baseUrl: data.baseUrl,
      modelName: data.modelName,
      options: data.options,
    );
  }
}