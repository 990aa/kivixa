// lib/presentation/widgets/toolbar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/drawing_provider.dart';
import '../../domain/models/note.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingState = ref.watch(drawingProvider);
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tool selection
          _ToolButton(
            tool: DrawingTool.pen,
            isSelected: drawingState.selectedTool == DrawingTool.pen,
            icon: Icons.edit,
            onTap: () => ref.read(drawingProvider.notifier).selectTool(DrawingTool.pen),
          ),
          _ToolButton(
            tool: DrawingTool.highlighter,
            isSelected: drawingState.selectedTool == DrawingTool.highlighter,
            icon: Icons.highlight,
            onTap: () => ref.read(drawingProvider.notifier).selectTool(DrawingTool.highlighter),
          ),
          _ToolButton(
            tool: DrawingTool.eraser,
            isSelected: drawingState.selectedTool == DrawingTool.eraser,
            icon: Icons.auto_delete,
            onTap: () => ref.read(drawingProvider.notifier).selectTool(DrawingTool.eraser),
          ),
          const VerticalDivider(),
          // Color picker
          _ColorPickerButton(
            currentColor: drawingState.selectedColor,
            onColorSelected: (color) => ref.read(drawingProvider.notifier).setColor(color),
          ),
          const VerticalDivider(),
          // Thickness slider
          Expanded(
            child: Slider(
              value: drawingState.thickness,
              min: 1,
              max: 20,
              onChanged: (value) => ref.read(drawingProvider.notifier).setThickness(value),
            ),
          ),
          // Add image button
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () => _pickImage(context, ref),
          ),
          // Add page button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addPage(context, ref),
          ),
        ],
      ),
    );
  }

  void _pickImage(BuildContext context, WidgetRef ref) async {
    // Implementation for image picker
  }

  void _addPage(BuildContext context, WidgetRef ref) {
    // Implementation for adding new page
  }
}

class _ToolButton extends StatelessWidget {
  final DrawingTool tool;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolButton({
    required this.tool,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
      onPressed: onTap,
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerButton({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      itemBuilder: (context) => [
        Colors.black,
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.orange,
        Colors.purple,
      ].map((color) => PopupMenuItem(
        value: color,
        child: Container(
          width: 24,
          height: 24,
          color: color,
        ),
      )).toList(),
      onSelected: onColorSelected,
    );
  }
}