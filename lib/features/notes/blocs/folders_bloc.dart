import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/services/notes_database_service.dart';
import 'package:meta/meta.dart';

part 'folders_event.dart';
part 'folders_state.dart';

class FoldersBloc extends Bloc<FoldersEvent, FoldersState> {
  final NotesDatabaseService _notesDatabaseService;

  FoldersBloc(this._notesDatabaseService) : super(FoldersInitial()) {
    on<LoadFolders>((event, emit) async {
      emit(FoldersLoadInProgress());
      try {
        final folders = await _notesDatabaseService.getAllFolders();
        emit(FoldersLoadSuccess(folders));
      } catch (e) {
        emit(FoldersLoadFailure(e.toString()));
      }
    });

    on<AddFolder>((event, emit) async {
      try {
        await _notesDatabaseService.createFolder(event.folder);
        final folders = await _notesDatabaseService.getAllFolders();
        emit(FoldersLoadSuccess(folders));
      } catch (e) {
        emit(FoldersLoadFailure(e.toString()));
      }
    });
  }
}
