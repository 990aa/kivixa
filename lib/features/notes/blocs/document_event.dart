part of 'document_bloc.dart';

@immutable
abstract class DocumentEvent {}

class DocumentLoaded extends DocumentEvent {
  final String id;

  DocumentLoaded(this.id);
}

class DocumentSaved extends DocumentEvent {
  final NoteDocument document;

  DocumentSaved(this.document);
}

class DocumentContentChanged extends DocumentEvent {
  final NoteDocument document;

  DocumentContentChanged(this.document);
}
