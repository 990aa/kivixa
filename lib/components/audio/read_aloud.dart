// Read Aloud TTS Feature
//
// Text-to-speech accessibility feature with mini player.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';

enum AudioVoiceProfile { female, male, custom }

AudioVoiceProfile audioVoiceProfileFromPref(int value) {
  if (value <= 0) return AudioVoiceProfile.female;
  if (value == 1) return AudioVoiceProfile.male;
  return AudioVoiceProfile.custom;
}

String? selectPreferredVoiceId(
  List<VoiceStyle> voices,
  AudioVoiceProfile profile, {
  String? customVoiceId,
}) {
  if (voices.isEmpty) return null;

  if (profile == AudioVoiceProfile.custom &&
      customVoiceId != null &&
      customVoiceId.isNotEmpty) {
    final customMatch = voices.where((voice) => voice.id == customVoiceId);
    if (customMatch.isNotEmpty) {
      return customMatch.first.id;
    }
  }

  bool isMaleVoice(VoiceStyle voice) {
    final id = voice.id.toLowerCase();
    final name = voice.name.toLowerCase();
    final malePattern = RegExp(r'(^|[^a-z])male([^a-z]|$)');
    return id.startsWith('am_') ||
        id.startsWith('bm_') ||
      malePattern.hasMatch(id) ||
      malePattern.hasMatch(name);
  }

  bool isFemaleVoice(VoiceStyle voice) {
    final id = voice.id.toLowerCase();
    final name = voice.name.toLowerCase();
    final femalePattern = RegExp(r'(^|[^a-z])female([^a-z]|$)');
    return id.startsWith('af_') ||
        id.startsWith('bf_') ||
      femalePattern.hasMatch(id) ||
      femalePattern.hasMatch(name);
  }

  final preferred = switch (profile) {
    AudioVoiceProfile.male => voices.where(isMaleVoice),
    AudioVoiceProfile.female => voices.where(isFemaleVoice),
    AudioVoiceProfile.custom => const Iterable<VoiceStyle>.empty(),
  };

  if (preferred.isNotEmpty) {
    return preferred.first.id;
  }

  return voices.first.id;
}

/// Read aloud controller for managing TTS playback
class ReadAloudController extends ChangeNotifier {
  final _engine = AudioNeuralEngine();
  final _playback = AudioPlaybackService();

  var _isPlaying = false;
  var _progress = 0.0;
  var _currentSentence = '';
  var _currentSentenceIndex = 0;
  var _sentences = <String>[];
  var _availableVoices = <VoiceStyle>[];

  // Settings
  var _speed = 1.0;
  String? _voiceId;

  ReadAloudController() {
    _speed = stows.audioTtsSpeed.value.clamp(0.5, 2.0);
    _voiceId = stows.audioCustomVoiceId.value;
    _playback.setSpeed(_speed);
  }

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
    stows.audioTtsSpeed.value = _speed;
    notifyListeners();
  }

  /// Selected voice ID
  String? get voiceId => _voiceId;
  set voiceId(String? value) {
    _voiceId = value;
    stows.audioCustomVoiceId.value = value;
    if (value != null && value.isNotEmpty) {
      stows.audioVoiceProfile.value = AudioVoiceProfile.custom.index;
    }
    notifyListeners();
  }

  /// Available voices detected from the TTS backend.
  List<VoiceStyle> get availableVoices => List.unmodifiable(_availableVoices);

  /// Start reading text aloud
  Future<void> startReading(String text) async {
    if (text.isEmpty || !stows.audioIntelligenceEnabled.value) return;

    _speed = stows.audioTtsSpeed.value.clamp(0.5, 2.0);
    _playback.setSpeed(_speed);

    _sentences = _splitIntoSentences(text);
    _currentSentenceIndex = 0;
    _isPlaying = true;
    notifyListeners();

    await _engine.initialize();
    await _refreshVoices();
    _applyPreferredVoice();
    await _playCurrentSentence();
  }

  Future<void> _refreshVoices() async {
    final voices = _engine.getAvailableVoices();
    _availableVoices = voices;
  }

  void _applyPreferredVoice() {
    final preferred = selectPreferredVoiceId(
      _availableVoices,
      audioVoiceProfileFromPref(stows.audioVoiceProfile.value),
      customVoiceId: stows.audioCustomVoiceId.value,
    );
    _voiceId = preferred;
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

    final result = await _engine.synthesize(
      _currentSentence,
      voiceId: _voiceId,
    );
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

  /// Whether to show voice selector in expanded mode.
  final bool showVoiceSelector;

  const ReadAloudMiniPlayer({
    super.key,
    required this.controller,
    this.onClose,
    this.expanded = false,
    this.showVoiceSelector = true,
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
              if (widget.showVoiceSelector &&
                  widget.controller.availableVoices.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Voice:', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value:
                            widget.controller.availableVoices.any(
                              (voice) => voice.id == widget.controller.voiceId,
                            )
                            ? widget.controller.voiceId
                            : widget.controller.availableVoices.first.id,
                        isDense: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        items: widget.controller.availableVoices
                            .map(
                              (voice) => DropdownMenuItem<String>(
                                value: voice.id,
                                child: Text(
                                  voice.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          widget.controller.voiceId = value;
                        },
                      ),
                    ),
                  ],
                ),
              ],
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
          expanded: true,
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
