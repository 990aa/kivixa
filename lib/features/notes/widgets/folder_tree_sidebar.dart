import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/models/folder_tree_node.dart';

class FolderTreeSidebar extends StatelessWidget {
  const FolderTreeSidebar({super.key, required this.rootFolder});

  final Folder rootFolder;

  @override
  Widget build(BuildContext context) {
    final tree = FolderTreeNode.fromFolder(rootFolder);

    return TreeView.simple(
      tree: tree,
      showRootNode: true,
      expansionIndicatorBuilder: (context, node) =>
          ChevronIndicator.rightDown(
        tree: node,
        color: Colors.white,
      ),
      indentation: const Indentation(width: 20),
      builder: (context, node) => Card(
        color: Colors.white.withOpacity(0.1),
        child: ListTile(
          title: Text(
            node.data!.name,
            style: const TextStyle(color: Colors.white),
          ),
          leading: Icon(
            node.data!.icon,
            color: Colors.white,
          ),
          onTap: () {
            // Handle folder selection
          },
        ),
      ),
    );
  }
}
