// Quick Notes "Thought Catcher" Widget
//
// Long-press mic button that captures fleeting thoughts with background
// transcription and minimal UI interruption.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Quick note data model
class QuickNote {
  /// Unique ID
  final String id;

  /// Transcribed text
  final String text;

  /// Audio file path (if saved)
  final String? audioPath;

  /// Duration of recording
  final Duration duration;

  /// Timestamp
  final DateTime timestamp;

  /// Tags extracted from content
  final List<String> tags;

  /// Whether transcription is complete
  final bool isTranscribed;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  const QuickNote({
    required this.id,
    required this.text,
    this.audioPath,
    required this.duration,
    required this.timestamp,
    this.tags = const [],
    this.isTranscribed = true,
    this.confidence = 1.0,
  });

  QuickNote copyWith({
    String? text,
    String? audioPath,
    List<String>? tags,
    bool? isTranscribed,
    double? confidence,
  }) {
    return QuickNote(
      id: id,
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      duration: duration,
      timestamp: timestamp,
      tags: tags ?? this.tags,
      isTranscribed: isTranscribed ?? this.isTranscribed,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Thought Catcher - Quick note capture widget
class ThoughtCatcher extends StatefulWidget {
  /// Callback when a note is captured
  final void Function(QuickNote note)? onNoteCaptured;

  /// Position of the floating button
  final Alignment alignment;

  /// Whether to show toast notifications
  final bool showToast;

  /// Auto-save to notes
  final bool autoSave;

  /// Child widget (the main UI)
  final Widget child;

  const ThoughtCatcher({
    super.key,
    this.onNoteCaptured,
    this.alignment = Alignment.bottomRight,
    this.showToast = true,
    this.autoSave = true,
    required this.child,
  });

  @override
  State<ThoughtCatcher> createState() => ThoughtCatcherState();
}

class ThoughtCatcherState extends State<ThoughtCatcher>
    with SingleTickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();

  late AnimationController _pulseController;

  var _isRecording = false;
  var _isProcessing = false;
  var _recordingDuration = Duration.zero;
  var _currentText = '';

  Timer? _durationTimer;
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;
  StreamSubscription<AudioVisualizerData>? _visualizerSub;
  var _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _durationTimer?.cancel();
    _transcriptionSub?.cancel();
    _visualizerSub?.cancel();
    super.dispose();
  }

  /// Start capturing a thought
  Future<void> startCapture() async {
    if (_isRecording) return;

    HapticFeedback.mediumImpact();

    final initialized = await _engine.initialize();
    if (!initialized) return;

    setState(() {
      _isRecording = true;
      _currentText = '';
      _recordingDuration = Duration.zero;
    });

    _pulseController.repeat(reverse: true);

    // Setup subscriptions
    _transcriptionSub = _engine.transcriptionStream.listen((result) {
      if (mounted) {
        setState(() => _currentText = result.text);
      }
    });

    _visualizerSub = _engine.visualizerStream.listen((data) {
      if (mounted) {
        setState(() => _amplitude = data.rmsLevel);
      }
    });

    // Start recording and listening
    await _recorder.startRecording();
    await _engine.startListening();

    // Duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  /// Stop capturing and process the thought
  Future<void> stopCapture() async {
    if (!_isRecording) return;

    HapticFeedback.lightImpact();

    _durationTimer?.cancel();
    _pulseController.stop();

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    // Stop recording
    final filePath = await _recorder.stopRecording();
    await _engine.stopListening();

    // Wait a moment for final transcription
    await Future.delayed(const Duration(milliseconds: 500));

    final finalText = _currentText.trim();

    if (finalText.isNotEmpty) {
      final note = QuickNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: finalText,
        audioPath: filePath,
        duration: _recordingDuration,
        timestamp: DateTime.now(),
        tags: _extractTags(finalText),
      );

      widget.onNoteCaptured?.call(note);

      if (widget.showToast && mounted) {
        _showCapturedToast(note);
      }
    }

    _transcriptionSub?.cancel();
    _visualizerSub?.cancel();

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _currentText = '';
      });
    }
  }

  /// Extract tags from text (simple implementation)
  List<String> _extractTags(String text) {
    final tags = <String>[];
    final lowerText = text.toLowerCase();

    // Simple keyword extraction
    final keywords = ['todo', 'idea', 'remember', 'important', 'note', 'meeting'];
    for (final keyword in keywords) {
      if (lowerText.contains(keyword)) {
        tags.add(keyword);
      }
    }

    return tags;
  }

  void _showCapturedToast(QuickNote note) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thought captured!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    note.text.length > 50
                        ? '${note.text.substring(0, 50)}...'
                        : note.text,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Open quick notes view
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // Main content
        widget.child,

        // Recording overlay
        if (_isRecording) _buildRecordingOverlay(colorScheme),

        // Processing indicator
        if (_isProcessing)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // Floating thought catcher button
        Positioned(
          right: widget.alignment == Alignment.bottomRight ||
                  widget.alignment == Alignment.topRight
              ? 16
              : null,
          left: widget.alignment == Alignment.bottomLeft ||
                  widget.alignment == Alignment.topLeft
              ? 16
              : null,
          bottom: widget.alignment == Alignment.bottomRight ||
                  widget.alignment == Alignment.bottomLeft
              ? 80
              : null,
          top: widget.alignment == Alignment.topRight ||
                  widget.alignment == Alignment.topLeft
              ? 100
              : null,
          child: _buildCaptureButton(colorScheme),
        ),
      ],
    );
  }

  Widget _buildCaptureButton(ColorScheme colorScheme) {
    return GestureDetector(
      onLongPressStart: (_) => startCapture(),
      onLongPressEnd: (_) => stopCapture(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isRecording
              ? 1.0 + (_pulseController.value * 0.1) + (_amplitude * 0.2)
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : colorScheme.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: _isRecording ? 20 : 10,
                    spreadRadius: _isRecording ? 5 : 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.lightbulb_outline,
                color: _isRecording
                    ? Colors.white
                    : colorScheme.onPrimaryContainer,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingOverlay(ColorScheme colorScheme) {
    return Positioned(
      bottom: 160,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red
                              .withValues(alpha: _pulseController.value),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Capturing thought...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDuration(_recordingDuration),
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live transcription
            if (_currentText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentText,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(
                'Speak your thought...',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 8),

            // Hint
            Text(
              'Release to save',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Quick Notes List View
class QuickNotesList extends StatelessWidget {
  final List<QuickNote> notes;
  final void Function(QuickNote note)? onNoteTap;
  final void Function(QuickNote note)? onNoteDelete;
  final void Function(QuickNote note)? onNoteEdit;

  const QuickNotesList({
    super.key,
    required this.notes,
    this.onNoteTap,
    this.onNoteDelete,
    this.onNoteEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No quick notes yet',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long-press the mic button to capture a thought',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _QuickNoteCard(
          note: note,
          onTap: () => onNoteTap?.call(note),
          onDelete: () => onNoteDelete?.call(note),
          onEdit: () => onNoteEdit?.call(note),
        );
      },
    );
  }
}

class _QuickNoteCard extends StatelessWidget {
  final QuickNote note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _QuickNoteCard({
    required this.note,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with time and duration
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(note.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(note.duration),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Note text
              Text(
                note.text,
                style: TextStyle(color: colorScheme.onSurface),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: note.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // Confidence indicator
              if (note.confidence < 0.9) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 14,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Low confidence - tap to review',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
