import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/home/new_folder_dialog.dart';
import 'package:kivixa/data/editor/page.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/editor/editor.dart';

class NewNoteButton extends StatefulWidget {
  const NewNoteButton({
    super.key,
    required this.cupertino,
    this.path,
    this.createFolder,
    this.doesFolderExist,
  });

  final bool cupertino;
  final String? path;
  final void Function(String, {Color? color})? createFolder;
  final bool Function(String)? doesFolderExist;

  @override
  State<NewNoteButton> createState() => _NewNoteButtonState();
}

class _NewNoteButtonState extends State<NewNoteButton> {
  final ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  Future<void> _createHandwrittenNote() async {
    // Show orientation dialog
    final orientation = await showDialog<PageOrientation>(
      context: context,
      builder: (context) => _PageOrientationDialog(),
    );

    if (orientation == null || !mounted) return;

    final isLandscape = orientation == PageOrientation.landscape;

    if (widget.path == null) {
      context.push('${RoutePaths.edit}?landscape=$isLandscape');
    } else {
      final newFilePath = await FileManager.newFilePath('${widget.path}/');
      if (!mounted) return;
      context.push(
        RoutePaths.editFilePath(newFilePath, landscape: isLandscape),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      spacing: 3,
      mini: true,
      openCloseDial: isDialOpen,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 4,
      switchLabelPosition: Directionality.of(context) == TextDirection.rtl,
      dialRoot: (ctx, open, toggleChildren) {
        return FloatingActionButton(
          shape: widget.cupertino ? const CircleBorder() : null,
          onPressed: toggleChildren,
          tooltip: t.home.tooltips.newNote,
          child: const Icon(Icons.add),
        );
      },
      children: [
        SpeedDialChild(
          child: const Icon(Icons.draw),
          label: 'New Handwritten Note',
          onTap: _createHandwrittenNote,
        ),
        SpeedDialChild(
          child: const Icon(Icons.article),
          label: 'New Text File',
          onTap: () async {
            if (widget.path == null) {
              context.push(RoutePaths.textFile);
            } else {
              final basePath = await FileManager.newFilePath('${widget.path}/');
              if (!context.mounted) return;
              context.push(RoutePaths.textFilePath(basePath));
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.description),
          label: 'New Markdown Note',
          onTap: () async {
            if (widget.path == null) {
              context.push(RoutePaths.markdown);
            } else {
              final basePath = await FileManager.newFilePath('${widget.path}/');
              // Append .md extension for markdown notes
              final newFilePath = '$basePath.md';
              if (!context.mounted) return;
              context.push(RoutePaths.markdownFilePath(newFilePath));
            }
          },
        ),
        if (widget.createFolder != null && widget.doesFolderExist != null)
          SpeedDialChild(
            child: const Icon(Icons.create_new_folder),
            label: t.home.newFolder.newFolder,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => NewFolderDialog(
                  createFolder: widget.createFolder!,
                  doesFolderExist: widget.doesFolderExist!,
                ),
              );
            },
          ),
        SpeedDialChild(
          child: const Icon(Icons.note_add),
          label: t.home.create.importNote,
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
              withData: false,
            );
            if (result == null) return;

            final filePath = result.files.single.path;
            final fileName = result.files.single.name;
            if (filePath == null) return;

            if (filePath.toLowerCase().endsWith('.kvx') ||
                filePath.toLowerCase().endsWith('.kvx') ||
                filePath.toLowerCase().endsWith('.kvx ')) {
              final path = await FileManager.importFile(
                filePath,
                '${widget.path ?? ''}/',
              );
              if (path == null) return;
              if (!context.mounted) return;

              context.push(RoutePaths.editFilePath(path));
            } else if (filePath.toLowerCase().endsWith('.pdf')) {
              if (!Editor.canRasterPdf) return;
              if (!mounted) return;

              final fileNameWithoutExtension = fileName.substring(
                0,
                fileName.length - '.pdf'.length,
              );
              final kvxFilePath =
                  await FileManager.suffixFilePathToMakeItUnique(
                    '${widget.path ?? ''}/$fileNameWithoutExtension',
                  );
              if (!context.mounted) return;

              context.push(RoutePaths.editImportPdf(kvxFilePath, filePath));
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.home.invalidFormat)));
              }
              throw 'Invalid file type';
            }
          },
        ),
      ],
    );
  }
}

/// Dialog for selecting page orientation when creating a new note.
class _PageOrientationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return AlertDialog(
      title: Text(t.editor.menu.choosePageOrientation),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OrientationOption(
                orientation: PageOrientation.portrait,
                onTap: () => Navigator.pop(context, PageOrientation.portrait),
                colorScheme: colorScheme,
              ),
              _OrientationOption(
                orientation: PageOrientation.landscape,
                onTap: () => Navigator.pop(context, PageOrientation.landscape),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}

class _OrientationOption extends StatelessWidget {
  const _OrientationOption({
    required this.orientation,
    required this.onTap,
    required this.colorScheme,
  });

  final PageOrientation orientation;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isPortrait = orientation == PageOrientation.portrait;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: isPortrait ? 50 : 70,
              height: isPortrait ? 70 : 50,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.onSurface, width: 2),
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.surface,
              ),
              child: Icon(
                isPortrait ? Icons.crop_portrait : Icons.crop_landscape,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPortrait ? t.editor.menu.portrait : t.editor.menu.landscape,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
