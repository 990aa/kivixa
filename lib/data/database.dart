
import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DataClassName('ProviderConfig')
class ProviderConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get providerId => text()();
  TextColumn get baseUrl => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get options => text().nullable()(); // JSON encoded options
}

@DataClassName('JobQueue')
class JobQueues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobType => text()(); // e.g., 'export_kivixa', 'export_pdf'
  TextColumn get status => text()(); // e.g., 'pending', 'in_progress', 'completed', 'failed'
  TextColumn get payload => text()(); // JSON encoded payload
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [ProviderConfigs, JobQueues])
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
