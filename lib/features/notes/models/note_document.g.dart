// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteDocument _$NoteDocumentFromJson(Map<String, dynamic> json) => NoteDocument(
  id: json['id'] as String?,
  title: json['title'] as String,
  pages: (json['pages'] as List<dynamic>)
      .map((e) => NotePage.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  folderId: json['folderId'] as String?,
);

Map<String, dynamic> _$NoteDocumentToJson(NoteDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'pages': instance.pages,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'folderId': instance.folderId,
    };
