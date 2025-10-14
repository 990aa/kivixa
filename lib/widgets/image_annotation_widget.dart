import 'package:flutter/material.dart';
import '../models/image_annotation.dart';

/// Interactive widget for displaying and manipulating image annotations
/// Supports dragging and resizing with corner handles
/// Uses PDF coordinate system for proper zoom/scroll behavior
class ImageAnnotationWidget extends StatefulWidget {
  final ImageAnnotation imageAnnotation;
  final Function(ImageAnnotation) onUpdate;
  final Function(ImageAnnotation) onDelete;
  final Size pageSize;
  final Offset Function(Offset) pdfToScreenTransform;
  final Offset Function(Offset) screenToPdfTransform;
  final Function()? onDeselect;

  const ImageAnnotationWidget({
    super.key,
    required this.imageAnnotation,
    required this.onUpdate,
    required this.onDelete,
    required this.pageSize,
    required this.pdfToScreenTransform,
    required this.screenToPdfTransform,
    this.onDeselect,
  });

  @override
  State<ImageAnnotationWidget> createState() => _ImageAnnotationWidgetState();
}

class _ImageAnnotationWidgetState extends State<ImageAnnotationWidget> {
  bool _isSelected = false;
  Offset? _dragStartPdfPosition;
  Offset? _dragStartLocalOffset;
  Size? _resizeStartSize;
  Offset? _resizeStartOffset;

  @override
  Widget build(BuildContext context) {
    // Convert PDF coordinates to screen coordinates
    final screenTopLeft = widget.pdfToScreenTransform(
      Offset(
        widget.imageAnnotation.position.dx,
        widget.imageAnnotation.position.dy,
      ),
    );
    
    // Calculate screen size based on PDF size and current scale
    final screenBottomRight = widget.pdfToScreenTransform(
      Offset(
        widget.imageAnnotation.position.dx + widget.imageAnnotation.size.width,
        widget.imageAnnotation.position.dy - widget.imageAnnotation.size.height,
      ),
    );
    
    final screenWidth = (screenBottomRight.dx - screenTopLeft.dx).abs();
    final screenHeight = (screenBottomRight.dy - screenTopLeft.dy).abs();

    return Positioned(
      left: screenTopLeft.dx,
      top: screenTopLeft.dy,
      child: GestureDetector(
        onTap: () {
          setState(() => _isSelected = !_isSelected);
        },
        onPanStart: (details) {
          if (!_isSelected) {
            setState(() => _isSelected = true);
          }
          _dragStartPdfPosition = widget.imageAnnotation.position;
          _dragStartLocalOffset = details.localPosition;
        },
        onPanUpdate: (details) {
          if (_dragStartPdfPosition == null || _dragStartLocalOffset == null) {
            return;
          }

          // Calculate delta in screen space
          final deltaScreen = details.localPosition - _dragStartLocalOffset!;
          
          // Convert screen positions to PDF coordinates
          final startScreen = widget.pdfToScreenTransform(_dragStartPdfPosition!);
          final newScreen = startScreen + deltaScreen;
          final newPdf = widget.screenToPdfTransform(newScreen);

          // Clamp to page boundaries in PDF space
          final clampedX = newPdf.dx.clamp(
            0.0,
            widget.pageSize.width - widget.imageAnnotation.size.width,
          );
          final clampedY = newPdf.dy.clamp(
            widget.imageAnnotation.size.height,
            widget.pageSize.height,
          );

          widget.onUpdate(
            widget.imageAnnotation.copyWith(
              position: Offset(clampedX, clampedY),
            ),
          );
        },
        onPanEnd: (details) {
          _dragStartPdfPosition = null;
          _dragStartLocalOffset = null;
          // Don't deselect on pan end, let user explicitly deselect
        },
        child: Stack(
          children: [
            // Image display
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: BoxDecoration(
                border: _isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
                boxShadow: _isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Image.memory(
                widget.imageAnnotation.imageBytes,
                fit: BoxFit.fill,
              ),
            ),

            // Resize handles (only visible when selected)
            if (_isSelected) ...[
              // Top-left handle
              _buildResizeHandle(
                alignment: Alignment.topLeft,
                onPanStart: _onResizeStart,
                onPanUpdate: (details) =>
                    _onResizeUpdate(details, ResizeDirection.topLeft),
                onPanEnd: _onResizeEnd,
              ),

              // Top-right handle
              _buildResizeHandle(
                alignment: Alignment.topRight,
                onPanStart: _onResizeStart,
                onPanUpdate: (details) =>
                    _onResizeUpdate(details, ResizeDirection.topRight),
                onPanEnd: _onResizeEnd,
              ),

              // Bottom-left handle
              _buildResizeHandle(
                alignment: Alignment.bottomLeft,
                onPanStart: _onResizeStart,
                onPanUpdate: (details) =>
                    _onResizeUpdate(details, ResizeDirection.bottomLeft),
                onPanEnd: _onResizeEnd,
              ),

              // Bottom-right handle
              _buildResizeHandle(
                alignment: Alignment.bottomRight,
                onPanStart: _onResizeStart,
                onPanUpdate: (details) =>
                    _onResizeUpdate(details, ResizeDirection.bottomRight),
                onPanEnd: _onResizeEnd,
              ),

              // Delete button
              Positioned(
                right: -8,
                top: -8,
                child: GestureDetector(
                  onTap: () => widget.onDelete(widget.imageAnnotation),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle({
    required Alignment alignment,
    required Function(DragStartDetails) onPanStart,
    required Function(DragUpdateDetails) onPanUpdate,
    required Function(DragEndDetails) onPanEnd,
  }) {
    return Positioned(
      left: alignment.x > 0 ? null : -6,
      right: alignment.x > 0 ? -6 : null,
      top: alignment.y > 0 ? null : -6,
      bottom: alignment.y > 0 ? -6 : null,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      ),
    );
  }

  void _onResizeStart(DragStartDetails details) {
    _resizeStartSize = widget.imageAnnotation.size;
    _resizeStartOffset = widget.imageAnnotation.position;
  }

  void _onResizeUpdate(DragUpdateDetails details, ResizeDirection direction) {
    if (_resizeStartSize == null || _resizeStartOffset == null) return;

    double newWidth = _resizeStartSize!.width;
    double newHeight = _resizeStartSize!.height;
    Offset newPosition = _resizeStartOffset!;

    const minSize = 50.0;

    switch (direction) {
      case ResizeDirection.topLeft:
        newWidth = (_resizeStartSize!.width - details.localPosition.dx).clamp(
          minSize,
          widget.pageSize.width,
        );
        newHeight = (_resizeStartSize!.height - details.localPosition.dy).clamp(
          minSize,
          widget.pageSize.height,
        );
        newPosition = Offset(
          (_resizeStartOffset!.dx + details.localPosition.dx).clamp(
            0.0,
            widget.pageSize.width - minSize,
          ),
          (_resizeStartOffset!.dy + details.localPosition.dy).clamp(
            minSize,
            widget.pageSize.height,
          ),
        );
        break;

      case ResizeDirection.topRight:
        newWidth = (_resizeStartSize!.width + details.localPosition.dx).clamp(
          minSize,
          widget.pageSize.width,
        );
        newHeight = (_resizeStartSize!.height - details.localPosition.dy).clamp(
          minSize,
          widget.pageSize.height,
        );
        newPosition = Offset(
          _resizeStartOffset!.dx,
          (_resizeStartOffset!.dy + details.localPosition.dy).clamp(
            minSize,
            widget.pageSize.height,
          ),
        );
        break;

      case ResizeDirection.bottomLeft:
        newWidth = (_resizeStartSize!.width - details.localPosition.dx).clamp(
          minSize,
          widget.pageSize.width,
        );
        newHeight = (_resizeStartSize!.height + details.localPosition.dy).clamp(
          minSize,
          widget.pageSize.height,
        );
        newPosition = Offset(
          (_resizeStartOffset!.dx + details.localPosition.dx).clamp(
            0.0,
            widget.pageSize.width - minSize,
          ),
          _resizeStartOffset!.dy,
        );
        break;

      case ResizeDirection.bottomRight:
        newWidth = (_resizeStartSize!.width + details.localPosition.dx).clamp(
          minSize,
          widget.pageSize.width,
        );
        newHeight = (_resizeStartSize!.height + details.localPosition.dy).clamp(
          minSize,
          widget.pageSize.height,
        );
        break;
    }

    widget.onUpdate(
      widget.imageAnnotation.copyWith(
        size: Size(newWidth, newHeight),
        position: newPosition,
      ),
    );
  }

  void _onResizeEnd(DragEndDetails details) {
    _resizeStartSize = null;
    _resizeStartOffset = null;
  }
}

enum ResizeDirection { topLeft, topRight, bottomLeft, bottomRight }
