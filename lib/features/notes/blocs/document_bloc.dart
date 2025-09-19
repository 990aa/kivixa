import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DocumentEvent {}

abstract class DocumentState {}

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  DocumentBloc() : super(DocumentInitial()) {
    // TODO: implement event handlers
  }
}

class DocumentInitial extends DocumentState {}
