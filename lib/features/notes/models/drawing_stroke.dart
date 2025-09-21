import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'drawing_stroke.g.dart';

@JsonSerializable(converters: [OffsetConverter()])
class DrawingStroke {
  final List<Offset> coordinates;
  final int color;
  final double width;
  final int timestamp;

  DrawingStroke({
    required this.coordinates,
    required this.color,
    required this.width,
    required this.timestamp,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) =>
      _$DrawingStrokeFromJson(json);

  Map<String, dynamic> toJson() => _$DrawingStrokeToJson(this);

  factory DrawingStroke.fromScribble(Map<String, dynamic> json) {
    return DrawingStroke(
      coordinates: (json['points'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      color: json['color'] as int,
      width: json['strokeWidth'] as double,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// Since Offset is not directly serializable, we need a custom converter.
class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(json['dx'] as double, json['dy'] as double);
  }

  @override
  Map<String, dynamic> toJson(Offset object) {
    return {'dx': object.dx, 'dy': object.dy};
  }
}
