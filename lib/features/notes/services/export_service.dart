import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/note_document.dart';

class ExportService {
  Future<NoteDocument?> importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return NoteDocument.fromJson(jsonMap);
    }
    return null;
  }

  Future<String> exportToJson(NoteDocument document) async {
    final jsonString = jsonEncode(document.toJson());
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${document.title}.json';
    final file = File(path);
    await file.writeAsString(jsonString);
    return path;
  }

  Future<String> exportToPdf(NoteDocument document) async {
    final pdf = pw.Document();

    for (final page in document.pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                for (final stroke in page.drawingData)
                  for (int i = 0; i < stroke.coordinates.length - 1; i++)
                    pw.Positioned(
                      left: 0,
                      top: 0,
                      child: pw.Container(
                        width: PdfPageFormat.a4.width,
                        height: PdfPageFormat.a4.height,
                        child: pw.Line(
                          x1: stroke.coordinates[i].dx,
                          y1: PdfPageFormat.a4.height - stroke.coordinates[i].dy,
                          x2: stroke.coordinates[i + 1].dx,
                          y2: PdfPageFormat.a4.height - stroke.coordinates[i + 1].dy,
                          color: PdfColor.fromInt(stroke.color),
                          thickness: stroke.width,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${document.title}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

}
