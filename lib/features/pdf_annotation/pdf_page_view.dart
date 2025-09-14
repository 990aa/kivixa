import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfPageView extends StatefulWidget {
  final String pdfPath;

  const PdfPageView({super.key, required this.pdfPath});

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  PdfDocument? _pdfDocument;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfDocument();
  }

  Future<void> _loadPdfDocument() async {
    try {
      final document = await PdfDocument.openFile(widget.pdfPath);
      if (mounted) {
        setState(() {
          _pdfDocument = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors, e.g., show an error message
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // print('Error loading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pdfDocument == null) {
      // This case handles if loading failed
      return const Center(child: Text('Failed to load PDF.'));
    }
    return PdfView(
      document: _pdfDocument!,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
    );
  }

  @override
  void dispose() {
    _pdfDocument?.dispose();
    super.dispose();
  }
}
