import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:mix/mix.dart';

class ModernFolderCard extends StatelessWidget {
  const ModernFolderCard({super.key, required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final style = Mix(
      height(150),
      width(150),
      rounded(12),
      padding(16),
      shadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
      ),
      border(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );

    return Pressable(
      onPress: () {
        // Handle folder tap
      },
      child: GlassmorphicContainer(
        width: 150,
        height: 150,
        borderRadius: 12,
        blur: 10,
        alignment: Alignment.bottomCenter,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            folder.color.withOpacity(0.1),
            folder.color.withOpacity(0.2),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.5),
          ],
        ),
        child: Style(
          $with: style,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                folder.icon,
                color: Colors.white,
                size: 40,
              ),
              const Spacer(),
              Text(
                folder.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
