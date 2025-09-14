import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' show PdfView;

class PdfPageView extends StatefulWidget {
  final String pdfPath;

  const PdfPageView({super.key, required this.pdfPath});

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  @override
  Widget build(BuildContext context) {
    return PdfView.openFile(widget.pdfPath);
  }
}
