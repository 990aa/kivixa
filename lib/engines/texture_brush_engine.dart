import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/models/brush_settings.dart';
import 'package:kivixa/engines/brush_engine.dart';

/// Texture-based brush using fragment shaders
class TextureBrushEngine extends BrushEngine {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  var _isShaderLoaded = false;

  /// Load the fragment shader from assets
  Future<void> loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(
        'shaders/texture_brush.frag',
      );
      _isShaderLoaded = true;
    } catch (e) {
      debugPrint('Failed to load texture brush shader: $e');
      _isShaderLoaded = false;
    }
  }

  /// Check if shader is ready
  bool get isReady => _isShaderLoaded && _program != null;

  @override
  void applyStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (!isReady || settings.textureImage == null) {
      // Fallback to simple brush if shader not loaded
      _applyFallbackStroke(canvas, points, settings);
      return;
    }

    final spacedPoints = applySpacing(points, settings);

    for (int i = 0; i < spacedPoints.length; i++) {
      final point = spacedPoints[i];
      final size = calculatePressureSize(
        settings.size,
        point.pressure,
        settings,
      );

      final opacity = calculatePressureOpacity(
        settings.opacity,
        point.pressure,
        settings,
      );

      // Create shader instance
      _shader = _program!.fragmentShader();

      // Set shader uniforms
      _setShaderUniforms(_shader!, size, settings, opacity, point);

      final paint = Paint()..shader = _shader;

      // Apply rotation if needed
      if (settings.rotation != 0 || settings.rotationJitter) {
        canvas.save();
        final rotation = settings.rotationJitter
            ? settings.rotation + (_seededRandom(i) - 0.5) * 3.14
            : settings.rotation;
        canvas.translate(point.position.dx, point.position.dy);
        canvas.rotate(rotation);
        canvas.drawCircle(Offset.zero, size, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(point.position, size, paint);
      }
    }
  }

  /// Set shader uniforms
  void _setShaderUniforms(
    ui.FragmentShader shader,
    double size,
    BrushSettings settings,
    double opacity,
    StrokePoint point,
  ) {
    // uSize (vec2)
    shader.setFloat(0, size * 2); // width
    shader.setFloat(1, size * 2); // height

    // uColor (vec4)
    shader.setFloat(2, ((settings.color.r * 255.0).round() & 0xff) / 255.0);
    shader.setFloat(3, ((settings.color.g * 255.0).round() & 0xff) / 255.0);
    shader.setFloat(4, ((settings.color.b * 255.0).round() & 0xff) / 255.0);
    shader.setFloat(5, ((settings.color.a * 255.0).round() & 0xff) / 255.0);

    // uOpacity (float)
    shader.setFloat(6, opacity);

    // uBrushTexture (sampler2D)
    shader.setImageSampler(0, settings.textureImage!);
  }

  /// Fallback rendering without shader
  void _applyFallbackStroke(
    Canvas canvas,
    List<StrokePoint> points,
    BrushSettings settings,
  ) {
    if (points.isEmpty) return;

    final spacedPoints = applySpacing(points, settings);

    for (final point in spacedPoints) {
      final size = calculatePressureSize(
        settings.size,
        point.pressure,
        settings,
      );

      final opacity = calculatePressureOpacity(
        settings.opacity,
        point.pressure,
        settings,
      );

      // If we have a texture image, draw it directly
      if (settings.textureImage != null) {
        final paint = Paint()
          ..color = settings.color.withValues(alpha: opacity)
          ..blendMode = settings.blendMode;

        final srcRect = Rect.fromLTWH(
          0,
          0,
          settings.textureImage!.width.toDouble(),
          settings.textureImage!.height.toDouble(),
        );

        final dstRect = Rect.fromCenter(
          center: point.position,
          width: size * 2,
          height: size * 2,
        );

        canvas.drawImageRect(settings.textureImage!, srcRect, dstRect, paint);
      } else {
        // Simple circle fallback
        final paint = Paint()
          ..color = settings.color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill
          ..blendMode = settings.blendMode;

        canvas.drawCircle(point.position, size, paint);
      }
    }
  }

  double _seededRandom(int seed) {
    final x = (seed * 0x5DEECE66D + 0xB) & ((1 << 48) - 1);
    return (x >> 16) / (1 << 32);
  }

  /// Dispose shader resources
  void dispose() {
    _shader?.dispose();
    _shader = null;
    _program = null;
    _isShaderLoaded = false;
  }
}

/// Helper to load brush textures
class BrushTextureLoader {
  static final Map<String, ui.Image> _cache = {};

  /// Load a texture from assets
  static Future<ui.Image?> loadTexture(String assetPath) async {
    // Check cache first
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath];
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _cache[assetPath] = frame.image;
      return frame.image;
    } catch (e) {
      debugPrint('Failed to load brush texture: $e');
      return null;
    }
  }

  /// Clear texture cache
  static void clearCache() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  /// Get cached texture
  static ui.Image? getCached(String assetPath) {
    return _cache[assetPath];
  }
}
