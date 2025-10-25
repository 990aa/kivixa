import 'package:flutter/material.dart';
import 'package:kivixa/models/annotation_data.dart';
import 'package:kivixa/models/drawing_tool.dart';

class AnnotationController extends ChangeNotifier {
  final List<AnnotationData> _annotations = [];
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;

  List<AnnotationData> get annotations => _annotations;
  DrawingTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;

  void setCurrentTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setCurrentColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void addAnnotation(AnnotationData annotation) {
    _annotations.add(annotation);
    notifyListeners();
  }

  void addPointsToCurrentAnnotation(List<Offset> points, int pageNumber) {
    if (_annotations.isEmpty || _annotations.last.pageNumber != pageNumber) {
      final newAnnotation = AnnotationData(
        points: points,
        color: _currentColor,
        strokeWidth: _currentTool == DrawingTool.highlighter ? 12.0 : 4.0,
        tool: _currentTool,
        pageNumber: pageNumber,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      addAnnotation(newAnnotation);
    } else {
      _annotations.last.points.addAll(points);
    }
    notifyListeners();
  }

  void clearAnnotationsForPage(int pageNumber) {
    _annotations.removeWhere((a) => a.pageNumber == pageNumber);
    notifyListeners();
  }

  void clearAllAnnotations() {
    _annotations.clear();
    notifyListeners();
  }
}
