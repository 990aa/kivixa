import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/high_resolution_exporter.dart';
import '../services/pdf_drawing_manager.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Example demonstrating high-resolution export and PDF integration
class ExportAndPDFExample extends StatefulWidget {
  const ExportAndPDFExample({super.key});

  @override
  State<ExportAndPDFExample> createState() => _ExportAndPDFExampleState();
}

class _ExportAndPDFExampleState extends State<ExportAndPDFExample> {
  final List<DrawingLayer> _layers = [];
  final List<StrokePoint> _currentStroke = [];
  final HighResolutionExporter _exporter = HighResolutionExporter();
  final PDFDrawingManager _pdfManager = PDFDrawingManager();

  // Export settings
  ExportQuality _selectedQuality = ExportQuality.print;
  double _customDPI = 300.0;
  ExportFormat _selectedFormat = ExportFormat.png;

  // PDF settings
  bool _pdfLoaded = false;
  int _currentPDFPage = 0;

  // Export progress
  double _exportProgress = 0.0;
  String _exportStatus = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one layer
    _layers.add(DrawingLayer(name: 'Layer 1'));
  }

  @override
  void dispose() {
    _pdfManager.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke.clear();
      _currentStroke.add(
        StrokePoint(position: details.localPosition, pressure: 1.0),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(
        StrokePoint(position: details.localPosition, pressure: 1.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.length < 2) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stroke = LayerStroke(
      points: List.from(_currentStroke),
      brushProperties: paint,
    );

    setState(() {
      _layers.first.addStroke(stroke);

      // If PDF is loaded, also add to PDF
      if (_pdfLoaded) {
        _pdfManager.addStrokeToPage(
          _currentPDFPage,
          stroke,
          const Size(800, 600),
        );
      }

      _currentStroke.clear();
    });
  }

  Future<void> _exportImage() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportStatus = 'Starting export...';
    });

    try {
      final bytes = await _exporter.exportWithProgress(
        layers: _layers,
        canvasSize: const Size(800, 600),
        targetDPI: _selectedQuality == ExportQuality.custom
            ? _customDPI
            : HighResolutionExporter.getDPIForQuality(_selectedQuality),
        format: _selectedFormat,
        backgroundColor: Colors.white,
        onProgress: (progress, status) {
          setState(() {
            _exportProgress = progress;
            _exportStatus = status;
          });
        },
      );

      // Save file
      await _saveFile(bytes, 'drawing.png');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export successful!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      setState(() {
        _isExporting = false;
        _exportProgress = 0.0;
        _exportStatus = '';
      });
    }
  }

  Future<void> _loadPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        await _pdfManager.loadPDF(bytes);

        setState(() {
          _pdfLoaded = true;
          _currentPDFPage = 0;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF loaded: ${_pdfManager.pageCount} pages'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load PDF: $e')));
      }
    }
  }

  Future<void> _exportPDF() async {
    if (!_pdfLoaded) return;

    try {
      final bytes = await _pdfManager.exportAnnotatedPDF();
      await _saveFile(bytes, 'annotated.pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    }
  }

  Future<void> _saveFile(Uint8List bytes, String filename) async {
    // For web, this would use different approach
    if (Platform.isAndroid || Platform.isIOS) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: filename,
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export & PDF Integration Example')),
      body: Row(
        children: [
          // Drawing canvas
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DrawingPainter(_layers, _currentStroke),
                ),
              ),
            ),
          ),

          // Control panel
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Export Settings
                  const Text(
                    'High-Resolution Export',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Quality:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...HighResolutionExporter.ExportQuality.values.map((quality) {
                    return RadioListTile<HighResolutionExporter.ExportQuality>(
                      title: Text(quality.name.toUpperCase()),
                      subtitle: Text(
                        '${HighResolutionExporter.getDPIForQuality(quality)} DPI',
                      ),
                      value: quality,
                      groupValue: _selectedQuality,
                      onChanged: (value) {
                        setState(() {
                          _selectedQuality = value!;
                        });
                      },
                    );
                  }),

                  if (_selectedQuality ==
                      HighResolutionExporter.ExportQuality.custom)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Custom DPI',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _customDPI = double.tryParse(value) ?? 300.0;
                        },
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Text(
                    'Format:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<HighResolutionExporter.ExportFormat>(
                    value: _selectedFormat,
                    isExpanded: true,
                    items: HighResolutionExporter.ExportFormat.values.map((
                      format,
                    ) {
                      return DropdownMenuItem(
                        value: format,
                        child: Text(format.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportImage,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Image'),
                  ),

                  if (_isExporting) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _exportProgress),
                    const SizedBox(height: 8),
                    Text(
                      _exportStatus,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const Divider(height: 32),

                  // PDF Settings
                  const Text(
                    'PDF Integration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _loadPDF,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Load PDF'),
                  ),

                  if (_pdfLoaded) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Pages: ${_pdfManager.pageCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Current: ${_currentPDFPage + 1}'),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentPDFPage > 0
                                ? () {
                                    setState(() {
                                      _currentPDFPage--;
                                    });
                                  }
                                : null,
                            child: const Text('Previous'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _currentPDFPage < _pdfManager.pageCount - 1
                                ? () {
                                    setState(() {
                                      _currentPDFPage++;
                                    });
                                  }
                                : null,
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _exportPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export Annotated PDF'),
                    ),

                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _pdfManager.clearPageAnnotations(_currentPDFPage);
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],

                  const Divider(height: 32),

                  // Info
                  const Text(
                    'Export Info',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Output size: ${_exporter.calculateExportDimensions(const Size(800, 600), _selectedQuality == HighResolutionExporter.ExportQuality.custom ? _customDPI : HighResolutionExporter.getDPIForQuality(_selectedQuality)).width.toInt()}x${_exporter.calculateExportDimensions(const Size(800, 600), _selectedQuality == HighResolutionExporter.ExportQuality.custom ? _customDPI : HighResolutionExporter.getDPIForQuality(_selectedQuality)).height.toInt()} px',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Est. size: ${_exporter.estimateFileSizeMB(const Size(800, 600), _selectedQuality == HighResolutionExporter.ExportQuality.custom ? _customDPI : HighResolutionExporter.getDPIForQuality(_selectedQuality), format: _selectedFormat).toStringAsFixed(2)} MB',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final List<StrokePoint> currentStroke;

  _DrawingPainter(this.layers, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing layers
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        for (int i = 1; i < stroke.points.length; i++) {
          canvas.drawLine(
            stroke.points[i - 1].position,
            stroke.points[i].position,
            stroke.brushProperties,
          );
        }
      }
    }

    // Draw current stroke
    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 1; i < currentStroke.length; i++) {
        canvas.drawLine(
          currentStroke[i - 1].position,
          currentStroke[i].position,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
