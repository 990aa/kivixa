import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/document_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/models/drawing_stroke.dart';
import 'package:kivixa/features/notes/services/export_service.dart';
import 'package:kivixa/features/notes/services/recent_documents_service.dart';
import 'package:kivixa/features/notes/widgets/notes_drawing_canvas.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? documentId;

  const NoteEditorScreen({super.key, this.documentId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> with WidgetsBindingObserver {
  final ExportService _exportService = ExportService();
  final RecentDocumentsService _recentDocumentsService = RecentDocumentsService();
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.documentId != null) {
      context.read<DocumentBloc>().add(DocumentLoaded(widget.documentId!));
      _recentDocumentsService.addRecentDocument(widget.documentId!);
    }
    context.read<DrawingBloc>().add(DrawingStarted());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final documentState = context.read<DocumentBloc>().state;
      if (documentState is DocumentLoadSuccess) {
        context.read<DocumentBloc>().add(DocumentSaved(documentState.document));
      }
    }
  }

  Future<void> _exportPageAsPng() async {
    try {
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final documentState = context.read<DocumentBloc>().state;
      if (documentState is DocumentLoadSuccess) {
        final path = await _exportService.exportToPng(
          documentState.document,
          pngBytes,
          0, // Assuming we're exporting the first page
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $path')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
        actions: [
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state is DocumentLoadSuccess) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'pdf':
                        try {
                          final path = await _exportService.exportToPdf(state.document);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exported to $path')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export failed: $e')),
                          );
                        }
                        break;
                      case 'png':
                        await _exportPageAsPng();
                        break;
                      case 'json':
                        try {
                          final path = await _exportService.exportToJson(state.document);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exported to $path')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export failed: $e')),
                          );
                        }
                        break;
                      case 'share':
                        try {
                          final path = await _exportService.exportToPdf(state.document);
                          await Share.shareXFiles([XFile(path)], text: 'Here is my note!');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sharing failed: $e')),
                          );
                        }
                        break;
                      case 'import_image':
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null) {
                          final imageBytes = await result.files.single.bytes;
                          final updatedDocument = state.document.copyWith(
                            pages: state.document.pages.map((page) {
                              if (page.pageNumber == 0) { // Assuming we're on the first page
                                return page.copyWith(backgroundImage: imageBytes);
                              }
                              return page;
                            }).toList(),
                          );
                          context.read<DocumentBloc>().add(DocumentContentChanged(updatedDocument));
                        }
                        break;
                      case 'print':
                        final pdfBytes = await _exportService.exportToPdf(state.document);
                        await Printing.layoutPdf(onLayout: (_) => File(pdfBytes).readAsBytes());
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'pdf',
                      child: Text('Export as PDF'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'png',
                      child: Text('Export as PNG'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'json',
                      child: Text('Export as JSON'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Share'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'import_image',
                      child: Text('Import Image'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'print',
                      child: Text('Print'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, documentState) {
          if (documentState is DocumentLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (documentState is DocumentLoadSuccess) {
            return RepaintBoundary(
              key: _canvasKey,
              child: BlocBuilder<DrawingBloc, DrawingState>(
                builder: (context, drawingState) {
                  if (drawingState is DrawingLoadSuccess) {
                    drawingState.notifier.addListener(() {
                      final updatedDocument = documentState.document;
                      final sketch = drawingState.notifier.toJson();
                      if (sketch['points'] != null) {
                        updatedDocument.pages.first.drawingData = (sketch['points'] as List)
                            .map((e) => DrawingStroke.fromScribble(e))
                            .toList();
                      }
                      context.read<DocumentBloc>().add(DocumentContentChanged(updatedDocument));
                    });
                    return NotesDrawingCanvas(
                      notifier: drawingState.notifier,
                      backgroundImage: documentState.document.pages.first.backgroundImage,
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            );
          } else if (documentState is DocumentLoadFailure) {
            return Center(child: Text(documentState.error));
          } else {
            return const Center(child: Text('No document loaded.'));
          }
        },
      ),
    );
  }
}
