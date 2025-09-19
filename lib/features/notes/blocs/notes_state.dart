part of 'notes_bloc.dart';

@immutable
abstract class NotesState {}

class NotesInitial extends NotesState {}

class NotesLoadInProgress extends NotesState {}

class NotesLoadSuccess extends NotesState {
  final List<NoteDocument> notes;

  NotesLoadSuccess(this.notes);
}

class NotesLoadFailure extends NotesState {
  final String error;

  NotesLoadFailure(this.error);
}
