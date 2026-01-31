// Neural Dictation Bar Widget
//
// Smart dictation input accessory that sits above the keyboard.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kivixa/components/audio/audio_waveform.dart';
import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Dictation mode
enum DictationMode {
  /// Normal text dictation
  text,

  /// Command mode for app actions
  command,
}

/// Neural dictation bar widget
class NeuralDictationBar extends StatefulWidget {
  /// Callback when text is recognized
  final void Function(String text, bool isFinal)? onTextRecognized;

  /// Callback when a command is recognized
  final void Function(String command)? onCommandRecognized;

  /// Text editing controller to insert text into
  final TextEditingController? controller;

  /// Height of the dictation bar
  final double height;

  /// Whether to show confidence indicator
  final bool showConfidence;

  /// Whether to enable command mode
  final bool enableCommandMode;

  const NeuralDictationBar({
    super.key,
    this.onTextRecognized,
    this.onCommandRecognized,
    this.controller,
    this.height = 56,
    this.showConfidence = true,
    this.enableCommandMode = true,
  });

  @override
  State<NeuralDictationBar> createState() => _NeuralDictationBarState();
}

class _NeuralDictationBarState extends State<NeuralDictationBar> {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();

  DictationMode _mode = DictationMode.text;
  var _currentText = '';
  var _confidence = 0.0;
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
    setState(() {
      _currentText = result.text;
      _confidence = result.confidence;
    });

    if (_mode == DictationMode.command && result.isFinal) {
      widget.onCommandRecognized?.call(result.text);
    } else {
      widget.onTextRecognized?.call(result.text, result.isFinal);

      // Insert into controller if final
      if (result.isFinal && widget.controller != null) {
        _insertTextAtCursor(result.text);
      }
    }
  }

  void _insertTextAtCursor(String text) {
    final controller = widget.controller;
    if (controller == null) return;

    final selection = controller.selection;
    final currentText = controller.text;

    String newText;
    int newCursorPos;

    if (selection.isValid && selection.isCollapsed) {
      // Insert at cursor
      newText =
          currentText.substring(0, selection.start) +
          text +
          currentText.substring(selection.end);
      newCursorPos = selection.start + text.length;
    } else if (selection.isValid) {
      // Replace selection
      newText =
          currentText.substring(0, selection.start) +
          text +
          currentText.substring(selection.end);
      newCursorPos = selection.start + text.length;
    } else {
      // Append to end
      newText = currentText + text;
      newCursorPos = newText.length;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _recorder.stopRecording();
      await _engine.stopListening();
      setState(() => _isListening = false);
    } else {
      await _engine.initialize();
      await _engine.startListening();
      await _recorder.startRecording();
      setState(() {
        _isListening = true;
        _currentText = '';
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == DictationMode.text
          ? DictationMode.command
          : DictationMode.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Microphone button
          _buildMicButton(colorScheme),

          // Waveform / Text display
          Expanded(
            child: _isListening ? _buildWaveform() : _buildTextPreview(theme),
          ),

          // Confidence indicator
          if (widget.showConfidence && _isListening)
            _buildConfidenceIndicator(colorScheme),

          // Command mode button
          if (widget.enableCommandMode) _buildCommandButton(colorScheme),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMicButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton.filled(
        onPressed: _toggleListening,
        style: IconButton.styleFrom(
          backgroundColor: _isListening
              ? colorScheme.error
              : colorScheme.primaryContainer,
          foregroundColor: _isListening
              ? colorScheme.onError
              : colorScheme.onPrimaryContainer,
        ),
        icon: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
    );
  }

  Widget _buildWaveform() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const AudioWaveform(
            height: 40,
            style: WaveformStyle.bars,
            barCount: 24,
          ),
          // Overlay current text
          if (_currentText.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black54,
                child: Text(
                  _currentText,
                  style: TextStyle(
                    color: _confidence > 0.8 ? Colors.white : Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextPreview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        _currentText.isEmpty ? 'Tap mic to start dictation' : _currentText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: _currentText.isEmpty
              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
              : theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildConfidenceIndicator(ColorScheme colorScheme) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _confidence,
            strokeWidth: 3,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              _confidence > 0.8
                  ? colorScheme.primary
                  : _confidence > 0.5
                  ? colorScheme.tertiary
                  : colorScheme.error,
            ),
          ),
          Text(
            '${(_confidence * 100).round()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: _toggleMode,
      icon: Icon(
        _mode == DictationMode.command ? Icons.terminal : Icons.text_fields,
      ),
      color: _mode == DictationMode.command
          ? colorScheme.primary
          : colorScheme.onSurface.withValues(alpha: 0.6),
      tooltip: _mode == DictationMode.command ? 'Text mode' : 'Command mode',
    );
  }
}

/// Floating dictation button that can be placed anywhere
class FloatingDictationButton extends StatefulWidget {
  /// Callback when text is recognized
  final void Function(String text)? onTextRecognized;

  /// Button size
  final double size;

  const FloatingDictationButton({
    super.key,
    this.onTextRecognized,
    this.size = 56,
  });

  @override
  State<FloatingDictationButton> createState() =>
      _FloatingDictationButtonState();
}

class _FloatingDictationButtonState extends State<FloatingDictationButton>
    with SingleTickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();

  late AnimationController _pulseController;
  var _isListening = false;
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _transcriptionSub = _engine.transcriptionStream.listen((result) {
      if (result.isFinal) {
        widget.onTextRecognized?.call(result.text);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transcriptionSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _pulseController.stop();
      await _recorder.stopRecording();
      final result = await _engine.stopListening();
      if (result != null) {
        widget.onTextRecognized?.call(result.text);
      }
      setState(() => _isListening = false);
    } else {
      await _engine.initialize();
      await _engine.startListening();
      await _recorder.startRecording();
      _pulseController.repeat(reverse: true);
      setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_isListening ? _pulseController.value * 0.1 : 0.0);

        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            onPressed: _toggleListening,
            backgroundColor: _isListening
                ? colorScheme.error
                : colorScheme.primaryContainer,
            foregroundColor: _isListening
                ? colorScheme.onError
                : colorScheme.onPrimaryContainer,
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
              size: widget.size * 0.5,
            ),
          ),
        );
      },
    );
  }
}
