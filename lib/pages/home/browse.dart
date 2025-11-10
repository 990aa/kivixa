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

  @override
  void initState() {
    path = widget.initialPath;

    findChildrenOfPath();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);

    super.initState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
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
                  expandedHeight: 200 - 8,
                  pinned: true,
                  scrolledUnderElevation: 1,
                  flexibleSpace: FlexibleSpaceBar(
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
                  createFolder: createFolder,
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
                        for (final filePath in children?.files ?? const [])
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
      floatingActionButton: NewNoteButton(cupertino: cupertino, path: path),
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
