import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

@immutable
class Folder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime lastModified;
  final Color color;
  final IconData icon;
  final List<Folder> subFolders;
  final int noteCount;

  Folder({
    String? id,
    required this.name,
    this.parentId,
    DateTime? createdAt,
    DateTime? lastModified,
    this.color = Colors.blue,
    this.icon = Icons.folder,
    this.subFolders = const [],
    this.noteCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? lastModified,
    Color? color,
    IconData? icon,
    List<Folder>? subFolders,
    int? noteCount,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      subFolders: subFolders ?? this.subFolders,
      noteCount: noteCount ?? this.noteCount,
    );
  }
}
