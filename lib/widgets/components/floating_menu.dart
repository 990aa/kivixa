import 'package:flutter/material.dart';
import 'custom_popup_menu.dart';

/// Shows a floating menu with a shadow/elevation animation.
///
/// The menu is positioned contextually to avoid screen edges.
void showFloatingMenu({
  required BuildContext context,
  required Offset position,
  required List<PopupMenuEntry> items,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final screenSize = overlay.size;

  showCustomMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      screenSize.width - position.dx,
      screenSize.height - position.dy,
    ),
    items: items,
    elevation: 8.0,
  );
}
