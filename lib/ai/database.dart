import 'package:drift/drift.dart';

class ProviderConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text()();
  TextColumn get baseUrl => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get options => text().nullable()();
}

class JobQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobType => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(const Constant(DateTime.now()))();
}
