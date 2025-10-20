import 'package:flutter/material.dart';
import '../widgets/infinite_canvas.dart';
import '../models/stroke.dart';

/// Demo screen to showcase the infinite canvas with pan/zoom capabilities
class InfiniteCanvasScreen extends StatefulWidget {
  const InfiniteCanvasScreen({super.key});

  @override
  State<InfiniteCanvasScreen> createState() => _InfiniteCanvasScreenState();
}

class _InfiniteCanvasScreenState extends State<InfiniteCanvasScreen> {
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 4.0;
  bool _isHighlighter = false;
  List<Stroke> _strokes = [];

  void _handleStrokesChanged(List<Stroke> strokes) {
    setState(() {
      _strokes = strokes;
    });
  }

  void _clearCanvas() {
    setState(() {
      _strokes = [];
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes = _strokes.sublist(0, _strokes.length - 1);
      });
    }
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
                initialStrokes: _strokes,
                currentColor: _currentColor,
                currentStrokeWidth: _currentStrokeWidth,
                isHighlighter: _isHighlighter,
                onStrokesChanged: _handleStrokesChanged,
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
