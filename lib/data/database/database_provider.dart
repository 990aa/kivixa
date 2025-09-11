import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String dbPath = join(documentsDirectory.path, 'kivixa.db');
    final bool exists = await File(dbPath).exists();
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await _runSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );
    await _configurePragmas(db);
    if (!exists) {
      await _runSchema(db);
    }
    await _runIntegrityChecks(db);
    return db;
  }

  Future<void> _runSchema(Database db) async {
    final String schema = await rootBundle.loadString(
      'assets/database/schema.sql',
    );
    final List<String> statements = schema
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    for (final stmt in statements) {
      await db.execute(stmt);
    }
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Implement migration logic here. For now, schema.sql is idempotent.
    await _runSchema(db);
  }

  Future<void> _configurePragmas(Database db) async {
    await db.execute("PRAGMA journal_mode=WAL;");
    await db.execute("PRAGMA foreign_keys=ON;");
    await db.execute("PRAGMA synchronous=NORMAL;");
    await db.execute("PRAGMA temp_store=MEMORY;");
    await db.execute("PRAGMA cache_size=10000;");
    await db.execute("PRAGMA mmap_size=300000000;");
  }

  Future<void> _runIntegrityChecks(Database db) async {
    final result = await db.rawQuery('PRAGMA integrity_check;');
    if (result.isNotEmpty && result.first.values.first != 'ok') {
      throw Exception(
        'Database integrity check failed: ${result.first.values.first}',
      );
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
