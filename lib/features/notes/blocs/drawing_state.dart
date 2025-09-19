part of 'drawing_bloc.dart';

@immutable
abstract class DrawingState {}

class DrawingInitial extends DrawingState {}

class DrawingLoadSuccess extends DrawingState {
  final ScribbleNotifier notifier;

  DrawingLoadSuccess(this.notifier);
}
