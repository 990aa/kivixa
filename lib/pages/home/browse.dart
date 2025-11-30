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
import 'package:kivixa/data/file_manager/file_manager.dart';
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

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  // Search, filter, and sort
  final _searchController = TextEditingController();
  var _isSearching = false;
  var _filterType = FileFilterType.all; // all, handwritten, markdown, text
  var _sortType = SortType.aToZ; // A-Z, Z-A, latest-oldest, oldest-latest

  @override
  void initState() {
    path = widget.initialPath;

    findChildrenOfPath();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);
    _searchController.addListener(_setState);

    super.initState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
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

    if (mounted) setState(() {});
  }

  void onDirectoryTap(String folder) {
    selectedFiles.value = [];
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

  DateTime _getFileModifiedTime(String filePath) {
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
                  expandedHeight: _isSearching ? kToolbarHeight : 200 - 8,
                  pinned: true,
                  scrolledUnderElevation: 1,
                  flexibleSpace: _isSearching
                      ? null
                      : FlexibleSpaceBar(
                          title: Text(
                            t.home.titles.browse,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          centerTitle: false,
                          titlePadding: const EdgeInsetsDirectional.only(
                            start: 16,
                            bottom: 8,
                          ),
                        ),
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
                    ],
                  ],
                ),
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
                  folders: [
                    for (final directoryPath
                        in children?.directories ?? const [])
                      directoryPath,
                  ],
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
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: NewNoteButton(
        cupertino: cupertino,
        path: path,
        createFolder: createFolder,
        doesFolderExist: (String folderName) {
          return children?.directories.contains(folderName) ?? false;
        },
      ),
      persistentFooterButtons: selectedFiles.value.isEmpty
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
              ExportNoteButton(selectedFiles: selectedFiles.value),
            ],
    );
  }
}

enum FileFilterType { all, handwritten, markdown, text }

enum SortType { aToZ, zToA, latestFirst, oldestFirst }
