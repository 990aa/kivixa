import 'package:flutter/material.dart';
import 'package:kivixa/components/quick_notes/quick_note_canvas.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';

/// A compact inline quick notes widget for the sidebar/browse page.
/// Shows all quick notes side by side with newest on the left.
class InlineQuickNotes extends StatefulWidget {
  const InlineQuickNotes({super.key});

  @override
  State<InlineQuickNotes> createState() => _InlineQuickNotesState();
}

class _InlineQuickNotesState extends State<InlineQuickNotes> {
  var _isExpanded = false;
  var _isAddingNew = false;
  var _isHandwritingMode = false;
  final _textController = TextEditingController();
  final _canvasKey = GlobalKey<QuickNoteCanvasState>();

  @override
  void initState() {
    super.initState();
    QuickNotesService.instance.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    QuickNotesService.instance.removeListener(_onNotesChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    if (mounted) setState(() {});
  }

  void _addTextNote() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    QuickNotesService.instance.addNote(content: text);
    _textController.clear();
    setState(() => _isAddingNew = false);
  }

  void _addHandwritingNote() {
    final canvasState = _canvasKey.currentState;
    if (canvasState == null || canvasState.data.isEmpty) return;

    QuickNotesService.instance.addNote(
      content: 'Handwritten note',
      isHandwritten: true,
      handwrittenData: canvasState.data.toJsonString(),
    );

    setState(() => _isAddingNew = false);
  }

  void _deleteNote(String id) {
    QuickNotesService.instance.deleteNote(id);
  }

  String _getTimeRemaining(QuickNote note) {
    final remaining = note.remainingTime(
      QuickNotesService.instance.autoDeleteDuration,
    );

    if (remaining == Duration.zero) return 'Expired';

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    }
    return '<1m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final notes = QuickNotesService.instance.activeNotes;
    final hasNotes = notes.isNotEmpty;

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
            _buildHeader(context, hasNotes, notes.length),

            // Collapsed preview
            if (!_isExpanded && hasNotes)
              _buildCollapsedPreview(context, notes),

            // Expanded content
            if (_isExpanded) ...[
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              _buildExpandedContent(context, notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool hasNotes, int count) {
    final colorScheme = ColorScheme.of(context);

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(12),
        bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                'Quick Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (hasNotes) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedPreview(BuildContext context, List<QuickNote> notes) {
    final colorScheme = ColorScheme.of(context);
    final previewNote = notes.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Text(
        previewNote.isHandwritten
            ? '✏️ ${notes.length} note${notes.length > 1 ? 's' : ''}'
            : notes.length > 1
            ? '${previewNote.content.length > 30 ? '${previewNote.content.substring(0, 30)}...' : previewNote.content} +${notes.length - 1} more'
            : previewNote.content.length > 50
            ? '${previewNote.content.substring(0, 50)}...'
            : previewNote.content,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, List<QuickNote> notes) {
    final colorScheme = ColorScheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add new note section
          if (_isAddingNew) ...[
            _buildAddNoteSection(context),
            const SizedBox(height: 12),
          ],

          // Notes horizontal scroll list
          if (notes.isNotEmpty) ...[
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: notes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return _buildNoteCard(context, note);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Actions row
          Row(
            children: [
              if (!_isAddingNew)
                FilledButton.tonalIcon(
                  onPressed: () => setState(() {
                    _isAddingNew = true;
                    _isHandwritingMode = false;
                    _textController.clear();
                  }),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Note'),
                ),
              const Spacer(),
              if (notes.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    QuickNotesService.instance.clearAllNotes();
                  },
                  icon: Icon(
                    Icons.delete_sweep,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    'Clear All',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddNoteSection(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode toggle
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.text_fields, size: 16),
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.draw, size: 16),
                      label: Text('Draw'),
                    ),
                  ],
                  selected: {_isHandwritingMode},
                  onSelectionChanged: (value) {
                    setState(() => _isHandwritingMode = value.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _isAddingNew = false),
                tooltip: 'Cancel',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input area
          if (_isHandwritingMode) ...[
            QuickNoteCanvas(
              key: _canvasKey,
              height: 120,
              strokeColor: colorScheme.onSurface,
              strokeWidth: 2.0,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _canvasKey.currentState?.clear(),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addHandwritingNote,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _textController,
              maxLines: 2,
              minLines: 1,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Jot something down...',
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onSubmitted: (_) => _addTextNote(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: _textController.text.trim().isNotEmpty
                      ? _addTextNote
                      : null,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, QuickNote note) {
    final colorScheme = ColorScheme.of(context);

    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with time and delete
          Row(
            children: [
              Icon(
                note.isHandwritten ? Icons.draw : Icons.notes,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTimeRemaining(note),
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _deleteNote(note.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: note.isHandwritten
                ? _buildHandwritingPreview(context, note)
                : Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandwritingPreview(BuildContext context, QuickNote note) {
    if (note.handwrittenData == null) {
      return const Center(child: Icon(Icons.draw, size: 32));
    }

    try {
      final data = QuickNoteHandwritingData.fromJsonString(
        note.handwrittenData!,
      );
      return QuickNoteHandwritingPreview(data: data, height: 80);
    } catch (e) {
      return const Center(child: Icon(Icons.draw, size: 32));
    }
  }
}
