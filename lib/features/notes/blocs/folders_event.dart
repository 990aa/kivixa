part of 'folders_bloc.dart';

@immutable
abstract class FoldersEvent {}

class LoadFolders extends FoldersEvent {}

class AddFolder extends FoldersEvent {
  final Folder folder;

  AddFolder(this.folder);
}
