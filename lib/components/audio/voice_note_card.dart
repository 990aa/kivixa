// Voice Note Card Widget
//
// Enhanced voice note block for editor integration with
// speaker diarization colors, karaoke highlighting, and waveform background.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Speaker information for diarization
class SpeakerInfo {
  /// Unique speaker identifier
  final String id;

  /// Display name
  final String name;

  /// Assigned color
  final Color color;

  const SpeakerInfo({
    required this.id,
    required this.name,
    required this.color,
  });

  static const defaultSpeakers = [
    SpeakerInfo(id: 'speaker_0', name: 'Speaker 1', color: Color(0xFF2196F3)),
    SpeakerInfo(id: 'speaker_1', name: 'Speaker 2', color: Color(0xFF9C27B0)),
    SpeakerInfo(id: 'speaker_2', name: 'Speaker 3', color: Color(0xFF4CAF50)),
    SpeakerInfo(id: 'speaker_3', name: 'Speaker 4', color: Color(0xFFFF9800)),
  ];
}

/// Audio segment with speaker info
class AudioSegment {
  /// Start time in seconds
  final double startTime;

  /// End time in seconds
  final double endTime;

  /// Speaker ID
  final String? speakerId;

  /// Transcribed text
  final String text;

  /// Confidence level
  final double confidence;

  /// Whether this is a silence segment
  final bool isSilence;

  const AudioSegment({
    required this.startTime,
    required this.endTime,
    this.speakerId,
    required this.text,
    this.confidence = 1.0,
    this.isSilence = false,
  });

  double get duration => endTime - startTime;
}

/// Voice note data model
class VoiceNoteCardData {
  /// Unique identifier
  final String id;

  /// Audio file path (if saved)
  final String? audioPath;

  /// Raw audio samples (f32 normalized)
  final List<double> samples;

  /// Sample rate
  final int sampleRate;

  /// Total duration in seconds
  final double duration;

  /// Audio segments with transcription and speaker info
  final List<AudioSegment> segments;

  /// Waveform peaks for visualization (normalized 0-1)
  final List<double> waveformPeaks;

  /// Speaker map
  final Map<String, SpeakerInfo> speakers;

  /// Creation timestamp
  final DateTime createdAt;

  /// Title (optional)
  final String? title;

  const VoiceNoteCardData({
    required this.id,
    this.audioPath,
    required this.samples,
    required this.sampleRate,
    required this.duration,
    required this.segments,
    required this.waveformPeaks,
    this.speakers = const {},
    required this.createdAt,
    this.title,
  });

  /// Get full transcript text
  String get fullText => segments
      .where((s) => !s.isSilence)
      .map((s) => s.text)
      .join(' ');

  /// Get segment at a specific time
  AudioSegment? getSegmentAtTime(double time) {
    for (final segment in segments) {
      if (time >= segment.startTime && time <= segment.endTime) {
        return segment;
      }
    }
    return null;
  }

  /// Get speaker color for a segment
  Color getSpeakerColor(AudioSegment segment) {
    if (segment.speakerId == null) return Colors.grey;
    return speakers[segment.speakerId]?.color ?? Colors.grey;
  }
}

/// Voice Note Card - Interactive audio block for editors
class VoiceNoteCard extends StatefulWidget {
  /// Voice note data
  final VoiceNoteCardData? data;

  /// Callback when recording completes
  final void Function(VoiceNoteCardData data)? onRecordingComplete;

  /// Callback when playback position changes
  final void Function(double position)? onPositionChanged;

  /// Callback when seeking to a time
  final void Function(double time)? onSeek;

  /// Callback when transcript is edited
  final void Function(String newText)? onTranscriptEdit;

  /// Callback when audio segment is deleted
  final void Function(AudioSegment segment)? onSegmentDelete;

  /// Whether to expand transcript drawer by default
  final bool initiallyExpanded;

  /// Whether to enable karaoke mode (word highlighting)
  final bool enableKaraokeMode;

  /// Whether to visually shrink silence gaps
  final bool shrinkSilence;

  /// Whether to skip silence during playback
  final bool skipSilence;

  /// Search query to highlight in transcript
  final String? searchQuery;

  const VoiceNoteCard({
    super.key,
    this.data,
    this.onRecordingComplete,
    this.onPositionChanged,
    this.onSeek,
    this.onTranscriptEdit,
    this.onSegmentDelete,
    this.initiallyExpanded = false,
    this.enableKaraokeMode = true,
    this.shrinkSilence = true,
    this.skipSilence = false,
    this.searchQuery,
  });

  @override
  State<VoiceNoteCard> createState() => _VoiceNoteCardState();
}

class _VoiceNoteCardState extends State<VoiceNoteCard>
    with SingleTickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _playback = AudioPlaybackService();
  final _recorder = AudioRecordingService();

  late AnimationController _playheadController;

  VoiceNoteCardData? _data;
  var _isRecording = false;
  var _isPlaying = false;
  var _isExpanded = false;
  var _playbackPosition = 0.0;
  var _currentSegmentIndex = -1;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _isExpanded = widget.initiallyExpanded;

    _playheadController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: ((_data?.duration ?? 1.0) * 1000).round(),
      ),
    );

    _positionSub = _playback.positionStream.listen(_onPositionChanged);
    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);
    _playbackStateSub = _playback.stateStream.listen(_onPlaybackStateChanged);
  }

  @override
  void dispose() {
    _playheadController.dispose();
    _positionSub?.cancel();
    _transcriptionSub?.cancel();
    _playbackStateSub?.cancel();
    super.dispose();
  }

  void _onPositionChanged(Duration position) {
    final seconds = position.inMilliseconds / 1000.0;
    setState(() => _playbackPosition = seconds);
    widget.onPositionChanged?.call(seconds);

    // Update playhead animation
    if (_data != null && _data!.duration > 0) {
      _playheadController.value = seconds / _data!.duration;
    }

    // Update current segment for karaoke mode
    if (widget.enableKaraokeMode && _data != null) {
      final segment = _data!.getSegmentAtTime(seconds);
      if (segment != null) {
        final index = _data!.segments.indexOf(segment);
        if (index != _currentSegmentIndex) {
          setState(() => _currentSegmentIndex = index);
        }
      }
    }

    // Skip silence if enabled
    if (widget.skipSilence && _data != null) {
      final segment = _data!.getSegmentAtTime(seconds);
      if (segment != null && segment.isSilence) {
        _skipToNextNonSilence(seconds);
      }
    }
  }

  void _onPlaybackStateChanged(PlaybackState state) {
    setState(() {
      _isPlaying = state == PlaybackState.playing;
    });

    if (state == PlaybackState.playing) {
      _playheadController.forward();
    } else {
      _playheadController.stop();
    }
  }

  void _onTranscription(SpeechRecognitionResult result) {
    // Accumulate transcription during recording
    if (_isRecording && result.isFinal) {
      // In real implementation, add to segments list
    }
  }

  void _skipToNextNonSilence(double currentTime) {
    if (_data == null) return;

    for (final segment in _data!.segments) {
      if (segment.startTime > currentTime && !segment.isSilence) {
        _seekTo(segment.startTime);
        break;
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _recorder.stopRecording();
      final result = await _engine.stopListening();

      if (result != null) {
        // Create voice note data from recording
        final newData = VoiceNoteCardData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          samples: [],
          sampleRate: 16000,
          duration: result.endTime,
          segments: [
            AudioSegment(
              startTime: 0,
              endTime: result.endTime,
              text: result.text,
              confidence: result.confidence,
            ),
          ],
          waveformPeaks: List.generate(
            100,
            (i) => (math.sin(i * 0.2) + 1) / 2 * math.Random().nextDouble(),
          ),
          createdAt: DateTime.now(),
        );

        setState(() {
          _isRecording = false;
          _data = newData;
        });

        widget.onRecordingComplete?.call(newData);
      } else {
        setState(() => _isRecording = false);
      }
    } else {
      // Start recording
      await _engine.initialize();
      await _engine.startListening();
      await _recorder.startRecording();
      setState(() => _isRecording = true);
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _playback.pause();
    } else if (_data != null) {
      // In real implementation, play actual audio
      _playback.speak(_data!.fullText);
    }
  }

  void _seekTo(double time) {
    widget.onSeek?.call(time);
    _playback.seek(Duration(milliseconds: (time * 1000).round()));
    setState(() => _playbackPosition = time);
  }

  void _seekToSegment(int index) {
    if (_data == null || index < 0 || index >= _data!.segments.length) return;
    _seekTo(_data!.segments[index].startTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform background with playhead
          _buildWaveformSection(colorScheme),

          // Controls row
          _buildControlsRow(theme, colorScheme),

          // Expandable transcript drawer
          if (_isExpanded) _buildTranscriptDrawer(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildWaveformSection(ColorScheme colorScheme) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          // Waveform background with speaker colors
          if (_data != null)
            CustomPaint(
              painter: _SpeakerWaveformPainter(
                waveformPeaks: _data!.waveformPeaks,
                segments: _data!.segments,
                duration: _data!.duration,
                getSpeakerColor: (s) => _data!.getSpeakerColor(s),
                shrinkSilence: widget.shrinkSilence,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              size: const Size.fromHeight(80),
            )
          else
            Container(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: _isRecording
                    ? const _RecordingIndicator()
                    : Text(
                        'Tap to record voice note',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),

          // Playhead
          if (_data != null)
            AnimatedBuilder(
              animation: _playheadController,
              builder: (context, child) {
                return Positioned(
                  left: _playheadController.value *
                      (MediaQuery.of(context).size.width - 32),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: colorScheme.primary,
                  ),
                );
              },
            ),

          // Tap to seek
          if (_data != null)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final localX = details.localPosition.dx;
                  final progress = localX / box.size.width;
                  _seekTo(progress * _data!.duration);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Record/Play/Pause button
          IconButton.filled(
            onPressed: _data == null ? _toggleRecording : _togglePlayback,
            icon: Icon(
              _isRecording
                  ? Icons.stop
                  : _data == null
                      ? Icons.mic
                      : _isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _isRecording
                  ? colorScheme.error
                  : colorScheme.primaryContainer,
              foregroundColor: _isRecording
                  ? colorScheme.onError
                  : colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 12),

          // Duration / Position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_data?.title != null)
                  Text(
                    _data!.title!,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  _data != null
                      ? '${_formatDuration(_playbackPosition)} / ${_formatDuration(_data!.duration)}'
                      : _isRecording
                          ? 'Recording...'
                          : 'No recording',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Skip silence toggle
          if (_data != null)
            IconButton(
              onPressed: () {
                // Toggle skip silence in parent
              },
              icon: Icon(
                widget.skipSilence
                    ? Icons.skip_next
                    : Icons.skip_next_outlined,
              ),
              tooltip: 'Skip silence',
              color: widget.skipSilence
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),

          // Expand transcript button
          if (_data != null)
            IconButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(
                _isExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
              ),
              tooltip: _isExpanded ? 'Hide transcript' : 'Show transcript',
            ),
        ],
      ),
    );
  }

  Widget _buildTranscriptDrawer(ThemeData theme, ColorScheme colorScheme) {
    if (_data == null) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SingleChildScrollView(
        child: SelectableText.rich(
          TextSpan(
            children: _data!.segments.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              if (segment.isSilence) return const TextSpan(text: '');

              final isHighlighted =
                  widget.enableKaraokeMode && index == _currentSegmentIndex;
              final speakerColor = _data!.getSpeakerColor(segment);

              // Check if text matches search query
              final matchesSearch = widget.searchQuery != null &&
                  widget.searchQuery!.isNotEmpty &&
                  segment.text.toLowerCase().contains(
                        widget.searchQuery!.toLowerCase(),
                      );

              return TextSpan(
                text: segment.text + ' ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  backgroundColor: isHighlighted
                      ? speakerColor.withValues(alpha: 0.3)
                      : matchesSearch
                          ? Colors.yellow.withValues(alpha: 0.4)
                          : null,
                  color: colorScheme.onSurface,
                ),
                recognizer: null, // Would add TapGestureRecognizer for seek
              );
            }).toList(),
          ),
          onTap: () {
            // Seek to tapped word position
          },
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Recording indicator with pulsing animation
class _RecordingIndicator extends StatefulWidget {
  const _RecordingIndicator();

  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(
                  alpha: 0.5 + _controller.value * 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recording...',
              style: TextStyle(
                color: Colors.red.withValues(
                  alpha: 0.7 + _controller.value * 0.3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter for waveform with speaker colors
class _SpeakerWaveformPainter extends CustomPainter {
  final List<double> waveformPeaks;
  final List<AudioSegment> segments;
  final double duration;
  final Color Function(AudioSegment) getSpeakerColor;
  final bool shrinkSilence;
  final Color backgroundColor;

  _SpeakerWaveformPainter({
    required this.waveformPeaks,
    required this.segments,
    required this.duration,
    required this.getSpeakerColor,
    required this.shrinkSilence,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    if (waveformPeaks.isEmpty || duration <= 0) return;

    final centerY = size.height / 2;
    final maxHeight = size.height * 0.8;
    final peakWidth = size.width / waveformPeaks.length;

    for (var i = 0; i < waveformPeaks.length; i++) {
      final x = i * peakWidth;
      final timeAtX = (i / waveformPeaks.length) * duration;

      // Find segment at this time
      AudioSegment? segment;
      for (final s in segments) {
        if (timeAtX >= s.startTime && timeAtX <= s.endTime) {
          segment = s;
          break;
        }
      }

      // Determine color based on speaker
      Color color;
      double amplitude = waveformPeaks[i];

      if (segment != null) {
        if (segment.isSilence && shrinkSilence) {
          // Draw thin line for silence
          amplitude = 0.05;
          color = Colors.grey.withValues(alpha: 0.3);
        } else {
          color = getSpeakerColor(segment);
        }
      } else {
        color = Colors.grey;
      }

      final barHeight = amplitude * maxHeight;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + peakWidth / 2, centerY),
          width: peakWidth * 0.8,
          height: barHeight.clamp(2.0, maxHeight),
        ),
        const Radius.circular(1),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SpeakerWaveformPainter oldDelegate) =>
      waveformPeaks != oldDelegate.waveformPeaks ||
      segments != oldDelegate.segments;
}
