import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:kivixa/components/canvas/canvas_gesture_detector.dart';
import 'package:kivixa/components/canvas/canvas_preview.dart';
import 'package:kivixa/components/theming/adaptive_icon.dart';
import 'package:kivixa/data/editor/editor_core_info.dart';
import 'package:kivixa/data/editor/page.dart';
import 'package:kivixa/i18n/strings.g.dart';

class EditorPageManager extends StatefulWidget {
  const EditorPageManager({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.redrawAndSave,
    required this.insertPageAfter,
    required this.duplicatePage,
    required this.clearPage,
    required this.deletePage,
    required this.transformationController,
  });

  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final VoidCallback redrawAndSave;

  final void Function(int, {PageOrientation? orientation}) insertPageAfter;
  final void Function(int) duplicatePage;
  final void Function(int) clearPage;
  final void Function(int) deletePage;

  final TransformationController transformationController;

  @override
  State<EditorPageManager> createState() => _EditorPageManagerState();
}

class _EditorPageManagerState extends State<EditorPageManager> {
  void scrollToPage(int pageIndex) => CanvasGestureDetector.scrollToPage(
    pageIndex: pageIndex,
    pages: widget.coreInfo.pages,
    screenWidth: MediaQuery.sizeOf(context).width,
    transformationController: widget.transformationController,
  );

  Future<void> _showInsertPageDialog(int pageIndex) async {
    // Get current page orientation as default
    final currentOrientation =
        pageIndex >= 0 && pageIndex < widget.coreInfo.pages.length
        ? widget.coreInfo.pages[pageIndex].orientation
        : PageOrientation.portrait;

    final result = await showDialog<PageOrientation>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editor.menu.insertPage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.editor.menu.choosePageOrientation),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OrientationOption(
                  orientation: PageOrientation.portrait,
                  isSelected: currentOrientation == PageOrientation.portrait,
                  onTap: () => Navigator.pop(context, PageOrientation.portrait),
                ),
                _OrientationOption(
                  orientation: PageOrientation.landscape,
                  isSelected: currentOrientation == PageOrientation.landscape,
                  onTap: () =>
                      Navigator.pop(context, PageOrientation.landscape),
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
      ),
    );

    if (result != null) {
      setState(() {
        widget.insertPageAfter(pageIndex, orientation: result);
        scrollToPage(pageIndex + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final cupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return SizedBox(
      width: cupertino ? null : 300,
      height: cupertino ? 600 : null,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: widget.coreInfo.pages.length,
        itemBuilder: (context, pageIndex) {
          final isEmptyLastPage =
              pageIndex == widget.coreInfo.pages.length - 1 &&
              widget.coreInfo.pages[pageIndex].isEmpty;
          return InkWell(
            key: ValueKey(pageIndex),
            onTap: () => scrollToPage(pageIndex),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${pageIndex + 1} / ${widget.coreInfo.pages.length}',
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: cupertino ? 100 : 150,
                          maxHeight: 250,
                        ),
                        child: FittedBox(
                          child: CanvasPreview(
                            pageIndex: pageIndex,
                            height: null,
                            coreInfo: widget.coreInfo,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: ReorderableDragStartListener(
                          index: pageIndex,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: t.editor.menu.insertPage,
                        icon: const AdaptiveIcon(
                          icon: Icons.note_add,
                          cupertinoIcon: CupertinoIcons.doc_on_doc,
                        ),
                        onPressed: () => _showInsertPageDialog(pageIndex),
                      ),
                      IconButton(
                        tooltip: t.editor.menu.duplicatePage,
                        icon: const AdaptiveIcon(
                          icon: Icons.content_copy,
                          cupertinoIcon: CupertinoIcons.doc_on_clipboard,
                        ),
                        onPressed: () => setState(() {
                          widget.duplicatePage(pageIndex);
                          scrollToPage(pageIndex + 1);
                        }),
                      ),
                      IconButton(
                        tooltip: t.editor.menu.clearPage(
                          page: pageIndex + 1,
                          totalPages: widget.coreInfo.pages.length,
                        ),
                        icon: const AdaptiveIcon(
                          icon: Icons.layers_clear,
                          cupertinoIcon: CupertinoIcons.paintbrush,
                        ),
                        onPressed: isEmptyLastPage
                            ? null
                            : () => setState(() {
                                widget.clearPage(pageIndex);
                                scrollToPage(pageIndex);
                              }),
                      ),
                      IconButton(
                        tooltip: t.editor.menu.deletePage,
                        icon: const AdaptiveIcon(
                          icon: Icons.delete,
                          cupertinoIcon: CupertinoIcons.delete,
                        ),
                        onPressed: isEmptyLastPage
                            ? null
                            : () => setState(() {
                                widget.deletePage(pageIndex);
                                scrollToPage(pageIndex);
                              }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex == newIndex) return;
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          widget.coreInfo.pages.insert(
            newIndex,
            widget.coreInfo.pages.removeAt(oldIndex),
          );

          // reassign pageIndex of pages' strokes and images
          for (int i = 0; i < widget.coreInfo.pages.length; i++) {
            for (final stroke in widget.coreInfo.pages[i].strokes) {
              stroke.pageIndex = i;
            }
            for (final image in widget.coreInfo.pages[i].images) {
              image.pageIndex = i;
            }
          }

          widget.redrawAndSave();
        },
      ),
    );
  }
}

/// Widget for displaying a page orientation option in the dialog.
class _OrientationOption extends StatelessWidget {
  const _OrientationOption({
    required this.orientation,
    required this.isSelected,
    required this.onTap,
  });

  final PageOrientation orientation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final isPortrait = orientation == PageOrientation.portrait;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: isPortrait ? 40 : 56,
              height: isPortrait ? 56 : 40,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.onSurface),
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.surface,
              ),
              child: Icon(
                isPortrait ? Icons.crop_portrait : Icons.crop_landscape,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPortrait ? t.editor.menu.portrait : t.editor.menu.landscape,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : null,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
