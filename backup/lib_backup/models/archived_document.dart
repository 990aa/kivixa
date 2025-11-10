import 'package:kivixa/models/drawing_document.dart';

/// Archived document model
///
/// Represents a compressed/archived version of a document.
/// Used for:
/// - Space optimization (compress rarely-used documents)
/// - Long-term storage
/// - Backup management
/// - Auto-archiving based on usage patterns
///
/// Features:
/// - Tracks compression statistics
/// - Links to original document
/// - Supports manual and automatic archiving
/// - Records archive date and ratios
class ArchivedDocument {
  final int? id;
  final int documentId;
  final String originalFilePath;
  final String archivedFilePath;
  final double compressionRatio;
  final int originalSize;
  final int archivedSize;
  final DateTime archivedAt;
  final bool autoArchived;

  // Computed property (loaded from join)
  DrawingDocument? document;

  ArchivedDocument({
    this.id,
    required this.documentId,
    required this.originalFilePath,
    required this.archivedFilePath,
    required this.compressionRatio,
    required this.originalSize,
    required this.archivedSize,
    required this.archivedAt,
    this.autoArchived = false,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'original_file_path': originalFilePath,
      'archived_file_path': archivedFilePath,
      'compression_ratio': compressionRatio,
      'original_size': originalSize,
      'archived_size': archivedSize,
      'archived_at': archivedAt.millisecondsSinceEpoch,
      'auto_archived': autoArchived ? 1 : 0,
    };
  }

  /// Create from database map
  factory ArchivedDocument.fromMap(Map<String, dynamic> map) {
    return ArchivedDocument(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      originalFilePath: map['original_file_path'] as String,
      archivedFilePath: map['archived_file_path'] as String,
      compressionRatio: map['compression_ratio'] as double,
      originalSize: map['original_size'] as int,
      archivedSize: map['archived_size'] as int,
      archivedAt: DateTime.fromMillisecondsSinceEpoch(
        map['archived_at'] as int,
      ),
      autoArchived: map['auto_archived'] == 1,
    );
  }

  /// Create a copy with modified fields
  ArchivedDocument copyWith({
    int? id,
    int? documentId,
    String? originalFilePath,
    String? archivedFilePath,
    double? compressionRatio,
    int? originalSize,
    int? archivedSize,
    DateTime? archivedAt,
    bool? autoArchived,
  }) {
    return ArchivedDocument(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      archivedFilePath: archivedFilePath ?? this.archivedFilePath,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      originalSize: originalSize ?? this.originalSize,
      archivedSize: archivedSize ?? this.archivedSize,
      archivedAt: archivedAt ?? this.archivedAt,
      autoArchived: autoArchived ?? this.autoArchived,
    )..document = document;
  }

  /// Calculate space saved in bytes
  int get spaceSaved {
    return originalSize - archivedSize;
  }

  /// Get human-readable space saved
  String get spaceSavedFormatted {
    final saved = spaceSaved;
    if (saved < 1024) {
      return '$saved B';
    } else if (saved < 1024 * 1024) {
      return '${(saved / 1024).toStringAsFixed(1)} KB';
    } else if (saved < 1024 * 1024 * 1024) {
      return '${(saved / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(saved / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get human-readable original size
  String get originalSizeFormatted {
    if (originalSize < 1024) {
      return '$originalSize B';
    } else if (originalSize < 1024 * 1024) {
      return '${(originalSize / 1024).toStringAsFixed(1)} KB';
    } else if (originalSize < 1024 * 1024 * 1024) {
      return '${(originalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(originalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get human-readable archived size
  String get archivedSizeFormatted {
    if (archivedSize < 1024) {
      return '$archivedSize B';
    } else if (archivedSize < 1024 * 1024) {
      return '${(archivedSize / 1024).toStringAsFixed(1)} KB';
    } else if (archivedSize < 1024 * 1024 * 1024) {
      return '${(archivedSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(archivedSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get compression percentage (e.g., "65.5%")
  String get compressionPercentage {
    return '${(compressionRatio * 100).toStringAsFixed(1)}%';
  }

  /// Get archive type label
  String get archiveTypeLabel {
    return autoArchived ? 'Auto-archived' : 'Manually archived';
  }

  /// Get time since archived
  Duration get timeSinceArchived {
    return DateTime.now().difference(archivedAt);
  }

  /// Format relative time (e.g., "2 hours ago")
  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Get relative time string for archive date
  String get archivedRelative => getRelativeTime(archivedAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArchivedDocument && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ArchivedDocument(id: $id, documentId: $documentId, '
        'compression: $compressionPercentage, saved: $spaceSavedFormatted)';
  }
}
