import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/services/media_service.dart';

/// A callback for when media element properties change
typedef MediaElementCallback = void Function(MediaElement element);

/// Interactive widget that allows resize, rotate, drag, and comments on media.
///
/// Features:
/// - Corner/edge resize handles with aspect ratio lock option
/// - Rotation handle at top with 15° snapping
/// - Pan gesture for repositioning
/// - Selection state with visual feedback
/// - RepaintBoundary for performance isolation
class InteractiveMediaWidget extends StatefulWidget {
  const InteractiveMediaWidget({
    super.key,
    required this.element,
    required this.onChanged,
    this.onTap,
    this.onDoubleTap,
    this.isSelected = false,
    this.child,
    this.minWidth = 50,
    this.minHeight = 50,
    this.maxWidth = 2000,
    this.maxHeight = 2000,
    this.showRotationHandle = true,
    this.rotationSnapAngle = 15.0,
    this.lockAspectRatio = false,
  });

  /// The media element data
  final MediaElement element;

  /// Callback when element properties change
  final MediaElementCallback onChanged;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when double tapped
  final VoidCallback? onDoubleTap;

  /// Whether the widget is currently selected
  final bool isSelected;

  /// Optional child widget (if not provided, will load from element.path)
  final Widget? child;

  /// Minimum width constraint
  final double minWidth;

  /// Minimum height constraint
  final double minHeight;

  /// Maximum width constraint
  final double maxWidth;

  /// Maximum height constraint
  final double maxHeight;

  /// Whether to show the rotation handle
  final bool showRotationHandle;

  /// Angle in degrees to snap rotation to
  final double rotationSnapAngle;

  /// Whether to lock aspect ratio during resize
  final bool lockAspectRatio;

  @override
  State<InteractiveMediaWidget> createState() => _InteractiveMediaWidgetState();
}

class _InteractiveMediaWidgetState extends State<InteractiveMediaWidget> {
  static const _handleSize = 12.0;
  static const _rotationHandleOffset = 30.0;

  // Local state for smooth interactions
  double _width = 200;
  double _height = 200;
  double _rotation = 0;
  double _posX = 0;
  double _posY = 0;

  // Interaction state
  var _isDragging = false;
  var _isResizing = false;
  var _isRotating = false;
  _ResizeHandle? _activeHandle;

  // For rotation calculations
  Offset? _rotationCenter;
  double? _initialRotation;
  double? _initialAngle;

  // For resize calculations
  double? _initialWidth;
  double? _initialHeight;
  Offset? _initialPointer;

  // Debounce timer for callback
  DateTime? _lastCallback;

  // Loaded image
  Widget? _loadedChild;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _syncFromElement();
    _loadMedia();
  }

  @override
  void didUpdateWidget(InteractiveMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element != widget.element) {
      _syncFromElement();
    }
  }

  void _syncFromElement() {
    _width = widget.element.width ?? 200;
    _height = widget.element.height ?? 200;
    _rotation = widget.element.rotation;
    _posX = widget.element.posX;
    _posY = widget.element.posY;
  }

  Future<void> _loadMedia() async {
    if (widget.child != null) {
      setState(() {
        _loadedChild = widget.child;
        _isLoading = false;
      });
      return;
    }

    if (widget.element.isVideo) {
      // Video will be handled by MediaVideoPlayer
      setState(() => _isLoading = false);
      return;
    }

    final bytes = await MediaService.instance.resolveMedia(widget.element);
    if (bytes != null && mounted) {
      setState(() {
        _loadedChild = Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _notifyChange() {
    // Debounce callbacks to avoid excessive updates
    final now = DateTime.now();
    if (_lastCallback != null &&
        now.difference(_lastCallback!).inMilliseconds < 100) {
      return;
    }
    _lastCallback = now;

    widget.onChanged(
      widget.element.copyWith(
        width: _width,
        height: _height,
        rotation: _rotation,
        posX: _posX,
        posY: _posY,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isSelected) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _posX += details.delta.dx;
      _posY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);
    _notifyChange();
  }

  void _onResizeStart(_ResizeHandle handle, DragStartDetails details) {
    setState(() {
      _isResizing = true;
      _activeHandle = handle;
      _initialWidth = _width;
      _initialHeight = _height;
      _initialPointer = details.globalPosition;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (!_isResizing || _activeHandle == null) return;

    final delta = details.globalPosition - _initialPointer!;
    var newWidth = _initialWidth!;
    var newHeight = _initialHeight!;

    // Calculate rotation in radians
    final radians = _rotation * math.pi / 180;
    final cos = math.cos(radians);
    final sin = math.sin(radians);

    // Transform delta to account for rotation
    final rotatedDelta = Offset(
      delta.dx * cos + delta.dy * sin,
      -delta.dx * sin + delta.dy * cos,
    );

    switch (_activeHandle!) {
      case _ResizeHandle.topLeft:
        newWidth = (_initialWidth! - rotatedDelta.dx).clamp(
          widget.minWidth,
          widget.maxWidth,
        );
        newHeight = (_initialHeight! - rotatedDelta.dy).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
      case _ResizeHandle.topRight:
        newWidth = (_initialWidth! + rotatedDelta.dx).clamp(
          widget.minWidth,
          widget.maxWidth,
        );
        newHeight = (_initialHeight! - rotatedDelta.dy).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
      case _ResizeHandle.bottomLeft:
        newWidth = (_initialWidth! - rotatedDelta.dx).clamp(
          widget.minWidth,
          widget.maxWidth,
        );
        newHeight = (_initialHeight! + rotatedDelta.dy).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
      case _ResizeHandle.bottomRight:
        newWidth = (_initialWidth! + rotatedDelta.dx).clamp(
          widget.minWidth,
          widget.maxWidth,
        );
        newHeight = (_initialHeight! + rotatedDelta.dy).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
      case _ResizeHandle.left:
        newWidth = (_initialWidth! - rotatedDelta.dx).clamp(
          widget.minWidth,
          widget.maxWidth,
        );
      case _ResizeHandle.right:
        newWidth = (_initialWidth! + rotatedDelta.dx).clamp(
          widget.minWidth,
          widget.maxWidth,
        );
      case _ResizeHandle.top:
        newHeight = (_initialHeight! - rotatedDelta.dy).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
      case _ResizeHandle.bottom:
        newHeight = (_initialHeight! + rotatedDelta.dy).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
    }

    // Lock aspect ratio if enabled
    if (widget.lockAspectRatio && _initialWidth! > 0 && _initialHeight! > 0) {
      final aspectRatio = _initialWidth! / _initialHeight!;
      if (_activeHandle!.isCorner) {
        // For corner handles, maintain ratio based on larger change
        final widthRatio = newWidth / _initialWidth!;
        final heightRatio = newHeight / _initialHeight!;
        if (widthRatio.abs() > heightRatio.abs()) {
          newHeight = newWidth / aspectRatio;
        } else {
          newWidth = newHeight * aspectRatio;
        }
      }
    }

    setState(() {
      _width = newWidth;
      _height = newHeight;
    });
  }

  void _onResizeEnd(DragEndDetails details) {
    if (!_isResizing) return;
    setState(() {
      _isResizing = false;
      _activeHandle = null;
    });
    _notifyChange();
  }

  void _onRotationStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final center = box.localToGlobal(Offset(_width / 2, _height / 2));
    _rotationCenter = center;
    _initialRotation = _rotation;

    final pointerOffset = details.globalPosition - center;
    _initialAngle = math.atan2(pointerOffset.dy, pointerOffset.dx);

    setState(() => _isRotating = true);
  }

  void _onRotationUpdate(DragUpdateDetails details) {
    if (!_isRotating || _rotationCenter == null) return;

    final pointerOffset = details.globalPosition - _rotationCenter!;
    final currentAngle = math.atan2(pointerOffset.dy, pointerOffset.dx);
    final deltaAngle = (currentAngle - _initialAngle!) * 180 / math.pi;

    var newRotation = _initialRotation! + deltaAngle;

    // Normalize to 0-360
    while (newRotation < 0) {
      newRotation += 360;
    }
    while (newRotation >= 360) {
      newRotation -= 360;
    }

    // Snap to angle increments
    if (widget.rotationSnapAngle > 0) {
      newRotation =
          (newRotation / widget.rotationSnapAngle).round() *
          widget.rotationSnapAngle;
    }

    setState(() => _rotation = newRotation);
  }

  void _onRotationEnd(DragEndDetails details) {
    if (!_isRotating) return;
    setState(() => _isRotating = false);
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(_posX, _posY),
        child: Transform.rotate(
          angle: _rotation * math.pi / 180,
          child: GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SizedBox(
              width: _width + (widget.isSelected ? _handleSize * 2 : 0),
              height:
                  _height +
                  (widget.isSelected ? _handleSize * 2 : 0) +
                  (widget.isSelected && widget.showRotationHandle
                      ? _rotationHandleOffset
                      : 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main content
                  Positioned(
                    left: widget.isSelected ? _handleSize : 0,
                    top: widget.isSelected && widget.showRotationHandle
                        ? _handleSize + _rotationHandleOffset
                        : (widget.isSelected ? _handleSize : 0),
                    width: _width,
                    height: _height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                        boxShadow: _isDragging
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _buildContent(),
                      ),
                    ),
                  ),

                  // Selection handles
                  if (widget.isSelected) ..._buildHandles(colorScheme),

                  // Rotation handle
                  if (widget.isSelected && widget.showRotationHandle)
                    _buildRotationHandle(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadedChild != null) {
      return _loadedChild!;
    }

    // Fallback placeholder
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }

  List<Widget> _buildHandles(ColorScheme colorScheme) {
    final handles = <Widget>[];
    final offsetTop = widget.showRotationHandle ? _rotationHandleOffset : 0.0;

    for (final handle in _ResizeHandle.values) {
      handles.add(
        Positioned(
          left: _getHandleLeft(handle),
          top: _getHandleTop(handle) + offsetTop,
          child: GestureDetector(
            onPanStart: (d) => _onResizeStart(handle, d),
            onPanUpdate: _onResizeUpdate,
            onPanEnd: _onResizeEnd,
            child: MouseRegion(
              cursor: _getHandleCursor(handle),
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return handles;
  }

  double _getHandleLeft(_ResizeHandle handle) {
    switch (handle) {
      case _ResizeHandle.topLeft:
      case _ResizeHandle.left:
      case _ResizeHandle.bottomLeft:
        return 0;
      case _ResizeHandle.top:
      case _ResizeHandle.bottom:
        return _width / 2 + _handleSize / 2;
      case _ResizeHandle.topRight:
      case _ResizeHandle.right:
      case _ResizeHandle.bottomRight:
        return _width + _handleSize;
    }
  }

  double _getHandleTop(_ResizeHandle handle) {
    switch (handle) {
      case _ResizeHandle.topLeft:
      case _ResizeHandle.top:
      case _ResizeHandle.topRight:
        return 0;
      case _ResizeHandle.left:
      case _ResizeHandle.right:
        return _height / 2 + _handleSize / 2;
      case _ResizeHandle.bottomLeft:
      case _ResizeHandle.bottom:
      case _ResizeHandle.bottomRight:
        return _height + _handleSize;
    }
  }

  MouseCursor _getHandleCursor(_ResizeHandle handle) {
    switch (handle) {
      case _ResizeHandle.topLeft:
      case _ResizeHandle.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case _ResizeHandle.topRight:
      case _ResizeHandle.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case _ResizeHandle.left:
      case _ResizeHandle.right:
        return SystemMouseCursors.resizeLeftRight;
      case _ResizeHandle.top:
      case _ResizeHandle.bottom:
        return SystemMouseCursors.resizeUpDown;
    }
  }

  Widget _buildRotationHandle(ColorScheme colorScheme) {
    return Positioned(
      left: _width / 2 + _handleSize / 2,
      top: 0,
      child: Column(
        children: [
          GestureDetector(
            onPanStart: _onRotationStart,
            onPanUpdate: _onRotationUpdate,
            onPanEnd: _onRotationEnd,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.rotate_right,
                  size: _handleSize - 4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: _rotationHandleOffset - _handleSize,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

enum _ResizeHandle {
  topLeft,
  top,
  topRight,
  left,
  right,
  bottomLeft,
  bottom,
  bottomRight;

  bool get isCorner =>
      this == topLeft ||
      this == topRight ||
      this == bottomLeft ||
      this == bottomRight;
}
