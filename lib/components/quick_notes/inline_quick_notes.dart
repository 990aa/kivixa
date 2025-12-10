import 'package:flutter/material.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';

/// A compact inline quick notes widget for the sidebar/browse page.
/// Shows current quick note and allows editing.
class InlineQuickNotes extends StatefulWidget {
  const InlineQuickNotes({super.key});

  @override
  State<InlineQuickNotes> createState() => _InlineQuickNotesState();
}

class _InlineQuickNotesState extends State<InlineQuickNotes> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  var _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentNote();
    QuickNotesService.instance.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    QuickNotesService.instance.removeListener(_onNotesChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    if (mounted) {
      _loadCurrentNote();
    }
  }

  void _loadCurrentNote() {
    final notes = QuickNotesService.instance.activeNotes;
    if (notes.isNotEmpty) {
      final note = notes.first;
      if (!note.isHandwritten && _controller.text != note.content) {
        _controller.text = note.content;
      }
    } else if (_controller.text.isNotEmpty) {
      _controller.clear();
    }
    if (mounted) setState(() {});
  }

  void _saveNote() {
    final text = _controller.text.trim();
    final notes = QuickNotesService.instance.activeNotes;

    if (text.isNotEmpty) {
      if (notes.isNotEmpty) {
        // Update existing note
        QuickNotesService.instance.updateNote(notes.first.id, content: text);
      } else {
        // Create new note
        QuickNotesService.instance.addNote(content: text);
      }
    }
  }

  void _clearNote() {
    QuickNotesService.instance.clearAllNotes();
    _controller.clear();
    setState(() {});
  }

  String _getTimeRemaining() {
    final notes = QuickNotesService.instance.activeNotes;
    if (notes.isEmpty) return '';

    final note = notes.first;
    final remaining = note.remainingTime(
      QuickNotesService.instance.autoDeleteDuration,
    );

    if (remaining == Duration.zero) return 'Expired';

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m left';
    }
    return 'Less than 1m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final notes = QuickNotesService.instance.activeNotes;
    final hasNote = notes.isNotEmpty;
    final note = hasNote ? notes.first : null;
    final isHandwriting = note?.isHandwritten ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick Note',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (hasNote) ...[
                      Text(
                        _getTimeRemaining(),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            if (_isExpanded) ...[
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isHandwriting) ...[
                      // Show handwriting preview
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.draw,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Handwritten note',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Text input
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Jot something down...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (_) => _saveNote(),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasNote) ...[
                          TextButton.icon(
                            onPressed: _clearNote,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (hasNote) ...[
              // Collapsed preview
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  isHandwriting
                      ? '✏️ Handwritten note'
                      : (note?.content ?? '').length > 50
                      ? '${(note?.content ?? '').substring(0, 50)}...'
                      : (note?.content ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
