import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'drawing_database.dart';
import '../models/archived_document.dart';
import '../models/drawing_document.dart';

/// Repository for managing archived documents
///
/// Provides compression, storage, and retrieval of archived documents.
///
/// Features:
/// - Compress documents with ZIP
/// - Track compression statistics
/// - Auto-archive based on last opened date
/// - Unarchive on demand
/// - Query archived documents
/// - Calculate storage savings
class ArchiveRepository {
  static const String tableArchives = 'archives';

  /// Get database instance
  Future<Database> get database async => DrawingDatabase.database;

  /// Create archive tables (call during database initialization)
  static Future<void> createArchiveTables(Database db) async {
    // Archive table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableArchives (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        original_file_path TEXT NOT NULL,
        archived_file_path TEXT NOT NULL,
        compression_ratio REAL NOT NULL,
        original_size INTEGER NOT NULL,
        archived_size INTEGER NOT NULL,
        archived_at INTEGER NOT NULL,
        auto_archived INTEGER DEFAULT 0,
        FOREIGN KEY (document_id) REFERENCES ${DrawingDatabase.tableDocuments}(id) ON DELETE CASCADE
      )
    ''');

    // Index for querying by document
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_archives_document 
      ON $tableArchives(document_id)
    ''');

    // Index for querying by archive date
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_archives_date 
      ON $tableArchives(archived_at)
    ''');

    // Index for auto-archived documents
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_archives_auto 
      ON $tableArchives(auto_archived)
    ''');

    // Add last_opened_at index to documents table if not exists
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_last_opened 
      ON ${DrawingDatabase.tableDocuments}(last_opened_at)
    ''');
  }

  /// Archive a document (compress and store)
  ///
  /// Parameters:
  /// - [document]: Document to archive
  /// - [archiveDirectory]: Directory to store archived files
  /// - [autoArchived]: Whether this is automatic archiving
  ///
  /// Returns: ArchivedDocument record with compression stats
  Future<ArchivedDocument> archiveDocument(
    DrawingDocument document,
    String archiveDirectory, {
    bool autoArchived = false,
  }) async {
    final db = await database;

    // Check if document is already archived
    final existing = await getByDocumentId(document.id!);
    if (existing != null) {
      throw Exception('Document is already archived');
    }

    // Read original file
    final originalFile = File(document.filePath);
    if (!await originalFile.exists()) {
      throw Exception('Original file not found: ${document.filePath}');
    }

    final originalBytes = await originalFile.readAsBytes();
    final originalSize = originalBytes.length;

    // Compress file using ZIP
    final encoder = ZipEncoder();
    final archive = Archive();

    final fileName = path.basename(document.filePath);
    final archiveFile = ArchiveFile(
      fileName,
      originalBytes.length,
      originalBytes,
    );
    archive.addFile(archiveFile);

    final compressedBytes = encoder.encode(archive);
    // Note: encode() always returns a non-null List<int>
    
    final archivedSize = compressedBytes.length;

    // Create archive directory if it doesn't exist
    final archiveDir = Directory(archiveDirectory);
    if (!await archiveDir.exists()) {
      await archiveDir.create(recursive: true);
    }

    // Generate archived file path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archivedFileName = '${document.id}_$timestamp.zip';
    final archivedFilePath = path.join(archiveDirectory, archivedFileName);

    // Write compressed file
    final archivedFile = File(archivedFilePath);
    await archivedFile.writeAsBytes(compressedBytes);

    // Calculate compression ratio
    final compressionRatio = archivedSize / originalSize;

    // Create archived document record
    final archivedDocument = ArchivedDocument(
      documentId: document.id!,
      originalFilePath: document.filePath,
      archivedFilePath: archivedFilePath,
      compressionRatio: compressionRatio,
      originalSize: originalSize,
      archivedSize: archivedSize,
      archivedAt: DateTime.now(),
      autoArchived: autoArchived,
    );

    // Insert into database
    final id = await db.insert(tableArchives, archivedDocument.toMap());

    // Delete original file to save space
    await originalFile.delete();

    return archivedDocument.copyWith(id: id);
  }

  /// Unarchive a document (decompress and restore)
  ///
  /// Parameters:
  /// - [archivedDocument]: Archived document to restore
  ///
  /// Returns: Path to restored file
  Future<String> unarchiveDocument(ArchivedDocument archivedDocument) async {
    final db = await database;

    // Read archived file
    final archivedFile = File(archivedDocument.archivedFilePath);
    if (!await archivedFile.exists()) {
      throw Exception(
        'Archived file not found: ${archivedDocument.archivedFilePath}',
      );
    }

    final compressedBytes = await archivedFile.readAsBytes();

    // Decompress file
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(compressedBytes);

    if (archive.isEmpty) {
      throw Exception('Archive is empty');
    }

    // Get first file from archive
    final file = archive.first;
    final decompressedBytes = file.content as List<int>;

    // Restore to original path
    final restoredFile = File(archivedDocument.originalFilePath);

    // Create parent directory if needed
    final parentDir = restoredFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    await restoredFile.writeAsBytes(decompressedBytes);

    // Delete archive record
    await db.delete(
      tableArchives,
      where: 'id = ?',
      whereArgs: [archivedDocument.id],
    );

    // Delete archived file
    await archivedFile.delete();

    return archivedDocument.originalFilePath;
  }

  /// Auto-archive documents that haven't been opened in specified days
  ///
  /// Parameters:
  /// - [daysThreshold]: Days since last opened
  /// - [archiveDirectory]: Directory to store archived files
  ///
  /// Returns: List of archived documents
  Future<List<ArchivedDocument>> autoArchiveOldDocuments(
    int daysThreshold,
    String archiveDirectory,
  ) async {
    final db = await database;

    // Calculate threshold timestamp
    final thresholdDate = DateTime.now().subtract(
      Duration(days: daysThreshold),
    );
    final thresholdTimestamp = thresholdDate.millisecondsSinceEpoch;

    // Query documents not opened in threshold period
    final results = await db.query(
      DrawingDatabase.tableDocuments,
      where: 'last_opened_at < ? OR last_opened_at IS NULL',
      whereArgs: [thresholdTimestamp],
    );

    final archivedDocuments = <ArchivedDocument>[];

    for (final map in results) {
      final document = DrawingDocument.fromMap(map);

      // Skip if already archived
      final existing = await getByDocumentId(document.id!);
      if (existing != null) continue;

      try {
        final archived = await archiveDocument(
          document,
          archiveDirectory,
          autoArchived: true,
        );
        archivedDocuments.add(archived);
      } catch (e) {
        // Skip documents that fail to archive
      }
    }

    return archivedDocuments;
  }

  /// Get all archived documents
  Future<List<ArchivedDocument>> getAll() async {
    final db = await database;
    final results = await db.query(tableArchives, orderBy: 'archived_at DESC');
    return results.map((map) => ArchivedDocument.fromMap(map)).toList();
  }

  /// Get archived document by ID
  Future<ArchivedDocument?> getById(int id) async {
    final db = await database;
    final results = await db.query(
      tableArchives,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ArchivedDocument.fromMap(results.first);
  }

  /// Get archived document by document ID
  Future<ArchivedDocument?> getByDocumentId(int documentId) async {
    final db = await database;
    final results = await db.query(
      tableArchives,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
    if (results.isEmpty) return null;
    return ArchivedDocument.fromMap(results.first);
  }

  /// Get all auto-archived documents
  Future<List<ArchivedDocument>> getAutoArchived() async {
    final db = await database;
    final results = await db.query(
      tableArchives,
      where: 'auto_archived = ?',
      whereArgs: [1],
      orderBy: 'archived_at DESC',
    );
    return results.map((map) => ArchivedDocument.fromMap(map)).toList();
  }

  /// Get all manually archived documents
  Future<List<ArchivedDocument>> getManuallyArchived() async {
    final db = await database;
    final results = await db.query(
      tableArchives,
      where: 'auto_archived = ?',
      whereArgs: [0],
      orderBy: 'archived_at DESC',
    );
    return results.map((map) => ArchivedDocument.fromMap(map)).toList();
  }

  /// Get archived documents with their document details
  Future<List<ArchivedDocument>> getWithDocuments() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT 
        a.*,
        d.id as doc_id,
        d.name as doc_name,
        d.type as doc_type,
        d.folder_id as doc_folder_id,
        d.file_path as doc_file_path,
        d.thumbnail_path as doc_thumbnail_path,
        d.width as doc_width,
        d.height as doc_height,
        d.file_size as doc_file_size,
        d.created_at as doc_created_at,
        d.modified_at as doc_modified_at,
        d.last_opened_at as doc_last_opened_at,
        d.is_favorite as doc_is_favorite,
        d.stroke_count as doc_stroke_count,
        d.layer_count as doc_layer_count
      FROM $tableArchives a
      LEFT JOIN ${DrawingDatabase.tableDocuments} d ON a.document_id = d.id
      ORDER BY a.archived_at DESC
    ''');

    return results.map((map) {
      final archived = ArchivedDocument.fromMap(map);
      if (map['doc_id'] != null) {
        archived.document = DrawingDocument.fromMap({
          'id': map['doc_id'],
          'name': map['doc_name'],
          'type': map['doc_type'],
          'folder_id': map['doc_folder_id'],
          'file_path': map['doc_file_path'],
          'thumbnail_path': map['doc_thumbnail_path'],
          'width': map['doc_width'],
          'height': map['doc_height'],
          'file_size': map['doc_file_size'],
          'created_at': map['doc_created_at'],
          'modified_at': map['doc_modified_at'],
          'last_opened_at': map['doc_last_opened_at'],
          'is_favorite': map['doc_is_favorite'],
          'stroke_count': map['doc_stroke_count'],
          'layer_count': map['doc_layer_count'],
        });
      }
      return archived;
    }).toList();
  }

  /// Calculate total space saved by archiving
  Future<Map<String, dynamic>> getStorageStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_archives,
        SUM(original_size) as total_original_size,
        SUM(archived_size) as total_archived_size,
        SUM(original_size - archived_size) as total_space_saved,
        AVG(compression_ratio) as avg_compression_ratio
      FROM $tableArchives
    ''');

    final stats = result.first;
    return {
      'totalArchives': stats['total_archives'] ?? 0,
      'totalOriginalSize': stats['total_original_size'] ?? 0,
      'totalArchivedSize': stats['total_archived_size'] ?? 0,
      'totalSpaceSaved': stats['total_space_saved'] ?? 0,
      'avgCompressionRatio': stats['avg_compression_ratio'] ?? 0.0,
    };
  }

  /// Delete an archive record (without unarchiving)
  Future<void> delete(int id) async {
    final db = await database;

    // Get archive to delete the file
    final archive = await getById(id);
    if (archive != null) {
      final file = File(archive.archivedFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await db.delete(tableArchives, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all archives for a document
  Future<void> deleteByDocumentId(int documentId) async {
    final db = await database;

    // Get all archives for document
    final archives = await db.query(
      tableArchives,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    // Delete archived files
    for (final map in archives) {
      final archive = ArchivedDocument.fromMap(map);
      final file = File(archive.archivedFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Delete records
    await db.delete(
      tableArchives,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Delete all archives
  Future<void> deleteAll() async {
    final db = await database;

    // Get all archives
    final archives = await getAll();

    // Delete all archived files
    for (final archive in archives) {
      final file = File(archive.archivedFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Delete all records
    await db.delete(tableArchives);
  }

  /// Check if a document is archived
  Future<bool> isArchived(int documentId) async {
    final archive = await getByDocumentId(documentId);
    return archive != null;
  }

  /// Get count of archived documents
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableArchives',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get count of auto-archived documents
  Future<int> getAutoArchivedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableArchives WHERE auto_archived = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
