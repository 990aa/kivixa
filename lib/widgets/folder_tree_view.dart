import 'package:flutter/material.dart';
import '../models/folder.dart';

/// Tree view widget for displaying hierarchical folder structure
///
/// Features:
/// - Recursive folder display with indentation
/// - Folder icons with custom colors
/// - Document count badges
/// - Long press for context menu
/// - Expandable/collapsible folders
class FolderTreeView extends StatefulWidget {
  final List<Folder> folders;
  final Function(Folder) onFolderSelected;
  final Function(Folder)? onFolderLongPress;
  final Folder? selectedFolder;
  final bool showDocumentCount;

  const FolderTreeView({
    super.key,
    required this.folders,
    required this.onFolderSelected,
    this.onFolderLongPress,
    this.selectedFolder,
    this.showDocumentCount = true,
  });

  @override
  State<FolderTreeView> createState() => _FolderTreeViewState();
}

class _FolderTreeViewState extends State<FolderTreeView> {
  final Set<int> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand root folders
    for (final folder in widget.folders) {
      if (folder.id != null) {
        _expandedFolders.add(folder.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No folders yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.folders.length,
      itemBuilder: (context, index) {
        return _buildFolderItem(context, widget.folders[index], 0);
      },
    );
  }

  Widget _buildFolderItem(BuildContext context, Folder folder, int level) {
    final hasSubfolders = folder.subfolders.isNotEmpty;
    final isExpanded =
        folder.id != null && _expandedFolders.contains(folder.id!);
    final isSelected = widget.selectedFolder?.id == folder.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => widget.onFolderSelected(folder),
          onLongPress: () => widget.onFolderLongPress?.call(folder),
          child: Container(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : null,
            padding: EdgeInsets.only(
              left: level * 24.0 + 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                // Expand/collapse button
                if (hasSubfolders)
                  GestureDetector(
                    onTap: () => _toggleExpanded(folder.id),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                  )
                else
                  const SizedBox(width: 20),

                const SizedBox(width: 8),

                // Folder icon
                Icon(
                  _getFolderIcon(folder, isExpanded),
                  color: folder.color ?? Colors.blue,
                  size: 24,
                ),

                const SizedBox(width: 12),

                // Folder name
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Document count badge
                if (widget.showDocumentCount && folder.documentCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${folder.documentCount}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                const SizedBox(width: 8),

                // More options button
                if (widget.onFolderLongPress != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => widget.onFolderLongPress?.call(folder),
                    tooltip: 'Folder options',
                  ),
              ],
            ),
          ),
        ),

        // Recursively build subfolders
        if (hasSubfolders && isExpanded)
          ...folder.subfolders.map(
            (subfolder) => _buildFolderItem(context, subfolder, level + 1),
          ),
      ],
    );
  }

  IconData _getFolderIcon(Folder folder, bool isExpanded) {
    if (folder.icon != null && folder.icon!.isNotEmpty) {
      // Custom icon support (if folder has icon field)
      switch (folder.icon) {
        case 'star':
          return Icons.star;
        case 'work':
          return Icons.work;
        case 'home':
          return Icons.home;
        case 'favorite':
          return Icons.favorite;
        default:
          break;
      }
    }

    // Default folder icons
    if (folder.subfolders.isEmpty) {
      return Icons.folder;
    }
    return isExpanded ? Icons.folder_open : Icons.folder;
  }

  void _toggleExpanded(int? folderId) {
    if (folderId == null) return;

    setState(() {
      if (_expandedFolders.contains(folderId)) {
        _expandedFolders.remove(folderId);
      } else {
        _expandedFolders.add(folderId);
      }
    });
  }
}

/// Folder context menu options
class FolderContextMenu extends StatelessWidget {
  final Folder folder;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onCreateSubfolder;
  final VoidCallback? onChangeColor;

  const FolderContextMenu({
    super.key,
    required this.folder,
    this.onRename,
    this.onDelete,
    this.onCreateSubfolder,
    this.onChangeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRename != null)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              onRename?.call();
            },
          ),
        if (onCreateSubfolder != null)
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('New Subfolder'),
            onTap: () {
              Navigator.pop(context);
              onCreateSubfolder?.call();
            },
          ),
        if (onChangeColor != null)
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Change Color'),
            onTap: () {
              Navigator.pop(context);
              onChangeColor?.call();
            },
          ),
        if (onDelete != null) const Divider(),
        if (onDelete != null)
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
      ],
    );
  }
}
