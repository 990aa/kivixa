import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/models/drawing_stroke.dart';
import 'package:scribble/scribble.dart';

@immutable
abstract class DrawingEvent {}

class DrawingStarted extends DrawingEvent {}

class ToolChanged extends DrawingEvent {
  final ScribbleTool tool;

  ToolChanged(this.tool);
}

class ColorChanged extends DrawingEvent {
  final Color color;

  ColorChanged(this.color);
}

class StrokeWidthChanged extends DrawingEvent {
  final double width;

  StrokeWidthChanged(this.width);
}

@immutable
abstract class DrawingState {}

class DrawingInitial extends DrawingState {}

class DrawingLoadSuccess extends DrawingState {
  final ScribbleNotifier notifier;

  DrawingLoadSuccess(this.notifier);
}

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  DrawingBloc() : super(DrawingInitial()) {
    on<DrawingStarted>((event, emit) {
      final notifier = ScribbleNotifier();
      emit(DrawingLoadSuccess(notifier));
    });

    on<ToolChanged>((event, emit) {
      if (state is DrawingLoadSuccess) {
        final notifier = (state as DrawingLoadSuccess).notifier;
        notifier.setTool(event.tool);
        emit(DrawingLoadSuccess(notifier));
      }
    });

    on<ColorChanged>((event, emit) {
      if (state is DrawingLoadSuccess) {
        final notifier = (state as DrawingLoadSuccess).notifier;
        notifier.setColor(event.color);
        emit(DrawingLoadSuccess(notifier));
      }
    });

    on<StrokeWidthChanged>((event, emit) {
      if (state is DrawingLoadSuccess) {
        final notifier = (state as DrawingLoadSuccess).notifier;
        notifier.setStrokeWidth(event.width);
        emit(DrawingLoadSuccess(notifier));
      }
    });
  }
}