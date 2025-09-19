import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/services/notes_database_service.dart';
import 'package:meta/meta.dart';

import '../models/note_document.dart';

part 'document_event.dart';
part 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final NotesDatabaseService _notesDatabaseService;
  Timer? _saveTimer;

  DocumentBloc(this._notesDatabaseService) : super(DocumentInitial()) {
    on<DocumentLoaded>((event, emit) async {
      emit(DocumentLoadInProgress());
      try {
        final document = await _notesDatabaseService.getNoteById(event.id);
        emit(DocumentLoadSuccess(document));
      } catch (e) {
        emit(DocumentLoadFailure(e.toString()));
      }
    });

    on<DocumentSaved>((event, emit) async {
      emit(DocumentSaveInProgress());
      try {
        await _notesDatabaseService.updateNote(event.document);
        emit(DocumentSaveSuccess());
      } catch (e) {
        emit(DocumentSaveFailure(e.toString()));
      }
    });

    on<DocumentContentChanged>((event, emit) {
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 30), () {
        add(DocumentSaved(event.document));
      });
    });
  }

  @override
  Future<void> close() {
    _saveTimer?.cancel();
    return super.close();
  }
}
