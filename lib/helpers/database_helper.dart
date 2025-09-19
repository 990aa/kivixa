import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/folder.dart';
import '../models/pdf.dart';

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
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
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
  }

  Future<int> insertFolder(Folder folder) async {
    Database db = await database;
    return await db.insert('folders', folder.toMap());
  }

  Future<List<Folder>> getFolders(int? parentId) async {
    Database db = await database;
    var folders = await db.query('folders', where: 'parentId = ?', whereArgs: [parentId]);
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
    var pdfs = await db.query('pdfs', where: 'folderId = ?', whereArgs: [folderId]);
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
}
