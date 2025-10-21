import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/annotation_layer.dart';
import '../models/drawing_tool.dart';
import '../painters/annotation_painter.dart';
import '../widgets/annotation_canvas.dart';
import '../widgets/toolbar_widget.dart';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;

class PDFViewerScreen extends StatefulWidget {
  final String? pdfPath;
  final Uint8List? pdfBytes;

  const PDFViewerScreen({super.key, this.pdfPath, this.pdfBytes})
    : assert(pdfPath != null || pdfBytes != null);

  const PDFViewerScreen.file({super.key, required this.pdfPath})
    : pdfBytes = null;

  const PDFViewerScreen.memory({super.key, required this.pdfBytes})
    : pdfPath = null;

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();

  final AnnotationLayer _annotationLayer = AnnotationLayer();
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;

  bool _isToolbarVisible = true;
  bool _isLoading = false;
  String? _error;

  final Size _canvasSize = const Size(595, 842);
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() {
      _error = 'Error loading PDF: ${details.error}';
      _isLoading = false;
    });
  }

  void _clearAnnotations() {
    setState(() {
      _annotationLayer.clearAnnotationsForPage(_currentPage);
    });
  }

  Future<void> _saveAnnotations() async {
    try {
      final String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Annotations',
        fileName: 'annotations.json',
        allowedExtensions: ['json'],
      );

      if (filePath != null) {
        final json = _annotationLayer.exportToJson();
        final File file = File(filePath);
        await file.writeAsString(json);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annotations saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving annotations: $e')));
      }
    }
  }

  Future<void> _exportAsImage() async {
    try {
      // Create a simple export using annotations
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final painter = AnnotationPainter();
      painter.paint(canvas, _canvasSize);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        _canvasSize.width.toInt(),
        _canvasSize.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to get image bytes');
      }

      final imageBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: await _createPdfWithImage(imageBytes),
          filename: 'exported_page.pdf',
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/exported_page.png';
        await File(imagePath).writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(imagePath),
        ], text: 'Check out my annotated page!');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _createPdfWithImage(Uint8List imageBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image));
        },
      ),
    );

    return pdf.save();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  String _getPageInfo() {
    return 'Page $_currentPage of $_totalPages';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfPath?.split('/').last ?? 'PDF Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnnotations,
            tooltip: 'Save Annotations',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportAsImage,
            tooltip: 'Export as Image',
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                _isToolbarVisible = !_isToolbarVisible;
              });
            },
            tooltip: _isToolbarVisible ? 'Hide Toolbar' : 'Show Toolbar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                if (widget.pdfBytes != null)
                  SfPdfViewer.memory(
                    widget.pdfBytes!,
                    controller: _pdfController,
                    onDocumentLoaded: _onDocumentLoaded,
                    onDocumentLoadFailed: _onDocumentLoadFailed,
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                  )
                else if (widget.pdfPath != null)
                  SfPdfViewer.file(
                    File(widget.pdfPath!),
                    controller: _pdfController,
                    onDocumentLoaded: _onDocumentLoaded,
                    onDocumentLoadFailed: _onDocumentLoadFailed,
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                  ),
                Positioned.fill(
                  child: Center(
                    child: AnnotationCanvas(
                      annotationLayer: _annotationLayer,
                      currentPage: _currentPage,
                      currentTool: _currentTool,
                      currentColor: _currentColor,
                      canvasSize: _canvasSize,
                      onAnnotationsChanged: () {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                if (_isToolbarVisible)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ToolbarWidget(
                      currentTool: _currentTool,
                      currentColor: _currentColor,
                      onToolChanged: (tool) {
                        setState(() {
                          _currentTool = tool;
                        });
                      },
                      onColorChanged: (color) {
                        setState(() {
                          _currentColor = color;
                        });
                      },
                      onClear: _clearAnnotations,
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: Colors.black.withAlpha(120),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _pdfController.previousPage();
                          },
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _getPageInfo(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _pdfController.nextPage();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
