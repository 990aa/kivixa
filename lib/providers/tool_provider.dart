import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing_tool.dart';

final currentToolProvider = StateNotifierProvider<ToolNotifier, DrawingTool>((ref) {
  return ToolNotifier();
});

class ToolNotifier extends StateNotifier<DrawingTool> {
  ToolNotifier() : super(DrawingTool(type: ToolType.pen));

  void setTool(ToolType type) {
    state = state.copyWith(type: type);
  }

  void setColor(Color color) {
    state = state.copyWith(color: color);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }
}
