import 'package:flutter/material.dart';

class AnnotationToolbar extends StatelessWidget {
  final Rect selectionRect;
  final VoidCallback onHighlight;
  final VoidCallback onUnderline;
  final VoidCallback onAddNote;

  const AnnotationToolbar({
    super.key,
    required this.selectionRect,
    required this.onHighlight,
    required this.onUnderline,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: selectionRect.top - 50,
      left: selectionRect.left,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.highlight),
              onPressed: onHighlight,
            ),
            IconButton(
              icon: const Icon(Icons.format_underlined), // Corrected icon name
              onPressed: onUnderline,
            ),
            IconButton(
              icon: const Icon(Icons.note_add),
              onPressed: onAddNote,
            ),
          ],
        ),
      ),
    );
  }
}
