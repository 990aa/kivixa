// Audio Waveform Widget
//
// Visualizes audio amplitude in real-time.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kivixa/services/audio/audio_neural_engine.dart';

/// Waveform display style
enum WaveformStyle {
  /// Simple bar visualization
  bars,

  /// Smooth line visualization
  line,

  /// Circular visualization
  circular,

  /// Breathing orb visualization
  orb,
}

/// Audio waveform visualizer widget
class AudioWaveform extends StatefulWidget {
  /// Height of the waveform
  final double height;

  /// Width of the waveform (null = expand)
  final double? width;

  /// Visualization style
  final WaveformStyle style;

  /// Primary color
  final Color? color;

  /// Secondary color for gradients
  final Color? secondaryColor;

  /// Number of bars for bar visualization
  final int barCount;

  /// Whether to animate when idle
  final bool animateIdle;

  /// Custom visualizer data stream (uses global engine if null)
  final Stream<AudioVisualizerData>? dataStream;

  const AudioWaveform({
    super.key,
    this.height = 48,
    this.width,
    this.style = WaveformStyle.bars,
    this.color,
    this.secondaryColor,
    this.barCount = 32,
    this.animateIdle = true,
    this.dataStream,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  AudioVisualizerData _currentData = AudioVisualizerData.empty;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.animateIdle) {
      _idleController.repeat(reverse: true);
    }

    // Listen to visualizer stream
    final stream = widget.dataStream ?? AudioNeuralEngine().visualizerStream;
    stream.listen((data) {
      if (mounted) {
        setState(() => _currentData = data);
      }
    });
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final secondaryColor =
        widget.secondaryColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveformPainter(
              data: _currentData,
              style: widget.style,
              color: color,
              secondaryColor: secondaryColor,
              barCount: widget.barCount,
              idleProgress: _idleController.value,
            ),
            size: Size(widget.width ?? double.infinity, widget.height),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final AudioVisualizerData data;
  final WaveformStyle style;
  final Color color;
  final Color secondaryColor;
  final int barCount;
  final double idleProgress;

  _WaveformPainter({
    required this.data,
    required this.style,
    required this.color,
    required this.secondaryColor,
    required this.barCount,
    required this.idleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case WaveformStyle.bars:
        _paintBars(canvas, size);
      case WaveformStyle.line:
        _paintLine(canvas, size);
      case WaveformStyle.circular:
        _paintCircular(canvas, size);
      case WaveformStyle.orb:
        _paintOrb(canvas, size);
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / (barCount * 2);
    final maxHeight = size.height * 0.8;
    final centerY = size.height / 2;

    for (var i = 0; i < barCount; i++) {
      // Get amplitude from frequency bands or generate idle animation
      double amplitude;
      if (data.frequencyBands.isNotEmpty && i < data.frequencyBands.length) {
        amplitude = data.frequencyBands[i];
      } else {
        // Idle animation
        final phase = (i / barCount + idleProgress) * math.pi * 2;
        amplitude = (math.sin(phase) + 1) / 2 * 0.3;
      }

      final barHeight = amplitude * maxHeight;
      final x = i * barWidth * 2 + barWidth / 2;

      // Draw bar from center
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
  }

  void _paintLine(Canvas canvas, Size size) {
    if (barCount < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final maxAmplitude = size.height * 0.4;

    for (var i = 0; i < barCount; i++) {
      final x = (i / (barCount - 1)) * size.width;

      double amplitude;
      if (data.frequencyBands.isNotEmpty && i < data.frequencyBands.length) {
        amplitude = data.frequencyBands[i];
      } else {
        final phase = (i / barCount + idleProgress) * math.pi * 2;
        amplitude = math.sin(phase) * 0.3;
      }

      final y = centerY + amplitude * maxAmplitude;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw mirrored line
    paint.color = secondaryColor;
    final mirrorPath = Path();

    for (var i = 0; i < barCount; i++) {
      final x = (i / (barCount - 1)) * size.width;

      double amplitude;
      if (data.frequencyBands.isNotEmpty && i < data.frequencyBands.length) {
        amplitude = data.frequencyBands[i];
      } else {
        final phase = (i / barCount + idleProgress) * math.pi * 2;
        amplitude = math.sin(phase) * 0.3;
      }

      final y = centerY - amplitude * maxAmplitude;

      if (i == 0) {
        mirrorPath.moveTo(x, y);
      } else {
        mirrorPath.lineTo(x, y);
      }
    }

    canvas.drawPath(mirrorPath, paint);
  }

  void _paintCircular(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.7;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();

    for (var i = 0; i <= barCount; i++) {
      final angle = (i / barCount) * math.pi * 2 - math.pi / 2;

      double amplitude;
      if (data.frequencyBands.isNotEmpty && i < data.frequencyBands.length) {
        amplitude = data.frequencyBands[i % data.frequencyBands.length];
      } else {
        final phase = (i / barCount + idleProgress) * math.pi * 2;
        amplitude = (math.sin(phase) + 1) / 2 * 0.3;
      }

      final r = radius * (0.7 + amplitude * 0.5);
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Inner circle
    paint.color = secondaryColor;
    canvas.drawCircle(center, radius * 0.5, paint);
  }

  void _paintOrb(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 * 0.6;

    // Pulsing radius based on RMS level
    final pulseAmount = data.voiceDetected ? data.rmsLevel : idleProgress * 0.2;
    final radius = baseRadius * (0.8 + pulseAmount * 0.4);

    // Gradient fill
    final gradient = RadialGradient(
      colors: [color, secondaryColor],
      stops: const [0.3, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);

    // Glow effect
    if (data.voiceDetected) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(center, radius * 1.1, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return data != oldDelegate.data || idleProgress != oldDelegate.idleProgress;
  }
}
