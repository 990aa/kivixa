import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/document_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/models/drawing_stroke.dart';
import 'package:kivixa/features/notes/services/export_service.dart';
import 'package:kivixa/features/notes/widgets/notes_drawing_canvas.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? documentId;

  const NoteEditorScreen({super.key, this.documentId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> with WidgetsBindingObserver {
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.documentId != null) {
      context.read<DocumentBloc>().add(DocumentLoaded(widget.documentId!));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
        actions: [
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state is DocumentLoadSuccess) {
                return IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
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
                  },
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
            return BlocBuilder<DrawingBloc, DrawingState>(
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
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
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
