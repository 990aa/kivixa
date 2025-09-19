import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/document_bloc.dart';
import 'package:kivixa/features/notes/blocs/document_event.dart';
import 'package:kivixa/features/notes/blocs/document_state.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_event.dart';
import 'package:kivixa/features/notes/blocs/drawing_state.dart';
import 'package:kivixa/features/notes/widgets/notes_drawing_canvas.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? documentId;

  const NoteEditorScreen({super.key, this.documentId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.documentId != null) {
      context.read<DocumentBloc>().add(DocumentLoaded(widget.documentId!));
    }
    context.read<DrawingBloc>().add(DrawingStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
      ),
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, documentState) {
          if (documentState is DocumentLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (documentState is DocumentLoadSuccess) {
            return BlocBuilder<DrawingBloc, DrawingState>(
              builder: (context, drawingState) {
                if (drawingState is DrawingState) {
                  drawingState.notifier.addListener(() {
                    final updatedDocument = documentState.document.copyWith(
                      strokes: drawingState.notifier.currentSketch.strokes,
                    );
                    context.read<DocumentBloc>().add(DocumentContentChanged(updatedDocument));
                  });
                  return NotesDrawingCanvas(
                    notifier: drawingState.notifier,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
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
