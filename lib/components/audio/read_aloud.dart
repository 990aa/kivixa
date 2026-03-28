// Read Aloud TTS Feature
//
// Text-to-speech accessibility feature with mini player.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';

/// Read aloud controller for managing TTS playback
class ReadAloudController extends ChangeNotifier {
  final _engine = AudioNeuralEngine();
  final _playback = AudioPlaybackService();

  var _isPlaying = false;
  var _progress = 0.0;
  var _currentSentence = '';
  var _currentSentenceIndex = 0;
  var _sentences = <String>[];

  // Settings
  var _speed = 1.0;
  String? _voiceId;

  /// Whether TTS is currently playing
  bool get isPlaying => _isPlaying;

  /// Current playback progress (0.0 - 1.0)
  double get progress => _progress;

  /// Currently spoken sentence
  String get currentSentence => _currentSentence;

  /// Current sentence index
  int get currentSentenceIndex => _currentSentenceIndex;

  /// Total sentence count
  int get sentenceCount => _sentences.length;

  /// Playback speed
  double get speed => _speed;
  set speed(double value) {
    _speed = value.clamp(0.5, 2.0);
    _playback.setSpeed(_speed);
    notifyListeners();
  }

  /// Selected voice ID
  String? get voiceId => _voiceId;
  set voiceId(String? value) {
    _voiceId = value;
    notifyListeners();
  }

  /// Start reading text aloud
  Future<void> startReading(String text) async {
    if (text.isEmpty) return;

    _sentences = _splitIntoSentences(text);
    _currentSentenceIndex = 0;
    _isPlaying = true;
    notifyListeners();

    await _engine.initialize();
    await _playCurrentSentence();
  }

  /// Pause playback
  void pause() {
    _playback.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// Resume playback
  void resume() {
    _playback.resume();
    _isPlaying = true;
    notifyListeners();
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  /// Stop playback completely
  void stop() {
    _playback.stop();
    _isPlaying = false;
    _progress = 0.0;
    _currentSentenceIndex = 0;
    _currentSentence = '';
    notifyListeners();
  }

  /// Skip to next sentence
  Future<void> next() async {
    if (_currentSentenceIndex < _sentences.length - 1) {
      _playback.stop();
      _currentSentenceIndex++;
      await _playCurrentSentence();
    }
  }

  /// Skip to previous sentence
  Future<void> previous() async {
    if (_currentSentenceIndex > 0) {
      _playback.stop();
      _currentSentenceIndex--;
      await _playCurrentSentence();
    }
  }

  Future<void> _playCurrentSentence() async {
    if (_currentSentenceIndex >= _sentences.length) {
      stop();
      return;
    }

    _currentSentence = _sentences[_currentSentenceIndex];
    _progress = _currentSentenceIndex / _sentences.length;
    notifyListeners();

    final result = await _engine.synthesize(_currentSentence);
    if (result != null) {
      await _playback.playSynthesis(result);

      // Wait for completion
      while (_playback.state.value == PlaybackState.playing && _isPlaying) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Move to next sentence if still playing
      if (_isPlaying && _currentSentenceIndex < _sentences.length - 1) {
        _currentSentenceIndex++;
        await _playCurrentSentence();
      } else if (_currentSentenceIndex >= _sentences.length - 1) {
        stop();
      }
    }
  }

  List<String> _splitIntoSentences(String text) {
    // Split by sentence-ending punctuation
    final sentencePattern = RegExp(r'[.!?]+\s*');
    final sentences = text
        .split(sentencePattern)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return sentences;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Read aloud mini player widget
class ReadAloudMiniPlayer extends StatefulWidget {
  /// The controller for playback
  final ReadAloudController controller;

  /// Callback when closed
  final VoidCallback? onClose;

  /// Whether to show expanded controls
  final bool expanded;

  const ReadAloudMiniPlayer({
    super.key,
    required this.controller,
    this.onClose,
    this.expanded = false,
  });

  @override
  State<ReadAloudMiniPlayer> createState() => _ReadAloudMiniPlayerState();
}

class _ReadAloudMiniPlayerState extends State<ReadAloudMiniPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: widget.controller.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),

            const SizedBox(height: 8),

            // Current text
            Text(
              widget.controller.currentSentence,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous
                IconButton(
                  onPressed: widget.controller.currentSentenceIndex > 0
                      ? widget.controller.previous
                      : null,
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 24,
                ),

                // Play/Pause
                IconButton(
                  onPressed: widget.controller.togglePlayPause,
                  icon: Icon(
                    widget.controller.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 48,
                  color: colorScheme.primary,
                ),

                // Next
                IconButton(
                  onPressed:
                      widget.controller.currentSentenceIndex <
                          widget.controller.sentenceCount - 1
                      ? widget.controller.next
                      : null,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 24,
                ),

                // Close
                IconButton(
                  onPressed: () {
                    widget.controller.stop();
                    widget.onClose?.call();
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),

            // Speed control (expanded mode)
            if (widget.expanded) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Speed:', style: theme.textTheme.bodySmall),
                  Slider(
                    value: widget.controller.speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${widget.controller.speed.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      widget.controller.speed = value;
                    },
                  ),
                  Text(
                    '${widget.controller.speed.toStringAsFixed(1)}x',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Read aloud context menu action
class ReadAloudAction extends StatelessWidget {
  /// Text to read
  final String text;

  /// Controller for playback
  final ReadAloudController controller;

  /// Custom icon
  final IconData? icon;

  /// Custom label
  final String? label;

  const ReadAloudAction({
    super.key,
    required this.text,
    required this.controller,
    this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => controller.startReading(text),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon ?? Icons.volume_up),
            const SizedBox(width: 12),
            Text(label ?? 'Read Aloud'),
          ],
        ),
      ),
    );
  }
}

/// Floating read aloud button that shows mini player
class FloatingReadAloudButton extends StatefulWidget {
  /// Get the text to read when pressed
  final String Function() getText;

  const FloatingReadAloudButton({super.key, required this.getText});

  @override
  State<FloatingReadAloudButton> createState() =>
      _FloatingReadAloudButtonState();
}

class _FloatingReadAloudButtonState extends State<FloatingReadAloudButton> {
  final _controller = ReadAloudController();
  var _showMiniPlayer = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    final shouldShow =
        _controller.isPlaying || _controller.currentSentence.isNotEmpty;

    if (shouldShow != _showMiniPlayer) {
      setState(() => _showMiniPlayer = shouldShow);
    }
  }

  void _startReading() {
    final text = widget.getText();
    if (text.isNotEmpty) {
      _controller.startReading(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_showMiniPlayer) {
      return Positioned(
        bottom: 100,
        left: 16,
        right: 16,
        child: ReadAloudMiniPlayer(
          controller: _controller,
          onClose: () => setState(() => _showMiniPlayer = false),
        ),
      );
    }

    return FloatingActionButton.small(
      onPressed: _startReading,
      tooltip: 'Read aloud',
      backgroundColor: colorScheme.secondaryContainer,
      child: Icon(Icons.volume_up, color: colorScheme.onSecondaryContainer),
    );
  }
}

/// Text selection with read aloud option
class ReadAloudSelectionControls extends MaterialTextSelectionControls {
  final ReadAloudController controller;

  ReadAloudSelectionControls({required this.controller});

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _ReadAloudToolbar(
      controller: controller,
      delegate: delegate,
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      clipboardStatus: clipboardStatus,
    );
  }
}

class _ReadAloudToolbar extends StatelessWidget {
  final ReadAloudController controller;
  final TextSelectionDelegate delegate;
  final Rect globalEditableRegion;
  final double textLineHeight;
  final Offset selectionMidpoint;
  final List<TextSelectionPoint> endpoints;
  final ValueListenable<ClipboardStatus>? clipboardStatus;

  const _ReadAloudToolbar({
    required this.controller,
    required this.delegate,
    required this.globalEditableRegion,
    required this.textLineHeight,
    required this.selectionMidpoint,
    required this.endpoints,
    this.clipboardStatus,
  });

  @override
  Widget build(BuildContext context) {
    final selection = delegate.textEditingValue.selection;
    final text = selection.textInside(delegate.textEditingValue.text);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Read aloud button
          IconButton(
            onPressed: text.isNotEmpty
                ? () => controller.startReading(text)
                : null,
            icon: const Icon(Icons.volume_up),
            tooltip: 'Read aloud',
          ),
          // Copy button
          IconButton(
            onPressed: () =>
                delegate.copySelection(SelectionChangedCause.toolbar),
            icon: const Icon(Icons.copy),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
