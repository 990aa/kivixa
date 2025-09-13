import 'package:flutter/material.dart';

/// Shows a floating menu with a shadow/elevation animation.
///
/// The menu is positioned contextually to avoid screen edges.
void showFloatingMenu({
  required BuildContext context,
  required Offset position,
  required List<Widget> items,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final screenSize = overlay.size;

  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      screenSize.width - position.dx,
      screenSize.height - position.dy,
    ),
    items: items.map((item) {
      return PopupMenuItem(
        child: item,
      );
    }).toList(),
    elevation: 8.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  );
}
