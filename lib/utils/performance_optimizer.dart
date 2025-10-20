import '../models/annotation_data.dart';

class PerformanceOptimizer {
  List<AnnotationData> simplifyAnnotations(List<AnnotationData> annotations, double tolerance) {
    return annotations.map((annotation) {
      if (annotation.points.length < 2) {
        return annotation;
      }
      final simplifiedPoints = _simplify(annotation.points, tolerance);
      return AnnotationData(
        points: simplifiedPoints,
        color: annotation.color,
        strokeWidth: annotation.strokeWidth,
        tool: annotation.tool,
        pageNumber: annotation.pageNumber,
        timestamp: annotation.timestamp,
      );
    }).toList();
  }

  List<T> _simplify<T>(List<T> points, double tolerance) {
    if (points.length < 3) {
      return points;
    }

    final double sqTolerance = tolerance * tolerance;
    List<T> simplified = [];

    // Add the first point
    simplified.add(points.first);

    // Ramer-Douglas-Peucker algorithm
    _rdp(points, 0, points.length - 1, sqTolerance, simplified);

    // Add the last point
    simplified.add(points.last);

    return simplified;
  }

  void _rdp<T>(List<T> points, int startIndex, int endIndex, double sqTolerance, List<T> out) {
    // Find the point with the maximum distance
    double dmax = 0;
    int index = 0;

    for (int i = startIndex + 1; i < endIndex; i++) {
      double d = 0.0; // Placeholder for distance calculation logic
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (dmax > sqTolerance) {
      // Recursive call for the first part
      if (index - 1 > startIndex) {
        _rdp(points, startIndex, index - 1, sqTolerance, out);
      }

      // Add the point with the max distance
      out.add(points[index]);

      // Recursive call for the second part
      if (endIndex - 1 > index) {
        _rdp(points, index + 1, endIndex - 1, sqTolerance, out);
      }
    }
  }
}
