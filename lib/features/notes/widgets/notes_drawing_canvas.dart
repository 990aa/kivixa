
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/features/notes/widgets/paper_background.dart';
import 'package:scribble/scribble.dart';

class NotesDrawingCanvas extends StatefulWidget {
  const NotesDrawingCanvas({super.key});

  @override
  State<NotesDrawingCanvas> createState() => _NotesDrawingCanvasState();
}

class _NotesDrawingCanvasState extends State<NotesDrawingCanvas> {
  late ScribbleNotifier notifier;
  PaperType _paperType = PaperType.blank;

  @override
  void initState() {
    super.initState();
    notifier = ScribbleNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            RedoIntent(),
      },
      actions: {
        UndoIntent: CallbackAction(onInvoke: (e) => notifier.undo()),
        RedoIntent: CallbackAction(onInvoke: (e) => notifier.redo()),
      },
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Stack(
                children: [
                  PaperBackground(paperType: _paperType),
                  Listener(
                    onPointerDown: (details) {
                      switch (details.kind) {
                        case PointerDeviceKind.stylus:
                        case PointerDeviceKind.invertedStylus:
                          notifier.setAllowedPointers(1);
                          break;
                        case PointerDeviceKind.touch:
                          notifier.setAllowedPointers(2);
                          break;
                        case PointerDeviceKind.mouse:
                          notifier.setAllowedPointers(1);
                          break;
                        default:
                      }
                    },
                    child: Scribble(
                      notifier: notifier,
                      drawPen: true,
                      pressureCurve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => notifier.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => notifier.redo(),
          ),
          _buildToolButton(ScribbleTool.pen),
          _buildToolButton(ScribbleTool.eraser),
          _buildToolButton(ScribbleTool.highlighter),
          _buildColorPalette(),
          _buildStrokeWidthSlider(),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {
              setState(() {
                _paperType = PaperType.values[
                    (_paperType.index + 1) % PaperType.values.length];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(ScribbleTool tool) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        final isSelected = value.activeTool == tool;
        return IconButton(
          icon: Icon(
            _getIconForTool(tool),
            color: isSelected ? Theme.of(context).colorScheme.secondary : null,
          ),
          onPressed: () => notifier.setTool(tool),
        );
      },
    );
  }

  IconData _getIconForTool(ScribbleTool tool) {
    switch (tool) {
      case ScribbleTool.pen:
        return Icons.edit;
      case ScribbleTool.eraser:
        return Icons.cleaning_services;
      case ScribbleTool.highlighter:
        return Icons.highlight;
      default:
        return Icons.edit;
    }
  }

  Widget _buildColorPalette() {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        return Row(
          children: [
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.blue),
          ],
        );
      },
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => notifier.setColor(color),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 12,
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        return Slider(
          value: value.strokeWidth,
          min: 1,
          max: 10,
          onChanged: (val) => notifier.setStrokeWidth(val),
        );
      },
    );
  }
}

class UndoIntent extends Intent {}

class RedoIntent extends Intent {}
