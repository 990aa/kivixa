// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotePage _$NotePageFromJson(Map<String, dynamic> json) => NotePage(
  pageNumber: (json['pageNumber'] as num).toInt(),
  strokes: (json['strokes'] as List<dynamic>)
      .map((e) => DrawingStroke.fromJson(e as Map<String, dynamic>))
      .toList(),
  paperSettings: const PaperSettingsConverter().fromJson(
    json['paperSettings'] as Map<String, dynamic>,
  ),
  backgroundImage: const Uint8ListConverter().fromJson(
    json['backgroundImage'] as List<int>?,
  ),
);

Map<String, dynamic> _$NotePageToJson(NotePage instance) => <String, dynamic>{
  'pageNumber': instance.pageNumber,
  'strokes': instance.strokes,
  'paperSettings': const PaperSettingsConverter().toJson(
    instance.paperSettings,
  ),
  'backgroundImage': const Uint8ListConverter().toJson(
    instance.backgroundImage,
  ),
};
