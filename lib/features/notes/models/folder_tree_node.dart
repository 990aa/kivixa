import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'folder_model.dart';

class FolderTreeNode extends TreeNode<Folder> {
  FolderTreeNode(Folder data) : super(key: data.id, data: data);

  static FolderTreeNode fromFolder(Folder folder) {
    final node = FolderTreeNode(folder);
    if (folder.subFolders.isNotEmpty) {
      for (final subFolder in folder.subFolders) {
        node.add(fromFolder(subFolder));
      }
    }
    return node;
  }
}
