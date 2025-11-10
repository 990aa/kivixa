import 'package:sqflite/sqflite.dart';
import 'package:kivixa/database/drawing_database.dart';
import 'package:kivixa/models/archived_document.dart';
import 'package:kivixa/models/drawing_document.dart';
import 'package:kivixa/services/compression_service.dart';

/// Enhanced archive repository with GZIP compression
///
/// Provides high-level archive operations using lossless GZIP compression.
///
/// Features:
/// - Manual archive/unarchive
/// - Storage statistics
/// - Document status tracking
/// - Integration with CompressionService
class GzipArchiveRepository {
  Future<Database> get database async => DrawingDatabase.database;

  /// Manually archive document using GZIP compression
  ///
  /// Compresses document, stores archive record, and marks document as archived.
  ///
  /// Parameters:
  /// - [document]: Document to archive
  ///
  /// Throws: Exception if archiving fails
  Future<void> archiveDocument(DrawingDocument document) async {
    if (document.id == null) {
      throw Exception('Document must have an ID');
    }

    final db = await database;

    // Check if already archived
    final existing = await db.query(
      'archives',
      where: 'document_id = ?',
      whereArgs: [document.id],
    );

    if (existing.isNotEmpty) {
      throw Exception('Document is already archived');
    }

    // Compress and archive using GZIP
    final archive = await CompressionService.archiveDocument(
      document: document,
      autoArchived: false,
    );

    // Save archive record
    await db.insert('archives', archive.toMap());

    // Update document metadata (if archived field exists)
    try {
      await db.update(
        DrawingDatabase.tableDocuments,
        {'last_opened_at': null}, // Clear last opened to indicate archived
        where: 'id = ?',
        whereArgs: [document.id],
      );
    } catch (e) {
      // Table might not have archived field yet
    }
  }

  /// Unarchive document
  ///
  /// Decompresses archive, restores file, and removes archive record.
  ///
  /// Parameters:
  /// - [documentId]: ID of document to unarchive
  ///
  /// Throws: Exception if unarchiving fails or archive not found
  Future<void> unarchiveDocument(int documentId) async {
    final db = await database;

    // Get archive record
    final archiveData = await db.query(
      'archives',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    if (archiveData.isEmpty) {
      throw Exception('Archive not found for document $documentId');
    }

    final archive = ArchivedDocument.fromMap(archiveData.first);

    // Get document metadata
    final docData = await db.query(
      DrawingDatabase.tableDocuments,
      where: 'id = ?',
      whereArgs: [documentId],
    );

    if (docData.isEmpty) {
      throw Exception('Document not found: $documentId');
    }

    final document = DrawingDocument.fromMap(docData.first);

    // Restore file using GZIP decompression
    await CompressionService.unarchiveDocument(
      archive: archive,
      document: document,
    );

    // Remove from archives table
    await db.delete(
      'archives',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    // Update document status
    await db.update(
      DrawingDatabase.tableDocuments,
      {'last_opened_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Get all archived documents
  Future<List<ArchivedDocument>> getArchivedDocuments() async {
    final db = await database;
    final maps = await db.query('archives', orderBy: 'archived_at DESC');

    return maps.map((map) => ArchivedDocument.fromMap(map)).toList();
  }

  /// Get archived documents with document details
  Future<List<ArchivedDocument>> getArchivedWithDocuments() async {
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
      FROM archives a
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

  /// Get storage savings from archiving
  ///
  /// Returns statistics about compression performance.
  Future<Map<String, dynamic>> getArchiveStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_archived,
        SUM(original_size) as total_original_size,
        SUM(archived_size) as total_archived_size,
        AVG(compression_ratio) as avg_compression_ratio
      FROM archives
    ''');

    final stats = result.first;
    final originalSize = (stats['total_original_size'] as int?) ?? 0;
    final archivedSize = (stats['total_archived_size'] as int?) ?? 0;
    final spaceSaved = originalSize - archivedSize;

    return {
      'totalArchived': stats['total_archived'] ?? 0,
      'totalOriginalSize': originalSize,
      'totalArchivedSize': archivedSize,
      'totalSpaceSaved': spaceSaved,
      'avgCompressionRatio': stats['avg_compression_ratio'] ?? 0.0,
      'spaceSavingPercentage': originalSize > 0
          ? (spaceSaved / originalSize) * 100
          : 0.0,
    };
  }

  /// Get formatted storage statistics
  Future<Map<String, String>> getFormattedArchiveStats() async {
    final stats = await getArchiveStats();

    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(2)} KB';
      }
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }

    final originalSize = stats['totalOriginalSize'] as int;
    final archivedSize = stats['totalArchivedSize'] as int;
    final spaceSaved = stats['totalSpaceSaved'] as int;
    final compressionRatio = stats['avgCompressionRatio'] as double;
    final savingPercentage = stats['spaceSavingPercentage'] as double;

    return {
      'totalArchived': stats['totalArchived'].toString(),
      'totalOriginalSize': formatBytes(originalSize),
      'totalArchivedSize': formatBytes(archivedSize),
      'totalSpaceSaved': formatBytes(spaceSaved),
      'avgCompressionRatio':
          '${((1 - compressionRatio) * 100).toStringAsFixed(1)}%',
      'spaceSavingPercentage': '${savingPercentage.toStringAsFixed(1)}%',
    };
  }

  /// Check if document is archived
  Future<bool> isArchived(int documentId) async {
    final db = await database;
    final result = await db.query(
      'archives',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
    return result.isNotEmpty;
  }

  /// Get archive count
  Future<int> getArchiveCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM archives');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete archive without unarchiving
  ///
  /// WARNING: This permanently deletes the archived file!
  Future<void> deleteArchive(int archiveId) async {
    final db = await database;

    // Get archive to delete file
    final archives = await db.query(
      'archives',
      where: 'id = ?',
      whereArgs: [archiveId],
    );

    if (archives.isNotEmpty) {
      // Physical file cleanup handled by resource cleanup service
    }

    await db.delete('archives', where: 'id = ?', whereArgs: [archiveId]);
  }
}
