import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfPageView extends StatefulWidget {
  final String pdfPath;

  const PdfPageView({super.key, required this.pdfPath});

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdfView(
      controller: _pdfController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }
}
