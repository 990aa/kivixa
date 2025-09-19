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

  /// Exports a list of PNG images (one per page) as a PDF.
  Future<String> exportImagesToPdf(
    String title,
    List<Uint8List> pngPages,
  ) async {
    final pdf = pw.Document();
    for (final pngBytes in pngPages) {
      final image = pw.MemoryImage(pngBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
              ),
            );
          },
        ),
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$title.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }
}
