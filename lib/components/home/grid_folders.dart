import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kivixa/components/home/delete_folder_button.dart';
import 'package:kivixa/components/home/folder_picker_dialog.dart';
import 'package:kivixa/components/home/rename_folder_button.dart';
import 'package:kivixa/components/theming/adaptive_icon.dart';
import 'package:kivixa/data/extensions/list_extensions.dart';
import 'package:kivixa/i18n/strings.g.dart';

class GridFolders extends StatelessWidget {
  const GridFolders({
    super.key,
    required this.isAtRoot,
    required this.onTap,
    required this.crossAxisCount,
    required this.doesFolderExist,
    required this.renameFolder,
    required this.isFolderEmpty,
    required this.deleteFolder,
    required this.folders,
    this.moveFolder,
    this.currentPath,
    this.selectedFolders,
    this.isMultiSelectMode = false,
    this.onFolderSelectionToggle,
  });

  final bool isAtRoot;
  final Function(String) onTap;
  final int crossAxisCount;

  final bool Function(String) doesFolderExist;
  final Future<void> Function(String oldName, String newName) renameFolder;
  final Future<bool> Function(String) isFolderEmpty;
  final Future<void> Function(String) deleteFolder;
  final Future<void> Function(String folderName, String destinationPath)?
      moveFolder;
  final String? currentPath;

  final List<String> folders;

  // Multi-select support
  final List<String>? selectedFolders;
  final bool isMultiSelectMode;
  final void Function(String folderName, bool selected)? onFolderSelectionToggle;

  @override
  Widget build(BuildContext context) {
    /// The cards that come before the actual folders
    final extraCards = <_FolderCardType>[
      if (!isAtRoot) _FolderCardType.backFolder,
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverAlignedGrid.count(
        itemCount: folders.length + extraCards.length,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        itemBuilder: (context, index) {
          final cardType =
              extraCards.getOrNull(index) ?? _FolderCardType.realFolder;
          final folderName = cardType == _FolderCardType.realFolder
              ? folders[index - extraCards.length]
              : null;
          return _GridFolder(
            cardType: cardType,
            folderName: folderName,
            doesFolderExist: doesFolderExist,
            renameFolder: renameFolder,
            isFolderEmpty: isFolderEmpty,
            deleteFolder: deleteFolder,
            moveFolder: moveFolder,
            currentPath: currentPath,
            onTap: onTap,
            isSelected: selectedFolders?.contains(folderName) ?? false,
            isMultiSelectMode: isMultiSelectMode,
            onSelectionToggle: onFolderSelectionToggle,
          );
        },
      ),
    );
  }
}

class _GridFolder extends StatefulWidget {
  const _GridFolder({
    // ignore: unused_element_parameter
    super.key,
    required this.cardType,
    required this.folderName,
    required this.doesFolderExist,
    required this.renameFolder,
    required this.isFolderEmpty,
    required this.deleteFolder,
    required this.onTap,
    this.moveFolder,
    this.currentPath,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onSelectionToggle,
  }) : assert(
         (folderName == null) ^ (cardType == _FolderCardType.realFolder),
         'Real folders must specify a folder name',
       );

  final _FolderCardType cardType;
  final String? folderName;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String oldName, String newName) renameFolder;
  final Future<bool> Function(String) isFolderEmpty;
  final Future<void> Function(String) deleteFolder;
  final Future<void> Function(String folderName, String destinationPath)?
      moveFolder;
  final String? currentPath;
  final Function(String) onTap;
  final bool isSelected;
  final bool isMultiSelectMode;
  final void Function(String folderName, bool selected)? onSelectionToggle;

  @override
  State<_GridFolder> createState() => _GridFolderState();
}

class _GridFolderState extends State<_GridFolder> {
  ValueNotifier<bool> expanded = ValueNotifier(false);

  void _handleTap() {
    // In multi-select mode, toggle selection instead of navigating
    if (widget.isMultiSelectMode &&
        widget.cardType == _FolderCardType.realFolder) {
      widget.onSelectionToggle?.call(widget.folderName!, !widget.isSelected);
      return;
    }

    if (expanded.value) return;
    switch (widget.cardType) {
      case _FolderCardType.backFolder:
        widget.onTap('..');
      case _FolderCardType.realFolder:
        widget.onTap(widget.folderName!);
    }
  }

  Future<void> _showMoveDialog(BuildContext context) async {
    final destinationFolder = await showDialog<String>(
      context: context,
      builder: (context) => FolderPickerDialog(
        currentPath: widget.currentPath,
      ),
    );

    if (destinationFolder == null) return;

    // Get the full path of the folder to move
    final folderPath = widget.currentPath?.isEmpty ?? true
        ? '/${widget.folderName!}'
        : '${widget.currentPath}/${widget.folderName!}';

    // Calculate new path
    final newPath = destinationFolder == '/'
        ? '/${widget.folderName!}'
        : '$destinationFolder/${widget.folderName!}';

    // Check if trying to move to same location
    if (folderPath == newPath) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder is already in this location')),
        );
      }
      return;
    }

    // Check if trying to move into itself or a subdirectory of itself
    if (newPath.startsWith('$folderPath/')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot move folder into itself or its subdirectory'),
          ),
        );
      }
      return;
    }

    await widget.moveFolder?.call(widget.folderName!, destinationFolder);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder moved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final cardElevatedColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.05),
      colorScheme.surface,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: widget.cardType == _FolderCardType.realFolder
            ? () {
                if (widget.isMultiSelectMode) {
                  widget.onSelectionToggle?.call(
                    widget.folderName!,
                    !widget.isSelected,
                  );
                } else {
                  expanded.value = !expanded.value;
                }
              }
            : null,
        onSecondaryTap: widget.cardType == _FolderCardType.realFolder
            ? () => expanded.value = !expanded.value
            : null,
        child: Card(
          color: widget.isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          elevation: widget.isSelected ? 4 : 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Center(
                        child: Tooltip(
                          message: switch (widget.cardType) {
                            _FolderCardType.backFolder => t.home.backFolder,
                            _FolderCardType.realFolder => '',
                          },
                          child: AdaptiveIcon(
                            icon: switch (widget.cardType) {
                              _FolderCardType.backFolder => Icons.folder_open,
                              _FolderCardType.realFolder => Icons.folder,
                            },
                            cupertinoIcon: switch (widget.cardType) {
                              _FolderCardType.backFolder =>
                                CupertinoIcons.folder_open,
                              _FolderCardType.realFolder =>
                                CupertinoIcons.folder_fill,
                            },
                            size: 50,
                          ),
                        ),
                      ),
                      // Selection indicator for multi-select mode
                      if (widget.isMultiSelectMode &&
                          widget.cardType == _FolderCardType.realFolder)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isSelected
                                  ? Icons.check
                                  : Icons.circle_outlined,
                              size: 16,
                              color: widget.isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      // Three-dot menu for real folders (only when not in multi-select mode)
                      if (widget.cardType == _FolderCardType.realFolder &&
                          !widget.isMultiSelectMode)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                size: 20,
                              ),
                              onSelected: (value) {
                                switch (value) {
                                  case 'rename':
                                    _showRenameDialog(context);
                                  case 'move':
                                    _showMoveDialog(context);
                                  case 'delete':
                                    _showDeleteDialog(context);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(t.common.rename),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'move',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.drive_file_move,
                                        size: 20,
                                        color: colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Move'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        t.common.delete,
                                        style: TextStyle(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Legacy expanded menu (keeping for backward compatibility with long-press/right-click)
                      if (widget.cardType == _FolderCardType.realFolder &&
                          !widget.isMultiSelectMode)
                        Positioned.fill(
                          child: ValueListenableBuilder(
                            valueListenable: expanded,
                            builder: (context, expanded, child) =>
                                AnimatedOpacity(
                                  opacity: expanded ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IgnorePointer(
                                    ignoring: !expanded,
                                    child: child!,
                                  ),
                                ),
                            child: GestureDetector(
                              onTap: () => expanded.value = !expanded.value,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      cardElevatedColor.withValues(alpha: 0.3),
                                      cardElevatedColor.withValues(alpha: 0.9),
                                      cardElevatedColor.withValues(alpha: 1),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    RenameFolderButton(
                                      folderName: widget.folderName!,
                                      doesFolderExist: widget.doesFolderExist,
                                      renameFolder: (String folderName) async {
                                        await widget.renameFolder(
                                          widget.folderName!,
                                          folderName,
                                        );
                                        expanded.value = false;
                                      },
                                    ),
                                    DeleteFolderButton(
                                      folderName: widget.folderName!,
                                      deleteFolder: (String folderName) async {
                                        await widget.deleteFolder(folderName);
                                        expanded.value = false;
                                      },
                                      isFolderEmpty: widget.isFolderEmpty,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                switch (widget.cardType) {
                  _FolderCardType.backFolder => const Icon(Icons.arrow_back),
                  _FolderCardType.realFolder => Text(widget.folderName!),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _RenameFolderDialog(
          folderName: widget.folderName!,
          doesFolderExist: widget.doesFolderExist,
          renameFolder: (String newName) async {
            await widget.renameFolder(widget.folderName!, newName);
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DeleteFolderDialog(
        folderName: widget.folderName!,
        deleteFolder: widget.deleteFolder,
        isFolderEmpty: widget.isFolderEmpty,
      ),
    );
  }
}

/// Dialog for renaming folders - used by the popup menu
class _RenameFolderDialog extends StatefulWidget {
  const _RenameFolderDialog({
    required this.folderName,
    required this.doesFolderExist,
    required this.renameFolder,
  });

  final String folderName;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String newName) renameFolder;

  @override
  State<_RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<_RenameFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  String? validateFolderName(String? folderName) {
    if (folderName == null || folderName.isEmpty) {
      return t.home.renameFolder.folderNameEmpty;
    }
    if (folderName.contains('/') || folderName.contains('\\')) {
      return t.home.renameFolder.folderNameContainsSlash;
    }
    if (folderName != widget.folderName && widget.doesFolderExist(folderName)) {
      return t.home.renameFolder.folderNameExists;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.folderName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.home.renameFolder.renameFolder),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.home.renameFolder.folderName,
            border: const OutlineInputBorder(),
          ),
          validator: validateFolderName,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(t.common.rename),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await widget.renameFolder(_controller.text);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

/// Dialog for deleting folders - used by the popup menu
class _DeleteFolderDialog extends StatefulWidget {
  const _DeleteFolderDialog({
    required this.folderName,
    required this.deleteFolder,
    required this.isFolderEmpty,
  });

  final String folderName;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  @override
  State<_DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<_DeleteFolderDialog> {
  var isFolderEmpty = false;
  var alsoDeleteContents = false;

  @override
  void initState() {
    super.initState();
    checkIfFolderIsEmpty();
  }

  Future<void> checkIfFolderIsEmpty() async {
    isFolderEmpty = await widget.isFolderEmpty(widget.folderName);
    if (isFolderEmpty) alsoDeleteContents = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final deleteAllowed = isFolderEmpty || alsoDeleteContents;
    return AlertDialog(
      title: Text(t.home.deleteFolder.deleteName(f: widget.folderName)),
      content: isFolderEmpty
          ? const SizedBox.shrink()
          : Row(
              children: [
                Checkbox(
                  value: alsoDeleteContents,
                  onChanged: isFolderEmpty
                      ? null
                      : (value) {
                          setState(() => alsoDeleteContents = value!);
                        },
                ),
                Expanded(child: Text(t.home.deleteFolder.alsoDeleteContents)),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: deleteAllowed
              ? () async {
                  await widget.deleteFolder(widget.folderName);
                  if (context.mounted) Navigator.of(context).pop();
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(t.common.delete),
        ),
      ],
    );
  }
}

enum _FolderCardType { backFolder, realFolder }
