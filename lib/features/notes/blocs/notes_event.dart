part of 'notes_bloc.dart';

@immutable
abstract class NotesEvent {}

class NotesLoaded extends NotesEvent {}

class NoteAdded extends NotesEvent {
  final NoteDocument note;

  NoteAdded(this.note);
}
