import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;
import '../models/annotation_data.dart';
import '../models/annotation_layer.dart';
import '../models/drawing_tool.dart';
import '../painters/annotation_painter.dart';
import '../widgets/toolbar_widget.dart';
import '../services/annotation_storage.dart';

class PDFViewerScreen extends StatefulWidget {
  final String? pdfPath;
  final Uint8List? pdfBytes;

  const PDFViewerScreen({super.key, required String pdfPath})
      : pdfPath = pdfPath,
        pdfBytes = null;

  const PDFViewerScreen.file({super.key, required String pdfPath})
      : pdfPath = pdfPath,
        pdfBytes = null;

  const PDFViewerScreen.memory({super.key, required Uint8List pdfBytes})
      : pdfBytes = pdfBytes,
        pdfPath = null;

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}
