import 'package:sqflite/sqflite.dart';
import '../database/drawing_database.dart';
import '../models/folder.dart';

/// Repository for folder operations
///
/// Handles all CRUD operations for folders with hierarchical support
class FolderRepository {
  /// Create a new folder
  Future<int> createFolder(Folder folder) async {
    return await insert(folder);
  }

  /// Insert a new folder
  Future<int> insert(Folder folder) async {
    final db = await DrawingDatabase.database;
    return await db.insert(
      DrawingDatabase.tableFolders,
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing folder
  Future<int> update(Folder folder) async {
    return await updateFolder(folder);
  }

  /// Update folder
  Future<int> updateFolder(Folder folder) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.tableFolders,
      folder.copyWith(modifiedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  /// Delete a folder (and all subfolders due to CASCADE)
  Future<int> delete(int id) async {
    return await deleteFolder(id);
  }

  /// Delete folder (cascade deletes subfolders due to FK constraint)
  Future<int> deleteFolder(int folderId) async {
    final db = await DrawingDatabase.database;
    return await db.delete(
      DrawingDatabase.tableFolders,
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  /// Get folder by ID
  Future<Folder?> getById(int id) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableFolders,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Folder.fromMap(maps.first);
  }

  /// Get all folders
  Future<List<Folder>> getAll() async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableFolders,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Folder.fromMap(map)).toList();
  }

  /// Get root folders (no parent)
  Future<List<Folder>> getRootFolders() async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableFolders,
      where: 'parent_folder_id IS NULL',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Folder.fromMap(map)).toList();
  }

  /// Get subfolders of a specific folder
  Future<List<Folder>> getSubfolders(int parentId) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableFolders,
      where: 'parent_folder_id = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Folder.fromMap(map)).toList();
  }

  /// Get folder hierarchy with document counts
  Future<List<Folder>> getFolderHierarchy() async {
    final folders = await getAll();

    // Build hierarchy
    final rootFolders = folders.where((f) => f.isRoot).toList();

    for (final root in rootFolders) {
      await _buildHierarchy(root, folders);
    }

    return rootFolders;
  }

  /// Get complete folder tree (alias for getFolderHierarchy)
  Future<List<Folder>> getFolderTree() async {
    return await getFolderHierarchy();
  }

  Future<void> _buildHierarchy(Folder parent, List<Folder> allFolders) async {
    // Get subfolders
    parent.subfolders = allFolders
        .where((f) => f.parentFolderId == parent.id)
        .toList();

    // Get document count
    parent.documentCount = await _getDocumentCount(parent.id!);

    // Recursively build hierarchy for subfolders
    for (final subfolder in parent.subfolders) {
      await _buildHierarchy(subfolder, allFolders);
    }
  }

  /// Helper method to load subfolders recursively
  Future<void> _loadSubfoldersRecursive(Folder folder) async {
    if (folder.id == null) return;

    folder.subfolders = await getSubfolders(folder.id!);

    for (final subfolder in folder.subfolders) {
      await _loadSubfoldersRecursive(subfolder);
    }
  }

  Future<int> _getDocumentCount(int folderId) async {
    final db = await DrawingDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DrawingDatabase.tableDocuments} WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Move folder to different parent
  Future<int> moveFolder(int folderId, int? newParentId) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.tableFolders,
      {
        'parent_folder_id': newParentId,
        'modified_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  /// Search folders by name
  Future<List<Folder>> searchByName(String query) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableFolders,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Folder.fromMap(map)).toList();
  }
}
