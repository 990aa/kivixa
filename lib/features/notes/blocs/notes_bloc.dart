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
  }
}
