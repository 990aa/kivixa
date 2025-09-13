import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/data/database.dart';
import 'package:kivixa/data/repository.dart';

class DocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentData>>> {
  DocumentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _repository.watchDocuments().listen((documents) {
      state = AsyncValue.data(documents);
    }).onError((error) {
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  final DocumentRepository _repository;

  Future<void> createDocument(String title) async {
    // Optimistic update
    final previousState = state;
    final optimisticDocument = DocumentData(
      id: -1, // Placeholder ID
      title: title,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    state = AsyncValue.data([optimisticDocument, ...state.value!]);

    try {
      await _repository.createDocument(title);
    } catch (e) {
      // Revert on error
      state = previousState;
      // Optionally, expose the error to the UI
    }
  }
}

final documentsNotifierProvider = StateNotifierProvider<DocumentsNotifier, AsyncValue<List<DocumentData>>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentsNotifier(repository);
});
