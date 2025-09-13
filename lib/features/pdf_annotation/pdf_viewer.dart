import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'pdf_text_selector.dart';

class PdfViewer extends StatefulWidget {
  const PdfViewer({super.key});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  String? _pdfPath;
  PDFViewController? _pdfViewController;
  Size? _pageSize;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: _pdfPath == null
          ? const Center(
              child: Text('No PDF selected'),
            )
          : Stack(
              children: [
                PDFView(
                  filePath: _pdfPath!,
                  onViewCreated: (controller) {
                    _pdfViewController = controller;
                  },
                  onPageChanged: (page, total) {
                    _pdfViewController?.getPageSize(page ?? 0).then((size) {
                      setState(() {
                        _pageSize = size;
                      });
                    });
                  },
                ),
                if (_pageSize != null)
                  PdfTextSelector(
                    pdfPath: _pdfPath!,
                    pageSize: _pageSize!,
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.attach_file),
      ),
    );
  }
}
