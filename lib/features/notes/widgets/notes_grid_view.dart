import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card_shimmer.dart';

class NotesGridView extends StatelessWidget {
  const NotesGridView({super.key, required this.folders, this.isLoading = false});

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

        return AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: crossAxisCount,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: ModernFolderCard(folder: folders[index]),
                  ),
                ),
              );
            },
          ),
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