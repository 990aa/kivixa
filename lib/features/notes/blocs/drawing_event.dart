part of 'drawing_bloc.dart';

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
