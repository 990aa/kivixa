import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/notes_home_screen.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card_shimmer.dart';

class NotesGridView extends StatelessWidget {
  const NotesGridView({
    super.key,
    required this.folders,
    this.isLoading = false,
  });

  final List<Folder> folders;
  final bool isLoading;

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
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotesHomeScreen(folderId: folder.id),
                  ),
                );
              },
              child: ModernFolderCard(folder: folder),
            );
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
