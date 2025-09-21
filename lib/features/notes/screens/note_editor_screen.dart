import 'dart:ui' as ui;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/document_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/services/export_service.dart';
import 'package:kivixa/features/notes/services/favorite_documents_service.dart';
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

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  final ExportService _exportService = ExportService();
  final RecentDocumentsService _recentDocumentsService =
      RecentDocumentsService();
  final FavoriteDocumentsService _favoriteDocumentsService =
      FavoriteDocumentsService();
  final GlobalKey _canvasKey = GlobalKey();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.documentId != null) {
      context.read<DocumentBloc>().add(DocumentLoaded(widget.documentId!));
      _recentDocumentsService.addRecentDocument(widget.documentId!);
      _checkIfFavorite();
    }
    context.read<DrawingBloc>().add(DrawingStarted());
  }

  void _checkIfFavorite() async {
    _isFavorite = await _favoriteDocumentsService.isFavorite(
      widget.documentId!,
    );
    setState(() {});
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
      final boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final documentState = context.read<DocumentBloc>().state;
      if (documentState is DocumentLoadSuccess) {
        // Save PNG to file or handle as needed
        final directory = await FilePicker.platform.getDirectoryPath();
        if (directory != null) {
          final path = '$directory/${documentState.document.title}_page_0.png';
          final file = File(path);
          await file.writeAsBytes(pngBytes);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Exported to $path')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            onPressed: () {
              if (_isFavorite) {
                _favoriteDocumentsService.removeFavoriteDocument(
                  widget.documentId!,
                );
              } else {
                _favoriteDocumentsService.addFavoriteDocument(
                  widget.documentId!,
                );
              }
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state is DocumentLoadSuccess) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'pdf':
                        try {
                          final boundary =
                              _canvasKey.currentContext!.findRenderObject()
                                  as RenderRepaintBoundary;
                          final image = await boundary.toImage();
                          final byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png,
                          );
                          final pngBytes = byteData!.buffer.asUint8List();
                          final path = await _exportService.exportImagesToPdf(
                            state.document.title,
                            [pngBytes],
                          );
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
                          final path = await _exportService.exportToJson(
                            state.document,
                          );
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
                          final boundary =
                              _canvasKey.currentContext!.findRenderObject()
                                  as RenderRepaintBoundary;
                          final image = await boundary.toImage();
                          final byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png,
                          );
                          final pngBytes = byteData!.buffer.asUint8List();
                          final path = await _exportService.exportImagesToPdf(
                            state.document.title,
                            [pngBytes],
                          );
                          await Share.shareXFiles(
                            [XFile(path)],
                            text: 'Here is my note!',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sharing failed: $e')),
                          );
                        }
                        break;
                      case 'import_image':
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null) {
                          final imageBytes = result.files.single.bytes;
                          final updatedDocument = state.document.copyWith(
                            pages: state.document.pages.map((page) {
                              if (page.pageNumber == 0) {
                                // Assuming we're on the first page
                                return page.copyWith(
                                  backgroundImage: imageBytes,
                                );
                              }
                              return page;
                            }).toList(),
                          );
                          context.read<DocumentBloc>().add(
                            DocumentContentChanged(updatedDocument),
                          );
                        }
                        break;
                      case 'print':
                        try {
                          final boundary =
                              _canvasKey.currentContext!.findRenderObject()
                                  as RenderRepaintBoundary;
                          final image = await boundary.toImage();
                          final byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png,
                          );
                          final pngBytes = byteData!.buffer.asUint8List();
                          final path = await _exportService.exportImagesToPdf(
                            state.document.title,
                            [pngBytes],
                          );
                          await Printing.layoutPdf(
                            onLayout: (_) async =>
                                await XFile(path).readAsBytes(),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
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
                    // Drawing notifier toJson and drawingData logic removed for compatibility with scribble 0.10.0+1
                    return NotesDrawingCanvas(
                      notifier: drawingState.notifier,
                      backgroundImage:
                          documentState.document.pages.first.backgroundImage,
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
