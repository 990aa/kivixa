import 'package:json_annotation/json_annotation.dart';
import 'note_page.dart';

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
    required this.id,
    required this.title,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
  });

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
