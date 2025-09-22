import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContextMenuAction {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;

  ContextMenuAction({required this.title, required this.icon, this.onPressed});
}

void showModernContextMenu({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuAction> actions,
}) {
  final overlay = context.findRenderObject() as RenderBox;
  final screenWidth = overlay.size.width;
  final screenHeight = overlay.size.height;

  // Constants for menu dimensions
  const menuWidth = 220.0;
  const menuItemHeight = 50.0;
  final menuHeight = actions.length * menuItemHeight;
  const screenPadding = 16.0;

  // Calculate horizontal position
  double left = position.dx;
  if (left + menuWidth > screenWidth - screenPadding) {
    left = screenWidth - menuWidth - screenPadding;
  }
  if (left < screenPadding) {
    left = screenPadding;
  }

  // Calculate vertical position
  double top = position.dy;
  if (top + menuHeight > screenHeight - screenPadding) {
    top = screenHeight - menuHeight - screenPadding;
  }
  if (top < screenPadding) {
    top = screenPadding;
  }

  HapticFeedback.mediumImpact();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withAlpha((255 * 0.2).round()),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return Stack(
        children: [
          // Blurred Background
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * curvedAnimation.value,
              sigmaY: 5 * curvedAnimation.value,
            ),
            child: Container(color: Colors.transparent),
          ),
          // Menu Content
          Positioned(
            top: top,
            left: left,
            child: FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: curvedAnimation,
                alignment: Alignment.topLeft,
                child: _ContextMenuContent(
                  actions: actions,
                  width: menuWidth,
                  itemHeight: menuItemHeight,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ContextMenuContent extends StatelessWidget {
  const _ContextMenuContent({
    required this.actions,
    required this.width,
    required this.itemHeight,
  });

  final List<ContextMenuAction> actions;
  final double width;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((action) {
              return _ContextMenuItem(action: action, height: itemHeight);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ContextMenuItem extends StatefulWidget {
  const _ContextMenuItem({required this.action, required this.height});

  final ContextMenuAction action;
  final double height;

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop(); // Close the menu
          widget.action.onPressed?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          color: _isHovered
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.action.icon,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.action.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
