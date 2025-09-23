import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:kivixa/features/notes/screens/a4_drawing_page.dart';
import 'package:kivixa/features/notes/screens/notes_home_screen.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card_shimmer.dart';
import 'package:kivixa/features/notes/widgets/modern_note_card.dart';

class NotesGridView extends StatelessWidget {
  const NotesGridView({
    super.key,
    required this.items,
    this.isLoading = false,
    this.onRename,
    this.onMove,
    this.onDelete,
  });

  final List<dynamic> items;
  final bool isLoading;
  final void Function(dynamic item)? onRename;
  final void Function(dynamic item)? onMove;
  final void Function(dynamic item)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmer(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

        return MasonryGridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is Folder) {
              return ModernFolderCard(
                folder: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotesHomeScreen(folderId: item.id),
                    ),
                  );
                },
                onRename: () => onRename?.call(item),
                onMove: () => onMove?.call(item),
                onDelete: () => onDelete?.call(item),
              );
            } else if (item is NoteDocument) {
              return ModernNoteCard(
                note: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => A4DrawingPage(
                        noteName: item.title,
                        folderId: item.folderId,
                      ),
                    ),
                  );
                },
                onRename: () => onRename?.call(item),
                onMove: () => onMove?.call(item),
                onDelete: () => onDelete?.call(item),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) {
      return 6;
    } else if (width > 900) {
      return 5;
    } else if (width > 600) {
      return 4;
    } else if (width > 400) {
      return 3;
    } else {
      return 2;
    }
  }

  Widget _buildShimmer(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: 12, // Display a dozen shimmer cards
          itemBuilder: (context, index) {
            return const ModernFolderCardShimmer();
          },
        );
      },
    );
  }
}
