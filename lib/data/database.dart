import 'package:drift/drift.dart';
import 'package:kivixa/data/schema/custom_tables.dart';
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
  TextColumn get status =>
      text()(); // e.g., 'pending', 'in_progress', 'completed', 'failed'
  TextColumn get payload => text()(); // JSON encoded payload
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('DocProvenanceData')
class DocProvenance extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get newDocumentId => text()();
  TextColumn get type => text()(); // merge, split, raster
  TextColumn get sourceDocumentIds => text()(); // comma-separated list
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('LinkData')
class Links extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromPageId => integer()();
  IntColumn get toPageId => integer()();
  TextColumn get type => text()();
}

@DataClassName('DocumentData')
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
}

@DataClassName('OutlineData')
class Outlines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer()();
  TextColumn get data => text()();
}

@DataClassName('CommentData')
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pageId => integer()();
  TextColumn get content => text()();
}

@DataClassName('TextBlockData')
class TextBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get layerId => integer()();
  TextColumn get content => text()();
}

@DataClassName('RedoLogData')
class RedoLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer()();
  TextColumn get action => text()();
  TextColumn get data => text().nullable()();
  IntColumn get ts => integer()();
}

@DataClassName('AssetData')
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text()();
  IntColumn get size => integer()();
  TextColumn get hash => text()();
  TextColumn get mime => text()();
  TextColumn get sourceUri => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    ProviderConfigs,
    JobQueues,
    DocProvenance,
    Links,
    Documents,
    Outlines,
    Comments,
    TextBlocks,
    RedoLog,
    Assets,
    ChecklistItems,
    CalendarEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
