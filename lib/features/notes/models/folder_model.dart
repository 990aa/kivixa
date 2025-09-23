// This file defines the Folder model for the notes app.
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note_document.dart'; // Changed to relative import

class Folder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime lastModified;
  final Color color;
  final IconData icon;
  final List<Folder> subFolders;
  final List<NoteDocument> notes;
  final int noteCount;
  final double size;
  final double capacity;

  Folder({
    String? id,
    required this.name,
    this.parentId,
    DateTime? createdAt,
    DateTime? lastModified,
    this.color = Colors.blue,
    this.icon = Icons.folder,
    this.subFolders = const [],
    this.notes = const [],
    this.noteCount = 0,
    this.size = 0.0,
    this.capacity = 1.0,
  }) : id = id ?? const Uuid().v4(),
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
    List<NoteDocument>? notes,
    int? noteCount,
    double? size,
    double? capacity,
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
      notes: notes ?? this.notes,
      noteCount: noteCount ?? this.noteCount,
      size: size ?? this.size,
      capacity: capacity ?? this.capacity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      parentId: map['parentId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
      color: Color(map['color']),
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
    );
  }
}
