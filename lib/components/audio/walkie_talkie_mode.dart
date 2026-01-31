// AI Walkie-Talkie Mode
//
// Full-screen hands-free AI conversation mode using voice.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Walkie-talkie conversation turn
class ConversationTurn {
  /// Who spoke
  final bool isUser;

  /// Text content
  final String text;

  /// Timestamp
  final DateTime timestamp;

  const ConversationTurn({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}

/// AI walkie-talkie mode state
enum WalkieTalkieState {
  /// Idle, not active
  idle,

  /// Listening for user speech
  listening,

  /// Processing user speech
  processing,

  /// AI is responding
  responding,

  /// Paused
  paused,
}

/// Full-screen walkie-talkie mode for hands-free AI conversation
class WalkieTalkieMode extends StatefulWidget {
  /// Callback to send user message to AI and get response
  final Future<String> Function(String userMessage) onSendMessage;

  /// Callback when mode is exited
  final VoidCallback? onExit;

  const WalkieTalkieMode({super.key, required this.onSendMessage, this.onExit});

  /// Show walkie-talkie mode as full screen
  static Future<void> show(
    BuildContext context, {
    required Future<String> Function(String userMessage) onSendMessage,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return WalkieTalkieMode(
            onSendMessage: onSendMessage,
            onExit: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<WalkieTalkieMode> createState() => _WalkieTalkieModeState();
}

class _WalkieTalkieModeState extends State<WalkieTalkieMode>
    with TickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _recorder = AudioRecordingService();
  final _playback = AudioPlaybackService();

  late AnimationController _userOrbController;
  late AnimationController _aiOrbController;

  var _state = WalkieTalkieState.idle;
  final List<ConversationTurn> _conversation = [];
  var _currentTranscription = '';

  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;
  StreamSubscription<bool>? _vadSub;

  @override
  void initState() {
    super.initState();

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _userOrbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _aiOrbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _initialize();
  }

  @override
  void dispose() {
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _userOrbController.dispose();
    _aiOrbController.dispose();
    _transcriptionSub?.cancel();
    _vadSub?.cancel();
    _cleanup();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _engine.initialize();

    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);
    _vadSub = _engine.vadStream.listen(_onVadStateChange);

    // Start in listening mode
    await _startListening();
  }

  Future<void> _cleanup() async {
    await _recorder.stopRecording();
    await _engine.stopListening();
    _playback.stop();
  }

  void _onTranscription(SpeechRecognitionResult result) {
    setState(() => _currentTranscription = result.text);

    if (result.isFinal && result.text.isNotEmpty) {
      _processUserMessage(result.text);
    }
  }

  void _onVadStateChange(bool isSpeaking) {
    if (isSpeaking) {
      _userOrbController.repeat(reverse: true);
    } else {
      _userOrbController.stop();
      _userOrbController.animateTo(0);
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _state = WalkieTalkieState.listening;
      _currentTranscription = '';
    });

    _engine.startListening();
    await _recorder.startRecording();
  }

  Future<void> _stopListening() async {
    await _recorder.stopRecording();
    await _engine.stopListening();
  }

  Future<void> _processUserMessage(String message) async {
    await _stopListening();

    setState(() {
      _state = WalkieTalkieState.processing;
      _conversation.add(
        ConversationTurn(
          isUser: true,
          text: message,
          timestamp: DateTime.now(),
        ),
      );
    });

    try {
      // Get AI response
      final response = await widget.onSendMessage(message);

      setState(() {
        _state = WalkieTalkieState.responding;
        _conversation.add(
          ConversationTurn(
            isUser: false,
            text: response,
            timestamp: DateTime.now(),
          ),
        );
      });

      // Speak AI response
      _aiOrbController.repeat(reverse: true);
      await _speakResponse(response);
      _aiOrbController.stop();
      _aiOrbController.animateTo(0);

      // Resume listening
      await _startListening();
    } catch (e) {
      // Handle error, resume listening
      await _startListening();
    }
  }

  Future<void> _speakResponse(String text) async {
    await _playback.speak(text);

    // Wait for speech to complete
    while (_playback.state.value == PlaybackState.playing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _togglePause() {
    if (_state == WalkieTalkieState.paused) {
      _startListening();
    } else if (_state == WalkieTalkieState.listening) {
      _stopListening();
      setState(() => _state = WalkieTalkieState.paused);
    }
  }

  void _exit() {
    _cleanup();
    widget.onExit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _exit,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Text(
                    'AI Walkie-Talkie',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _togglePause,
                    icon: Icon(
                      _state == WalkieTalkieState.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Conversation history
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                reverse: true,
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  final turn = _conversation[_conversation.length - 1 - index];
                  return _ConversationBubble(turn: turn);
                },
              ),
            ),

            // Orbs section
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // User orb (bottom left)
                  Positioned(
                    left: 60,
                    bottom: 80,
                    child: _AudioOrb(
                      controller: _userOrbController,
                      isActive: _state == WalkieTalkieState.listening,
                      color: colorScheme.primary,
                      label: 'You',
                      size: 120,
                    ),
                  ),

                  // AI orb (top right)
                  Positioned(
                    right: 60,
                    top: 40,
                    child: _AudioOrb(
                      controller: _aiOrbController,
                      isActive: _state == WalkieTalkieState.responding,
                      color: colorScheme.secondary,
                      label: 'AI',
                      size: 140,
                    ),
                  ),

                  // Connection line
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _ConnectionPainter(
                      progress: _state == WalkieTalkieState.responding
                          ? 1.0
                          : _state == WalkieTalkieState.listening
                          ? 0.5
                          : 0.2,
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Current transcription
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: Text(
                _getStatusText(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_state) {
      case WalkieTalkieState.idle:
        return 'Initializing...';
      case WalkieTalkieState.listening:
        return _currentTranscription.isEmpty
            ? 'Listening...'
            : _currentTranscription;
      case WalkieTalkieState.processing:
        return 'Processing...';
      case WalkieTalkieState.responding:
        return 'AI is speaking...';
      case WalkieTalkieState.paused:
        return 'Paused - Tap play to resume';
    }
  }
}

/// Animated audio orb widget
class _AudioOrb extends StatelessWidget {
  final AnimationController controller;
  final bool isActive;
  final Color color;
  final String label;
  final double size;

  const _AudioOrb({
    required this.controller,
    required this.isActive,
    required this.color,
    required this.label,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final scale = 1.0 + controller.value * 0.2;
            return Transform.scale(
              scale: isActive ? scale : 1.0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color,
                      color.withValues(alpha: isActive ? 0.5 : 0.2),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  label == 'You' ? Icons.person : Icons.smart_toy,
                  size: size * 0.4,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Conversation bubble widget
class _ConversationBubble extends StatelessWidget {
  final ConversationTurn turn;

  const _ConversationBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: turn.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: turn.isUser
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              turn.text,
              style: TextStyle(
                color: turn.isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection painter between orbs
class _ConnectionPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ConnectionPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * (1 - progress),
        size.width,
        0,
      );

    canvas.drawPath(path, paint);

    // Draw animated dots
    if (progress > 0.3) {
      final dotPaint = Paint()..color = color;
      const dotCount = 3;
      for (var i = 0; i < dotCount; i++) {
        final t = (progress - 0.3 + i * 0.15) % 1.0;
        final point = _getPointOnPath(path, t, size);
        canvas.drawCircle(point, 4, dotPaint);
      }
    }
  }

  Offset _getPointOnPath(Path path, double t, Size size) {
    final x = t * size.width;
    final y = size.height * (1 - t) * (1 - math.pow(t, 0.5));
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
