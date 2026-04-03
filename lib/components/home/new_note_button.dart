import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
import 'package:kivixa/pages/textfile/text_file_editor.dart';

enum ImportedNoteType { handwritten, pdf, markdown, text, docx, unsupported }

ImportedNoteType classifyImportedNoteType(String filePath) {
  final normalized = filePath.trim().toLowerCase();

  if (normalized.endsWith('.kvx') || normalized.endsWith('.kvx1')) {
    return ImportedNoteType.handwritten;
  }
  if (normalized.endsWith('.pdf')) {
    return ImportedNoteType.pdf;
  }
  if (normalized.endsWith('.md')) {
    return ImportedNoteType.markdown;
  }
  if (normalized.endsWith('.txt')) {
    return ImportedNoteType.text;
  }
  if (normalized.endsWith('.docx')) {
    return ImportedNoteType.docx;
  }
  return ImportedNoteType.unsupported;
}

String importedNoteBaseName(String filePath) {
  final fileName = filePath.split(RegExp(r'[\\/]')).last;
  final lastDot = fileName.lastIndexOf('.');
  if (lastDot <= 0) return fileName;
  return fileName.substring(0, lastDot);
}

Map<String, dynamic> buildTextNotePayload({
  required String fileName,
  required String content,
  DateTime? createdAt,
}) {
  final normalizedContent = content.endsWith('\n') ? content : '$content\n';
  return {
    'document': [
      {'insert': normalizedContent},
    ],
    'fileName': fileName,
    'version': 1,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };
}

String _decodeDocxXmlEntities(String value) {
  return value
      .replaceAll('&#xD;', '')
      .replaceAll('&#13;', '')
      .replaceAll('&#xA;', '\n')
      .replaceAll('&#10;', '\n')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

String extractPlainTextFromDocxBytes(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);
  final documentXml = archive.findFile('word/document.xml');
  if (documentXml == null || !documentXml.isFile) {
    throw const FormatException('Invalid DOCX: missing word/document.xml');
  }

  final xmlBytes = documentXml.content;
  final xml = utf8.decode(
    xmlBytes is List<int> ? xmlBytes : List<int>.from(xmlBytes as Iterable),
    allowMalformed: true,
  );

  final tokenPattern = RegExp(
    r'<w:t(?:\s[^>]*)?>(.*?)</w:t>|<w:tab\b[^>]*/>|<w:br\b[^>]*/>|</w:p>',
    dotAll: true,
  );

  final buffer = StringBuffer();
  for (final match in tokenPattern.allMatches(xml)) {
    final textContent = match.group(1);
    if (textContent != null) {
      buffer.write(_decodeDocxXmlEntities(textContent));
      continue;
    }

    final token = match.group(0)!;
    if (token.startsWith('<w:tab')) {
      buffer.write('\t');
    } else {
      buffer.write('\n');
    }
  }

  return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight();
}

Future<String> importTextLikeNoteAsCopy({
  required String sourcePath,
  required String destinationDir,
}) async {
  var safeDestinationDir = destinationDir;
  if (!safeDestinationDir.startsWith('/')) {
    safeDestinationDir = '/$safeDestinationDir';
  }
  if (!safeDestinationDir.endsWith('/')) {
    safeDestinationDir = '$safeDestinationDir/';
  }

  final baseName = importedNoteBaseName(sourcePath);
  final uniqueBasePath = await FileManager.suffixFilePathToMakeItUnique(
    '$safeDestinationDir$baseName',
  );

  final sourceBytes = await File(sourcePath).readAsBytes();
  final importedType = classifyImportedNoteType(sourcePath);

  final content = switch (importedType) {
    ImportedNoteType.docx => extractPlainTextFromDocxBytes(sourceBytes),
    _ => () {
      try {
        return utf8.decode(sourceBytes);
      } catch (_) {
        return latin1.decode(sourceBytes);
      }
    }(),
  };

  final payload = buildTextNotePayload(fileName: baseName, content: content);
  final encoded = utf8.encode(json.encode(payload));

  await FileManager.writeFile(
    '$uniqueBasePath${TextFileEditor.internalExtension}',
    encoded,
    awaitWrite: true,
  );

  return uniqueBasePath;
}

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

            final importedType = classifyImportedNoteType(filePath);
            final destinationDir = '${widget.path ?? ''}/';

            try {
              switch (importedType) {
                case ImportedNoteType.handwritten:
                  final importedPath = await FileManager.importFile(
                    filePath,
                    destinationDir,
                  );
                  if (importedPath == null || !context.mounted) return;

                  context.push(RoutePaths.editFilePath(importedPath));
                  return;

                case ImportedNoteType.pdf:
                  if (!Editor.canRasterPdf || !mounted) return;

                  final fileNameWithoutExtension = fileName.substring(
                    0,
                    fileName.length - '.pdf'.length,
                  );
                  final kvxFilePath =
                      await FileManager.suffixFilePathToMakeItUnique(
                        '$destinationDir$fileNameWithoutExtension',
                      );
                  if (!context.mounted) return;

                  context.push(RoutePaths.editImportPdf(kvxFilePath, filePath));
                  return;

                case ImportedNoteType.markdown:
                  final importedPath = await FileManager.importFile(
                    filePath,
                    destinationDir,
                    extension: '.md',
                  );
                  if (importedPath == null || !context.mounted) return;

                  context.push(RoutePaths.markdownFilePath(importedPath));
                  return;

                case ImportedNoteType.text:
                case ImportedNoteType.docx:
                  final importedPath = await importTextLikeNoteAsCopy(
                    sourcePath: filePath,
                    destinationDir: destinationDir,
                  );
                  if (!context.mounted) return;

                  context.push(RoutePaths.textFilePath(importedPath));
                  return;

                case ImportedNoteType.unsupported:
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.home.invalidFormat)),
                    );
                  }
                  return;
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: $e')),
                );
              }
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
