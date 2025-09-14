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
  // PDFViewController? _pdfViewController; // Removed: unused field
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
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: _pdfPath == null
          ? const Center(child: Text('No PDF selected'))
          : Stack(
              children: [
                PDFView(
                  filePath: _pdfPath!,
                  onViewCreated: (controller) {
                    // _pdfViewController = controller; // Removed: unused assignment
                  },
                  onPageChanged: (page, total) {
                    // PDFView (flutter_pdfview) does not provide page size info.
                    // If you need the real page size, use a package like pdfrx or pdf_render.
                    // For now, set a default A4 size as a stub.
                    setState(() {
                      _pageSize = const Size(595, 842); // A4 size in points
                    });
                  },
                ),
                if (_pageSize != null)
                  PdfTextSelector(pdfPath: _pdfPath!, pageSize: _pageSize!),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.attach_file),
      ),
    );
  }
}
