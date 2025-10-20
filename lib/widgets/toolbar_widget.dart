import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kivixa/models/drawing_tool.dart';

class ToolbarWidget extends StatelessWidget {
  final DrawingTool currentTool;
  final Color currentColor;
  final ValueChanged<DrawingTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onClear;

  const ToolbarWidget({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onClear,
  });

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool selection buttons
            _buildToolButton(context, DrawingTool.pen, Icons.edit),
            _buildToolButton(context, DrawingTool.highlighter, Icons.highlight),
            _buildToolButton(context, DrawingTool.eraser, Icons.cleaning_services),

            const Divider(height: 16),

            // Color picker button
            GestureDetector(
              onTap: () => _showColorPicker(context),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: currentColor,
                child: currentTool == DrawingTool.eraser
                    ? const Icon(Icons.palette, color: Colors.white, size: 16)
                    : null,
              ),
            ),

            const Divider(height: 16),

            // Clear button
            IconButton(
              icon: const Icon(Icons.clear, size: 24),
              onPressed: onClear,
              tooltip: 'Clear Annotations',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
      BuildContext context, DrawingTool tool, IconData icon) {
    final isSelected = currentTool == tool;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
        size: 24,
      ),
      onPressed: () => onToolChanged(tool),
      tooltip: tool.toString().split('.').last,
    );
  }
}
