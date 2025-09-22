part of 'folders_bloc.dart';

@immutable
abstract class FoldersState {}

class FoldersInitial extends FoldersState {}

class FoldersLoadInProgress extends FoldersState {}

class FoldersLoadSuccess extends FoldersState {
  final List<Folder> folders;

  FoldersLoadSuccess(this.folders);
}

class FoldersLoadFailure extends FoldersState {
  final String error;

  FoldersLoadFailure(this.error);
}
