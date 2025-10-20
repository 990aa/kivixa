import 'package:flutter/material.dart';

/// Folder model with hierarchical structure support
///
/// Supports:
/// - Parent-child relationships
/// - Nested folders (unlimited depth)
/// - Custom colors for visual organization
/// - Computed properties for subfolders and documents
class Folder {
  final int? id;
  final String name;
  final int? parentFolderId;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final Color? color;
  final String? icon;
  final String? description;

  // Computed properties (not stored in database)
  List<Folder> subfolders = [];
  int documentCount = 0;

  Folder({
    this.id,
    required this.name,
    this.parentFolderId,
    required this.createdAt,
    required this.modifiedAt,
    this.color,
    this.icon,
    this.description,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_folder_id': parentFolderId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'modified_at': modifiedAt.millisecondsSinceEpoch,
      'color': color?.toARGB32(),
      'icon': icon,
      'description': description,
    };
  }

  /// Create from database map
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentFolderId: map['parent_folder_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        map['modified_at'] as int,
      ),
      color: map['color'] != null ? Color(map['color'] as int) : null,
      icon: map['icon'] as String?,
      description: map['description'] as String?,
    );
  }

  /// Create a copy with modified fields
  Folder copyWith({
    int? id,
    String? name,
    int? parentFolderId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Color? color,
    String? icon,
    String? description,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      description: description ?? this.description,
    );
  }

  /// Check if this folder is a root folder (no parent)
  bool get isRoot => parentFolderId == null;

  /// Get folder path (for breadcrumb navigation)
  /// Requires parent folder lookup
  String getPath(List<Folder> allFolders) {
    if (isRoot) return name;

    final parent = allFolders.firstWhere(
      (f) => f.id == parentFolderId,
      orElse: () => this,
    );

    if (parent.id == id) return name; // Safety check
    return '${parent.getPath(allFolders)} / $name';
  }

  /// Get all ancestor folders
  List<Folder> getAncestors(List<Folder> allFolders) {
    if (isRoot) return [];

    final ancestors = <Folder>[];
    Folder? current = this;

    while (current != null && !current.isRoot) {
      final parent = allFolders.firstWhere(
        (f) => f.id == current!.parentFolderId,
        orElse: () => current!,
      );

      if (parent.id == current.id) break; // Safety check
      ancestors.insert(0, parent);
      current = parent;
    }

    return ancestors;
  }

  /// Get all descendant folders (recursive)
  List<Folder> getDescendants(List<Folder> allFolders) {
    final descendants = <Folder>[];

    void addDescendants(Folder folder) {
      final children = allFolders.where((f) => f.parentFolderId == folder.id);
      for (final child in children) {
        descendants.add(child);
        addDescendants(child);
      }
    }

    addDescendants(this);
    return descendants;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Folder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, parent: $parentFolderId)';
  }
}
