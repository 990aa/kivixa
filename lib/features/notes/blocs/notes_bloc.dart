import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/services/notes_database_service.dart';
import 'package:meta/meta.dart';

import '../models/note_document.dart';

part 'notes_event.dart';
part 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesDatabaseService _notesDatabaseService;

  NotesBloc(this._notesDatabaseService) : super(NotesInitial()) {
    on<NotesLoaded>((event, emit) async {
      emit(NotesLoadInProgress());
      try {
        final notes = await _notesDatabaseService.getAllNotes();
        emit(NotesLoadSuccess(notes));
      } catch (e) {
        emit(NotesLoadFailure(e.toString()));
      }
    });

    on<NoteAdded>((event, emit) async {
      try {
        // Use create or updateNote depending on whether the note exists
        if (event.note.id.isEmpty) {
          await _notesDatabaseService.create(event.note);
        } else {
          await _notesDatabaseService.updateNote(event.note);
        }
        final notes = await _notesDatabaseService.getAllNotes();
        emit(NotesLoadSuccess(notes));
      } catch (e) {
        emit(NotesLoadFailure(e.toString()));
      }
    });
  }
}
