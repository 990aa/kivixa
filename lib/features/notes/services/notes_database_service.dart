import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotesDatabaseService {
  static final NotesDatabaseService instance = NotesDatabaseService._init();
  static Database? _database;

  NotesDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE notes ( 
  id $idType, 
  title $textType,
  pages $textType,
  createdAt $intType,
  updatedAt $intType
  )
''');
  }

  Future<NoteDocument> create(NoteDocument note) async {
    final db = await instance.database;
    await db.insert('notes', note.toJson());
    return note;
  }

  Future<NoteDocument> getNoteById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      columns: ['id', 'title', 'pages', 'createdAt', 'updatedAt'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return NoteDocument.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<NoteDocument>> getAllNotes() async {
    final db = await instance.database;
    const orderBy = 'updatedAt DESC';
    final result = await db.query('notes', orderBy: orderBy);
    return result.map((json) => NoteDocument.fromJson(json)).toList();
  }

  Future<int> updateNote(NoteDocument note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
