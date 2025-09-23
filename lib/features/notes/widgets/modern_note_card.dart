import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/note_document.dart';

class ModernNoteCard extends StatelessWidget {
  const ModernNoteCard({
    super.key,
    required this.note,
    this.onTap,
  });

  final NoteDocument note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note, size: 40),
              const SizedBox(height: 8),
              Text(
                note.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Created: ${note.createdAt.toLocal().toString().split(' ')[0]}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
