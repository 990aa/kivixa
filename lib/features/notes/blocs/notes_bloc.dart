import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NotesEvent {}

abstract class NotesState {}

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc() : super(NotesInitial()) {
    // TODO: implement event handlers
  }
}

class NotesInitial extends NotesState {}
