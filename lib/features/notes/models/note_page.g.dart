// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotePage _$NotePageFromJson(Map<String, dynamic> json) => NotePage(
  pageNumber: (json['pageNumber'] as num).toInt(),
  paperType: json['paperType'] as String,
  drawingData: (json['drawingData'] as List<dynamic>)
      .map((e) => DrawingStroke.fromJson(e as Map<String, dynamic>))
      .toList(),
  backgroundSettings: json['backgroundSettings'] as Map<String, dynamic>,
);

Map<String, dynamic> _$NotePageToJson(NotePage instance) => <String, dynamic>{
  'pageNumber': instance.pageNumber,
  'paperType': instance.paperType,
  'drawingData': instance.drawingData,
  'backgroundSettings': instance.backgroundSettings,
};
