// Voice Note Block Widget
//
// Interactive voice note component for markdown/text editors.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kivixa/components/audio/audio_waveform.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Transcription segment with speaker info
class TranscriptSegment {
  /// Segment text
  final String text;

  /// Start time in seconds
  final double startTime;

  /// End time in seconds
  final double endTime;

  /// Speaker identifier (for diarization)
  final String? speakerId;

  /// Confidence level
  final double confidence;

  const TranscriptSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.speakerId,
    this.confidence = 1.0,
  });
}

/// Voice note data model
class VoiceNoteData {
  /// Audio samples (f32 normalized)
  final List<double> samples;

  /// Sample rate
  final int sampleRate;

  /// Total duration in seconds
  final double duration;

  /// Transcription segments
  final List<TranscriptSegment> segments;

  /// Full transcription text
  final String fullText;

  /// Waveform peaks for visualization
  final List<double> waveformPeaks;

  const VoiceNoteData({
    required this.samples,
    required this.sampleRate,
    required this.duration,
    required this.segments,
    required this.fullText,
    required this.waveformPeaks,
  });

  /// Create empty voice note data
  static const empty = VoiceNoteData(
    samples: [],
    sampleRate: 16000,
    duration: 0,
    segments: [],
    fullText: '',
    waveformPeaks: [],
  );

  /// Get segment at a specific time
  TranscriptSegment? getSegmentAtTime(double time) {
    for (final segment in segments) {
      if (time >= segment.startTime && time <= segment.endTime) {
        return segment;
      }
    }
    return null;
  }

  /// Search for text and return matching segments
  List<TranscriptSegment> search(String query) {
    final lowerQuery = query.toLowerCase();
    return segments
        .where((s) => s.text.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

/// Voice note block widget
class VoiceNoteBlock extends StatefulWidget {
  /// Voice note data
  final VoiceNoteData? data;

  /// Callback when recording is complete
  final void Function(VoiceNoteData data)? onRecordingComplete;

  /// Callback when playback position changes
  final void Function(double position)? onPositionChanged;

  /// Whether to show transcript
  final bool showTranscript;

  /// Whether to enable karaoke mode (word highlighting)
  final bool enableKaraokeMode;

  /// Search query to highlight
  final String? searchQuery;

  /// Initial expanded state
  final bool initiallyExpanded;

  const VoiceNoteBlock({
    super.key,
    this.data,
    this.onRecordingComplete,
    this.onPositionChanged,
    this.showTranscript = true,
    this.enableKaraokeMode = true,
    this.searchQuery,
    this.initiallyExpanded = false,
  });

  @override
  State<VoiceNoteBlock> createState() => _VoiceNoteBlockState();
}

class _VoiceNoteBlockState extends State<VoiceNoteBlock> {
  final _engine = AudioNeuralEngine();
  final _playback = AudioPlaybackService();
  final _recorder = AudioRecordingService();

  VoiceNoteData? _data;
  var _isRecording = false;
  var _isExpanded = false;
  var _playbackPosition = 0.0;
  var _highlightedWordIndex = -1;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _isExpanded = widget.initiallyExpanded;

    _positionSub = _playback.positionStream.listen(_onPositionChanged);
    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _transcriptionSub?.cancel();
    super.dispose();
  }

  void _onPositionChanged(Duration position) {
    final seconds = position.inMilliseconds / 1000.0;
    setState(() => _playbackPosition = seconds);
    widget.onPositionChanged?.call(seconds);

    // Update highlighted word for karaoke mode
    if (widget.enableKaraokeMode && _data != null) {
      final segment = _data!.getSegmentAtTime(seconds);
      if (segment != null) {
        final index = _data!.segments.indexOf(segment);
        if (index != _highlightedWordIndex) {
          setState(() => _highlightedWordIndex = index);
        }
      }
    }
  }

  void _onTranscription(SpeechRecognitionResult result) {
    // Accumulate transcription during recording
    if (_isRecording) {
      // In a real implementation, build up segments as they come in
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _recorder.stopRecording();
      final result = await _engine.stopListening();

      if (result != null) {
        // Create voice note data from recording
        final newData = VoiceNoteData(
          samples: [], // Would be filled from actual recording
          sampleRate: 16000,
          duration: result.endTime,
          segments: [
            TranscriptSegment(
              text: result.text,
              startTime: 0,
              endTime: result.endTime,
              confidence: result.confidence,
            ),
          ],
          fullText: result.text,
          waveformPeaks: List.generate(50, (i) => math.Random().nextDouble()),
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
    if (_playback.isPlaying) {
      _playback.pause();
    } else if (_data != null && _data!.samples.isNotEmpty) {
      // In a real implementation, play the actual audio
      // For now, simulate with synthesis
      _playback.speak(_data!.fullText);
    }
  }

  void _seekToTime(double time) {
    _playback.seek(Duration(milliseconds: (time * 1000).round()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with controls
          _buildHeader(theme, colorScheme),

          // Waveform visualization
          if (_data != null || _isRecording) _buildWaveform(colorScheme),

          // Transcript (expandable)
          if (widget.showTranscript && _data != null) _buildTranscript(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Recording/playback button
          if (_data == null)
            _buildRecordButton(colorScheme)
          else
            _buildPlayButton(colorScheme),

          const SizedBox(width: 12),

          // Title and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRecording
                      ? 'Recording...'
                      : _data != null
                      ? 'Voice Note'
                      : 'New Voice Note',
                  style: theme.textTheme.titleMedium,
                ),
                if (_data != null)
                  Text(
                    _formatDuration(_data!.duration),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),

          // Expand/collapse button
          if (_data != null && widget.showTranscript)
            IconButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(ColorScheme colorScheme) {
    return IconButton.filled(
      onPressed: _toggleRecording,
      style: IconButton.styleFrom(
        backgroundColor: _isRecording
            ? colorScheme.error
            : colorScheme.primaryContainer,
        foregroundColor: _isRecording
            ? colorScheme.onError
            : colorScheme.onPrimaryContainer,
      ),
      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
    );
  }

  Widget _buildPlayButton(ColorScheme colorScheme) {
    return ValueListenableBuilder(
      valueListenable: _playback.state,
      builder: (context, state, _) {
        final isPlaying = state == PlaybackState.playing;

        return IconButton.filled(
          onPressed: _togglePlayback,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        );
      },
    );
  }

  Widget _buildWaveform(ColorScheme colorScheme) {
    return GestureDetector(
      onTapDown: (details) {
        if (_data != null) {
          // Calculate time from tap position
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            final progress = localPosition.dx / box.size.width;
            final time = progress * _data!.duration;
            _seekToTime(time);
          }
        }
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: _isRecording
            ? const AudioWaveform(style: WaveformStyle.bars, barCount: 32)
            : _buildStaticWaveform(colorScheme),
      ),
    );
  }

  Widget _buildStaticWaveform(ColorScheme colorScheme) {
    if (_data == null || _data!.waveformPeaks.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _StaticWaveformPainter(
        peaks: _data!.waveformPeaks,
        progress: _playbackPosition / _data!.duration,
        activeColor: colorScheme.primary,
        inactiveColor: colorScheme.outline.withValues(alpha: 0.3),
        searchMatches: widget.searchQuery != null
            ? _getSearchMatchPositions()
            : null,
        highlightColor: colorScheme.tertiary,
      ),
      size: const Size(double.infinity, 60),
    );
  }

  List<double> _getSearchMatchPositions() {
    if (_data == null || widget.searchQuery == null) return [];

    final matches = _data!.search(widget.searchQuery!);
    return matches.map((m) => m.startTime / _data!.duration).toList();
  }

  Widget _buildTranscript(ThemeData theme) {
    if (!_isExpanded) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          if (_data!.segments.isEmpty)
            Text(_data!.fullText, style: theme.textTheme.bodyMedium)
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _data!.segments.asMap().entries.map((entry) {
                final index = entry.key;
                final segment = entry.value;
                final isHighlighted =
                    widget.enableKaraokeMode && index == _highlightedWordIndex;
                final isSearchMatch =
                    widget.searchQuery != null &&
                    segment.text.toLowerCase().contains(
                      widget.searchQuery!.toLowerCase(),
                    );

                return _buildWordChip(
                  segment,
                  isHighlighted,
                  isSearchMatch,
                  theme,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWordChip(
    TranscriptSegment segment,
    bool isHighlighted,
    bool isSearchMatch,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _seekToTime(segment.startTime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : isSearchMatch
              ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(4),
          border: isHighlighted
              ? Border.all(color: theme.colorScheme.primary)
              : null,
        ),
        child: Text(
          segment.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlighted ? FontWeight.bold : null,
            color: isSearchMatch
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurface,
          ),
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

class _StaticWaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final List<double>? searchMatches;
  final Color highlightColor;

  _StaticWaveformPainter({
    required this.peaks,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.searchMatches,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final barWidth = size.width / (peaks.length * 2);
    final maxHeight = size.height * 0.8;
    final centerY = size.height / 2;

    for (var i = 0; i < peaks.length; i++) {
      final position = i / peaks.length;
      final isActive = position <= progress;
      final isSearchMatch =
          searchMatches?.any((m) => (m - position).abs() < 0.05) ?? false;

      final paint = Paint()
        ..color = isSearchMatch
            ? highlightColor
            : isActive
            ? activeColor
            : inactiveColor
        ..style = PaintingStyle.fill;

      final barHeight = peaks[i] * maxHeight;
      final x = i * barWidth * 2 + barWidth / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight.clamp(4.0, maxHeight),
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }

    // Draw progress line
    final progressX = progress * size.width;
    final linePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(progressX, 0),
      Offset(progressX, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_StaticWaveformPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        peaks != oldDelegate.peaks ||
        searchMatches != oldDelegate.searchMatches;
  }
}
