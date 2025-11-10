import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:kivixa/models/drawing_layer.dart';
import 'package:kivixa/models/layer_stroke.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/painters/display_export_painter.dart';
import 'package:kivixa/services/alpha_channel_verifier.dart';

/// Interactive example demonstrating the critical architectural separation
/// between display rendering (with background) and export rendering (transparent).
///
/// This example proves that:
/// 1. Display shows white background for visual aid
/// 2. Export contains NO background - pure transparency
/// 3. Alpha channel is preserved in PNG format
/// 4. Verification confirms genuine transparency
class DisplayVsExportExample extends StatefulWidget {
  const DisplayVsExportExample({super.key});

  @override
  State<DisplayVsExportExample> createState() => _DisplayVsExportExampleState();
}

class _DisplayVsExportExampleState extends State<DisplayVsExportExample> {
  late List<DrawingLayer> _layers;
  Uint8List? _exportedImageBytes;
  Map<String, dynamic>? _transparencyStats;
  var _showBackground = true;
  var _isExporting = false;

  @override
  void initState() {
    super.initState();
    _layers = _createSampleArtwork();
  }

  /// Create sample artwork with various strokes and colors
  List<DrawingLayer> _createSampleArtwork() {
    final layer = DrawingLayer(
      id: 'sample-layer',
      name: 'Sample Artwork',
      isVisible: true,
      opacity: 1.0,
    );

    // Create colorful strokes with transparency
    final colors = [
      Colors.red.withValues(alpha: 0.8),
      Colors.blue.withValues(alpha: 0.6),
      Colors.green.withValues(alpha: 0.7),
      Colors.orange.withValues(alpha: 0.9),
      Colors.purple.withValues(alpha: 0.5),
    ];

    // Create circular pattern
    const center = Offset(200, 200);
    const radius = 100.0;

    for (int i = 0; i < 5; i++) {
      final start =
          center +
          Offset(
            radius * 0.5 * (i.isEven ? 1 : -1) * (i / 5),
            radius * 0.5 * (i.isEven ? -1 : 1) * (i / 5),
          );
      final end =
          center +
          Offset(
            radius * (i.isEven ? 1 : -1) * ((5 - i) / 5),
            radius * (i.isEven ? -1 : 1) * ((5 - i) / 5),
          );

      final points = <StrokePoint>[];
      for (double t = 0; t <= 1.0; t += 0.05) {
        points.add(
          StrokePoint(
            position: Offset.lerp(start, end, t)!,
            pressure: 0.5 + 0.5 * (t * 2 - 1).abs(),
          ),
        );
      }

      layer.strokes.add(
        LayerStroke(
          id: 'stroke-$i',
          points: points,
          brushProperties: Paint()
            ..color = colors[i]
            ..strokeWidth = 8.0 + i * 2.0
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..blendMode = BlendMode.srcOver,
        ),
      );
    }

    // Add a text-like pattern
    final textPoints = <StrokePoint>[
      const StrokePoint(position: Offset(100, 300), pressure: 1.0),
      const StrokePoint(position: Offset(150, 320), pressure: 0.8),
      const StrokePoint(position: Offset(200, 300), pressure: 1.0),
      const StrokePoint(position: Offset(250, 320), pressure: 0.8),
      const StrokePoint(position: Offset(300, 300), pressure: 1.0),
    ];

    layer.strokes.add(
      LayerStroke(
        id: 'text-stroke',
        points: textPoints,
        brushProperties: Paint()
          ..color = Colors.black.withValues(alpha: 0.8)
          ..strokeWidth = 12.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      ),
    );

    return [layer];
  }

  /// Export canvas WITHOUT background
  Future<void> _exportCanvas() async {
    setState(() {
      _isExporting = true;
      _exportedImageBytes = null;
      _transparencyStats = null;
    });

    try {
      // Use CanvasExportPainter - NO background!
      final image = await CanvasExportPainter.renderForExport(
        _layers,
        const Size(400, 400),
        scaleFactor: 1.0,
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      image.dispose();

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();

        // Verify transparency
        final stats = await AlphaChannelVerifier.getTransparencyStats(bytes);

        setState(() {
          _exportedImageBytes = bytes;
          _transparencyStats = stats;
        });
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display vs Export Separation')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArchitectureExplanation(),
              const SizedBox(height: 24),
              _buildControls(),
              const SizedBox(height: 24),
              _buildDisplaySection(),
              const SizedBox(height: 24),
              _buildExportSection(),
              const SizedBox(height: 24),
              if (_transparencyStats != null) _buildVerificationSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchitectureExplanation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.architecture, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Critical Architecture Pattern',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Display rendering (shows background) is SEPARATE from export rendering (transparent):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              'Display: CanvasDisplayPainter draws white background for visual aid',
            ),
            _buildBulletPoint(
              'Export: CanvasExportPainter draws NO background - transparent by default',
            ),
            _buildBulletPoint(
              'Verification: AlphaChannelVerifier confirms genuine transparency',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Canvas background is purely cosmetic and only part of exported artwork when user chooses.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Show Display Background'),
              subtitle: const Text('Visual aid only - not exported'),
              value: _showBackground,
              onChanged: (value) {
                setState(() {
                  _showBackground = value;
                });
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCanvas,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting ? 'Exporting...' : 'Export (No Background)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Display Rendering (CanvasDisplayPainter)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Shows ${_showBackground ? 'white' : 'NO'} background for visual aid',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  // Checkered pattern to show transparency
                  image: !_showBackground
                      ? const DecorationImage(
                          image: NetworkImage(
                            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAGElEQVQYlWNgYGD4z8DAwMDAwMDAAGMjCQAFAwICuUiaMQAAAABJRU5ErkJggg==',
                          ),
                          repeat: ImageRepeat.repeat,
                        )
                      : null,
                ),
                child: CustomPaint(
                  painter: CanvasDisplayPainter(
                    layers: _layers,
                    backgroundColor: Colors.white,
                    showBackground: _showBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Code:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'canvas.drawRect(rect, Paint()..color = Colors.white);',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Export Rendering (CanvasExportPainter)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'NO background drawn - transparent by default',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  // Checkered pattern to show transparency
                  image: const DecorationImage(
                    image: NetworkImage(
                      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAGElEQVQYlWNgYGD4z8DAwMDAwMDAAGMjCQAFAwICuUiaMQAAAABJRU5ErkJggg==',
                    ),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
                child: _exportedImageBytes != null
                    ? Image.memory(_exportedImageBytes!, fit: BoxFit.contain)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Export" to render',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Code:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '// NO background drawn!\n// Canvas is transparent by default',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    final stats = _transparencyStats!;

    if (stats.containsKey('error')) {
      return Card(
        color: Colors.red.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: ${stats['error']}'),
        ),
      );
    }

    final hasTransparency = stats['transparentPixels'] > 0;

    return Card(
      color: hasTransparency
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasTransparency ? Icons.check_circle : Icons.error,
                  color: hasTransparency ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alpha Channel Verification',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Pixels', '${stats['totalPixels']}'),
            _buildStatRow(
              'Transparent Pixels',
              '${stats['transparentPixels']}',
            ),
            _buildStatRow('Opaque Pixels', '${stats['opaquePixels']}'),
            _buildStatRow(
              'Transparency',
              '${stats['transparencyPercentage'].toStringAsFixed(2)}%',
            ),
            _buildStatRow(
              'Average Alpha',
              stats['averageAlpha'].toStringAsFixed(2),
            ),
            _buildStatRow(
              'Alpha Range',
              '${stats['minAlpha']} - ${stats['maxAlpha']}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasTransparency
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    hasTransparency ? Icons.check_circle : Icons.error,
                    color: hasTransparency ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasTransparency
                          ? '✅ Alpha channel preserved - transparency verified!'
                          : '❌ No transparency detected - check export process!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
