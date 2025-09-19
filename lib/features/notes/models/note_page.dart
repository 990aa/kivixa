import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'drawing_stroke.dart';

part 'note_page.g.dart';

@JsonSerializable(converters: [Uint8ListConverter()])
class NotePage {
  final int pageNumber;
  final String paperType;
  final List<DrawingStroke> drawingData;
  final Map<String, dynamic> backgroundSettings;
  final Uint8List? backgroundImage;

  NotePage({
    required this.pageNumber,
    required this.paperType,
    required this.drawingData,
    required this.backgroundSettings,
    this.backgroundImage,
  });

  factory NotePage.fromJson(Map<String, dynamic> json) => _$NotePageFromJson(json);

  Map<String, dynamic> toJson() => _$NotePageToJson(this);

  NotePage copyWith({
    int? pageNumber,
    String? paperType,
    List<DrawingStroke>? drawingData,
    Map<String, dynamic>? backgroundSettings,
    Uint8List? backgroundImage,
  }) {
    return NotePage(
      pageNumber: pageNumber ?? this.pageNumber,
      paperType: paperType ?? this.paperType,
      drawingData: drawingData ?? this.drawingData,
      backgroundSettings: backgroundSettings ?? this.backgroundSettings,
      backgroundImage: backgroundImage ?? this.backgroundImage,
    );
  }
}

class Uint8ListConverter implements JsonConverter<Uint8List?, List<int>?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(List<int>? json) {
    return json == null ? null : Uint8List.fromList(json);
  }

  @override
  List<int>? toJson(Uint8List? object) {
    return object?.toList();
  }
}
