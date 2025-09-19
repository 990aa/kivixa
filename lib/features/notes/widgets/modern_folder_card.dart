import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:mix/mix.dart';

class ModernFolderCard extends StatelessWidget {
  const ModernFolderCard({super.key, required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final style = Style(
      $box.height(150),
      $box.width(150),
      $box.borderRadius.all(12),
      $box.padding.all(16),
      $box.shadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
      ),
      $box.border(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      $flex.mainAxisAlignment.spaceBetween(),
      $flex.crossAxisAlignment.start(),
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
        child: StyledColumn(
          style: style,
          children: [
            StyledIcon(
              folder.icon,
              style: Style($icon.color(Colors.white), $icon.size(40)),
            ),
            const Spacer(),
            StyledText(
              folder.name,
              style: Style(
                $text.style.color(Colors.white),
                $text.style.fontSize(16),
                $text.style.fontWeight.bold(),
                $text.maxLines(2),
                $text.overflow.ellipsis(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}