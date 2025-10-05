import 'package:riverpod/riverpod.dart';
import '../domain/models/note.dart';

class NoteState {
  final List<Note> notes;
  final Note? currentNote;
  final bool isLoading;
  final String? error;

  const NoteState({
    required this.notes,
    this.currentNote,
    this.isLoading = false,
    this.error,
  });

  NoteState copyWith({
    List<Note>? notes,
    Note? currentNote,
    bool? isLoading,
    String? error,
  }) {
    return NoteState(
      notes: notes ?? this.notes,
      currentNote: currentNote ?? this.currentNote,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
