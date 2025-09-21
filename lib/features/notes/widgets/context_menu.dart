import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

void showContextMenu(BuildContext context, Offset position) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(40, 40), // smaller rect, the touch area
      Offset.zero & overlay.size, // Bigger rect, the entire screen
    ),
    items: [
      const PopupMenuItem(
        value: 'create',
        child: ListTile(
          leading: Icon(Icons.create_new_folder, color: Colors.white),
          title: Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete, color: Colors.white),
          title: Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ),
      const PopupMenuItem(
        value: 'move',
        child: ListTile(
          leading: Icon(Icons.move_to_inbox, color: Colors.white),
          title: Text('Move', style: TextStyle(color: Colors.white)),
        ),
      ),
      const PopupMenuItem(
        value: 'rename',
        child: ListTile(
          leading: Icon(Icons.edit, color: Colors.white),
          title: Text('Rename', style: TextStyle(color: Colors.white)),
        ),
      ),
      const PopupMenuItem(
        value: 'properties',
        child: ListTile(
          leading: Icon(Icons.info, color: Colors.white),
          title: Text('Properties', style: TextStyle(color: Colors.white)),
        ),
      ),
    ],
    color: Colors.transparent,
    elevation: 0,
  ).then((value) {
    if (value != null) {
      // Handle the selected action
      print('Selected: $value');
    }
  });
}
