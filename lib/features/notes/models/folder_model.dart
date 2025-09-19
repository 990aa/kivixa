import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

@immutable
class Folder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final Color color;
  final IconData icon;
  final List<Folder> subFolders;

  Folder({
    String? id,
    required this.name,
    this.parentId,
    DateTime? createdAt,
    this.color = Colors.blue,
    this.icon = Icons.folder,
    this.subFolders = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    Color? color,
    IconData? icon,
    List<Folder>? subFolders,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      subFolders: subFolders ?? this.subFolders,
    );
  }
}
