import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/models/drawing_stroke.dart';
import 'package:scribble/scribble.dart';

part 'drawing_event.dart';
part 'drawing_state.dart';

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  DrawingBloc() : super(DrawingInitial()) {
    on<DrawingStarted>((event, emit) {
      final notifier = ScribbleNotifier();
      emit(DrawingState(notifier));
    });

    on<ToolChanged>((event, emit) {
      if (state is DrawingState) {
        final notifier = (state as DrawingState).notifier;
        notifier.setTool(event.tool);
        emit(DrawingState(notifier));
      }
    });

    on<ColorChanged>((event, emit) {
      if (state is DrawingState) {
        final notifier = (state as DrawingState).notifier;
        notifier.setColor(event.color);
        emit(DrawingState(notifier));
      }
    });

    on<StrokeWidthChanged>((event, emit) {
      if (state is DrawingState) {
        final notifier = (state as DrawingState).notifier;
        notifier.setStrokeWidth(event.width);
        emit(DrawingState(notifier));
      }
    });
  }
}
