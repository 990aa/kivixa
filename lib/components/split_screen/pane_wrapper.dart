import 'package:flutter/material.dart';
import 'package:kivixa/components/split_screen/embedded_file_browser.dart';
import 'package:kivixa/components/split_screen/split_screen_state.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/markdown/advanced_markdown_editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

/// A wrapper widget for a single pane in the split screen
class PaneWrapper extends StatelessWidget {
  const PaneWrapper({
    super.key,
    required this.paneState,
    required this.isRightPane,
    required this.onClose,
    required this.onTap,
    this.showCloseButton = true,
    this.showFileBrowserWhenEmpty = false,
    this.onFileSelected,
  });

  final PaneState paneState;
  final bool isRightPane;
  final VoidCallback onClose;
  final VoidCallback onTap;
  final bool showCloseButton;
  final bool showFileBrowserWhenEmpty;
  final void Function(String filePath)? onFileSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: paneState.isActive
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Positioned.fill(child: _buildContent(context)),
            // Close button and pane indicator
            if (showCloseButton && !paneState.isEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Active indicator
                    if (paneState.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Close button
                    Material(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (paneState.isEmpty) {
      return _buildEmptyPane(context);
    }

    final filePath = paneState.filePath!;

    switch (paneState.fileType) {
      case PaneFileType.handwritten:
        return Editor(path: filePath);
      case PaneFileType.markdown:
        return AdvancedMarkdownEditor(filePath: filePath);
      case PaneFileType.textDocument:
        return TextFileEditor(filePath: filePath);
      case PaneFileType.none:
        return _buildEmptyPane(context);
    }
  }

  Widget _buildEmptyPane(BuildContext context) {
    // If showFileBrowserWhenEmpty is true, show the embedded file browser
    if (showFileBrowserWhenEmpty && onFileSelected != null) {
      return EmbeddedFileBrowser(onFileSelected: onFileSelected!);
    }

    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_add,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Open a file in this pane',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRightPane ? 'Right pane' : 'Left pane',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simplified pane for file selection (used in file browser)
class FileSelectorPane extends StatelessWidget {
  const FileSelectorPane({
    super.key,
    required this.onFileSelected,
    this.currentPath,
  });

  final void Function(String filePath) onFileSelected;
  final String? currentPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a file to open',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the file browser to select a file',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
