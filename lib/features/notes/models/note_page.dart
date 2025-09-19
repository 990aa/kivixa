import 'package:json_annotation/json_annotation.dart';
import 'drawing_stroke.dart';

part 'note_page.g.dart';

@JsonSerializable()
class NotePage {
  final int pageNumber;
  final String paperType;
  final List<DrawingStroke> drawingData;
  final Map<String, dynamic> backgroundSettings;

  NotePage({
    required this.pageNumber,
    required this.paperType,
    required this.drawingData,
    required this.backgroundSettings,
  });

  factory NotePage.fromJson(Map<String, dynamic> json) => _$NotePageFromJson(json);

  Map<String, dynamic> toJson() => _$NotePageToJson(this);
}
