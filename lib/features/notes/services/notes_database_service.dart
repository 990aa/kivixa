import 'package:kivixa/helpers/database.dart';
import 'package:postgres/postgres.dart';

import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/models/note_document.dart';

class NotesDatabaseService {
  static final NotesDatabaseService instance = NotesDatabaseService._init();
  NotesDatabaseService._init();

  Future<Connection> get database async {
    return await DatabaseHelper().connection;
  }

  Future<void> initDB() async {
    final conn = await database;
    await _createDB(conn);
  }

  Future<void> _createDB(Connection db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS folders ( 
  id TEXT PRIMARY KEY, 
  name TEXT NOT NULL,
  parentId TEXT,
  createdAt BIGINT NOT NULL,
  lastModified BIGINT NOT NULL,
  color INTEGER NOT NULL,
  icon INTEGER NOT NULL
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS notes ( 
  id TEXT PRIMARY KEY, 
  title TEXT NOT NULL,
  pages TEXT NOT NULL,
  createdAt BIGINT NOT NULL,
  updatedAt BIGINT NOT NULL,
  folderId TEXT
  )
''');
  }

  Future<Folder> createFolder(Folder folder) async {
    final db = await instance.database;
    await db.execute(
      Sql.named(
        'INSERT INTO folders (id, name, parentId, createdAt, lastModified, color, icon) VALUES (@id, @name, @parentId, @createdAt, @lastModified, @color, @icon)',
      ),
      parameters: folder.toMap(),
    );
    return folder;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named('SELECT * FROM folders ORDER BY lastModified DESC'),
    );
    return result.map((row) => Folder.fromMap(row.toColumnMap())).toList();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named(
        'UPDATE folders SET name = @name, parentId = @parentId, lastModified = @lastModified, color = @color, icon = @icon WHERE id = @id',
      ),
      parameters: folder.toMap(),
    );
    return result.affectedRows;
  }

  Future<int> updateFolderParent(String folderId, String? newParentId) async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named('UPDATE folders SET parentId = @parentId WHERE id = @id'),
      parameters: {'id': folderId, 'parentId': newParentId},
    );
    return result.affectedRows;
  }

  Future<NoteDocument> create(NoteDocument note) async {
    final db = await instance.database;
    await db.execute(
      Sql.named(
        'INSERT INTO notes (id, title, pages, createdAt, updatedAt, folderId) VALUES (@id, @title, @pages, @createdAt, @updatedAt, @folderId)',
      ),
      parameters: note.toJson(),
    );
    return note;
  }

  Future<NoteDocument> getNoteById(String id) async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named('SELECT * FROM notes WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isNotEmpty) {
      return NoteDocument.fromJson(result.first.toColumnMap());
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<NoteDocument>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named('SELECT * FROM notes ORDER BY updatedAt DESC'),
    );
    return result
        .map((row) => NoteDocument.fromJson(row.toColumnMap()))
        .toList();
  }

  Future<int> updateNote(NoteDocument note) async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named(
        'UPDATE notes SET title = @title, pages = @pages, updatedAt = @updatedAt, folderId = @folderId WHERE id = @id',
      ),
      parameters: note.toJson(),
    );
    return result.affectedRows;
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    final result = await db.execute(
      Sql.named('DELETE FROM notes WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows;
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
