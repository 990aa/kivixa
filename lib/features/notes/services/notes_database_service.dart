
import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
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
    const nullableTextType = 'TEXT';

    await db.execute('''
CREATE TABLE folders ( 
  id $idType, 
  name $textType,
  parentId $nullableTextType,
  createdAt $intType,
  lastModified $intType,
  color $intType,
  icon $intType
  )
''');

    await db.execute('''
CREATE TABLE notes ( 
  id $idType, 
  title $textType,
  pages $textType,
  createdAt $intType,
  updatedAt $intType,
  folderId $nullableTextType
  )
''');
  }

  Future<Folder> createFolder(Folder folder) async {
    final db = await instance.database;
    final Map<String, dynamic> row = {
      'id': folder.id,
      'name': folder.name,
      'parentId': folder.parentId,
      'createdAt': folder.createdAt.millisecondsSinceEpoch,
      'lastModified': folder.lastModified.millisecondsSinceEpoch,
      'color': folder.color.toARGB32(),
      'icon': folder.icon.codePoint,
    };
    await db.insert('folders', row);
    return folder;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    const orderBy = 'lastModified DESC';
    final result = await db.query('folders', orderBy: orderBy);
    return result.map((json) {
      return Folder(
        id: json['id'] as String,
        name: json['name'] as String,
        parentId: json['parentId'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(json['lastModified'] as int),
        color: Color(json['color'] as int),
        icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      );
    }).toList();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    return db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
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
      columns: [
        'id',
        'title',
        'pages',
        'createdAt',
        'updatedAt',
        'folderId'
      ],
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
