import 'package:json_annotation/json_annotation.dart';
import 'package:kivixa/features/notes/models/note_page.dart';
import 'package:uuid/uuid.dart';

part 'note_document.g.dart';

@JsonSerializable()
class NoteDocument {
  final String id;
  final String title;
  final List<NotePage> pages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;

  NoteDocument({
    String? id,
    required this.title,
    required this.pages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.folderId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory NoteDocument.fromJson(Map<String, dynamic> json) =>
      _$NoteDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$NoteDocumentToJson(this);

  NoteDocument copyWith({
    String? id,
    String? title,
    List<NotePage>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderId,
  }) {
    return NoteDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
    );
  }
}
