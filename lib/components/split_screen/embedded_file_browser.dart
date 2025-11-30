import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

/// An embedded file browser for selecting files in split screen view
class EmbeddedFileBrowser extends StatefulWidget {
  const EmbeddedFileBrowser({
    super.key,
    required this.onFileSelected,
    this.initialPath,
  });

  final void Function(String filePath) onFileSelected;
  final String? initialPath;

  @override
  State<EmbeddedFileBrowser> createState() => _EmbeddedFileBrowserState();
}

class _EmbeddedFileBrowserState extends State<EmbeddedFileBrowser> {
  DirectoryChildren? children;
  String? currentPath;
  final List<String?> pathHistory = [];

  StreamSubscription? fileWriteSubscription;

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
    _loadDirectory();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      _fileWriteListener,
    );
  }

  @override
  void dispose() {
    fileWriteSubscription?.cancel();
    super.dispose();
  }

  void _fileWriteListener(FileOperation event) {
    if (!event.filePath.startsWith(currentPath ?? '/')) return;
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    children = await FileManager.getChildrenOfDirectory(currentPath ?? '/');
    if (mounted) setState(() {});
  }

  void _navigateToFolder(String folder) {
    if (folder == '..') {
      currentPath = pathHistory.isEmpty ? null : pathHistory.removeLast();
    } else {
      pathHistory.add(currentPath);
      currentPath = "${currentPath ?? ''}/$folder";
    }
    _loadDirectory();
  }

  void _navigateToPath(String? newPath) {
    if (newPath == null || newPath.isEmpty || newPath == '/') {
      newPath = null;
      pathHistory.clear();
    }
    pathHistory.add(currentPath);
    currentPath = newPath;
    _loadDirectory();
  }

  String _getFileTypeIcon(String filePath) {
    final fullPath = "${currentPath ?? ''}/$filePath";
    if (FileManager.doesFileExist('$fullPath${Editor.extension}')) {
      return 'handwritten';
    } else if (FileManager.doesFileExist('$fullPath.md')) {
      return 'markdown';
    } else if (FileManager.doesFileExist(
      '$fullPath${TextFileEditor.internalExtension}',
    )) {
      return 'text';
    }
    return 'unknown';
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'handwritten':
        return Icons.draw;
      case 'markdown':
        return Icons.description;
      case 'text':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileType, ColorScheme colorScheme) {
    switch (fileType) {
      case 'handwritten':
        return colorScheme.primary;
      case 'markdown':
        return colorScheme.tertiary;
      case 'text':
        return colorScheme.secondary;
      default:
        return colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Header with path
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select a file',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Breadcrumb path
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _navigateToPath(null),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Home',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (currentPath != null) ...[
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _buildPathSegments(colorScheme)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // File list
          Expanded(
            child: children == null
                ? const Center(child: CircularProgressIndicator())
                : children!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No files in this folder',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      // Back button if not at root
                      if (currentPath != null)
                        _buildListTile(
                          icon: Icons.arrow_back,
                          iconColor: colorScheme.onSurfaceVariant,
                          title: '..',
                          subtitle: 'Go back',
                          onTap: () => _navigateToFolder('..'),
                          colorScheme: colorScheme,
                        ),
                      // Folders
                      for (final folder in children!.directories)
                        _buildListTile(
                          icon: Icons.folder,
                          iconColor: colorScheme.primary,
                          title: folder,
                          subtitle: 'Folder',
                          onTap: () => _navigateToFolder(folder),
                          colorScheme: colorScheme,
                        ),
                      // Files
                      for (final file in children!.files)
                        _buildFileTile(file, colorScheme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPathSegments(ColorScheme colorScheme) {
    final segments = currentPath!.split('/').where((s) => s.isNotEmpty);
    final widgets = <Widget>[];
    final pathBuffer = StringBuffer();

    for (final segment in segments) {
      pathBuffer.write('/$segment');
      final pathToNavigate = pathBuffer.toString();

      widgets.add(
        InkWell(
          onTap: () => _navigateToPath(pathToNavigate),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              segment,
              style: TextStyle(color: colorScheme.primary, fontSize: 12),
            ),
          ),
        ),
      );

      if (segment != segments.last) {
        widgets.add(
          Icon(
            Icons.chevron_right,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFileTile(String fileName, ColorScheme colorScheme) {
    final fileType = _getFileTypeIcon(fileName);
    final fileTypeName = switch (fileType) {
      'handwritten' => 'Handwritten Note',
      'markdown' => 'Markdown Note',
      'text' => 'Text Document',
      _ => 'File',
    };

    return ListTile(
      dense: true,
      leading: Icon(
        _getFileIcon(fileType),
        color: _getFileIconColor(fileType, colorScheme),
      ),
      title: Text(
        fileName,
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        fileTypeName,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.open_in_new,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        final fullPath = "${currentPath ?? ''}/$fileName";
        widget.onFileSelected(fullPath);
      },
    );
  }
}
