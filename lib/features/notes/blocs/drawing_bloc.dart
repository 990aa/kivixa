import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DrawingEvent {}

abstract class DrawingState {}

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  DrawingBloc() : super(DrawingInitial()) {
    // TODO: implement event handlers
  }
}

class DrawingInitial extends DrawingState {}
