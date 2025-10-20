import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
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

  const PDFViewerScreen.file({
    super.key,
    required this.pdfPath,
  }) : pdfBytes = null;

  const PDFViewerScreen.memory({
    super.key,
    required this.pdfBytes,
  }) : pdfPath = null;

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late final PdfController _pdfController;

  final AnnotationLayer _annotationLayer = AnnotationLayer();
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;

  bool _isToolbarVisible = true;
  bool _isLoading = true;
  String? _error;

  Size _canvasSize = const Size(595, 842);

  @override
  void initState() {
    super.initState();
    _initializePDF();
  }

  Future<void> _initializePDF() async {
    try {
      PdfDocument document;

      if (widget.pdfBytes != null) {
        document = await PdfDocument.openData(widget.pdfBytes!);
      } else if (widget.pdfPath != null) {
        document = await PdfDocument.openFile(widget.pdfPath!);
      } else {
        throw Exception('No PDF source provided');
      }

      _pdfController = PdfController(
        document: Future.value(document),
      );

      setState(() {
        _isLoading = false;
      });

      await _updateCanvasSize();
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCanvasSize() async {
    final page = await (await _pdfController.document).getPage(1);
    setState(() {
      _canvasSize = Size(page.width, page.height);
    });
  }

  void _clearAnnotations() {
    setState(() {
      _annotationLayer.clearAnnotationsForPage(_pdfController.page);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving annotations: $e')),
        );
      }
    }
  }

  Future<void> _exportAsImage() async {
    try {
      final page = await (await _pdfController.document).getPage(_pdfController.page);
      final pageImage = await page.render(
        width: _canvasSize.width,
        height: _canvasSize.height,
      );

      if (pageImage == null) {
        throw Exception('Failed to render page');
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final codec = await ui.instantiateImageCodec(pageImage.bytes);
      final frame = await codec.getNextFrame();
      canvas.drawImage(frame.image, Offset.zero, Paint());

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
            bytes: await _createPdfWithImage(imageBytes), filename: 'exported_page.pdf');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/exported_page.png';
        await File(imagePath).writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out my annotated page!',
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
          return pw.Center(
            child: pw.Image(image),
          );
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

  Future<String> _getPageInfo() async {
    final page = await (await _pdfController.document).getPage(_pdfController.page);
    final document = await _pdfController.document;
    return 'Page ${page.pageNumber} of ${document.pagesCount}';
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
                    Center(
                      child: PdfView(
                        controller: _pdfController,
                        onPageChanged: (page) {},
                        scrollDirection: Axis.vertical,
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: AnnotationCanvas(
                          annotationLayer: _annotationLayer,
                          currentPage: _pdfController.page,
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
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.black.withAlpha(120),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                _pdfController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.ease,
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            FutureBuilder<String>(
                              future: _getPageInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data!,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              onPressed: () {
                                _pdfController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.ease,
                                );
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
