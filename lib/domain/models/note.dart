// lib/domain/models/note.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'note.freezed.dart';
part 'note.g.dart';

@HiveType(typeId: 0)
enum PageTemplate {
  @HiveField(0)
  plain,
  @HiveField(1)
  ruled,
  @HiveField(2)
  grid,
}

@HiveType(typeId: 1)
enum DrawingTool {
  @HiveField(0)
  pen,
  @HiveField(1)
  highlighter,
  @HiveField(2)
  eraser,
}

@HiveType(typeId: 2)
@freezed
class Stroke with _$Stroke {
  @HiveField(0)
  const factory Stroke({
    @HiveField(1) required DrawingTool tool,
    @HiveField(2) required List<Offset> points,
    @HiveField(3) required Color color,
    @HiveField(4) required double thickness,
    @HiveField(5) required DateTime createdAt,
  }) = _Stroke;

  factory Stroke.fromJson(Map<String, dynamic> json) => _$StrokeFromJson(json);
}

@HiveType(typeId: 3)
@freezed
class CanvasImage with _$CanvasImage {
  @HiveField(0)
  const factory CanvasImage({
    @HiveField(1) required String id,
    @HiveField(2) required String imagePath,
    @HiveField(3) required Offset position,
    @HiveField(4) required Size size,
    @HiveField(5) required double rotation,
    @HiveField(6) required DateTime createdAt,
  }) = _CanvasImage;

  factory CanvasImage.fromJson(Map<String, dynamic> json) => _$CanvasImageFromJson(json);
}

@HiveType(typeId: 4)
@freezed
class NotePage with _$NotePage {
  @HiveField(0)
  const factory NotePage({
    @HiveField(1) required String id,
    @HiveField(2) required PageTemplate template,
    @HiveField(3) @Default([]) List<Stroke> strokes,
    @HiveField(4) @Default([]) List<CanvasImage> images,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required DateTime updatedAt,
  }) = _NotePage;

  factory NotePage.fromJson(Map<String, dynamic> json) => _$NotePageFromJson(json);
}

@HiveType(typeId: 5)
@freezed
class Note with _$Note {
  @HiveField(0)
  const factory Note({
    @HiveField(1) required String id,
    @HiveField(2) required String title,
    @HiveField(3) required List<NotePage> pages,
    @HiveField(4) required PageTemplate defaultTemplate,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required DateTime updatedAt,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}