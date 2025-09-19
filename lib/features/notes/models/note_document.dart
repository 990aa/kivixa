
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

  NoteDocument({
    required this.id,
    required this.title,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteDocument.fromJson(Map<String, dynamic> json) =>
      _$NoteDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$NoteDocumentToJson(this);
}
