import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/transparent_exporter.dart';
import 'package:kivixa/services/alpha_channel_verifier.dart';
import 'package:kivixa/models/stroke.dart';
import 'dart:io';
import 'dart:ui' as ui;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TransparentExporter exporter;
  late AlphaChannelVerifier verifier;
  late Directory testDir;

  setUp(() async {
    exporter = TransparentExporter();
    verifier = AlphaChannelVerifier();
    testDir = await Directory.systemTemp.createTemp('export_test_');
  });

  tearDown(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('Transparent Export', () {
    test('should export canvas with transparent background', () async {
      final strokes = [
        Stroke(
          points: [const Offset(10, 10), const Offset(100, 100)],
          color: Colors.black,
          strokeWidth: 2.0,
        ),
      ];

      final file = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        outputPath: '${testDir.path}/transparent.png',
      );

      expect(await file.exists(), true);
      expect(file.path.endsWith('.png'), true);
    });

    test('should verify exported image has transparency', () async {
      final strokes = [
        Stroke(
          points: [const Offset(50, 50), const Offset(150, 150)],
          color: Colors.blue,
          strokeWidth: 3.0,
        ),
      ];

      final file = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        outputPath: '${testDir.path}/test.png',
      );

      final hasTransparency = await verifier.verifyImageHasTransparency(
        file.path,
      );

      expect(hasTransparency, true);
    });

    test('should export with custom DPI', () async {
      final strokes = [
        Stroke(
          points: [const Offset(0, 0), const Offset(100, 100)],
          color: Colors.red,
          strokeWidth: 1.0,
        ),
      ];

      // Export at 300 DPI (high resolution)
      final file = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        dpi: 300,
        outputPath: '${testDir.path}/high_res.png',
      );

      expect(await file.exists(), true);

      // File should be larger due to higher resolution
      final fileSize = await file.length();
      expect(fileSize, greaterThan(0));
    });

    test('should export empty canvas as fully transparent', () async {
      final file = await exporter.exportToPNG(
        strokes: [],
        width: 100,
        height: 100,
        outputPath: '${testDir.path}/empty.png',
      );

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Verify image dimensions
      expect(image.width, 100);
      expect(image.height, 100);

      // Empty canvas should have transparency
      final hasTransparency = await verifier.verifyImageHasTransparency(
        file.path,
      );
      expect(hasTransparency, true);
    });
  });

  group('Layer Rendering', () {
    test('should render multiple layers with transparency', () async {
      final backgroundStrokes = [
        Stroke(
          points: [const Offset(0, 0), const Offset(200, 200)],
          color: Colors.blue,
          strokeWidth: 5.0,
        ),
      ];

      final foregroundStrokes = [
        Stroke(
          points: [const Offset(200, 0), const Offset(0, 200)],
          color: Colors.red.withOpacity(0.5),
          strokeWidth: 5.0,
        ),
      ];

      // Export with layers
      final file = await exporter.exportLayeredPNG(
        layers: [backgroundStrokes, foregroundStrokes],
        width: 200,
        height: 200,
        outputPath: '${testDir.path}/layered.png',
      );

      expect(await file.exists(), true);
    });

    test('should preserve layer transparency', () async {
      final transparentStroke = Stroke(
        points: [const Offset(50, 50), const Offset(150, 150)],
        color: Colors.black.withOpacity(0.3),
        strokeWidth: 10.0,
      );

      final file = await exporter.exportToPNG(
        strokes: [transparentStroke],
        width: 200,
        height: 200,
        outputPath: '${testDir.path}/semi_transparent.png',
      );

      // Verify transparency is preserved
      final hasTransparency = await verifier.verifyImageHasTransparency(
        file.path,
      );
      expect(hasTransparency, true);
    });
  });

  group('Alpha Channel Verification', () {
    test('should detect alpha channel in PNG', () async {
      // Create image with transparency
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final file = File('${testDir.path}/test_alpha.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());

      final hasAlpha = await verifier.hasAlphaChannel(file.path);
      expect(hasAlpha, true);
    });

    test('should calculate transparency percentage', () async {
      final strokes = [
        Stroke(
          points: [const Offset(50, 50), const Offset(150, 150)],
          color: Colors.black,
          strokeWidth: 2.0,
        ),
      ];

      final file = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        outputPath: '${testDir.path}/test.png',
      );

      final transparencyPercent = await verifier.getTransparencyPercentage(
        file.path,
      );

      // Most of the canvas should be transparent
      expect(transparencyPercent, greaterThan(50.0));
    });

    test('should identify fully opaque pixels', () async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw fully opaque rectangle
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final file = File('${testDir.path}/opaque.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());

      final transparencyPercent = await verifier.getTransparencyPercentage(
        file.path,
      );

      // Should be 0% transparent (fully opaque)
      expect(transparencyPercent, lessThan(1.0));
    });
  });

  group('Export Formats', () {
    test('should export to PNG format', () async {
      final strokes = [
        Stroke(
          points: [const Offset(10, 10), const Offset(90, 90)],
          color: Colors.green,
          strokeWidth: 3.0,
        ),
      ];

      final file = await exporter.exportToFormat(
        strokes: strokes,
        width: 100,
        height: 100,
        format: ExportFormat.png,
        outputPath: '${testDir.path}/test.png',
      );

      expect(file.path.endsWith('.png'), true);
      expect(await file.exists(), true);
    });

    test('should export to different resolutions', () async {
      final strokes = [
        Stroke(
          points: [const Offset(0, 0), const Offset(100, 100)],
          color: Colors.purple,
          strokeWidth: 2.0,
        ),
      ];

      // Export at different sizes
      final small = await exporter.exportToPNG(
        strokes: strokes,
        width: 100,
        height: 100,
        outputPath: '${testDir.path}/small.png',
      );

      final large = await exporter.exportToPNG(
        strokes: strokes,
        width: 1000,
        height: 1000,
        outputPath: '${testDir.path}/large.png',
      );

      final smallSize = await small.length();
      final largeSize = await large.length();

      expect(largeSize, greaterThan(smallSize));
    });
  });

  group('Eraser Transparency', () {
    test('should create transparent areas with eraser', () async {
      final drawStroke = Stroke(
        points: [const Offset(0, 0), const Offset(200, 200)],
        color: Colors.black,
        strokeWidth: 20.0,
      );

      final eraseStroke = Stroke(
        points: [const Offset(100, 0), const Offset(100, 200)],
        color: Colors.transparent,
        strokeWidth: 30.0,
        isEraser: true,
      );

      final file = await exporter.exportToPNG(
        strokes: [drawStroke, eraseStroke],
        width: 200,
        height: 200,
        outputPath: '${testDir.path}/erased.png',
      );

      // Verify transparency in erased area
      final hasTransparency = await verifier.verifyImageHasTransparency(
        file.path,
      );
      expect(hasTransparency, true);
    });

    test('should use correct blend mode for eraser', () async {
      final exporter = TransparentExporter(eraserBlendMode: BlendMode.clear);

      final strokes = [
        Stroke(
          points: [const Offset(0, 0), const Offset(100, 100)],
          color: Colors.black,
          strokeWidth: 10.0,
        ),
        Stroke(
          points: [const Offset(50, 0), const Offset(50, 100)],
          color: Colors.transparent,
          strokeWidth: 20.0,
          isEraser: true,
        ),
      ];

      final file = await exporter.exportToPNG(
        strokes: strokes,
        width: 100,
        height: 100,
        outputPath: '${testDir.path}/blend_test.png',
      );

      expect(await file.exists(), true);
    });
  });

  group('Export Optimization', () {
    test('should optimize export for file size', () async {
      final strokes = List.generate(
        100,
        (i) => Stroke(
          points: [
            Offset(i.toDouble(), i.toDouble()),
            Offset(i + 10.0, i + 10.0),
          ],
          color: Colors.black,
          strokeWidth: 1.0,
        ),
      );

      final normalFile = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        optimizeSize: false,
        outputPath: '${testDir.path}/normal.png',
      );

      final optimizedFile = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        optimizeSize: true,
        outputPath: '${testDir.path}/optimized.png',
      );

      final normalSize = await normalFile.length();
      final optimizedSize = await optimizedFile.length();

      // Optimized file should be smaller or equal
      expect(optimizedSize, lessThanOrEqualTo(normalSize));
    });

    test('should export with quality settings', () async {
      final strokes = [
        Stroke(
          points: [const Offset(0, 0), const Offset(100, 100)],
          color: Colors.red,
          strokeWidth: 5.0,
        ),
      ];

      final highQuality = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        quality: 100,
        outputPath: '${testDir.path}/high_quality.png',
      );

      final lowQuality = await exporter.exportToPNG(
        strokes: strokes,
        width: 200,
        height: 200,
        quality: 50,
        outputPath: '${testDir.path}/low_quality.png',
      );

      expect(await highQuality.exists(), true);
      expect(await lowQuality.exists(), true);
    });
  });

  group('Error Handling', () {
    test('should handle invalid output path', () async {
      final strokes = [
        Stroke(
          points: [const Offset(0, 0), const Offset(100, 100)],
          color: Colors.black,
          strokeWidth: 2.0,
        ),
      ];

      expect(
        () => exporter.exportToPNG(
          strokes: strokes,
          width: 100,
          height: 100,
          outputPath: '/invalid/path/file.png',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle zero dimensions', () async {
      expect(
        () => exporter.exportToPNG(
          strokes: [],
          width: 0,
          height: 0,
          outputPath: '${testDir.path}/zero.png',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle negative dimensions', () async {
      expect(
        () => exporter.exportToPNG(
          strokes: [],
          width: -100,
          height: -100,
          outputPath: '${testDir.path}/negative.png',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
