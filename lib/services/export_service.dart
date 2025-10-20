import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/annotation_data.dart';
import 'dart:ui' as ui;

class ExportService {
  Future<void> exportAnnotationsAsImage(List<AnnotationData> annotations, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    for (final annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = annotation.strokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (annotation.points.isNotEmpty) {
        path.moveTo(annotation.points.first.dx, annotation.points.first.dy);
        for (var i = 1; i < annotation.points.length; i++) {
          path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/annotated_image.png');
    await file.writeAsBytes(buffer);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'Annotated Image');
  }

  Future<void> exportAnnotationsAsPdf(List<AnnotationData> annotations, Size size) async {
    final pdf = pw.Document();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    for (final annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = annotation.strokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (annotation.points.isNotEmpty) {
        path.moveTo(annotation.points.first.dx, annotation.points.first.dy);
        for (var i = 1; i < annotation.points.length; i++) {
          path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final image = pw.MemoryImage(buffer);

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(child: pw.Image(image));
    }));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'annotated_document.pdf');
  }
}
