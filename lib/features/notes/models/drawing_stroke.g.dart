// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_stroke.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawingStroke _$DrawingStrokeFromJson(Map<String, dynamic> json) =>
    DrawingStroke(
      coordinates: (json['coordinates'] as List<dynamic>)
          .map(
            (e) => const OffsetConverter().fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      color: (json['color'] as num).toInt(),
      width: (json['width'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$DrawingStrokeToJson(DrawingStroke instance) =>
    <String, dynamic>{
      'coordinates': instance.coordinates
          .map(const OffsetConverter().toJson)
          .toList(),
      'color': instance.color,
      'width': instance.width,
      'timestamp': instance.timestamp,
    };
