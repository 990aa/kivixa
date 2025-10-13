import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/annotation_data.dart';

/// Utility class for performance optimization of annotation rendering
///
/// Features:
/// - Douglas-Peucker stroke simplification
/// - Lazy loading for multi-page documents
/// - Stroke caching with Picture objects
/// - Memory management
class PerformanceOptimizer {
  /// Simplify stroke using Douglas-Peucker algorithm
  ///
  /// Reduces point count by 30-50% while maintaining visual quality
  /// Target epsilon: 2.0 pixels
  ///
  /// Parameters:
  /// - [points]: Original stroke points
  /// - [epsilon]: Maximum distance threshold (default: 2.0)
  ///
  /// Returns: Simplified list of points
  static List<Offset> simplifyStroke(
    List<Offset> points, {
    double epsilon = 2.0,
  }) {
    if (points.length <= 2) return points;

    final startTime = DateTime.now();

    final simplified = _douglasPeucker(points, epsilon);

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMicroseconds;

    debugPrint('Stroke simplification:');
    debugPrint('  Original points: ${points.length}');
    debugPrint('  Simplified points: ${simplified.length}');
    debugPrint(
      '  Reduction: ${((1 - simplified.length / points.length) * 100).toStringAsFixed(1)}%',
    );
    debugPrint('  Time: ${duration}µs');

    return simplified;
  }

  /// Douglas-Peucker algorithm implementation
  static List<Offset> _douglasPeucker(List<Offset> points, double epsilon) {
    if (points.length <= 2) return points;

    // Find point with maximum distance from line segment
    double maxDistance = 0;
    int maxIndex = 0;
    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (maxDistance > epsilon) {
      // Recursive call
      final leftSegment = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      final rightSegment = _douglasPeucker(
        points.sublist(maxIndex),
        epsilon,
      );

      // Combine results (remove duplicate middle point)
      return [
        ...leftSegment.sublist(0, leftSegment.length - 1),
        ...rightSegment,
      ];
    } else {
      // Base case: just return endpoints
      return [start, end];
    }
  }

  /// Calculate perpendicular distance from point to line segment
  static double _perpendicularDistance(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    // Handle degenerate case (line is a point)
    if (dx == 0 && dy == 0) {
      return _distance(point, lineStart);
    }

    // Calculate perpendicular distance
    final numerator = ((point.dx - lineStart.dx) * dy -
            (point.dy - lineStart.dy) * dx)
        .abs();
    final denominator = _distance(lineStart, lineEnd);

    return numerator / denominator;
  }

  /// Calculate Euclidean distance between two points
  static double _distance(Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Create a cached Picture object from annotation strokes
  ///
  /// Improves performance by pre-rendering completed strokes
  static Future<ui.Picture> createCachedStrokePicture(
    List<AnnotationData> annotations,
    Size canvasSize,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Render all annotations to canvas
    for (var annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = annotation.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final points = annotation.strokePath;

      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
      }

      canvas.drawPath(path, paint);
    }

    return recorder.endRecording();
  }

  /// Memory-efficient page loader for large documents
  ///
  /// Only keeps current page + adjacent pages in memory
  static Set<int> getPagesToLoad(int currentPage, int totalPages) {
    final pages = <int>{};

    // Always load current page
    pages.add(currentPage);

    // Load previous page
    if (currentPage > 0) {
      pages.add(currentPage - 1);
    }

    // Load next page
    if (currentPage < totalPages - 1) {
      pages.add(currentPage + 1);
    }

    return pages;
  }

  /// Throttle function calls to maintain 60 FPS
  ///
  /// Returns true if enough time has elapsed since last call
  static bool shouldUpdate(DateTime? lastUpdate, {int targetFPS = 60}) {
    if (lastUpdate == null) return true;

    final elapsed = DateTime.now().difference(lastUpdate).inMilliseconds;
    final frameTime = 1000 ~/ targetFPS; // ~16ms for 60 FPS

    return elapsed >= frameTime;
  }

  /// Calculate optimal undo history size based on available memory
  ///
  /// Returns recommended max undo steps
  static int getOptimalUndoHistorySize({
    int defaultSize = 20,
    int minSize = 10,
    int maxSize = 50,
  }) {
    // In production, could check available memory
    // For now, use default
    return defaultSize;
  }

  /// Estimate memory usage of annotations
  ///
  /// Returns approximate memory in bytes
  static int estimateMemoryUsage(List<AnnotationData> annotations) {
    int totalBytes = 0;

    for (var annotation in annotations) {
      // Each Offset is 2 doubles (16 bytes)
      final pointsBytes = annotation.strokePath.length * 16;

      // Metadata overhead (color, width, type, etc.)
      const metadataBytes = 64;

      totalBytes += pointsBytes + metadataBytes;
    }

    return totalBytes;
  }

  /// Get memory usage as human-readable string
  static String formatMemoryUsage(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if stroke should be simplified based on point count
  static bool shouldSimplifyStroke(int pointCount, {int threshold = 50}) {
    return pointCount > threshold;
  }

  /// Batch process multiple strokes for simplification
  static List<AnnotationData> simplifyMultipleStrokes(
    List<AnnotationData> annotations, {
    double epsilon = 2.0,
  }) {
    final startTime = DateTime.now();
    final simplified = <AnnotationData>[];
    int totalOriginalPoints = 0;
    int totalSimplifiedPoints = 0;

    for (var annotation in annotations) {
      totalOriginalPoints += annotation.strokePath.length;

      if (shouldSimplifyStroke(annotation.strokePath.length)) {
        final simplifiedPoints = simplifyStroke(
          annotation.strokePath,
          epsilon: epsilon,
        );

        totalSimplifiedPoints += simplifiedPoints.length;

        simplified.add(
          annotation.copyWith(strokePath: simplifiedPoints),
        );
      } else {
        totalSimplifiedPoints += annotation.strokePath.length;
        simplified.add(annotation);
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;

    debugPrint('Batch simplification results:');
    debugPrint('  Annotations processed: ${annotations.length}');
    debugPrint('  Original points: $totalOriginalPoints');
    debugPrint('  Simplified points: $totalSimplifiedPoints');
    debugPrint(
      '  Reduction: ${((1 - totalSimplifiedPoints / totalOriginalPoints) * 100).toStringAsFixed(1)}%',
    );
    debugPrint('  Time: ${duration}ms');

    return simplified;
  }

  /// Create repaint boundary key for efficient repainting
  static GlobalKey createRepaintBoundaryKey() {
    return GlobalKey(debugLabel: 'annotation_layer_repaint_boundary');
  }

  /// Calculate optimal canvas update region
  ///
  /// Returns bounding box that needs repainting
  static Rect calculateDirtyRegion(
    List<Offset> newPoints, {
    double strokeWidth = 3.0,
  }) {
    if (newPoints.isEmpty) return Rect.zero;

    double minX = newPoints.first.dx;
    double minY = newPoints.first.dy;
    double maxX = newPoints.first.dx;
    double maxY = newPoints.first.dy;

    for (var point in newPoints) {
      minX = minX < point.dx ? minX : point.dx;
      minY = minY < point.dy ? minY : point.dy;
      maxX = maxX > point.dx ? maxX : point.dx;
      maxY = maxY > point.dy ? maxY : point.dy;
    }

    // Add padding for stroke width
    final padding = strokeWidth * 2;

    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// Performance monitoring helper
  static void logPerformanceMetrics({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? additionalMetrics,
  }) {
    final milliseconds = duration.inMilliseconds;
    final fps = milliseconds > 0 ? (1000 / milliseconds).toStringAsFixed(1) : '∞';

    debugPrint('Performance: $operation');
    debugPrint('  Duration: ${milliseconds}ms');
    debugPrint('  Equivalent FPS: $fps');

    if (additionalMetrics != null) {
      for (var entry in additionalMetrics.entries) {
        debugPrint('  ${entry.key}: ${entry.value}');
      }
    }
  }
}

/// Debouncer utility for auto-save and other delayed operations
class Debouncer {
  final Duration delay;
  VoidCallback? _action;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Call the action after delay, cancelling any previous pending calls
  void call(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, _execute);
  }

  void _execute() {
    _action?.call();
    _action = null;
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _action = null;
  }

  /// Dispose resources
  void dispose() {
    cancel();
  }
}

/// Throttler utility for limiting update frequency
class Throttler {
  final Duration interval;
  DateTime? _lastCall;

  Throttler({required this.interval});

  /// Execute action only if enough time has elapsed since last call
  bool call(VoidCallback action) {
    final now = DateTime.now();

    if (_lastCall == null ||
        now.difference(_lastCall!) >= interval) {
      _lastCall = now;
      action();
      return true;
    }

    return false;
  }

  /// Reset throttler
  void reset() {
    _lastCall = null;
  }
}
