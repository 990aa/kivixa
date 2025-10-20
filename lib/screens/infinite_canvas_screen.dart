import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/infinite_canvas.dart';
import '../models/stroke.dart';
import '../models/canvas_element.dart';
import '../services/image_picker_service.dart';
import '../services/export_import_service.dart';
import '../widgets/canvas_element_widget.dart';

/// Demo screen to showcase the infinite canvas with pan/zoom capabilities
class InfiniteCanvasScreen extends StatefulWidget {
  const InfiniteCanvasScreen({super.key});

  @override
  State<InfiniteCanvasScreen> createState() => _InfiniteCanvasScreenState();
}

class _InfiniteCanvasScreenState extends State<InfiniteCanvasScreen> {
  final GlobalKey<_InfiniteCanvasState> _canvasKey = GlobalKey();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final ExportImportService _exportService = ExportImportService();

  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 4.0;
  bool _isHighlighter = false;
  List<Stroke> _strokes = [];
  List<CanvasElement> _elements = [];

  void _handleStrokesChanged(List<Stroke> strokes) {
    setState(() {
      _strokes = strokes;
    });
  }

  void _handleElementsChanged(List<CanvasElement> elements) {
    setState(() {
      _elements = elements;
    });
  }

  void _clearCanvas() {
    setState(() {
      _strokes = [];
      _elements = [];
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes = _strokes.sublist(0, _strokes.length - 1);
      });
    }
  }

  Future<void> _addImage(ImageSource source) async {
    final element = await _imagePickerService.pickImage(
      source: source,
      position: const Offset(100, 100),
    );

    if (element != null) {
      setState(() {
        _elements.add(element);
      });
    }
  }

  void _addText() {
    final element = _imagePickerService.createTextElement(
      position: const Offset(100, 100),
    );

    showDialog<TextElement>(
      context: context,
      builder: (context) => TextEditDialog(element: element),
    ).then((updatedElement) {
      if (updatedElement != null) {
        setState(() {
          _elements.add(updatedElement);
        });
      }
    });
  }

  Future<void> _exportToPDF() async {
    try {
      final file = await _exportService.exportToPDF(
        strokes: _strokes,
        elements: _elements,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    }
  }

  Future<void> _exportToSVG() async {
    try {
      final svgContent = await _exportService.exportToSVG(
        strokes: _strokes,
        elements: _elements,
      );
      final file = await _exportService.saveSvgToFile(svgContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SVG exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting SVG: $e')));
      }
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Export as PDF'),
            onTap: () {
              Navigator.pop(context);
              _exportToPDF();
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Export as SVG'),
            onTap: () {
              Navigator.pop(context);
              _exportToSVG();
            },
          ),
        ],
      ),
    );
  }

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Add Image from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _addImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Add Image from Camera'),
            onTap: () {
              Navigator.pop(context);
              _addImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Add Text'),
            onTap: () {
              Navigator.pop(context);
              _addText();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Canvas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _showImportMenu,
            tooltip: 'Import',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportMenu,
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearCanvas,
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[200],
            child: Row(
              children: [
                // Color Picker
                const Text('Color: '),
                const SizedBox(width: 8),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.blue),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.orange),
                _buildColorButton(Colors.purple),
                const SizedBox(width: 16),
                // Stroke Width
                const Text('Width: '),
                Slider(
                  value: _currentStrokeWidth,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  label: _currentStrokeWidth.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _currentStrokeWidth = value;
                    });
                  },
                ),
                const SizedBox(width: 16),
                // Highlighter Toggle
                FilterChip(
                  label: const Text('Highlighter'),
                  selected: _isHighlighter,
                  onSelected: (value) {
                    setState(() {
                      _isHighlighter = value;
                      if (value) {
                        _currentStrokeWidth = 12.0;
                      } else {
                        _currentStrokeWidth = 4.0;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: Colors.white,
              child: InfiniteCanvas(
                key: _canvasKey,
                initialStrokes: _strokes,
                initialElements: _elements,
                currentColor: _currentColor,
                currentStrokeWidth: _currentStrokeWidth,
                isHighlighter: _isHighlighter,
                onStrokesChanged: _handleStrokesChanged,
                onElementsChanged: _handleElementsChanged,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Use two fingers to pan and zoom the canvas! Draw with one finger.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        },
        icon: const Icon(Icons.info),
        label: const Text('Help'),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentColor = color;
          });
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _currentColor == color ? Colors.blue : Colors.grey,
              width: _currentColor == color ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
