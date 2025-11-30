import 'package:flutter/material.dart';
import 'package:kivixa/components/split_screen/split_screen_state.dart';

/// A draggable divider for resizing split panes
class ResizableDivider extends StatefulWidget {
  const ResizableDivider({
    super.key,
    required this.direction,
    required this.onDrag,
    this.thickness = 8.0,
    this.color,
    this.hoverColor,
  });

  /// The direction of the split (horizontal = vertical divider, vertical = horizontal divider)
  final SplitDirection direction;

  /// Callback when the divider is dragged
  final void Function(double delta) onDrag;

  /// The thickness of the divider touch area
  final double thickness;

  /// The color of the divider
  final Color? color;

  /// The color of the divider when hovered
  final Color? hoverColor;

  @override
  State<ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<ResizableDivider> {
  var _isHovered = false;
  var _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _isHovered || _isDragging;

    final dividerColor = isActive
        ? (widget.hoverColor ?? colorScheme.primary)
        : (widget.color ?? colorScheme.outlineVariant);

    final isVerticalDivider = widget.direction == SplitDirection.horizontal;

    return MouseRegion(
      cursor: isVerticalDivider
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanEnd: (_) => setState(() => _isDragging = false),
        onPanCancel: () => setState(() => _isDragging = false),
        onPanUpdate: (details) {
          if (isVerticalDivider) {
            widget.onDrag(details.delta.dx);
          } else {
            widget.onDrag(details.delta.dy);
          }
        },
        child: Container(
          width: isVerticalDivider ? widget.thickness : double.infinity,
          height: isVerticalDivider ? double.infinity : widget.thickness,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isVerticalDivider ? (isActive ? 4 : 2) : double.infinity,
              height: isVerticalDivider ? double.infinity : (isActive ? 4 : 2),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: isActive
                  ? Center(
                      child: Container(
                        width: isVerticalDivider ? 4 : 24,
                        height: isVerticalDivider ? 24 : 4,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
