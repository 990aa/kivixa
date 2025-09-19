
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/note_document.dart';

class ExportService {
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
            return pw.CustomPaint(
              painter: (canvas, size) {
                for (final stroke in page.drawingData) {
                  final path = pw.Path()
                    ..moveTo(stroke.coordinates.first.dx,
                        size.height - stroke.coordinates.first.dy);
                  for (final point in stroke.coordinates.skip(1)) {
                    path.lineTo(point.dx, size.height - point.dy);
                  }
                  canvas.drawPath(
                    path,
                    pw.Paint()
                      ..color = PdfColor.fromInt(stroke.color)
                      ..strokeWidth = stroke.width
                      ..style = pw.PaintingStyle.stroke,
                  );
                }
              },
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

  Future<String> exportToPng(
      NoteDocument document, Uint8List pngBytes, int pageNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${document.title}_page_$pageNumber.png';
    final file = File(path);
    await file.writeAsBytes(pngBytes);
    return path;
  }
}
