part of 'drawing_bloc.dart';

@immutable
abstract class DrawingState {}

class DrawingInitial extends DrawingState {}

class DrawingState extends DrawingState {
  final ScribbleNotifier notifier;

  DrawingState(this.notifier);
}
