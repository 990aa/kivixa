// Neural Input Bar Widget
//
// Enhanced smart dictation input accessory with glassmorphism,
// ghost text preview, and Bezier curve waveform visualization.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Dictation mode
enum DictationMode {
  /// Normal text dictation
  text,

  /// Command mode for app actions
  command,
}

/// Ghost text state for showing unconfirmed transcription
class GhostTextState {
  /// The ghost text (unconfirmed)
  final String ghostText;

  /// The finalized text
  final String finalizedText;

  /// Confidence level
  final double confidence;

  /// Alternative interpretations
  final List<String> alternatives;

  const GhostTextState({
    this.ghostText = '',
    this.finalizedText = '',
    this.confidence = 0.0,
    this.alternatives = const [],
  });

  GhostTextState copyWith({
    String? ghostText,
    String? finalizedText,
    double? confidence,
    List<String>? alternatives,
  }) {
    return GhostTextState(
      ghostText: ghostText ?? this.ghostText,
      finalizedText: finalizedText ?? this.finalizedText,
      confidence: confidence ?? this.confidence,
      alternatives: alternatives ?? this.alternatives,
    );
  }

  String get displayText => finalizedText + ghostText;
}

/// Neural Input Bar - Smart dictation with glassmorphism design
class NeuralInputBar extends StatefulWidget {
  /// Callback when text is finalized
  final void Function(String text)? onTextFinalized;

  /// Callback when a command is recognized in command mode
  final void Function(String command)? onCommandRecognized;

  /// Text editing controller to insert text into
  final TextEditingController? controller;

  /// Height of the bar
  final double height;

  /// Whether to enable command mode toggle
  final bool enableCommandMode;

  /// Custom blur sigma for glassmorphism
  final double blurSigma;

  /// Whether to show above keyboard (Android) or as floating bar (Windows)
  final bool floatingMode;

  const NeuralInputBar({
    super.key,
    this.onTextFinalized,
    this.onCommandRecognized,
    this.controller,
    this.height = 64,
    this.enableCommandMode = true,
    this.blurSigma = 10.0,
    this.floatingMode = false,
  });

  @override
  State<NeuralInputBar> createState() => _NeuralInputBarState();
}

class _NeuralInputBarState extends State<NeuralInputBar>
    with TickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();

  // Animation controllers
  late AnimationController _micPulseController;
  late AnimationController _textFadeController;
  late AnimationController _waveController;

  // State
  DictationMode _mode = DictationMode.text;
  var _ghostState = const GhostTextState();
  var _isListening = false;
  // Paused state managed externally if needed
  List<double> _waveformAmplitudes = List.filled(64, 0.0);

  // Subscriptions
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;
  StreamSubscription<AudioVisualizerData>? _visualizerSub;
  StreamSubscription<bool>? _vadSub;

  @override
  void initState() {
    super.initState();

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();

    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);
    _visualizerSub = _engine.visualizerStream.listen(_onVisualizerData);
    _vadSub = _engine.vadStream.listen(_onVadState);
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _textFadeController.dispose();
    _waveController.dispose();
    _transcriptionSub?.cancel();
    _visualizerSub?.cancel();
    _vadSub?.cancel();
    super.dispose();
  }

  void _onTranscription(SpeechRecognitionResult result) {
    if (!mounted) return;

    if (result.isFinal) {
      // Finalize the text - animate it from ghost to solid
      _textFadeController.forward(from: 0.0);

      setState(() {
        _ghostState = _ghostState.copyWith(
          finalizedText: '${_ghostState.finalizedText}${result.text} ',
          ghostText: '',
          confidence: result.confidence,
        );
      });

      if (_mode == DictationMode.command) {
        widget.onCommandRecognized?.call(result.text);
      } else {
        // Insert into controller
        if (widget.controller != null) {
          _insertTextAtCursor('${result.text} ');
        }
        widget.onTextFinalized?.call(result.text);
      }
    } else {
      // Update ghost text with streaming animation
      setState(() {
        _ghostState = _ghostState.copyWith(
          ghostText: result.text,
          confidence: result.confidence,
        );
      });
    }
  }

  void _onVisualizerData(AudioVisualizerData data) {
    if (!mounted || !_isListening) return;

    setState(() {
      // Update waveform amplitudes from frequency bands
      if (data.frequencyBands.isNotEmpty) {
        _waveformAmplitudes = _interpolateAmplitudes(data.frequencyBands, 64);
      } else {
        // Decay existing amplitudes
        _waveformAmplitudes = _waveformAmplitudes
            .map((a) => (a * 0.9).clamp(0.0, 1.0))
            .toList();
      }
    });
  }

  void _onVadState(bool speaking) {
    if (!mounted) return;

    if (speaking && !_micPulseController.isAnimating) {
      _micPulseController.repeat(reverse: true);
    } else if (!speaking && _micPulseController.isAnimating) {
      _micPulseController.stop();
      _micPulseController.value = 0.0;
    }
  }

  List<double> _interpolateAmplitudes(List<double> bands, int targetCount) {
    if (bands.isEmpty) return List.filled(targetCount, 0.0);
    if (bands.length == targetCount) return bands;

    final result = <double>[];
    final ratio = bands.length / targetCount;

    for (var i = 0; i < targetCount; i++) {
      final srcIndex = (i * ratio).floor();
      final srcIndexNext = ((i + 1) * ratio).floor().clamp(0, bands.length - 1);
      final t = (i * ratio) - srcIndex;

      final value = bands[srcIndex] * (1 - t) + bands[srcIndexNext] * t;
      result.add(value.clamp(0.0, 1.0));
    }

    return result;
  }

  void _insertTextAtCursor(String text) {
    final controller = widget.controller;
    if (controller == null) return;

    final selection = controller.selection;
    final currentText = controller.text;

    String newText;
    int newCursorPos;

    if (selection.isValid && selection.isCollapsed) {
      newText =
          currentText.substring(0, selection.start) +
          text +
          currentText.substring(selection.end);
      newCursorPos = selection.start + text.length;
    } else if (selection.isValid) {
      newText =
          currentText.substring(0, selection.start) +
          text +
          currentText.substring(selection.end);
      newCursorPos = selection.start + text.length;
    } else {
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
      // Stop listening
      _micPulseController.stop();
      await _recorder.stopRecording();
      await _engine.stopListening();

      setState(() {
        _isListening = false;
        _waveformAmplitudes = List.filled(64, 0.0);
      });

      HapticFeedback.mediumImpact();
    } else {
      // Start listening
      final success = await _engine.initialize();
      if (!success) {
        _showError('Failed to initialize audio engine');
        return;
      }

      await _engine.startListening();
      await _recorder.startRecording();

      setState(() {
        _isListening = true;
        _ghostState = const GhostTextState();
      });

      HapticFeedback.lightImpact();
    }
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = _mode == DictationMode.text
          ? DictationMode.command
          : DictationMode.text;
      _ghostState = const GhostTextState();
    });
  }

  void _showAlternatives() {
    if (_ghostState.alternatives.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => _AlternativesSheet(
        alternatives: _ghostState.alternatives,
        onSelect: (text) {
          setState(() {
            _ghostState = _ghostState.copyWith(
              finalizedText: '${_ghostState.finalizedText}$text ',
              ghostText: '',
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget content = _buildContent(theme, colorScheme);

    if (widget.floatingMode) {
      return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: _buildGlassmorphicContainer(content, colorScheme),
      );
    }

    return _buildGlassmorphicContainer(content, colorScheme);
  }

  Widget _buildGlassmorphicContainer(Widget child, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: widget.floatingMode
          ? BorderRadius.circular(16)
          : BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: widget.floatingMode
                ? BorderRadius.circular(16)
                : null,
            border: Border(
              top: widget.floatingMode
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
            ),
            boxShadow: widget.floatingMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Pulsating microphone button
        _buildMicButton(colorScheme),

        // Center: Waveform or Ghost Text
        Expanded(
          child: _isListening
              ? _buildBezierWaveform(colorScheme)
              : _buildGhostText(theme, colorScheme),
        ),

        // Command mode toggle
        if (widget.enableCommandMode) _buildCommandToggle(colorScheme),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMicButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedBuilder(
        animation: _micPulseController,
        builder: (context, child) {
          final scale = 1.0 + (_micPulseController.value * 0.15);
          final glowOpacity = _micPulseController.value * 0.5;

          return DecoratedBox(
            decoration: _isListening
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.error.withValues(alpha: glowOpacity),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : const BoxDecoration(),
            child: Transform.scale(
              scale: _isListening ? scale : 1.0,
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
                icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBezierWaveform(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          return CustomPaint(
            painter: _BezierWaveformPainter(
              amplitudes: _waveformAmplitudes,
              color: colorScheme.primary,
              secondaryColor: colorScheme.tertiary,
              time: _waveController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildGhostText(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _ghostState.ghostText.isNotEmpty ? _showAlternatives : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              // Finalized text (solid)
              TextSpan(
                text: _ghostState.finalizedText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              // Ghost text (faded, animated)
              TextSpan(
                text: _ghostState.ghostText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(
                    alpha: 0.5 + (_ghostState.confidence * 0.3),
                  ),
                  fontStyle: FontStyle.italic,
                ),
              ),
              // Placeholder
              if (_ghostState.displayText.isEmpty)
                TextSpan(
                  text: _mode == DictationMode.command
                      ? 'Tap mic for voice commands...'
                      : 'Tap mic to start dictation...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandToggle(ColorScheme colorScheme) {
    return IconButton(
      onPressed: _toggleMode,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _mode == DictationMode.command
              ? Icons.bolt_rounded
              : Icons.text_fields_rounded,
          key: ValueKey(_mode),
        ),
      ),
      color: _mode == DictationMode.command
          ? colorScheme.primary
          : colorScheme.onSurface.withValues(alpha: 0.6),
      tooltip: _mode == DictationMode.command
          ? 'Switch to text mode'
          : 'Switch to command mode',
    );
  }
}

/// Custom painter for Bezier curve waveform (Siri/Google Assistant style)
class _BezierWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final Color secondaryColor;
  final double time;

  _BezierWaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.secondaryColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, secondaryColor, color],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final pointCount = amplitudes.length;
    final dx = size.width / (pointCount - 1);

    // Start point
    path.moveTo(0, centerY);

    // Draw smooth bezier curve through all points
    for (var i = 0; i < pointCount - 1; i++) {
      final x1 = i * dx;
      final x2 = (i + 1) * dx;

      // Add subtle animation wave
      final waveOffset = (time * 2 * 3.14159 + i * 0.2).remainder(6.28);
      final animatedAmp1 = amplitudes[i] + (0.05 * (1 + (waveOffset).abs()));
      final animatedAmp2 =
          amplitudes[i + 1] + (0.05 * (1 + (waveOffset + 0.2).abs()));

      final y1 = centerY - (animatedAmp1 * size.height * 0.4);
      final y2 = centerY - (animatedAmp2 * size.height * 0.4);

      // Control points for smooth curve
      final cpX = (x1 + x2) / 2;

      path.quadraticBezierTo(cpX, y1, x2, y2);
    }

    canvas.drawPath(path, paint);

    // Draw mirrored reflection (subtle)
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.3),
          secondaryColor.withValues(alpha: 0.3),
          color.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final reflectionPath = Path();
    reflectionPath.moveTo(0, centerY);

    for (var i = 0; i < pointCount - 1; i++) {
      final x1 = i * dx;
      final x2 = (i + 1) * dx;

      final waveOffset = (time * 2 * 3.14159 + i * 0.2).remainder(6.28);
      final animatedAmp1 = amplitudes[i] + (0.05 * (1 + (waveOffset).abs()));
      final animatedAmp2 =
          amplitudes[i + 1] + (0.05 * (1 + (waveOffset + 0.2).abs()));

      final y1 = centerY + (animatedAmp1 * size.height * 0.3);
      final y2 = centerY + (animatedAmp2 * size.height * 0.3);

      final cpX = (x1 + x2) / 2;
      reflectionPath.quadraticBezierTo(cpX, y1, x2, y2);
    }

    canvas.drawPath(reflectionPath, reflectionPaint);
  }

  @override
  bool shouldRepaint(_BezierWaveformPainter oldDelegate) => true; // Always repaint for animation
}

/// Bottom sheet for showing alternative interpretations
class _AlternativesSheet extends StatelessWidget {
  final List<String> alternatives;
  final void Function(String) onSelect;

  const _AlternativesSheet({
    required this.alternatives,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alternative Interpretations',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...alternatives.map(
            (alt) => ListTile(
              title: Text(alt),
              onTap: () => onSelect(alt),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
