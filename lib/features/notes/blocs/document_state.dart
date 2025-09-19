part of 'document_bloc.dart';

@immutable
abstract class DocumentState {}

class DocumentInitial extends DocumentState {}

class DocumentLoadInProgress extends DocumentState {}

class DocumentLoadSuccess extends DocumentState {
  final NoteDocument document;

  DocumentLoadSuccess(this.document);
}

class DocumentLoadFailure extends DocumentState {
  final String error;

  DocumentLoadFailure(this.error);
}

class DocumentSaveInProgress extends DocumentState {}

class DocumentSaveSuccess extends DocumentState {}

class DocumentSaveFailure extends DocumentState {
  final String error;

  DocumentSaveFailure(this.error);
}
