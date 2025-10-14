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
  final bool isSelected;
  final Function()? onSelect;

  const ImageAnnotationWidget({
    super.key,
    required this.imageAnnotation,
    required this.onUpdate,
    required this.onDelete,
    required this.pageSize,
    required this.pdfToScreenTransform,
    required this.screenToPdfTransform,
    this.onDeselect,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<ImageAnnotationWidget> createState() => _ImageAnnotationWidgetState();
}

class _ImageAnnotationWidgetState extends State<ImageAnnotationWidget> {
  Offset? _dragStartPdfPosition;
  Size? _resizeStartSize;
  Offset? _resizeStartPosition;

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
          widget.onSelect?.call();
        },
        onPanStart: (details) {
          if (!widget.isSelected) {
            widget.onSelect?.call();
          }
          _dragStartPdfPosition = widget.imageAnnotation.position;
        },
        onPanUpdate: (details) {
          if (_dragStartPdfPosition == null) return;

          // Convert the current screen position to PDF coordinates
          // Calculate the new position based on gesture delta
          final currentScreenPos = widget.pdfToScreenTransform(_dragStartPdfPosition!);
          final newScreenPos = currentScreenPos + details.delta;
          final newPdfPos = widget.screenToPdfTransform(newScreenPos);

          // Clamp to page boundaries in PDF space
          final clampedX = newPdfPos.dx.clamp(
            0.0,
            widget.pageSize.width - widget.imageAnnotation.size.width,
          );
          final clampedY = newPdfPos.dy.clamp(
            widget.imageAnnotation.size.height,
            widget.pageSize.height,
          );

          final clampedPosition = Offset(clampedX, clampedY);
          
          // Update the drag start position for next delta calculation
          _dragStartPdfPosition = clampedPosition;

          // Update the image annotation with smooth, continuous movement
          widget.onUpdate(
            widget.imageAnnotation.copyWith(
              position: clampedPosition,
            ),
          );
        },
        onPanEnd: (details) {
          _dragStartPdfPosition = null;
        },
        child: Stack(
          children: [
            // Image display
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: BoxDecoration(
                border: widget.isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
                boxShadow: widget.isSelected
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
            if (widget.isSelected) ...[
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
    _resizeStartPosition = widget.imageAnnotation.position;
  }

  void _onResizeUpdate(DragUpdateDetails details, ResizeDirection direction) {
    if (_resizeStartSize == null || _resizeStartPosition == null) return;

    // Use delta for smooth, continuous resizing
    final screenDelta = details.delta;
    
    // Convert screen delta to approximate PDF delta
    // For more accurate conversion, we'd need to track the scale factor
    final pdfDelta = screenDelta;

    double newWidth = widget.imageAnnotation.size.width;
    double newHeight = widget.imageAnnotation.size.height;
    Offset newPosition = widget.imageAnnotation.position;

    const minSize = 50.0;

    switch (direction) {
      case ResizeDirection.topLeft:
        // Resize from top-left: decrease width/height, move position
        newWidth = (newWidth - pdfDelta.dx).clamp(minSize, widget.pageSize.width);
        newHeight = (newHeight + pdfDelta.dy).clamp(minSize, widget.pageSize.height);
        newPosition = Offset(
          (newPosition.dx + pdfDelta.dx).clamp(0.0, widget.pageSize.width - minSize),
          (newPosition.dy - pdfDelta.dy).clamp(minSize, widget.pageSize.height),
        );
        break;

      case ResizeDirection.topRight:
        // Resize from top-right: increase width, decrease height
        newWidth = (newWidth + pdfDelta.dx).clamp(minSize, widget.pageSize.width - newPosition.dx);
        newHeight = (newHeight + pdfDelta.dy).clamp(minSize, widget.pageSize.height);
        newPosition = Offset(
          newPosition.dx,
          (newPosition.dy - pdfDelta.dy).clamp(minSize, widget.pageSize.height),
        );
        break;

      case ResizeDirection.bottomLeft:
        // Resize from bottom-left: decrease width, increase height
        newWidth = (newWidth - pdfDelta.dx).clamp(minSize, widget.pageSize.width);
        newHeight = (newHeight - pdfDelta.dy).clamp(minSize, widget.pageSize.height);
        newPosition = Offset(
          (newPosition.dx + pdfDelta.dx).clamp(0.0, widget.pageSize.width - minSize),
          newPosition.dy,
        );
        break;

      case ResizeDirection.bottomRight:
        // Resize from bottom-right: increase both width and height
        newWidth = (newWidth + pdfDelta.dx).clamp(minSize, widget.pageSize.width - newPosition.dx);
        newHeight = (newHeight - pdfDelta.dy).clamp(minSize, widget.pageSize.height);
        break;
    }

    // Smooth, continuous update with no quantization
    widget.onUpdate(
      widget.imageAnnotation.copyWith(
        size: Size(newWidth, newHeight),
        position: newPosition,
      ),
    );
  }

  void _onResizeEnd(DragEndDetails details) {
    _resizeStartSize = null;
    _resizeStartPosition = null;
  }
}

enum ResizeDirection { topLeft, topRight, bottomLeft, bottomRight }
