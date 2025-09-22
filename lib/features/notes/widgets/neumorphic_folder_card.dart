import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/neumorphic_card.dart';

class NeumorphicFolderCard extends StatelessWidget {
  const NeumorphicFolderCard({super.key, required this.folder, this.onTap});

  final Folder folder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(folder.icon, size: 40, color: folder.color),
            const SizedBox(height: 16),
            Text(
              folder.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${folder.noteCount} notes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor?.withAlpha((255 * 0.7).round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
