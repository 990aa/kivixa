import 'package:kivixa/helpers/database.dart';
import 'package:postgres/postgres.dart';

import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/models/note_document.dart';

class NotesDatabaseService {
  static final NotesDatabaseService instance = NotesDatabaseService._init();
  NotesDatabaseService._init();

  Future<PostgreSQLConnection> get database async {
    return await DatabaseHelper().connection;
  }

  Future<void> initDB() async {
    final conn = await database;
    await _createDB(conn);
  }

  Future<void> _createDB(PostgreSQLConnection db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS folders ( 
  id TEXT PRIMARY KEY, 
  name TEXT NOT NULL,
  parentId TEXT,
  createdAt INTEGER NOT NULL,
  lastModified INTEGER NOT NULL,
  color INTEGER NOT NULL,
  icon INTEGER NOT NULL
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS notes ( 
  id TEXT PRIMARY KEY, 
  title TEXT NOT NULL,
  pages TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  folderId TEXT
  )
''');
  }

  Future<Folder> createFolder(Folder folder) async {
    final db = await instance.database;
    await db.execute(
      'INSERT INTO folders (id, name, parentId, createdAt, lastModified, color, icon) VALUES (@id, @name, @parentId, @createdAt, @lastModified, @color, @icon)',
      substitutionValues: folder.toMap(),
    );
    return folder;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    final result = await db.query(
      'SELECT * FROM folders ORDER BY lastModified DESC',
    );
    return result.map((row) => Folder.fromMap(row.toColumnMap())).toList();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    final result = await db.execute(
      'UPDATE folders SET name = @name, parentId = @parentId, lastModified = @lastModified, color = @color, icon = @icon WHERE id = @id',
      substitutionValues: folder.toMap(),
    );
    return result.affectedRows;
  }

  Future<int> updateFolderParent(String folderId, String? newParentId) async {
    final db = await instance.database;
    final result = await db.execute(
      'UPDATE folders SET parentId = @parentId WHERE id = @id',
      substitutionValues: {'id': folderId, 'parentId': newParentId},
    );
    return result.affectedRows;
  }

  Future<NoteDocument> create(NoteDocument note) async {
    final db = await instance.database;
    await db.execute(
      'INSERT INTO notes (id, title, pages, createdAt, updatedAt, folderId) VALUES (@id, @title, @pages, @createdAt, @updatedAt, @folderId)',
      substitutionValues: note.toJson(),
    );
    return note;
  }

  Future<NoteDocument> getNoteById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'SELECT * FROM notes WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (result.isNotEmpty) {
      return NoteDocument.fromJson(result.first.toColumnMap());
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<NoteDocument>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query(
      'SELECT * FROM notes ORDER BY updatedAt DESC',
    );
    return result
        .map((row) => NoteDocument.fromJson(row.toColumnMap()))
        .toList();
  }

  Future<int> updateNote(NoteDocument note) async {
    final db = await instance.database;
    final result = await db.execute(
      'UPDATE notes SET title = @title, pages = @pages, updatedAt = @updatedAt, folderId = @folderId WHERE id = @id',
      substitutionValues: note.toJson(),
    );
    return result.affectedRows;
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    final result = await db.execute(
      'DELETE FROM notes WHERE id = @id',
      substitutionValues: {'id': id},
    );
    return result.affectedRows;
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
