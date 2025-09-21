import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/paper_settings.dart';
import 'package:kivixa/features/notes/services/paper_generator_service.dart';

class PaperGeneratorScreen extends StatefulWidget {
  const PaperGeneratorScreen({super.key});

  @override
  State<PaperGeneratorScreen> createState() => _PaperGeneratorScreenState();
}

class _PaperGeneratorScreenState extends State<PaperGeneratorScreen> {
  final PaperGeneratorService _paperGeneratorService = PaperGeneratorService();
  Uint8List? _generatedPaperBytes;
  bool _isLoading = true;
  String _error = '';

  PaperType _selectedPaperType = PaperType.ruled;
  PaperSize _selectedPaperSize = PaperSize.a4;

  @override
  void initState() {
    super.initState();
    _generatePaper();
  }

  @override
  void dispose() {
    _paperGeneratorService.dispose();
    super.dispose();
  }

  Future<void> _generatePaper() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final options = _getOptionsForType(_selectedPaperType);
      final bytes = await _paperGeneratorService.generatePaper(
        paperType: _selectedPaperType,
        paperSize: _selectedPaperSize,
        options: options,
      );
      setState(() {
        _generatedPaperBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate paper: $e';
        _isLoading = false;
      });
    }
  }

  PaperOptions _getOptionsForType(PaperType type) {
    switch (type) {
      case PaperType.ruled:
        return RuledPaperOptions(watermark: 'Kivixa Ruled');
      case PaperType.grid:
        return GridPaperOptions(watermark: 'Kivixa Grid');
      case PaperType.dotGrid:
        return DotGridPaperOptions(watermark: 'Kivixa Dots');
      case PaperType.graph:
        return GraphPaperOptions(watermark: 'Kivixa Graph');
      case PaperType.plain:
        return PlainPaperOptions(watermark: 'Kivixa Plain');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paper Generator')),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _error.isNotEmpty
                  ? Text(_error, style: const TextStyle(color: Colors.red))
                  : _generatedPaperBytes != null
                  ? AspectRatio(
                      aspectRatio:
                          _selectedPaperSize.width / _selectedPaperSize.height,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Image.memory(_generatedPaperBytes!),
                      ),
                    )
                  : const Text('No paper generated.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: [
          DropdownButton<PaperType>(
            value: _selectedPaperType,
            onChanged: (PaperType? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPaperType = newValue;
                });
              }
            },
            items: PaperType.values.map((PaperType type) {
              return DropdownMenuItem<PaperType>(
                value: type,
                child: Text(type.name),
              );
            }).toList(),
          ),
          DropdownButton<PaperSize>(
            value: _selectedPaperSize,
            onChanged: (PaperSize? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPaperSize = newValue;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: PaperSize.a4, child: Text('A4')),
              DropdownMenuItem(value: PaperSize.a3, child: Text('A3')),
              DropdownMenuItem(value: PaperSize.letter, child: Text('Letter')),
              DropdownMenuItem(value: PaperSize.legal, child: Text('Legal')),
            ],
          ),
          ElevatedButton(
            onPressed: _generatePaper,
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
