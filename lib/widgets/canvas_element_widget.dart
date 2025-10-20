import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/canvas_element.dart';

/// Widget for rendering and interacting with text elements
class TextElementWidget extends StatelessWidget {
  final TextElement element;
  final Function(TextElement) onUpdate;
  final VoidCallback? onDoubleTap;
  final bool isSelected;

  const TextElementWidget({
    super.key,
    required this.element,
    required this.onUpdate,
    this.onDoubleTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final updatedElement = element.copyWith(
            position: element.position + details.delta,
          );
          onUpdate(updatedElement);
        },
        onDoubleTap: onDoubleTap,
        child: Transform.rotate(
          angle: element.rotation,
          child: Transform.scale(
            scale: element.scale,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                element.text,
                style: element.style,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for rendering and interacting with image elements
class ImageElementWidget extends StatelessWidget {
  final ImageElement element;
  final Function(ImageElement) onUpdate;
  final bool isSelected;

  const ImageElementWidget({
    super.key,
    required this.element,
    required this.onUpdate,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final updatedElement = element.copyWith(
            position: element.position + details.delta,
          );
          onUpdate(updatedElement);
        },
        onScaleUpdate: (details) {
          final updatedElement = element.copyWith(
            scale: element.scale * details.scale,
            rotation: element.rotation + details.rotation,
          );
          onUpdate(updatedElement);
        },
        child: Transform.rotate(
          angle: element.rotation,
          child: Transform.scale(
            scale: element.scale,
            child: Container(
              width: element.width,
              height: element.height,
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    )
                  : null,
              child: Image.memory(
                element.imageData,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for rendering canvas elements directly on canvas
class ElementPainter extends CustomPainter {
  final List<CanvasElement> elements;

  ElementPainter({required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      canvas.save();
      canvas.translate(element.position.dx, element.position.dy);
      canvas.rotate(element.rotation);
      canvas.scale(element.scale);

      if (element is ImageElement) {
        _drawImage(canvas, element);
      } else if (element is TextElement) {
        _drawText(canvas, element);
      }

      canvas.restore();
    }
  }

  void _drawImage(Canvas canvas, ImageElement element) {
    try {
      final image = img.decodeImage(element.imageData);
      if (image != null) {
        // Convert img.Image to ui.Image would require async, so we skip this
        // In practice, use Image.memory widget instead
      }
    } catch (e) {
      debugPrint('Error drawing image: $e');
    }
  }

  void _drawText(Canvas canvas, TextElement element) {
    try {
      final textPainter = TextPainter(
        text: TextSpan(text: element.text, style: element.style),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);
    } catch (e) {
      debugPrint('Error drawing text: $e');
    }
  }

  @override
  bool shouldRepaint(covariant ElementPainter oldDelegate) {
    return oldDelegate.elements.length != elements.length;
  }
}

/// Dialog for editing text elements
class TextEditDialog extends StatefulWidget {
  final TextElement element;

  const TextEditDialog({super.key, required this.element});

  @override
  State<TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<TextEditDialog> {
  late TextEditingController _controller;
  late Color _selectedColor;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.element.text);
    _selectedColor = widget.element.style.color ?? Colors.black;
    _fontSize = widget.element.style.fontSize ?? 24;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Text'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Font Size: '),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12,
                  max: 72,
                  divisions: 60,
                  label: _fontSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Color: '),
              const SizedBox(width: 16),
              _buildColorButton(Colors.black),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.green),
              _buildColorButton(Colors.orange),
              _buildColorButton(Colors.purple),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedElement = widget.element.copyWith(
              text: _controller.text,
              style: widget.element.style.copyWith(
                fontSize: _fontSize,
                color: _selectedColor,
              ),
            );
            Navigator.of(context).pop(updatedElement);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedColor = color;
          });
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedColor == color ? Colors.blue : Colors.grey,
              width: _selectedColor == color ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
