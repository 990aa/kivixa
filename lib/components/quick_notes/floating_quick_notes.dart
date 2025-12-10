import 'package:flutter/material.dart';
import 'package:kivixa/components/quick_notes/quick_note_canvas.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';

/// A floating quick notes window that can be shown as an overlay.
class FloatingQuickNotes extends StatefulWidget {
  const FloatingQuickNotes({super.key, this.onClose, this.initialRect});

  final VoidCallback? onClose;
  final Rect? initialRect;

  @override
  State<FloatingQuickNotes> createState() => _FloatingQuickNotesState();
}

class _FloatingQuickNotesState extends State<FloatingQuickNotes>
    with SingleTickerProviderStateMixin {
  final _service = QuickNotesService.instance;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  late final TabController _tabController;
  final _canvasKey = GlobalKey<QuickNoteCanvasState>();

  var _isHandwritingMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.addListener(_onServiceChanged);
    _service.initialize();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _textController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_isHandwritingMode) {
      final canvasState = _canvasKey.currentState;
      if (canvasState == null || canvasState.data.isEmpty) return;

      _service.addNote(
        content: 'Handwritten note',
        isHandwritten: true,
        handwrittenData: canvasState.data.toJsonString(),
      );
      canvasState.clear();
    } else {
      final content = _textController.text.trim();
      if (content.isEmpty) return;

      _service.addNote(content: content);
      _textController.clear();
    }
  }

  bool _canAddNote() {
    if (_isHandwritingMode) {
      final canvasState = _canvasKey.currentState;
      return canvasState != null && canvasState.data.isNotEmpty;
    }
    return _textController.text.trim().isNotEmpty;
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Quick Notes?'),
        content: const Text(
          'This will permanently delete all quick notes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _service.clearAllNotes();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 320,
          maxWidth: 400,
          minHeight: 300,
          maxHeight: 500,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Notes', icon: Icon(Icons.notes)),
                Tab(text: 'New', icon: Icon(Icons.add)),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotesList(context),
                  _buildNewNoteForm(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.sticky_note_2, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_service.autoDeleteEnabled)
                  Text(
                    'Auto-delete: ${QuickNoteAutoDeletePresets.formatDuration(_service.autoDeleteDuration)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (_service.notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all notes',
              onPressed: _clearAll,
            ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context) {
    final notes = _service.activeNotes;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No quick notes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a note to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _QuickNoteCard(
          note: note,
          autoDeleteDuration: _service.autoDeleteDuration,
          autoDeleteEnabled: _service.autoDeleteEnabled,
          onDelete: () => _service.deleteNote(note.id),
        );
      },
    );
  }

  Widget _buildNewNoteForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.text_fields),
                label: Text('Text'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.draw),
                label: Text('Handwriting'),
              ),
            ],
            selected: {_isHandwritingMode},
            onSelectionChanged: (value) {
              setState(() => _isHandwritingMode = value.first);
            },
          ),

          const SizedBox(height: 16),

          // Input area
          Expanded(
            child: _isHandwritingMode
                ? _buildHandwritingArea(context)
                : _buildTextArea(context),
          ),

          const SizedBox(height: 16),

          // Add button
          FilledButton.icon(
            onPressed: _canAddNote() ? _addNote : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Quick Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: 'Type your quick note here...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _addNote(),
    );
  }

  Widget _buildHandwritingArea(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Column(
      children: [
        Expanded(
          child: QuickNoteCanvas(
            key: _canvasKey,
            strokeColor: colorScheme.onSurface,
            strokeWidth: 2.0,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _canvasKey.currentState?.clear(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Canvas'),
            ),
          ],
        ),
      ],
    );
  }
}

/// A card displaying a single quick note.
class _QuickNoteCard extends StatelessWidget {
  const _QuickNoteCard({
    required this.note,
    required this.autoDeleteDuration,
    required this.autoDeleteEnabled,
    required this.onDelete,
  });

  final QuickNote note;
  final Duration autoDeleteDuration;
  final bool autoDeleteEnabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = note.remainingTime(autoDeleteDuration);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  note.isHandwritten ? Icons.draw : Icons.text_snippet,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(note.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (autoDeleteEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getExpirationColor(remaining, colorScheme),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatRemaining(remaining),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Delete note',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (note.isHandwritten && note.handwrittenData != null)
              _buildHandwritingPreview(note.handwrittenData!)
            else
              Text(
                note.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandwritingPreview(String jsonData) {
    try {
      final data = QuickNoteHandwritingData.fromJsonString(jsonData);
      return QuickNoteHandwritingPreview(data: data, height: 80);
    } catch (e) {
      return const SizedBox(
        height: 80,
        child: Center(child: Icon(Icons.draw, size: 32)),
      );
    }
  }

  Color _getExpirationColor(Duration remaining, ColorScheme colorScheme) {
    if (remaining.inMinutes < 15) return Colors.red;
    if (remaining.inHours < 1) return Colors.orange;
    return colorScheme.primary;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatRemaining(Duration remaining) {
    if (remaining.inMinutes < 1) return 'Expiring';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}m left';
    if (remaining.inHours < 24) return '${remaining.inHours}h left';
    return '${remaining.inDays}d left';
  }
}

/// A compact button to open quick notes from the sidebar.
class QuickNotesButton extends StatelessWidget {
  const QuickNotesButton({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = QuickNotesService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final noteCount = service.activeNotes.length;

        if (compact) {
          return IconButton(
            icon: Badge(
              isLabelVisible: noteCount > 0,
              label: Text('$noteCount'),
              child: const Icon(Icons.sticky_note_2),
            ),
            tooltip: 'Quick Notes',
            onPressed: onTap,
          );
        }

        return Material(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: noteCount > 0,
                    label: Text('$noteCount'),
                    child: Icon(
                      Icons.sticky_note_2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Notes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          noteCount == 0
                              ? 'Tap to add a quick note'
                              : '$noteCount note${noteCount > 1 ? 's' : ''} • auto-delete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
