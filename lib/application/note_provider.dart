import 'package:riverpod/riverpod.dart';
import 'note_state.dart';
import '../infrastructure/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final noteStateProvider = StateNotifierProvider<NoteNotifier, NoteState>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteNotifier(repository);
});

class NoteNotifier extends StateNotifier<NoteState> {
  final NoteRepository _repository;

  NoteNotifier(this._repository) : super(const NoteState(notes: [])) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true);
    try {
      final notes = await _repository.getAllNotes();
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createNote({required String title, required PageTemplate template}) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      pages: [
        NotePage(
          id: '1',
          template: template,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      defaultTemplate: template,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String noteId) async {
    await _repository.deleteNote(noteId);
    await loadNotes();
  }

  void setCurrentNote(Note note) {
    state = state.copyWith(currentNote: note);
  }
}