import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kivixa/database/archive_repository.dart';
import 'package:kivixa/database/document_repository.dart';
import 'package:kivixa/models/archived_document.dart';
import 'package:kivixa/models/drawing_document.dart';

/// Archive management service
///
/// High-level service for document archiving with:
/// - Automatic archiving based on usage patterns
/// - Manual archive/unarchive operations
/// - Storage optimization
/// - Archive statistics and reporting
///
/// Usage:
/// ```dart
/// final service = ArchiveService();
///
/// // Manual archive
/// await service.archiveDocument(document);
///
/// // Auto-archive old documents (>90 days)
/// await service.runAutoArchive(daysThreshold: 90);
///
/// // Unarchive when needed
/// await service.unarchiveDocument(archivedDoc);
/// ```
class ArchiveService {
  final _archiveRepo = ArchiveRepository();
  final _documentRepo = DocumentRepository();

  /// Get archive directory path
  Future<String> getArchiveDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final archiveDir = Directory('${appDir.path}/archives');
    if (!await archiveDir.exists()) {
      await archiveDir.create(recursive: true);
    }
    return archiveDir.path;
  }

  /// Archive a document
  ///
  /// Parameters:
  /// - [document]: Document to archive
  /// - [autoArchived]: Whether this is automatic archiving
  ///
  /// Returns: ArchivedDocument with compression stats
  Future<ArchivedDocument> archiveDocument(
    DrawingDocument document, {
    bool autoArchived = false,
  }) async {
    if (document.id == null) {
      throw Exception('Document must have an ID');
    }

    // Check if already archived
    if (await _archiveRepo.isArchived(document.id!)) {
      throw Exception('Document is already archived');
    }

    final archiveDir = await getArchiveDirectory();
    final archived = await _archiveRepo.archiveDocument(
      document,
      archiveDir,
      autoArchived: autoArchived,
    );

    return archived;
  }

  /// Unarchive a document
  ///
  /// Parameters:
  /// - [archivedDocument]: Archived document to restore
  ///
  /// Returns: Path to restored file
  Future<String> unarchiveDocument(ArchivedDocument archivedDocument) async {
    return await _archiveRepo.unarchiveDocument(archivedDocument);
  }

  /// Run auto-archiving for old documents
  ///
  /// Archives documents not opened in the specified number of days.
  ///
  /// Parameters:
  /// - [daysThreshold]: Days since last opened (default: 90)
  /// - [excludeFavorites]: Skip favorite documents (default: true)
  /// - [onProgress]: Progress callback (archived count, total)
  ///
  /// Returns: List of archived documents
  Future<List<ArchivedDocument>> runAutoArchive({
    int daysThreshold = 90,
    bool excludeFavorites = true,
    Function(int archived, int total)? onProgress,
  }) async {
    final archiveDir = await getArchiveDirectory();

    // Get documents eligible for archiving
    final thresholdDate = DateTime.now().subtract(
      Duration(days: daysThreshold),
    );
    final documents = await _documentRepo.getAll();

    final eligibleDocs = documents.where((doc) {
      // Skip if already archived
      if (doc.id == null) return false;

      // Skip favorites if requested
      if (excludeFavorites && doc.isFavorite) return false;

      // Check last opened date
      if (doc.lastOpenedAt == null) {
        // Never opened - check creation date
        return doc.createdAt.isBefore(thresholdDate);
      }

      return doc.lastOpenedAt!.isBefore(thresholdDate);
    }).toList();

    final archivedDocuments = <ArchivedDocument>[];
    int processed = 0;

    for (final document in eligibleDocs) {
      // Check if already archived
      final isArchived = await _archiveRepo.isArchived(document.id!);
      if (isArchived) {
        processed++;
        continue;
      }

      try {
        final archived = await _archiveRepo.archiveDocument(
          document,
          archiveDir,
          autoArchived: true,
        );
        archivedDocuments.add(archived);
        processed++;
        onProgress?.call(processed, eligibleDocs.length);
      } catch (e) {
        processed++;
      }
    }

    return archivedDocuments;
  }

  /// Get all archived documents
  Future<List<ArchivedDocument>> getAllArchived() async {
    return await _archiveRepo.getAll();
  }

  /// Get all archived documents with document details
  Future<List<ArchivedDocument>> getAllArchivedWithDocuments() async {
    return await _archiveRepo.getWithDocuments();
  }

  /// Get archive by document ID
  Future<ArchivedDocument?> getArchivedByDocumentId(int documentId) async {
    return await _archiveRepo.getByDocumentId(documentId);
  }

  /// Check if document is archived
  Future<bool> isDocumentArchived(int documentId) async {
    return await _archiveRepo.isArchived(documentId);
  }

  /// Get storage statistics
  ///
  /// Returns:
  /// - totalArchives: Number of archived documents
  /// - totalOriginalSize: Total size before compression
  /// - totalArchivedSize: Total size after compression
  /// - totalSpaceSaved: Space saved in bytes
  /// - avgCompressionRatio: Average compression ratio
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _archiveRepo.getStorageStats();
  }

  /// Get formatted storage statistics
  Future<Map<String, String>> getFormattedStorageStats() async {
    final stats = await getStorageStats();

    String formatBytes(int bytes) {
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
      }
    }

    final totalOriginalSize = stats['totalOriginalSize'] as int;
    final totalArchivedSize = stats['totalArchivedSize'] as int;
    final totalSpaceSaved = stats['totalSpaceSaved'] as int;
    final avgCompressionRatio = stats['avgCompressionRatio'] as double;

    return {
      'totalArchives': stats['totalArchives'].toString(),
      'totalOriginalSize': formatBytes(totalOriginalSize),
      'totalArchivedSize': formatBytes(totalArchivedSize),
      'totalSpaceSaved': formatBytes(totalSpaceSaved),
      'avgCompressionRatio':
          '${(avgCompressionRatio * 100).toStringAsFixed(1)}%',
      'spaceSavingPercentage': totalOriginalSize > 0
          ? '${((totalSpaceSaved / totalOriginalSize) * 100).toStringAsFixed(1)}%'
          : '0%',
    };
  }

  /// Delete an archive (without unarchiving)
  Future<void> deleteArchive(int archiveId) async {
    await _archiveRepo.delete(archiveId);
  }

  /// Clean up invalid archives (missing files)
  ///
  /// Removes archive records where the archived file no longer exists.
  ///
  /// Returns: Number of cleaned up archives
  Future<int> cleanupInvalidArchives() async {
    final archives = await _archiveRepo.getAll();
    int cleaned = 0;

    for (final archive in archives) {
      final file = File(archive.archivedFilePath);
      if (!await file.exists()) {
        await _archiveRepo.delete(archive.id!);
        cleaned++;
      }
    }

    return cleaned;
  }

  /// Get documents eligible for auto-archiving
  ///
  /// Returns list of documents that haven't been opened in specified days.
  ///
  /// Parameters:
  /// - [daysThreshold]: Days since last opened
  /// - [excludeFavorites]: Skip favorite documents
  Future<List<DrawingDocument>> getEligibleForArchiving({
    int daysThreshold = 90,
    bool excludeFavorites = true,
  }) async {
    final thresholdDate = DateTime.now().subtract(
      Duration(days: daysThreshold),
    );
    final documents = await _documentRepo.getAll();

    final eligible = <DrawingDocument>[];

    for (final doc in documents) {
      if (doc.id == null) continue;

      // Skip favorites if requested
      if (excludeFavorites && doc.isFavorite) continue;

      // Skip if already archived
      final isArchived = await _archiveRepo.isArchived(doc.id!);
      if (isArchived) continue;

      // Check last opened date
      if (doc.lastOpenedAt == null) {
        // Never opened - check creation date
        if (doc.createdAt.isBefore(thresholdDate)) {
          eligible.add(doc);
        }
      } else if (doc.lastOpenedAt!.isBefore(thresholdDate)) {
        eligible.add(doc);
      }
    }

    return eligible;
  }

  /// Get archive count
  Future<int> getArchiveCount() async {
    return await _archiveRepo.getCount();
  }

  /// Get auto-archived count
  Future<int> getAutoArchivedCount() async {
    return await _archiveRepo.getAutoArchivedCount();
  }

  /// Estimate compression ratio for a document
  ///
  /// Performs test compression to estimate space savings.
  /// Does not create actual archive.
  Future<double?> estimateCompressionRatio(DrawingDocument document) async {
    try {
      final file = File(document.filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      // Use gzip for estimation (faster than zip)
      final compressed = const GZipEncoder().encode(bytes);
      // Note: encode() always returns a non-null List<int>

      return compressed.length / bytes.length;
    } catch (e) {
      return null;
    }
  }
}
