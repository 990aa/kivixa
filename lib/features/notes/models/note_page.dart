import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:kivixa/features/notes/models/paper_settings.dart';
import 'drawing_stroke.dart';

part 'note_page.g.dart';

@JsonSerializable(converters: [Uint8ListConverter(), PaperSettingsConverter()])
class NotePage {
  final int pageNumber;
  final List<DrawingStroke> strokes;
  final PaperSettings paperSettings;
  final Uint8List? backgroundImage;

  NotePage({
    required this.pageNumber,
    required this.strokes,
    required this.paperSettings,
    this.backgroundImage,
  });

  factory NotePage.fromJson(Map<String, dynamic> json) =>
      _$NotePageFromJson(json);

  Map<String, dynamic> toJson() => _$NotePageToJson(this);

  NotePage copyWith({
    int? pageNumber,
    List<DrawingStroke>? strokes,
    PaperSettings? paperSettings,
    Uint8List? backgroundImage,
  }) {
    return NotePage(
      pageNumber: pageNumber ?? this.pageNumber,
      strokes: strokes ?? this.strokes,
      paperSettings: paperSettings ?? this.paperSettings,
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

class PaperSettingsConverter
    implements JsonConverter<PaperSettings, Map<String, dynamic>> {
  const PaperSettingsConverter();

  @override
  PaperSettings fromJson(Map<String, dynamic> json) {
    final paperType = PaperType.values.byName(json['paperType']);
    final optionsJson = json['options'] as Map<String, dynamic>;
    switch (paperType) {
      case PaperType.plain:
        return PaperSettings(paperType: paperType, paperSize: PaperSize.a4, options: PlainPaperOptions.fromJson(optionsJson));
      case PaperType.ruled:
         return PaperSettings(paperType: paperType, paperSize: PaperSize.a4, options: RuledPaperOptions.fromJson(optionsJson));
      case PaperType.grid:
         return PaperSettings(paperType: paperType, paperSize: PaperSize.a4, options: GridPaperOptions.fromJson(optionsJson));
      case PaperType.dotGrid:
         return PaperSettings(paperType: paperType, paperSize: PaperSize.a4, options: DotGridPaperOptions.fromJson(optionsJson));
      case PaperType.graph:
         return PaperSettings(paperType: paperType, paperSize: PaperSize.a4, options: GraphPaperOptions.fromJson(optionsJson));
    }
  }

  @override
  Map<String, dynamic> toJson(PaperSettings object) {
    return {
      'paperType': object.paperType.name,
      'paperSize': {
        'width': object.paperSize.width,
        'height': object.paperSize.height,
      },
      'options': object.options.toJson(),
    };
  }
}