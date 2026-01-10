import 'dart:async';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/home/export_note_button.dart';
import 'package:kivixa/components/home/grid_folders.dart';
import 'package:kivixa/components/home/masonry_files.dart';
import 'package:kivixa/components/home/move_note_button.dart';
import 'package:kivixa/components/home/new_note_button.dart';
import 'package:kivixa/components/home/no_files.dart';
import 'package:kivixa/components/home/path_components.dart';
import 'package:kivixa/components/home/rename_note_button.dart';
import 'package:kivixa/components/quick_notes/inline_quick_notes.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({
    super.key,
    String? path,
    @visibleForTesting this.overrideChildren,
  }) : initialPath = path;

  final String? initialPath;
  final DirectoryChildren? overrideChildren;

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  DirectoryChildren? children;

  final List<String?> pathHistory = [];
  String? path;

  final selectedFiles = ValueNotifier<List<String>>([]);

  // Multi-select mode for folders
  final selectedFolders = ValueNotifier<List<String>>([]);
  var _isMultiSelectMode = false;

  // Search, filter, and sort
  final _searchController = TextEditingController();
  var _isSearching = false;
  var _filterType = FileFilterType.all; // all, handwritten, markdown, text
  var _sortType = SortType.aToZ; // A-Z, Z-A, latest-oldest, oldest-latest

  // PERFORMANCE FIX: Cache file modification times to avoid sync I/O during sort
  final Map<String, DateTime> _fileModTimeCache = {};

  @override
  void initState() {
    path = widget.initialPath;

    // Load persisted sort preference
    _loadSortPreference();

    findChildrenOfPath();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);
    selectedFolders.addListener(_setState);
    _searchController.addListener(_setState);

    super.initState();
  }

  void _loadSortPreference() {
    final savedSort = stows.browseSortType.value;
    _sortType = SortType.values[savedSort.clamp(0, SortType.values.length - 1)];
  }

  void _saveSortPreference(SortType type) {
    stows.browseSortType.value = type.index;
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
    selectedFolders.removeListener(_setState);
    _searchController.removeListener(_setState);
    _searchController.dispose();
    fileWriteSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    if (!event.filePath.startsWith(path ?? '/')) return;
    findChildrenOfPath(fromFileListener: true);
  }

  void _setState() => setState(() {});

  Future findChildrenOfPath({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      // don't refresh if we're not on the home page
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith(RoutePaths.prefixOfHome)) return;
    }

    children =
        widget.overrideChildren ??
        await FileManager.getChildrenOfDirectory(path ?? '/');

    // PERFORMANCE FIX: Clear and pre-populate file modification time cache
    _fileModTimeCache.clear();
    if (children != null) {
      for (final file in children!.files) {
        final filePath = "${path ?? ""}/$file";
        _fileModTimeCache[filePath] = _computeFileModifiedTime(filePath);
      }
    }

    if (mounted) setState(() {});
  }

  void onDirectoryTap(String folder) {
    selectedFiles.value = [];
    selectedFolders.value = [];
    _isMultiSelectMode = false;
    if (folder == '..') {
      path = pathHistory.isEmpty ? null : pathHistory.removeLast();
    } else {
      pathHistory.add(path);
      path = "${path ?? ''}/$folder";
    }
    context.go(HomeRoutes.browseFilePath(path ?? '/'));
    findChildrenOfPath();
  }

  void onPathComponentTap(String? newPath) {
    selectedFiles.value = [];
    selectedFolders.value = [];
    _isMultiSelectMode = false;
    if (newPath == null || newPath.isEmpty || newPath == '/') {
      newPath = null;
      pathHistory.clear();
    }
    pathHistory.add(path);
    path = newPath;
    context.go(HomeRoutes.browseFilePath(path ?? '/'));
    findChildrenOfPath();
  }

  Future<void> createFolder(String folderName) async {
    final folderPath = '${path ?? ''}/$folderName';
    await FileManager.createFolder(folderPath);
    findChildrenOfPath();
  }

  // Toggle multi-select mode
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        selectedFiles.value = [];
        selectedFolders.value = [];
      }
    });
  }

  // Toggle folder selection
  void _toggleFolderSelection(String folderName, bool selected) {
    if (selected) {
      selectedFolders.value = [...selectedFolders.value, folderName];
    } else {
      selectedFolders.value =
          selectedFolders.value.where((f) => f != folderName).toList();
    }
  }

  // Get total number of selected items
  int get _totalSelectedCount =>
      selectedFiles.value.length + selectedFolders.value.length;

  // Check if anything is selected
  bool get _hasSelection => _totalSelectedCount > 0;

  // Delete all selected items
  Future<void> _deleteAllSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        selectedFiles: selectedFiles.value,
        selectedFolders: selectedFolders.value,
        currentPath: path,
      ),
    );

    if (confirmed ?? false) {
      // Delete files first
      for (final filePath in selectedFiles.value) {
        try {
          final oldExtension = FileManager.doesFileExist(
            filePath + Editor.extensionOldJson,
          );
          await FileManager.deleteFile(
            filePath +
                (oldExtension ? Editor.extensionOldJson : Editor.extension),
          );
        } catch (e) {
          // Try other extensions
          if (FileManager.doesFileExist('$filePath.md')) {
            await FileManager.deleteFile('$filePath.md');
          } else if (FileManager.doesFileExist(
            '$filePath${TextFileEditor.internalExtension}',
          )) {
            await FileManager.deleteFile(
              '$filePath${TextFileEditor.internalExtension}',
            );
          }
        }
      }

      // Delete folders
      for (final folderName in selectedFolders.value) {
        final folderPath = '${path ?? ''}/$folderName';
        await FileManager.deleteDirectory(folderPath);
      }

      // Clear selections and exit multi-select mode
      selectedFiles.value = [];
      selectedFolders.value = [];
      _isMultiSelectMode = false;
      findChildrenOfPath();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items deleted successfully')),
        );
      }
    }
  }

  // Group selected items into a new folder
  Future<void> _groupSelectedItems() async {
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => _NewFolderDialog(
        doesFolderExist: (name) =>
            children?.directories.contains(name) ?? false,
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      final newFolderPath = '${path ?? ''}/$folderName';

      // Create the new folder
      await FileManager.createFolder(newFolderPath);

      // Move all selected files to the new folder
      for (final filePath in selectedFiles.value) {
        final fileName = filePath.split('/').last;
        try {
          final oldExtension = FileManager.doesFileExist(
            filePath + Editor.extensionOldJson,
          );
          await FileManager.moveFile(
            filePath +
                (oldExtension ? Editor.extensionOldJson : Editor.extension),
            '$newFolderPath/$fileName${oldExtension ? Editor.extensionOldJson : Editor.extension}',
          );
        } catch (e) {
          // Try other extensions
          if (FileManager.doesFileExist('$filePath.md')) {
            await FileManager.moveFile(
              '$filePath.md',
              '$newFolderPath/$fileName.md',
            );
          } else if (FileManager.doesFileExist(
            '$filePath${TextFileEditor.internalExtension}',
          )) {
            await FileManager.moveFile(
              '$filePath${TextFileEditor.internalExtension}',
              '$newFolderPath/$fileName${TextFileEditor.internalExtension}',
            );
          }
        }
      }

      // Move all selected folders to the new folder
      for (final folderToMove in selectedFolders.value) {
        final sourcePath = '${path ?? ''}/$folderToMove';
        final destPath = '$newFolderPath/$folderToMove';
        await FileManager.moveDirectory(sourcePath, destPath);
      }

      // Clear selections and exit multi-select mode
      selectedFiles.value = [];
      selectedFolders.value = [];
      _isMultiSelectMode = false;
      findChildrenOfPath();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Items grouped into folder "$folderName"')),
        );
      }
    }
  }

  // Move a folder to a new location
  Future<void> _moveFolder(String folderName, String destinationPath) async {
    final sourcePath = '${path ?? ''}/$folderName';
    final newPath = destinationPath == '/'
        ? '/$folderName'
        : '$destinationPath/$folderName';

    await FileManager.moveDirectory(sourcePath, newPath);
    findChildrenOfPath();
  }

  List<String> _getFilteredAndSortedFiles() {
    if (children == null) return [];

    var files = children!.files.toList();
    final searchQuery = _searchController.text.toLowerCase();

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      files = files.where((file) {
        return file.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Apply file type filter
    switch (_filterType) {
      case FileFilterType.handwritten:
        files = files.where((file) {
          // Check if .kvx file exists
          final fullPath = "${path ?? ""}/$file";
          return FileManager.doesFileExist('$fullPath${Editor.extension}');
        }).toList();
      case FileFilterType.markdown:
        files = files.where((file) {
          // Check if .md file exists
          final fullPath = "${path ?? ""}/$file";
          return FileManager.doesFileExist('$fullPath.md');
        }).toList();
      case FileFilterType.text:
        files = files.where((file) {
          // Check if .kvtx file exists
          final fullPath = "${path ?? ""}/$file";
          return FileManager.doesFileExist(
            '$fullPath${TextFileEditor.internalExtension}',
          );
        }).toList();
      case FileFilterType.all:
    }

    // Apply sorting
    switch (_sortType) {
      case SortType.aToZ:
        files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      case SortType.zToA:
        files.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
      case SortType.latestFirst:
        files.sort((a, b) {
          final aPath = "${path ?? ""}/$a";
          final bPath = "${path ?? ""}/$b";
          final aTime = _getFileModifiedTime(aPath);
          final bTime = _getFileModifiedTime(bPath);
          return bTime.compareTo(aTime); // Latest first
        });
      case SortType.oldestFirst:
        files.sort((a, b) {
          final aPath = "${path ?? ""}/$a";
          final bPath = "${path ?? ""}/$b";
          final aTime = _getFileModifiedTime(aPath);
          final bTime = _getFileModifiedTime(bPath);
          return aTime.compareTo(bTime); // Oldest first
        });
    }
    return files;
  }

  /// PERFORMANCE FIX: Use cached modification time for fast sorting
  DateTime _getFileModifiedTime(String filePath) {
    return _fileModTimeCache[filePath] ?? _computeFileModifiedTime(filePath);
  }

  /// Actually query file system for modification time (called once per file when loading)
  DateTime _computeFileModifiedTime(String filePath) {
    try {
      // Check .kvx file first, then .md, then .kvtx
      if (FileManager.doesFileExist('$filePath${Editor.extension}')) {
        return FileManager.lastModified('$filePath${Editor.extension}');
      } else if (FileManager.doesFileExist('$filePath.md')) {
        return FileManager.lastModified('$filePath.md');
      } else if (FileManager.doesFileExist(
        '$filePath${TextFileEditor.internalExtension}',
      )) {
        return FileManager.lastModified(
          '$filePath${TextFileEditor.internalExtension}',
        );
      }
    } catch (e) {
      // Ignore errors
    }
    return DateTime(2000); // Default to old date if file doesn't exist
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    const cupertino = false;

    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300 + 1;

    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: SvgPicture.asset(
                    'assets/images/home_page.svg',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),
          // Main content
          RefreshIndicator(
            onRefresh: () => Future.wait([
              findChildrenOfPath(),
              Future.delayed(const Duration(milliseconds: 500)),
            ]),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  collapsedHeight: kToolbarHeight,
                  expandedHeight: kToolbarHeight,
                  pinned: true,
                  scrolledUnderElevation: 1,
                  flexibleSpace: null,
                  title: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search files...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          style: TextStyle(color: colorScheme.onSurface),
                        )
                      : null,
                  actions: [
                    if (_isSearching)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                          });
                        },
                        tooltip: 'Close search',
                      )
                    else ...[
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                        tooltip: 'Search',
                      ),
                      PopupMenuButton<FileFilterType>(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter',
                        onSelected: (FileFilterType type) {
                          setState(() {
                            _filterType = type;
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: FileFilterType.all,
                            child: Row(
                              children: [
                                if (_filterType == FileFilterType.all)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('All Files'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: FileFilterType.handwritten,
                            child: Row(
                              children: [
                                if (_filterType == FileFilterType.handwritten)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('Handwritten Notes'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: FileFilterType.markdown,
                            child: Row(
                              children: [
                                if (_filterType == FileFilterType.markdown)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('Markdown Notes'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: FileFilterType.text,
                            child: Row(
                              children: [
                                if (_filterType == FileFilterType.text)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('Text Notes'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<SortType>(
                        icon: const Icon(Icons.sort),
                        tooltip: 'Sort',
                        onSelected: (SortType type) {
                          setState(() {
                            _sortType = type;
                          });
                          _saveSortPreference(type);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: SortType.aToZ,
                            child: Row(
                              children: [
                                if (_sortType == SortType.aToZ)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('A-Z'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortType.zToA,
                            child: Row(
                              children: [
                                if (_sortType == SortType.zToA)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('Z-A'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortType.latestFirst,
                            child: Row(
                              children: [
                                if (_sortType == SortType.latestFirst)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('Latest First'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortType.oldestFirst,
                            child: Row(
                              children: [
                                if (_sortType == SortType.oldestFirst)
                                  const Icon(Icons.check, size: 20)
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                const Text('Oldest First'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Split View button
                      IconButton(
                        icon: const Icon(Icons.vertical_split),
                        tooltip: 'Split View',
                        onPressed: () {
                          context.push(RoutePaths.splitScreen);
                        },
                      ),
                      // Multi-select button
                      IconButton(
                        icon: Icon(
                          _isMultiSelectMode
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        tooltip:
                            _isMultiSelectMode ? 'Exit Selection' : 'Select',
                        onPressed: _toggleMultiSelectMode,
                      ),
                    ],
                  ],
                ),
                // Quick Notes section
                const SliverToBoxAdapter(child: InlineQuickNotes()),
                SliverToBoxAdapter(
                  child: PathComponents(
                    path,
                    onPathComponentTap: onPathComponentTap,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                GridFolders(
                  isAtRoot: path?.isEmpty ?? true,
                  crossAxisCount: crossAxisCount,
                  onTap: onDirectoryTap,
                  doesFolderExist: (String folderName) {
                    return children?.directories.contains(folderName) ?? false;
                  },
                  renameFolder: (String oldName, String newName) async {
                    final oldPath = '${path ?? ''}/$oldName';
                    await FileManager.renameDirectory(oldPath, newName);
                    findChildrenOfPath();
                  },
                  isFolderEmpty: (String folderName) async {
                    final folderPath = '${path ?? ''}/$folderName';
                    final children = await FileManager.getChildrenOfDirectory(
                      folderPath,
                    );
                    return children?.isEmpty ?? true;
                  },
                  deleteFolder: (String folderName) async {
                    final folderPath = '${path ?? ''}/$folderName';
                    await FileManager.deleteDirectory(folderPath);
                    findChildrenOfPath();
                  },
                  moveFolder: _moveFolder,
                  currentPath: path,
                  folders: [
                    for (final directoryPath
                        in children?.directories ?? const [])
                      directoryPath,
                  ],
                  selectedFolders: selectedFolders.value,
                  isMultiSelectMode: _isMultiSelectMode,
                  onFolderSelectionToggle: _toggleFolderSelection,
                ),
                if (children == null) ...[
                  // loading
                ] else if (children!.isEmpty) ...[
                  const SliverSafeArea(
                    sliver: SliverToBoxAdapter(child: NoFiles()),
                  ),
                ] else ...[
                  SliverSafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(
                      top: 8,
                      // Allow space for the FloatingActionButton
                      bottom: 70,
                    ),
                    sliver: MasonryFiles(
                      crossAxisCount: crossAxisCount,
                      files: [
                        for (final filePath in _getFilteredAndSortedFiles())
                          "${path ?? ""}/$filePath",
                      ],
                      selectedFiles: selectedFiles,
                      isMultiSelectMode: _isMultiSelectMode,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : NewNoteButton(
              cupertino: cupertino,
              path: path,
              createFolder: createFolder,
              doesFolderExist: (String folderName) {
                return children?.directories.contains(folderName) ?? false;
              },
            ),
      persistentFooterButtons: _isMultiSelectMode
          ? [
              // Multi-select mode footer buttons
              // Selection count indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_totalSelectedCount selected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              // Delete All button
              TextButton.icon(
                onPressed: _hasSelection ? _deleteAllSelected : null,
                icon: Icon(
                  Icons.delete_forever,
                  color: _hasSelection ? colorScheme.error : null,
                ),
                label: Text(
                  'Delete All',
                  style: TextStyle(
                    color: _hasSelection ? colorScheme.error : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Group button
              TextButton.icon(
                onPressed: _hasSelection ? _groupSelectedItems : null,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Group'),
              ),
            ]
          : selectedFiles.value.isEmpty
              ? null
              : [
                  Collapsible(
                    axis: CollapsibleAxis.vertical,
                    collapsed: selectedFiles.value.length != 1,
                    child: RenameNoteButton(
                      existingPath: selectedFiles.value.isEmpty
                          ? ''
                          : selectedFiles.value.first,
                      unselectNotes: () => selectedFiles.value = [],
                    ),
                  ),
                  MoveNoteButton(
                    filesToMove: selectedFiles.value,
                    unselectNotes: () => selectedFiles.value = [],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: t.home.deleteNote,
                    onPressed: () async {
                      await Future.wait([
                        for (final filePath in selectedFiles.value)
                          Future.value(
                            FileManager.doesFileExist(
                              filePath + Editor.extensionOldJson,
                            ),
                          ).then(
                            (oldExtension) => FileManager.deleteFile(
                              filePath +
                                  (oldExtension
                                      ? Editor.extensionOldJson
                                      : Editor.extension),
                            ),
                          ),
                      ]);
                      selectedFiles.value = [];
                    },
                    icon: const Icon(Icons.delete_forever),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Group to new folder',
                    onPressed: () async {
                      final folderName = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('New Folder'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Folder Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, controller.text),
                                child: const Text('Create'),
                              ),
                            ],
                          );
                        },
                      );

                      if (folderName != null && folderName.isNotEmpty) {
                        final newFolderPath = '${path ?? ''}/$folderName';
                        await FileManager.createFolder(newFolderPath);

                        await Future.wait([
                          for (final filePath in selectedFiles.value)
                            Future.value(
                              FileManager.doesFileExist(
                                filePath + Editor.extensionOldJson,
                              ),
                            ).then((oldExtension) async {
                              final fileName = filePath.split('/').last;
                              await FileManager.moveFile(
                                filePath +
                                    (oldExtension
                                        ? Editor.extensionOldJson
                                        : Editor.extension),
                                '$newFolderPath/$fileName${oldExtension ? Editor.extensionOldJson : Editor.extension}',
                              );
                            }),
                        ]);
                        selectedFiles.value = [];
                        findChildrenOfPath();
                      }
                    },
                    icon: const Icon(Icons.create_new_folder),
                  ),
                  ExportNoteButton(selectedFiles: selectedFiles.value),
                ],
    );
  }
}

/// Dialog for confirming deletion of selected items
class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog({
    required this.selectedFiles,
    required this.selectedFolders,
    this.currentPath,
  });

  final List<String> selectedFiles;
  final List<String> selectedFolders;
  final String? currentPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalItems = selectedFiles.length + selectedFolders.length;

    return AlertDialog(
      title: const Text('Delete Selected Items'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete $totalItems item${totalItems == 1 ? '' : 's'}?',
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'The following items will be permanently deleted:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final folder in selectedFolders)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                folder,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final file in selectedFiles)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: Text(t.common.delete),
        ),
      ],
    );
  }
}

/// Dialog for creating a new folder (used by Group function)
class _NewFolderDialog extends StatefulWidget {
  const _NewFolderDialog({required this.doesFolderExist});

  final bool Function(String) doesFolderExist;

  @override
  State<_NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<_NewFolderDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateFolderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Folder name cannot be empty';
    }
    if (value.contains('/') || value.contains('\\')) {
      return 'Folder name cannot contain slashes';
    }
    if (widget.doesFolderExist(value)) {
      return 'A folder with this name already exists';
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Group into New Folder'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          validator: _validateFolderName,
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
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text);
    }
  }
}

enum FileFilterType { all, handwritten, markdown, text }

enum SortType { aToZ, zToA, latestFirst, oldestFirst }
