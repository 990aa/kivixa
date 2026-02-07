// Walkie-Talkie Mode Widget
//
// Full-screen hands-free AI conversation mode with dual animated orbs
// for user and AI, real-time speech detection, and instant interruption.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';
import 'package:kivixa/services/audio/audio_playback_service.dart';
import 'package:kivixa/services/audio/audio_recording_service.dart';

/// Conversation turn in walkie-talkie mode
class ConversationMessage {
  /// Whether this is a user message
  final bool isUser;

  /// Message text
  final String text;

  /// Timestamp
  final DateTime timestamp;

  /// Audio duration (if applicable)
  final Duration? audioDuration;

  const ConversationMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.audioDuration,
  });
}

/// Walkie-Talkie state machine
enum WalkieTalkiePhase {
  /// Idle, waiting for user to speak
  idle,

  /// User is speaking
  userSpeaking,

  /// Processing user input
  thinking,

  /// AI is responding
  aiSpeaking,

  /// Paused by user
  paused,
}

/// Walkie-Talkie Mode - Full-screen hands-free AI chat
class WalkieTalkieScreen extends StatefulWidget {
  /// Callback to send message to AI and receive response
  final Future<String> Function(String message) onSendMessage;

  /// Callback when closing walkie-talkie mode
  final VoidCallback? onClose;

  /// AI name to display
  final String aiName;

  /// Enable auto-listen (start listening automatically after AI speaks)
  final bool autoListen;

  const WalkieTalkieScreen({
    super.key,
    required this.onSendMessage,
    this.onClose,
    this.aiName = 'Kivixa AI',
    this.autoListen = true,
  });

  @override
  State<WalkieTalkieScreen> createState() => _WalkieTalkieScreenState();
}

class _WalkieTalkieScreenState extends State<WalkieTalkieScreen>
    with TickerProviderStateMixin {
  final _engine = AudioNeuralEngine();
  final _playback = AudioPlaybackService();
  final _recorder = AudioRecordingService();

  // Animation controllers
  late AnimationController _userOrbController;
  late AnimationController _aiOrbController;
  late AnimationController _thinkingController;
  late AnimationController _backgroundController;

  // State
  WalkieTalkiePhase _phase = WalkieTalkiePhase.idle;
  final List<ConversationMessage> _messages = [];
  var _currentUserText = '';
  var _currentAiText = '';
  var _userAmplitude = 0.0;

  // Subscriptions
  StreamSubscription<SpeechRecognitionResult>? _transcriptionSub;
  StreamSubscription<bool>? _vadSub;
  StreamSubscription<AudioVisualizerData>? _visualizerSub;
  VoidCallback? _playbackListener;

  @override
  void initState() {
    super.initState();

    _userOrbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _aiOrbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _thinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _setupSubscriptions();
    _startListening();
  }

  void _setupSubscriptions() {
    _transcriptionSub = _engine.transcriptionStream.listen(_onTranscription);

    _vadSub = _engine.vadStream.listen((speaking) {
      if (speaking && _phase == WalkieTalkiePhase.idle) {
        setState(() => _phase = WalkieTalkiePhase.userSpeaking);
        _userOrbController.repeat(reverse: true);
      }
    });

    _visualizerSub = _engine.visualizerStream.listen((data) {
      if (mounted) {
        setState(() => _userAmplitude = data.rmsLevel);
      }
    });

    _playbackListener = () {
      final state = _playback.state.value;
      if (state == PlaybackState.stopped) {
        // AI finished speaking, auto-listen if enabled
        if (widget.autoListen && _phase == WalkieTalkiePhase.aiSpeaking) {
          _startListening();
        }
      }
    };
    _playback.state.addListener(_playbackListener!);
  }

  @override
  void dispose() {
    _userOrbController.dispose();
    _aiOrbController.dispose();
    _thinkingController.dispose();
    _backgroundController.dispose();
    _transcriptionSub?.cancel();
    _vadSub?.cancel();
    _visualizerSub?.cancel();
    if (_playbackListener != null) {
      _playback.state.removeListener(_playbackListener!);
    }
    _stopListening();
    super.dispose();
  }

  void _onTranscription(SpeechRecognitionResult result) {
    if (!mounted) return;

    setState(() => _currentUserText = result.text);

    if (result.isFinal && result.text.isNotEmpty) {
      _handleUserMessage(result.text);
    }
  }

  Future<void> _handleUserMessage(String text) async {
    // Stop listening
    await _stopListening();

    // Add user message
    _messages.add(ConversationMessage(
      isUser: true,
      text: text,
      timestamp: DateTime.now(),
    ));

    // Transition to thinking phase immediately (latency masking)
    setState(() {
      _phase = WalkieTalkiePhase.thinking;
      _currentUserText = '';
    });
    _userOrbController.stop();
    _thinkingController.repeat();

    HapticFeedback.mediumImpact();

    try {
      // Get AI response
      final response = await widget.onSendMessage(text);

      // Transition to AI speaking
      setState(() {
        _phase = WalkieTalkiePhase.aiSpeaking;
        _currentAiText = response;
      });
      _thinkingController.stop();

      // Add AI message
      _messages.add(ConversationMessage(
        isUser: false,
        text: response,
        timestamp: DateTime.now(),
      ));

      // Speak the response
      await _playback.speak(response);
    } catch (e) {
      // Error handling
      setState(() => _phase = WalkieTalkiePhase.idle);
      if (widget.autoListen) {
        _startListening();
      }
    }
  }

  Future<void> _startListening() async {
    final success = await _engine.initialize();
    if (!success) return;

    await _engine.startListening();
    await _recorder.startRecording();

    setState(() => _phase = WalkieTalkiePhase.idle);
  }

  Future<void> _stopListening() async {
    await _recorder.stopRecording();
    await _engine.stopListening();

    _userOrbController.stop();
  }

  void _interrupt() {
    HapticFeedback.heavyImpact();

    // Stop AI speaking
    _playback.stop();

    // Reset state
    setState(() {
      _phase = WalkieTalkiePhase.idle;
      _currentAiText = '';
    });

    // Start listening again
    _startListening();
  }

  void _togglePause() {
    if (_phase == WalkieTalkiePhase.paused) {
      _startListening();
    } else {
      _stopListening();
      setState(() => _phase = WalkieTalkiePhase.paused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap anywhere to interrupt during AI speaking
        onTap: _phase == WalkieTalkiePhase.aiSpeaking ? _interrupt : null,
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(size),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(theme, colorScheme),

                  // Orbs area
                  Expanded(
                    child: _buildOrbsArea(size, colorScheme),
                  ),

                  // Bottom status and controls
                  _buildBottomArea(theme, colorScheme),
                ],
              ),
            ),

            // Tap to interrupt hint
            if (_phase == WalkieTalkiePhase.aiSpeaking)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap anywhere to interrupt',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            phase: _phase,
            progress: _backgroundController.value,
            userAmplitude: _userAmplitude,
          ),
          size: size,
        );
      },
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _stopListening();
              widget.onClose?.call();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Spacer(),
          Text(
            widget.aiName,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: _togglePause,
            icon: Icon(
              _phase == WalkieTalkiePhase.paused
                  ? Icons.play_arrow
                  : Icons.pause,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbsArea(Size size, ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // AI Orb (center, larger)
        Positioned(
          top: size.height * 0.15,
          child: _buildAiOrb(colorScheme),
        ),

        // User Orb (bottom)
        Positioned(
          bottom: size.height * 0.1,
          child: _buildUserOrb(colorScheme),
        ),

        // Current text display
        if (_currentUserText.isNotEmpty || _currentAiText.isNotEmpty)
          Positioned(
            left: 32,
            right: 32,
            bottom: size.height * 0.25,
            child: _buildCurrentText(),
          ),
      ],
    );
  }

  Widget _buildUserOrb(ColorScheme colorScheme) {
    const baseSize = 100.0;
    final isActive = _phase == WalkieTalkiePhase.userSpeaking;

    return AnimatedBuilder(
      animation: _userOrbController,
      builder: (context, child) {
        final scale = isActive
            ? 1.0 + (_userAmplitude * 0.5) + (_userOrbController.value * 0.1)
            : 0.8;

        return Container(
          width: baseSize * scale,
          height: baseSize * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.6),
                colorScheme.primary.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiOrb(ColorScheme colorScheme) {
    const baseSize = 180.0;
    final isThinking = _phase == WalkieTalkiePhase.thinking;
    final isSpeaking = _phase == WalkieTalkiePhase.aiSpeaking;

    return AnimatedBuilder(
      animation: isThinking ? _thinkingController : _aiOrbController,
      builder: (context, child) {
        final progress = isThinking
            ? _thinkingController.value
            : _aiOrbController.value;

        return CustomPaint(
          painter: _AiOrbPainter(
            progress: progress,
            isThinking: isThinking,
            isSpeaking: isSpeaking,
            primaryColor: colorScheme.tertiary,
            secondaryColor: colorScheme.secondary,
          ),
          size: const Size(baseSize, baseSize),
        );
      },
    );
  }

  Widget _buildCurrentText() {
    final text = _phase == WalkieTalkiePhase.aiSpeaking
        ? _currentAiText
        : _currentUserText;
    final isUser = _phase != WalkieTalkiePhase.aiSpeaking;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontStyle: isUser ? FontStyle.italic : FontStyle.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBottomArea(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phase indicator
          _buildPhaseIndicator(theme),

          const SizedBox(height: 16),

          // Conversation history preview
          if (_messages.isNotEmpty)
            TextButton(
              onPressed: _showHistory,
              child: Text(
                '${_messages.length} messages in conversation',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(ThemeData theme) {
    String text;
    IconData icon;

    switch (_phase) {
      case WalkieTalkiePhase.idle:
        text = 'Listening...';
        icon = Icons.mic;
      case WalkieTalkiePhase.userSpeaking:
        text = 'Speaking...';
        icon = Icons.record_voice_over;
      case WalkieTalkiePhase.thinking:
        text = 'Thinking...';
        icon = Icons.psychology;
      case WalkieTalkiePhase.aiSpeaking:
        text = '${widget.aiName} is speaking...';
        icon = Icons.volume_up;
      case WalkieTalkiePhase.paused:
        text = 'Paused';
        icon = Icons.pause_circle;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => _ConversationHistorySheet(messages: _messages),
    );
  }
}

/// Custom painter for animated background
class _BackgroundPainter extends CustomPainter {
  final WalkieTalkiePhase phase;
  final double progress;
  final double userAmplitude;

  _BackgroundPainter({
    required this.phase,
    required this.progress,
    required this.userAmplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: Alignment(
        math.sin(progress * 2 * math.pi) * 0.3,
        math.cos(progress * 2 * math.pi) * 0.3,
      ),
      radius: 1.5,
      colors: const [
        Color(0xFF1a1a2e),
        Color(0xFF16213e),
        Color(0xFF0f3460),
        Colors.black,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}

/// Custom painter for AI orb with "thinking" swirl effect
class _AiOrbPainter extends CustomPainter {
  final double progress;
  final bool isThinking;
  final bool isSpeaking;
  final Color primaryColor;
  final Color secondaryColor;

  _AiOrbPainter({
    required this.progress,
    required this.isThinking,
    required this.isSpeaking,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // Main orb gradient
    final orbGradient = RadialGradient(
      center: Alignment(
        math.sin(progress * 2 * math.pi) * 0.2,
        math.cos(progress * 2 * math.pi) * 0.2,
      ),
      colors: [
        secondaryColor,
        primaryColor,
        primaryColor.withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final orbPaint = Paint()
      ..shader = orbGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius * 0.8, orbPaint);

    // Swirling effect when thinking
    if (isThinking) {
      for (var i = 0; i < 3; i++) {
        final angle = progress * 2 * math.pi + (i * math.pi * 2 / 3);
        final swirlRadius = radius * 0.5;
        final swirlCenter = Offset(
          center.dx + math.cos(angle) * swirlRadius,
          center.dy + math.sin(angle) * swirlRadius,
        );

        final swirlPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawCircle(swirlCenter, 15, swirlPaint);
      }
    }

    // Pulsing rings when speaking
    if (isSpeaking) {
      for (var i = 0; i < 3; i++) {
        final ringProgress = (progress + i * 0.2) % 1.0;
        final ringRadius = radius * 0.8 + ringProgress * radius * 0.5;
        final opacity = (1.0 - ringProgress) * 0.5;

        final ringPaint = Paint()
          ..color = primaryColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(center, ringRadius, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AiOrbPainter oldDelegate) => true;
}

/// Conversation history bottom sheet
class _ConversationHistorySheet extends StatelessWidget {
  final List<ConversationMessage> messages;

  const _ConversationHistorySheet({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversation History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        message.isUser ? Icons.person : Icons.smart_toy,
                        color: message.isUser ? Colors.blue : Colors.purple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.text,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
