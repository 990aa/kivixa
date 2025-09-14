import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfPageView extends StatefulWidget {
  final String pdfPath;

  const PdfPageView({super.key, required this.pdfPath});

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  late PdfDocument _pdfDocument;

  @override
  void initState() {
    super.initState();
    _pdfDocument = PdfDocument.openFile(widget.pdfPath);
  }

  @override
  Widget build(BuildContext context) {
    return PdfView(
      document: _pdfDocument,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
    );
  }

  @override
  void dispose() {
    _pdfDocument.dispose();
    super.dispose();
  }
}
