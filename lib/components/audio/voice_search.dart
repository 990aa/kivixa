// Voice Search Widget
//
// Voice-enabled search with semantic audio search capabilities.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kivixa/components/audio/audio_waveform.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Voice search result
class VoiceSearchResult {
  /// Search query (spoken)
  final String query;

  /// Whether this is a final result
  final bool isFinal;

  /// Confidence level
  final double confidence;

  const VoiceSearchResult({
    required this.query,
    required this.isFinal,
    required this.confidence,
  });
}

/// Voice search widget that can be embedded in search bars
class VoiceSearchButton extends StatefulWidget {
  /// Callback when voice search produces a query
  final void Function(VoiceSearchResult result)? onSearchQuery;

  /// Callback when listening state changes
  final void Function(bool isListening)? onListeningChanged;

  /// Button size
  final double size;

  /// Icon when idle
  final IconData idleIcon;

  /// Icon when listening
  final IconData listeningIcon;

  const VoiceSearchButton({
    super.key,
    this.onSearchQuery,
    this.onListeningChanged,
    this.size = 24,
    this.idleIcon = Icons.mic,
    this.listeningIcon = Icons.mic_off,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();

  var _isListening = false;
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;

  @override
  void initState() {
    super.initState();
    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);
  }

  @override
  void dispose() {
    _transcriptionSub?.cancel();
    super.dispose();
  }

  void _onTranscription(SpeechRecognitionResult result) {
    widget.onSearchQuery?.call(
      VoiceSearchResult(
        query: result.text,
        isFinal: result.isFinal,
        confidence: result.confidence,
      ),
    );

    // Auto-stop on final result
    if (result.isFinal) {
      _stopListening();
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    await _engine.initialize();
    await _engine.startListening();
    await _recorder.startRecording();

    setState(() => _isListening = true);
    widget.onListeningChanged?.call(true);
  }

  Future<void> _stopListening() async {
    await _recorder.stopRecording();
    final result = await _engine.stopListening();

    setState(() => _isListening = false);
    widget.onListeningChanged?.call(false);

    if (result != null) {
      widget.onSearchQuery?.call(
        VoiceSearchResult(
          query: result.text,
          isFinal: true,
          confidence: result.confidence,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: _toggleListening,
      icon: Icon(
        _isListening ? widget.listeningIcon : widget.idleIcon,
        size: widget.size,
        color: _isListening ? colorScheme.error : colorScheme.onSurface,
      ),
      tooltip: _isListening ? 'Stop voice search' : 'Voice search',
    );
  }
}

/// Full voice search modal dialog
class VoiceSearchModal extends StatefulWidget {
  /// Callback when search is complete
  final void Function(String query)? onSearch;

  const VoiceSearchModal({super.key, this.onSearch});

  /// Show the voice search modal
  static Future<String?> show(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => VoiceSearchModal(
        onSearch: (query) => Navigator.of(context).pop(query),
      ),
    );
  }

  @override
  State<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<VoiceSearchModal>
    with SingleTickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();

  late AnimationController _pulseController;
  var _currentText = '';
  var _isListening = false;
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);

    // Start listening immediately
    _startListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transcriptionSub?.cancel();
    _stopListening();
    super.dispose();
  }

  void _onTranscription(SpeechRecognitionResult result) {
    setState(() => _currentText = result.text);

    if (result.isFinal && result.text.isNotEmpty) {
      widget.onSearch?.call(result.text);
    }
  }

  Future<void> _startListening() async {
    await _engine.initialize();
    await _engine.startListening();
    await _recorder.startRecording();
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _recorder.stopRecording();
    await _engine.stopListening();
    setState(() => _isListening = false);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _submit() {
    if (_currentText.isNotEmpty) {
      widget.onSearch?.call(_currentText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Listening orb
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.15;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.3),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 48,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Status text
            Text(
              _isListening ? 'Listening...' : 'Starting...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Current transcription
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                _currentText.isEmpty ? 'Say something...' : _currentText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _currentText.isEmpty
                      ? colorScheme.onSurface.withValues(alpha: 0.5)
                      : colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 16),

            // Waveform
            SizedBox(
              height: 40,
              child: AudioWaveform(
                style: WaveformStyle.line,
                barCount: 20,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(onPressed: _cancel, child: const Text('Cancel')),
                FilledButton(
                  onPressed: _currentText.isNotEmpty ? _submit : null,
                  child: const Text('Search'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
