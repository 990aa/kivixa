import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../models/canvas_settings.dart';
import '../models/drawing_layer.dart';
import '../painters/grid_overlay_painter.dart';
import 'dart:math' as math;

/// Interactive canvas view with zoom, pan, and rotation
class CanvasView extends StatefulWidget {
  final CanvasSettings settings;
  final List<DrawingLayer> layers;
  final Widget? child;
  final Function(Offset)? onCanvasPointTap;
  final Function(Offset, Offset)? onCanvasDrag;

  const CanvasView({
    super.key,
    required this.settings,
    this.layers = const [],
    this.child,
    this.onCanvasPointTap,
    this.onCanvasDrag,
  });

  @override
  State<CanvasView> createState() => CanvasViewState();
}

class CanvasViewState extends State<CanvasView> {
  final TransformationController _transformController =
      TransformationController();
  double _rotation = 0.0;
  double _currentScale = 1.0;
  Offset _currentTranslation = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final matrix = _transformController.value;
    setState(() {
      _currentScale = matrix.getMaxScaleOnAxis();
      _currentTranslation = Offset(
        matrix.getTranslation().x,
        matrix.getTranslation().y,
      );
    });
  }

  /// Zoom in programmatically
  void zoomIn() {
    final matrix = _transformController.value.clone();
    final scale = 1.2;

    // Get viewport center
    final Size viewportSize = context.size ?? Size.zero;
    final Offset viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    // Get translation component
    final trans = matrix.getTranslation();
    final translation = Offset(trans.x, trans.y);

    // Calculate focal point in canvas space
    final focalPoint = (viewportCenter - translation) / _currentScale;

    // Apply zoom
    final newScale = _currentScale * scale;
    final newTranslation = viewportCenter - (focalPoint * newScale);

    final newMatrix = Matrix4.identity()
      ..translateByVector3(
        vector.Vector3(newTranslation.dx, newTranslation.dy, 0),
      )
      ..scaleByVector3(vector.Vector3(newScale, newScale, 1.0));

    _transformController.value = newMatrix;
  }

  /// Zoom out programmatically
  void zoomOut() {
    final matrix = _transformController.value.clone();
    final scale = 0.8;

    // Get viewport center
    final Size viewportSize = context.size ?? Size.zero;
    final Offset viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    // Get translation component
    final trans = matrix.getTranslation();
    final translation = Offset(trans.x, trans.y);

    // Calculate focal point in canvas space
    final focalPoint = (viewportCenter - translation) / _currentScale;

    // Apply zoom
    final newScale = _currentScale * scale;
    final newTranslation = viewportCenter - (focalPoint * newScale);

    final newMatrix = Matrix4.identity()
      ..translateByVector3(
        vector.Vector3(newTranslation.dx, newTranslation.dy, 0),
      )
      ..scaleByVector3(vector.Vector3(newScale, newScale, 1.0));

    _transformController.value = newMatrix;
  }

  /// Zoom to specific level
  void zoomToLevel(double level) {
    final matrix = _transformController.value.clone();

    // Get viewport center
    final Size viewportSize = context.size ?? Size.zero;
    final Offset viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    // Get translation component
    final trans = matrix.getTranslation();
    final translation = Offset(trans.x, trans.y);

    // Calculate focal point in canvas space
    final focalPoint = (viewportCenter - translation) / _currentScale;

    // Apply zoom to level
    final newTranslation = viewportCenter - (focalPoint * level);

    final newMatrix = Matrix4.identity()
      ..translateByVector3(
        vector.Vector3(newTranslation.dx, newTranslation.dy, 0),
      )
      ..scaleByVector3(vector.Vector3(level, level, 1.0));

    _transformController.value = newMatrix;
  }

  /// Fit canvas to view
  void fitToView() {
    if (widget.settings.isInfinite) {
      resetView();
      return;
    }

    final Size viewportSize = context.size ?? Size.zero;
    final canvasWidth = widget.settings.canvasWidth ?? 800;
    final canvasHeight = widget.settings.canvasHeight ?? 600;

    // Calculate scale to fit
    final scaleX = (viewportSize.width - 100) / canvasWidth;
    final scaleY = (viewportSize.height - 100) / canvasHeight;
    final scale = math.min(scaleX, scaleY);

    // Center the canvas
    final offsetX = (viewportSize.width - canvasWidth * scale) / 2;
    final offsetY = (viewportSize.height - canvasHeight * scale) / 2;

    final matrix = Matrix4.identity()
      ..translateByVector3(vector.Vector3(offsetX, offsetY, 0))
      ..scaleByVector3(vector.Vector3(scale, scale, 1.0));

    _transformController.value = matrix;
  }

  /// Rotate canvas
  void rotateCanvas(double angle) {
    setState(() {
      _rotation += angle;
      // Normalize to 0-2π
      _rotation = _rotation % (2 * math.pi);
    });
  }

  /// Reset view to identity
  void resetView() {
    _transformController.value = Matrix4.identity();
    setState(() {
      _rotation = 0.0;
    });
  }

  /// Get current zoom level
  double get zoomLevel => _currentScale;

  /// Get current rotation in radians
  double get rotation => _rotation;

  /// Get current translation
  Offset get translation => _currentTranslation;

  /// Convert screen point to canvas point
  Offset screenToCanvas(Offset screenPoint) {
    final trans = _transformController.value.getTranslation();
    final translation = Offset(trans.x, trans.y);

    // Remove translation and scale
    final canvasPoint = (screenPoint - translation) / _currentScale;

    // Apply rotation
    if (_rotation != 0.0) {
      final cos = math.cos(-_rotation);
      final sin = math.sin(-_rotation);
      final x = canvasPoint.dx * cos - canvasPoint.dy * sin;
      final y = canvasPoint.dx * sin + canvasPoint.dy * cos;
      return Offset(x, y);
    }

    return canvasPoint;
  }

  /// Convert canvas point to screen point
  Offset canvasToScreen(Offset canvasPoint) {
    // Apply rotation
    var point = canvasPoint;
    if (_rotation != 0.0) {
      final cos = math.cos(_rotation);
      final sin = math.sin(_rotation);
      final x = point.dx * cos - point.dy * sin;
      final y = point.dx * sin + point.dy * cos;
      point = Offset(x, y);
    }

    // Apply scale and translation
    final trans = _transformController.value.getTranslation();
    final translation = Offset(trans.x, trans.y);
    return (point * _currentScale) + translation;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate canvas size
        final canvasWidth =
            widget.settings.canvasWidth ?? constraints.maxWidth * 3;
        final canvasHeight =
            widget.settings.canvasHeight ?? constraints.maxHeight * 3;

        return Stack(
          children: [
            // Main interactive viewer
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.1,
              maxScale: 50.0,
              boundaryMargin: widget.settings.isInfinite
                  ? const EdgeInsets.all(double.infinity)
                  : EdgeInsets.all(
                      math.max(constraints.maxWidth, constraints.maxHeight),
                    ),
              constrained: false,
              panEnabled: true,
              scaleEnabled: true,
              onInteractionStart: (details) {
                // Could add gesture handling here
              },
              child: Transform.rotate(
                angle: _rotation,
                child: Stack(
                  children: [
                    // Canvas boundary (for finite canvas)
                    if (!widget.settings.isInfinite)
                      CustomPaint(
                        painter: CanvasBoundaryPainter(
                          canvasWidth: canvasWidth,
                          canvasHeight: canvasHeight,
                        ),
                        size: Size(canvasWidth, canvasHeight),
                      ),

                    // Grid overlay
                    if (widget.settings.showGrid)
                      CustomPaint(
                        painter: GridOverlayPainter(
                          gridSize: widget.settings.gridSize,
                          gridColor: widget.settings.gridColor,
                          scale: _currentScale,
                        ),
                        size: Size(canvasWidth, canvasHeight),
                      ),

                    // Main canvas content
                    if (widget.child != null)
                      SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: widget.child,
                      ),
                  ],
                ),
              ),
            ),

            // Rulers overlay (fixed position, not transformed)
            if (widget.settings.showRulers)
              IgnorePointer(
                child: CustomPaint(
                  painter: RulerOverlayPainter(
                    scale: _currentScale,
                    offset: _currentTranslation,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),

            // Zoom level indicator
            Positioned(bottom: 16, right: 16, child: _buildZoomIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildZoomIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: zoomOut,
          ),
          const SizedBox(width: 8),
          Text(
            '${(_currentScale * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: zoomIn,
          ),
        ],
      ),
    );
  }
}

/// Canvas boundary painter (defined here to keep it with CanvasView)
class CanvasBoundaryPainter extends CustomPainter {
  final double canvasWidth;
  final double canvasHeight;
  final Color boundaryColor;
  final Color shadowColor;

  CanvasBoundaryPainter({
    required this.canvasWidth,
    required this.canvasHeight,
    this.boundaryColor = Colors.black,
    this.shadowColor = Colors.black54,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw shadow
    final shadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(
      Rect.fromLTWH(5, 5, canvasWidth, canvasHeight),
      shadowPaint,
    );

    // Draw canvas background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), bgPaint);

    // Draw boundary
    final borderPaint = Paint()
      ..color = boundaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CanvasBoundaryPainter oldDelegate) {
    return oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        oldDelegate.boundaryColor != boundaryColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
