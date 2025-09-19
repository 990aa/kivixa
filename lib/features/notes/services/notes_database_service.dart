import 'package:sqflite/sqflite.dart';

class NotesDatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // TODO: implement database initialization
    return {} as Future<Database>;
  }
}
