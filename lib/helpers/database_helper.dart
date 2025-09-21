import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/folder.dart';
import '../models/pdf.dart';
import '../features/notes/models/note_document.dart';
import '../features/notes/models/note_page.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kivixa.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        cover TEXT,
        createdAt TEXT,
        colorValue INTEGER,
        parentId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE pdfs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        path TEXT,
        folderId INTEGER
      )
    ''');
    await _onUpgrade(db, 0, version);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE folders ADD COLUMN parentId INTEGER');
      await db.execute('''
        CREATE TABLE pdfs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          path TEXT,
          folderId INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE notes_documents(
          id TEXT PRIMARY KEY,
          title TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          page_count INTEGER,
          is_favorited INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE notes_pages(
          id TEXT PRIMARY KEY,
          document_id TEXT,
          page_number INTEGER,
          paper_type TEXT,
          drawing_data_json TEXT,
          background_color INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE notes_settings(
          setting_key TEXT PRIMARY KEY,
          setting_value TEXT
        )
      ''');
    }
  }

  Future<int> insertFolder(Folder folder) async {
    Database db = await database;
    return await db.insert('folders', folder.toMap());
  }

  Future<List<Folder>> getFolders(int? parentId) async {
    Database db = await database;
    var folders = await db.query(
      'folders',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    List<Folder> folderList = folders.isNotEmpty
        ? folders.map((c) => Folder.fromMap(c)).toList()
        : [];
    return folderList;
  }

  Future<int> updateFolder(Folder folder) async {
    Database db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    Database db = await database;
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertPdf(Pdf pdf) async {
    Database db = await database;
    return await db.insert('pdfs', pdf.toMap());
  }

  Future<List<Pdf>> getPdfs(int folderId) async {
    Database db = await database;
    var pdfs = await db.query(
      'pdfs',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    List<Pdf> pdfList = pdfs.isNotEmpty
        ? pdfs.map((c) => Pdf.fromMap(c)).toList()
        : [];
    return pdfList;
  }

  Future<int> updatePdf(Pdf pdf) async {
    Database db = await database;
    return await db.update(
      'pdfs',
      pdf.toMap(),
      where: 'id = ?',
      whereArgs: [pdf.id],
    );
  }

  Future<int> deletePdf(int id) async {
    Database db = await database;
    return await db.delete('pdfs', where: 'id = ?', whereArgs: [id]);
  }

  // Notes Document CRUD
  Future<int> insertNoteDocument(NoteDocument document) async {
    Database db = await database;
    return await db.insert('notes_documents', {
      'id': document.id,
      'title': document.title,
      'createdAt': document.createdAt.toIso8601String(),
      'updatedAt': document.updatedAt.toIso8601String(),
      'page_count': document.pages.length,
      'is_favorited': 0, // Default value
    });
  }

  Future<List<NoteDocument>> getNoteDocuments() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes_documents');

    return List.generate(maps.length, (i) {
      return NoteDocument(
        id: maps[i]['id'],
        title: maps[i]['title'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
        updatedAt: DateTime.parse(maps[i]['updatedAt']),
        pages: [], // Pages are loaded separately
      );
    });
  }

  Future<int> updateNoteDocument(NoteDocument document) async {
    Database db = await database;
    return await db.update(
      'notes_documents',
      {
        'title': document.title,
        'updatedAt': document.updatedAt.toIso8601String(),
        'page_count': document.pages.length,
      },
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> deleteNoteDocument(String id) async {
    Database db = await database;
    await db.delete('notes_pages', where: 'document_id = ?', whereArgs: [id]);
    return await db.delete('notes_documents', where: 'id = ?', whereArgs: [id]);
  }

  // Notes Page CRUD
  Future<int> insertNotePage(NotePage page, String documentId) async {
    Database db = await database;
    // Note: You need to generate a unique ID for the page.
    // Consider using the uuid package.
    final pageId = page.pageNumber.toString(); // Placeholder, should be unique
    return await db.insert('notes_pages', {
      'id': pageId,
      'document_id': documentId,
      'page_number': page.pageNumber,
      'paper_type': page.paperType,
      'drawing_data_json': jsonEncode(
        page.drawingData.map((s) => s.toJson()).toList(),
      ),
      'background_color': page.backgroundSettings['color'],
    });
  }

  Future<List<NotePage>> getNotePages(String documentId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes_pages',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    return List.generate(maps.length, (i) {
      return NotePage.fromJson(maps[i]);
    });
  }

  Future<int> updateNotePage(NotePage page) async {
    Database db = await database;
    // Note: This assumes pageNumber is the unique identifier for the page within a document, which is not ideal.
    // A unique page ID would be better.
    return await db.update(
      'notes_pages',
      {
        'drawing_data_json': jsonEncode(
          page.drawingData.map((s) => s.toJson()).toList(),
        ),
        'background_color': page.backgroundSettings['color'],
      },
      where: 'id = ?',
      whereArgs: [
        page.pageNumber.toString(),
      ], // Placeholder, should be a unique page id
    );
  }

  Future<int> deleteNotePage(String id) async {
    Database db = await database;
    return await db.delete('notes_pages', where: 'id = ?', whereArgs: [id]);
  }
}
