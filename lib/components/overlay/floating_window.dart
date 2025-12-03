import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A floating window that can be dragged and resized.
///
/// Used for tool windows like AI assistant and browser that float
/// above the main app content.
class FloatingWindow extends StatefulWidget {
  const FloatingWindow({
    super.key,
    required this.rect,
    required this.onRectChanged,
    required this.onClose,
    required this.title,
    required this.icon,
    required this.child,
    this.minWidth = 300,
    this.minHeight = 200,
    this.maxWidth,
    this.maxHeight,
    this.resizable = true,
    this.onMinimize,
    this.showMinimizeButton = false,
  });

  /// Current position and size of the window.
  final Rect rect;

  /// Called when the window is moved or resized.
  final ValueChanged<Rect> onRectChanged;

  /// Called when the close button is pressed.
  final VoidCallback onClose;

  /// Called when the minimize button is pressed.
  final VoidCallback? onMinimize;

  /// Title displayed in the title bar.
  final String title;

  /// Icon displayed in the title bar.
  final IconData icon;

  /// Content of the window.
  final Widget child;

  /// Minimum width constraint.
  final double minWidth;

  /// Minimum height constraint.
  final double minHeight;

  /// Maximum width constraint.
  final double? maxWidth;

  /// Maximum height constraint.
  final double? maxHeight;

  /// Whether the window can be resized.
  final bool resizable;

  /// Whether to show a minimize button.
  final bool showMinimizeButton;

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  var _isDragging = false;
  var _isResizing = false;

  /// Whether we're on a desktop platform with mouse support.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget windowContent = Material(
      elevation: _isDragging || _isResizing ? 16 : 8,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: widget.rect.width,
        height: widget.rect.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging || _isResizing
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
            width: _isDragging || _isResizing ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Title bar
            _buildTitleBar(context),
            // Content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with resize handles if resizable
    if (widget.resizable) {
      windowContent = ResizableWindowContainer(
        rect: widget.rect,
        onRectChanged: widget.onRectChanged,
        minWidth: widget.minWidth,
        minHeight: widget.minHeight,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        onResizeStart: () => setState(() => _isResizing = true),
        onResizeEnd: () => setState(() => _isResizing = false),
        child: windowContent,
      );
    }

    return Positioned(
      left: widget.rect.left,
      top: widget.rect.top,
      child: windowContent,
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() => _isDragging = true);
        },
        onPanUpdate: (details) {
          final newRect = widget.rect.translate(
            details.delta.dx,
            details.delta.dy,
          );
          widget.onRectChanged(newRect);
        },
        onPanEnd: (details) {
          setState(() => _isDragging = false);
        },
        child: Container(
          height: _isDesktop ? 36 : 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              topRight: Radius.circular(11),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(widget.icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Minimize button
              if (widget.showMinimizeButton && widget.onMinimize != null)
                _TitleBarButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Minimize',
                  onPressed: widget.onMinimize!,
                ),
              // Close button
              _TitleBarButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                onPressed: widget.onClose,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// A button for the title bar.
class _TitleBarButton extends StatelessWidget {
  const _TitleBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 18,
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
    );
  }
}

/// A container that provides resize handles around a floating window.
class ResizableWindowContainer extends StatefulWidget {
  const ResizableWindowContainer({
    super.key,
    required this.rect,
    required this.onRectChanged,
    required this.child,
    this.minWidth = 300,
    this.minHeight = 200,
    this.maxWidth,
    this.maxHeight,
    this.onResizeStart,
    this.onResizeEnd,
  });

  final Rect rect;
  final ValueChanged<Rect> onRectChanged;
  final Widget child;
  final double minWidth;
  final double minHeight;
  final double? maxWidth;
  final double? maxHeight;
  final VoidCallback? onResizeStart;
  final VoidCallback? onResizeEnd;

  @override
  State<ResizableWindowContainer> createState() =>
      _ResizableWindowContainerState();
}

class _ResizableWindowContainerState extends State<ResizableWindowContainer> {
  /// Whether we're on a desktop platform with mouse support.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    // Larger touch targets on desktop for better mouse interaction
    final handleSize = _isDesktop ? 12.0 : 8.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        // Corner handles
        _buildCornerHandle(_Corner.topLeft, handleSize),
        _buildCornerHandle(_Corner.topRight, handleSize),
        _buildCornerHandle(_Corner.bottomLeft, handleSize),
        _buildCornerHandle(_Corner.bottomRight, handleSize),
        // Edge handles
        _buildEdgeHandle(_Edge.top, handleSize),
        _buildEdgeHandle(_Edge.bottom, handleSize),
        _buildEdgeHandle(_Edge.left, handleSize),
        _buildEdgeHandle(_Edge.right, handleSize),
      ],
    );
  }

  Widget _buildCornerHandle(_Corner corner, double size) {
    final cursor = switch (corner) {
      _Corner.topLeft ||
      _Corner.bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
      _Corner.topRight ||
      _Corner.bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
    };

    return Positioned(
      left: corner == _Corner.topLeft || corner == _Corner.bottomLeft
          ? -size / 2
          : null,
      right: corner == _Corner.topRight || corner == _Corner.bottomRight
          ? -size / 2
          : null,
      top: corner == _Corner.topLeft || corner == _Corner.topRight
          ? -size / 2
          : null,
      bottom: corner == _Corner.bottomLeft || corner == _Corner.bottomRight
          ? -size / 2
          : null,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (_) => widget.onResizeStart?.call(),
          onPanEnd: (_) => widget.onResizeEnd?.call(),
          onPanUpdate: (details) {
            double left = widget.rect.left;
            double top = widget.rect.top;
            double right = widget.rect.right;
            double bottom = widget.rect.bottom;

            switch (corner) {
              case _Corner.topLeft:
                left += details.delta.dx;
                top += details.delta.dy;
              case _Corner.topRight:
                right += details.delta.dx;
                top += details.delta.dy;
              case _Corner.bottomLeft:
                left += details.delta.dx;
                bottom += details.delta.dy;
              case _Corner.bottomRight:
                right += details.delta.dx;
                bottom += details.delta.dy;
            }

            // Apply min constraints
            if (right - left < widget.minWidth) {
              if (corner == _Corner.topLeft || corner == _Corner.bottomLeft) {
                left = right - widget.minWidth;
              } else {
                right = left + widget.minWidth;
              }
            }
            if (bottom - top < widget.minHeight) {
              if (corner == _Corner.topLeft || corner == _Corner.topRight) {
                top = bottom - widget.minHeight;
              } else {
                bottom = top + widget.minHeight;
              }
            }

            // Apply max constraints
            if (widget.maxWidth != null && right - left > widget.maxWidth!) {
              if (corner == _Corner.topLeft || corner == _Corner.bottomLeft) {
                left = right - widget.maxWidth!;
              } else {
                right = left + widget.maxWidth!;
              }
            }
            if (widget.maxHeight != null && bottom - top > widget.maxHeight!) {
              if (corner == _Corner.topLeft || corner == _Corner.topRight) {
                top = bottom - widget.maxHeight!;
              } else {
                bottom = top + widget.maxHeight!;
              }
            }

            widget.onRectChanged(Rect.fromLTRB(left, top, right, bottom));
          },
          child: Container(
            width: size * 2,
            height: size * 2,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle(_Edge edge, double size) {
    final cursor = switch (edge) {
      _Edge.top || _Edge.bottom => SystemMouseCursors.resizeUpDown,
      _Edge.left || _Edge.right => SystemMouseCursors.resizeLeftRight,
    };

    return Positioned(
      left: edge == _Edge.left
          ? -size / 2
          : (edge == _Edge.right ? null : size * 1.5),
      right: edge == _Edge.right
          ? -size / 2
          : (edge == _Edge.left ? null : size * 1.5),
      top: edge == _Edge.top
          ? -size / 2
          : (edge == _Edge.bottom ? null : size * 1.5),
      bottom: edge == _Edge.bottom
          ? -size / 2
          : (edge == _Edge.top ? null : size * 1.5),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (_) => widget.onResizeStart?.call(),
          onPanEnd: (_) => widget.onResizeEnd?.call(),
          onPanUpdate: (details) {
            double left = widget.rect.left;
            double top = widget.rect.top;
            double right = widget.rect.right;
            double bottom = widget.rect.bottom;

            switch (edge) {
              case _Edge.top:
                top += details.delta.dy;
              case _Edge.bottom:
                bottom += details.delta.dy;
              case _Edge.left:
                left += details.delta.dx;
              case _Edge.right:
                right += details.delta.dx;
            }

            // Apply min constraints
            if (right - left < widget.minWidth) {
              if (edge == _Edge.left) {
                left = right - widget.minWidth;
              } else if (edge == _Edge.right) {
                right = left + widget.minWidth;
              }
            }
            if (bottom - top < widget.minHeight) {
              if (edge == _Edge.top) {
                top = bottom - widget.minHeight;
              } else if (edge == _Edge.bottom) {
                bottom = top + widget.minHeight;
              }
            }

            // Apply max constraints
            if (widget.maxWidth != null && right - left > widget.maxWidth!) {
              if (edge == _Edge.left) {
                left = right - widget.maxWidth!;
              } else if (edge == _Edge.right) {
                right = left + widget.maxWidth!;
              }
            }
            if (widget.maxHeight != null && bottom - top > widget.maxHeight!) {
              if (edge == _Edge.top) {
                top = bottom - widget.maxHeight!;
              } else if (edge == _Edge.bottom) {
                bottom = top + widget.maxHeight!;
              }
            }

            widget.onRectChanged(Rect.fromLTRB(left, top, right, bottom));
          },
          child: Container(
            width: edge == _Edge.top || edge == _Edge.bottom ? null : size,
            height: edge == _Edge.left || edge == _Edge.right ? null : size,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

enum _Edge { top, bottom, left, right }
