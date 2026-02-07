// Read Aloud Widget with Floating Mini-Player
//
// Text-to-speech widget with sentence-level highlighting sync,
// cursor following, and floating mini-player during navigation.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';

/// Sentence information for highlighting
class SentenceInfo {
  /// Start index in text
  final int startIndex;

  /// End index in text
  final int endIndex;

  /// Start time in audio
  final Duration startTime;

  /// End time in audio
  final Duration endTime;

  /// The sentence text
  final String text;

  const SentenceInfo({
    required this.startIndex,
    required this.endIndex,
    required this.startTime,
    required this.endTime,
    required this.text,
  });
}

/// Read aloud playback info
class ReadAloudInfo {
  /// Full text being read
  final String text;

  /// Current playback position
  final Duration position;

  /// Total duration
  final Duration duration;

  /// Current sentence index
  final int currentSentence;

  /// All sentences
  final List<SentenceInfo> sentences;

  /// Playback speed
  final double speed;

  /// Is playing
  final bool isPlaying;

  const ReadAloudInfo({
    required this.text,
    required this.position,
    required this.duration,
    required this.currentSentence,
    required this.sentences,
    this.speed = 1.0,
    this.isPlaying = false,
  });

  ReadAloudInfo copyWith({
    Duration? position,
    int? currentSentence,
    double? speed,
    bool? isPlaying,
  }) {
    return ReadAloudInfo(
      text: text,
      position: position ?? this.position,
      duration: duration,
      currentSentence: currentSentence ?? this.currentSentence,
      sentences: sentences,
      speed: speed ?? this.speed,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

/// Read Aloud Controller
class ReadAloudController extends ChangeNotifier {
  final _engine = AudioNeuralEngine();
  final _playback = AudioPlaybackService();

  ReadAloudInfo? _info;
  ReadAloudInfo? get info => _info;

  StreamSubscription<Duration>? _positionSub;
  VoidCallback? _stateListener;

  var _isInitialized = false;
  var _speed = 1.0;

  /// Start reading text aloud
  Future<void> readAloud(String text) async {
    if (!_isInitialized) {
      await _engine.initialize();
      _isInitialized = true;
    }

    final sentences = _parseSentences(text);

    _info = ReadAloudInfo(
      text: text,
      position: Duration.zero,
      duration: Duration.zero,
      currentSentence: 0,
      sentences: sentences,
      speed: _speed,
      isPlaying: true,
    );

    notifyListeners();

    // Subscribe to playback events
    _positionSub = _playback.positionStream.listen(_onPosition);
    _stateListener = () => _onState(_playback.state.value);
    _playback.state.addListener(_stateListener!);

    await _playback.speak(text);
  }

  /// Parse text into sentences
  List<SentenceInfo> _parseSentences(String text) {
    final sentences = <SentenceInfo>[];
    final sentenceRegex = RegExp(r'[^.!?]+[.!?]+\s*|[^.!?]+$');
    final matches = sentenceRegex.allMatches(text);

    var timeOffset = Duration.zero;

    for (final match in matches) {
      final sentenceText = match.group(0)!.trim();
      if (sentenceText.isEmpty) continue;

      // Estimate duration based on word count (rough approximation)
      final wordCount = sentenceText.split(' ').length;
      final estimatedDuration = Duration(
        milliseconds: (wordCount * 350 / _speed).round(),
      );

      sentences.add(SentenceInfo(
        startIndex: match.start,
        endIndex: match.end,
        startTime: timeOffset,
        endTime: timeOffset + estimatedDuration,
        text: sentenceText,
      ));

      timeOffset += estimatedDuration;
    }

    return sentences;
  }

  void _onPosition(Duration position) {
    if (_info == null) return;

    // Find current sentence
    var currentSentence = 0;
    for (var i = 0; i < _info!.sentences.length; i++) {
      if (position >= _info!.sentences[i].startTime) {
        currentSentence = i;
      }
    }

    _info = _info!.copyWith(
      position: position,
      currentSentence: currentSentence,
    );
    notifyListeners();
  }

  void _onState(PlaybackState state) {
    if (_info == null) return;

    _info = _info!.copyWith(
      isPlaying: state == PlaybackState.playing,
    );
    notifyListeners();

    if (state == PlaybackState.stopped) {
      stop();
    }
  }

  /// Pause playback
  void pause() {
    _playback.pause();
    if (_info != null) {
      _info = _info!.copyWith(isPlaying: false);
      notifyListeners();
    }
  }

  /// Resume playback
  void resume() {
    _playback.resume();
    if (_info != null) {
      _info = _info!.copyWith(isPlaying: true);
      notifyListeners();
    }
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (_info?.isPlaying ?? false) {
      pause();
    } else {
      resume();
    }
  }

  /// Stop playback
  void stop() {
    _playback.stop();
    _positionSub?.cancel();
    if (_stateListener != null) {
      _playback.state.removeListener(_stateListener!);
    }
    _info = null;
    notifyListeners();
  }

  /// Skip to specific sentence
  void skipToSentence(int index) {
    if (_info == null || index >= _info!.sentences.length) return;

    final sentence = _info!.sentences[index];
    _playback.seek(sentence.startTime);
    _info = _info!.copyWith(currentSentence: index);
    notifyListeners();
  }

  /// Skip forward/backward
  void skip(Duration amount) {
    if (_info == null) return;

    final newPosition = _info!.position + amount;
    _playback.seek(newPosition);
  }

  /// Set playback speed
  void setSpeed(double speed) {
    _speed = speed;
    _playback.setSpeed(speed);
    if (_info != null) {
      _info = _info!.copyWith(speed: speed);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Floating Mini-Player for Read Aloud
class ReadAloudMiniPlayer extends StatelessWidget {
  final ReadAloudController controller;
  final VoidCallback? onExpand;
  final VoidCallback? onClose;

  const ReadAloudMiniPlayer({
    super.key,
    required this.controller,
    this.onExpand,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final info = controller.info;
        if (info == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Current sentence preview
                  Expanded(
                    child: GestureDetector(
                      onTap: onExpand,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reading aloud',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            info.currentSentence < info.sentences.length
                                ? info.sentences[info.currentSentence].text
                                : '',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Controls
                  IconButton(
                    onPressed: () => controller.skip(const Duration(seconds: -10)),
                    icon: const Icon(Icons.replay_10, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: controller.togglePlayPause,
                    icon: Icon(
                      info.isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 32,
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.skip(const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () {
                      controller.stop();
                      onClose?.call();
                    },
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              // Progress bar
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: info.duration.inMilliseconds > 0
                    ? info.position.inMilliseconds / info.duration.inMilliseconds
                    : 0,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Read Aloud Text Widget with Highlighting
class ReadAloudText extends StatefulWidget {
  final String text;
  final ReadAloudController controller;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final bool autoScroll;

  const ReadAloudText({
    super.key,
    required this.text,
    required this.controller,
    this.style,
    this.highlightStyle,
    this.autoScroll = true,
  });

  @override
  State<ReadAloudText> createState() => _ReadAloudTextState();
}

class _ReadAloudTextState extends State<ReadAloudText> {
  final _scrollController = ScrollController();
  final _sentenceKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!widget.autoScroll) return;

    final info = widget.controller.info;
    if (info == null) return;

    // Auto-scroll to current sentence
    if (info.currentSentence < _sentenceKeys.length) {
      final key = _sentenceKeys[info.currentSentence];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.3,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultStyle = widget.style ??
        theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
        );

    final highlightStyle = widget.highlightStyle ??
        defaultStyle?.copyWith(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
        );

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final info = widget.controller.info;

        // Generate sentence keys if needed
        if (info != null && _sentenceKeys.length != info.sentences.length) {
          _sentenceKeys.clear();
          for (var i = 0; i < info.sentences.length; i++) {
            _sentenceKeys.add(GlobalKey());
          }
        }

        if (info == null || info.sentences.isEmpty) {
          return SelectableText(
            widget.text,
            style: defaultStyle,
          );
        }

        // Build highlighted text spans
        return SingleChildScrollView(
          controller: _scrollController,
          child: SelectableText.rich(
            TextSpan(
              children: _buildTextSpans(info, defaultStyle, highlightStyle),
            ),
          ),
        );
      },
    );
  }

  List<InlineSpan> _buildTextSpans(
    ReadAloudInfo info,
    TextStyle? defaultStyle,
    TextStyle? highlightStyle,
  ) {
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (var i = 0; i < info.sentences.length; i++) {
      final sentence = info.sentences[i];

      // Add any text before this sentence
      if (sentence.startIndex > lastEnd) {
        spans.add(TextSpan(
          text: widget.text.substring(lastEnd, sentence.startIndex),
          style: defaultStyle,
        ));
      }

      // Add the sentence with appropriate style
      final isCurrentSentence = i == info.currentSentence && info.isPlaying;
      spans.add(WidgetSpan(
        child: Builder(
          key: _sentenceKeys.isNotEmpty && i < _sentenceKeys.length
              ? _sentenceKeys[i]
              : null,
          builder: (context) {
            return GestureDetector(
              onTap: () => widget.controller.skipToSentence(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isCurrentSentence ? 4 : 0,
                  vertical: isCurrentSentence ? 2 : 0,
                ),
                decoration: BoxDecoration(
                  color: isCurrentSentence
                      ? highlightStyle?.backgroundColor
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sentence.text,
                  style: isCurrentSentence ? highlightStyle : defaultStyle,
                ),
              ),
            );
          },
        ),
      ));

      // Add space after sentence if needed
      if (sentence.endIndex < widget.text.length) {
        final nextChar = widget.text[sentence.endIndex];
        if (nextChar == ' ' || nextChar == '\n') {
          spans.add(TextSpan(text: nextChar, style: defaultStyle));
        }
      }

      lastEnd = sentence.endIndex;
    }

    // Add any remaining text
    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return spans;
  }
}

/// Full Read Aloud Panel with Controls
class ReadAloudPanel extends StatelessWidget {
  final ReadAloudController controller;
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;

  const ReadAloudPanel({
    super.key,
    required this.controller,
    this.onMinimize,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final info = controller.info;
        if (info == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Read Aloud',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onMinimize,
                      icon: const Icon(Icons.minimize),
                      tooltip: 'Minimize',
                    ),
                    IconButton(
                      onPressed: () {
                        controller.stop();
                        onClose?.call();
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress slider
                Column(
                  children: [
                    Slider(
                      value: info.position.inMilliseconds.toDouble(),
                      max: info.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      onChanged: (value) {
                        controller.skip(
                          Duration(milliseconds: value.toInt()) - info.position,
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(info.position),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(info.duration),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speed control
                    PopupMenuButton<double>(
                      initialValue: info.speed,
                      onSelected: controller.setSpeed,
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                        const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                      ],
                      child: Chip(
                        label: Text('${info.speed}x'),
                        avatar: const Icon(Icons.speed, size: 18),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Skip backward
                    IconButton(
                      onPressed: () => controller.skip(const Duration(seconds: -10)),
                      icon: const Icon(Icons.replay_10),
                      iconSize: 32,
                    ),

                    const SizedBox(width: 8),

                    // Play/Pause
                    IconButton.filled(
                      onPressed: controller.togglePlayPause,
                      icon: Icon(
                        info.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      iconSize: 48,
                    ),

                    const SizedBox(width: 8),

                    // Skip forward
                    IconButton(
                      onPressed: () => controller.skip(const Duration(seconds: 10)),
                      icon: const Icon(Icons.forward_10),
                      iconSize: 32,
                    ),

                    const SizedBox(width: 24),

                    // Stop
                    IconButton(
                      onPressed: () {
                        controller.stop();
                        onClose?.call();
                      },
                      icon: const Icon(Icons.stop),
                      iconSize: 28,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sentence indicator
                Text(
                  'Sentence ${info.currentSentence + 1} of ${info.sentences.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
