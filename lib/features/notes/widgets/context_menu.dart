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
      CustomPopupMenuItem(
        value: 'create',
        child: const ListTile(
          leading: Icon(Icons.create_new_folder, color: Colors.white),
          title: Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ),
      CustomPopupMenuItem(
        value: 'delete',
        child: const ListTile(
          leading: Icon(Icons.delete, color: Colors.white),
          title: Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ),
      CustomPopupMenuItem(
        value: 'move',
        child: const ListTile(
          leading: Icon(Icons.move_to_inbox, color: Colors.white),
          title: Text('Move', style: TextStyle(color: Colors.white)),
        ),
      ),
      CustomPopupMenuItem(
        value: 'rename',
        child: const ListTile(
          leading: Icon(Icons.edit, color: Colors.white),
          title: Text('Rename', style: TextStyle(color: Colors.white)),
        ),
      ),
      CustomPopupMenuItem(
        value: 'properties',
        child: const ListTile(
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

class CustomPopupMenuItem<T> extends PopupMenuItem<T> {
  const CustomPopupMenuItem({
    super.key,
    required T super.value,
    required Widget super.child,
  });

  @override
  _CustomPopupMenuItemState<T> createState() => _CustomPopupMenuItemState<T>();
}

class _CustomPopupMenuItemState<T> extends PopupMenuItemState<T, CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: 200,
      height: 50,
      borderRadius: 10,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.1),
          const Color(0xFFFFFFFF).withOpacity(0.05),
        ],
        stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.5),
          const Color(0xFFFFFFFF).withOpacity(0.5),
        ],
      ),
      child: widget.child,
    );
  }
}