import 'package:flutter/material.dart';
import 'tag.dart';

/// Document type enumeration
enum DocumentType {
  canvas,
  image,
  pdf,
}

/// Drawing document model
/// 
/// Represents any file in the system:
/// - Canvas files (native drawing format)
/// - Imported images (PNG, JPEG, etc.)
/// - PDF files
/// 
/// Features:
/// - Multi-tag support
/// - Thumbnail generation
/// - Metadata tracking (size, dimensions, etc.)
/// - Favorite marking
/// - Last opened tracking
class DrawingDocument {
  final int? id;
  final String name;
  final DocumentType type;
  final int? folderId;
  final String filePath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final int fileSize;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? lastOpenedAt;
  final bool isFavorite;
  final int strokeCount;
  final int layerCount;

  // Computed properties (not stored directly)
  List<Tag> tags = [];

  DrawingDocument({
    this.id,
    required this.name,
    required this.type,
    this.folderId,
    required this.filePath,
    this.thumbnailPath,
    this.width,
    this.height,
    required this.fileSize,
    required this.createdAt,
    required this.modifiedAt,
    this.lastOpenedAt,
    this.isFavorite = false,
    this.strokeCount = 0,
    this.layerCount = 0,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'folder_id': folderId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'modified_at': modifiedAt.millisecondsSinceEpoch,
      'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'stroke_count': strokeCount,
      'layer_count': layerCount,
    };
  }

  /// Create from database map
  factory DrawingDocument.fromMap(Map<String, dynamic> map) {
    return DrawingDocument(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: DocumentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      folderId: map['folder_id'] as int?,
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      fileSize: map['file_size'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      modifiedAt:
          DateTime.fromMillisecondsSinceEpoch(map['modified_at'] as int),
      lastOpenedAt: map['last_opened_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_opened_at'] as int)
          : null,
      isFavorite: map['is_favorite'] == 1,
      strokeCount: map['stroke_count'] as int? ?? 0,
      layerCount: map['layer_count'] as int? ?? 0,
    );
  }

  /// Create a copy with modified fields
  DrawingDocument copyWith({
    int? id,
    String? name,
    DocumentType? type,
    int? folderId,
    String? filePath,
    String? thumbnailPath,
    int? width,
    int? height,
    int? fileSize,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? lastOpenedAt,
    bool? isFavorite,
    int? strokeCount,
    int? layerCount,
  }) {
    return DrawingDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      folderId: folderId ?? this.folderId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      strokeCount: strokeCount ?? this.strokeCount,
      layerCount: layerCount ?? this.layerCount,
    )..tags = tags;
  }

  /// Get file extension
  String get extension {
    return filePath.split('.').last.toLowerCase();
  }

  /// Get human-readable file size
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get human-readable dimensions
  String? get dimensionsFormatted {
    if (width == null || height == null) return null;
    return '$width × $height';
  }

  /// Get document type icon
  IconData get typeIcon {
    switch (type) {
      case DocumentType.canvas:
        return Icons.brush;
      case DocumentType.image:
        return Icons.image;
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
    }
  }

  /// Get document type label
  String get typeLabel {
    switch (type) {
      case DocumentType.canvas:
        return 'Canvas';
      case DocumentType.image:
        return 'Image';
      case DocumentType.pdf:
        return 'PDF';
    }
  }

  /// Check if document has thumbnail
  bool get hasThumbnail => thumbnailPath != null;

  /// Check if document has been opened
  bool get hasBeenOpened => lastOpenedAt != null;

  /// Get time since last modification
  Duration get timeSinceModified {
    return DateTime.now().difference(modifiedAt);
  }

  /// Get time since last opened
  Duration? get timeSinceOpened {
    if (lastOpenedAt == null) return null;
    return DateTime.now().difference(lastOpenedAt!);
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

  /// Get relative time string for last modified
  String get modifiedRelative => getRelativeTime(modifiedAt);

  /// Get relative time string for last opened
  String? get openedRelative {
    if (lastOpenedAt == null) return null;
    return getRelativeTime(lastOpenedAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawingDocument && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DrawingDocument(id: $id, name: $name, type: $type, tags: ${tags.length})';
  }
}
